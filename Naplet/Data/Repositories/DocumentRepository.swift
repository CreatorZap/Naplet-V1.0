import Foundation
import Supabase

// MARK: - Document Repository Protocol
protocol DocumentRepositoryProtocol {
    func fetchDocumentTypes() async throws -> [DocumentType]
    func fetchDocuments(babyId: UUID) async throws -> [BabyDocument]
    func fetchDocument(id: UUID) async throws -> BabyDocument
    func createDocument(_ document: BabyDocumentInsert) async throws -> BabyDocument
    func updateDocument(_ document: BabyDocument) async throws -> BabyDocument
    func deleteDocument(id: UUID) async throws
    func uploadFile(documentId: UUID, imageData: Data, fileName: String, pageNumber: Int, mimeType: String) async throws -> DocumentFile
    func deleteFile(id: UUID, filePath: String) async throws
    func toggleFavorite(documentId: UUID, isFavorite: Bool) async throws
}

// MARK: - Document Repository
@MainActor
class DocumentRepository: ObservableObject, DocumentRepositoryProtocol {
    static let shared = DocumentRepository()

    // MARK: - Published Properties
    @Published var documentTypes: [DocumentType] = []
    @Published var documents: [BabyDocument] = []

    // MARK: - Private Properties
    private let documentTypesTable = "document_types"
    private let documentsTable = "baby_documents"
    private let filesTable = "document_files"
    private let bucketName = "baby-documents"
    private let supabase = SupabaseService.shared

    private init() {}

    // MARK: - Document Types

    func fetchDocumentTypes() async throws -> [DocumentType] {
        Logger.info("Fetching document types from Supabase...")

        do {
            let types: [DocumentType] = try await supabase.client
                .from(documentTypesTable)
                .select()
                .eq("is_active", value: true)
                .order("order_index", ascending: true)
                .execute()
                .value

            self.documentTypes = types
            Logger.info("✅ Fetched \(types.count) document types")
            return types
        } catch let error as PostgrestError {
            Logger.error("❌ PostgrestError fetching document types: \(error.localizedDescription)")
            throw error
        } catch let error as DecodingError {
            Logger.error("❌ DecodingError fetching document types: \(error)")
            throw error
        } catch {
            Logger.error("❌ Failed to fetch document types: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Documents

    func fetchDocuments(babyId: UUID) async throws -> [BabyDocument] {
        Logger.info("Fetching documents for baby \(babyId)...")
        
        // Check authentication
        guard let userId = supabase.currentUserId else {
            Logger.error("❌ User not authenticated")
            throw DocumentRepositoryError.notAuthenticated
        }
        Logger.info("✅ User authenticated: \(userId.uuidString)")

        do {
            let documents: [BabyDocument] = try await supabase.client
                .from(documentsTable)
                .select("""
                    *,
                    document_types (*),
                    document_files (*)
                """)
                .eq("baby_id", value: babyId.uuidString)
                .order("is_favorite", ascending: false)
                .order("created_at", ascending: false)
                .execute()
                .value

            self.documents = documents
            Logger.info("✅ Fetched \(documents.count) documents")
            return documents
        } catch let error as PostgrestError {
            Logger.error("❌ PostgrestError fetching documents: \(error.localizedDescription)")
            throw error
        } catch let error as DecodingError {
            Logger.error("❌ DecodingError fetching documents: \(error)")
            throw error
        } catch {
            Logger.error("❌ Failed to fetch documents: \(error.localizedDescription)")
            throw error
        }
    }

    func fetchDocument(id: UUID) async throws -> BabyDocument {
        Logger.info("Fetching document \(id)...")

        do {
            let document: BabyDocument = try await supabase.client
                .from(documentsTable)
                .select("""
                    *,
                    document_types (*),
                    document_files (*)
                """)
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value

            Logger.info("Fetched document: \(document.title)")
            return document
        } catch {
            Logger.error("Failed to fetch document: \(error)")
            throw error
        }
    }

    func createDocument(_ document: BabyDocumentInsert) async throws -> BabyDocument {
        Logger.info("Creating document: \(document.title)...")
        Logger.info("Document data - babyId: \(document.babyId), typeId: \(document.documentTypeId), title: \(document.title)")
        Logger.info("Current user ID: \(supabase.currentUserId?.uuidString ?? "nil")")

        do {
            let created: BabyDocument = try await supabase.client
                .from(documentsTable)
                .insert(document)
                .select("""
                    *,
                    document_types (*),
                    document_files (*)
                """)
                .single()
                .execute()
                .value

            self.documents.insert(created, at: 0)
            Logger.info("Created document with id: \(created.id)")
            return created
        } catch let error as PostgrestError {
            Logger.error("❌ PostgrestError creating document:")
            Logger.error("   Error: \(error)")
            Logger.error("   Description: \(error.localizedDescription)")
            throw error
        } catch {
            Logger.error("Failed to create document: \(error)")
            Logger.error("Error type: \(type(of: error))")
            throw error
        }
    }

    func updateDocument(_ document: BabyDocument) async throws -> BabyDocument {
        Logger.info("Updating document \(document.id)...")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var updateData: [String: AnyEncodable] = [
            "title": AnyEncodable(document.title),
            "is_favorite": AnyEncodable(document.isFavorite),
            "updated_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]

        if let docNumber = document.documentNumber {
            updateData["document_number"] = AnyEncodable(docNumber)
        }
        if let issueDate = document.issueDate {
            updateData["issue_date"] = AnyEncodable(dateFormatter.string(from: issueDate))
        }
        if let expirationDate = document.expirationDate {
            updateData["expiration_date"] = AnyEncodable(dateFormatter.string(from: expirationDate))
        }
        if let authority = document.issuingAuthority {
            updateData["issuing_authority"] = AnyEncodable(authority)
        }
        if let notes = document.notes {
            updateData["notes"] = AnyEncodable(notes)
        }

        do {
            let updated: BabyDocument = try await supabase.client
                .from(documentsTable)
                .update(updateData)
                .eq("id", value: document.id.uuidString)
                .select("""
                    *,
                    document_types (*),
                    document_files (*)
                """)
                .single()
                .execute()
                .value

            // Update local cache
            if let index = documents.firstIndex(where: { $0.id == document.id }) {
                documents[index] = updated
            }

            Logger.info("Updated document: \(document.id)")
            return updated
        } catch {
            Logger.error("Failed to update document: \(error)")
            throw error
        }
    }

    func deleteDocument(id: UUID) async throws {
        Logger.info("Deleting document \(id)...")

        do {
            // First fetch files to delete from storage
            let files: [DocumentFile] = try await supabase.client
                .from(filesTable)
                .select()
                .eq("document_id", value: id.uuidString)
                .execute()
                .value

            // Delete files from storage
            for file in files {
                try? await supabase.client.storage
                    .from(bucketName)
                    .remove(paths: [file.filePath])
            }

            // Delete document (cascade deletes files)
            try await supabase.client
                .from(documentsTable)
                .delete()
                .eq("id", value: id.uuidString)
                .execute()

            // Update local cache
            documents.removeAll { $0.id == id }

            Logger.info("Deleted document and \(files.count) files")
        } catch {
            Logger.error("Failed to delete document: \(error)")
            throw error
        }
    }

    func toggleFavorite(documentId: UUID, isFavorite: Bool) async throws {
        Logger.info("Toggling favorite for document \(documentId) to \(isFavorite)")

        let updateData: [String: AnyEncodable] = [
            "is_favorite": AnyEncodable(isFavorite),
            "updated_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]

        do {
            try await supabase.client
                .from(documentsTable)
                .update(updateData)
                .eq("id", value: documentId.uuidString)
                .execute()

            // Update local cache
            if let index = documents.firstIndex(where: { $0.id == documentId }) {
                documents[index].isFavorite = isFavorite
            }

            Logger.info("Toggled favorite successfully")
        } catch {
            Logger.error("Failed to toggle favorite: \(error)")
            throw error
        }
    }

    // MARK: - Files

    func uploadFile(documentId: UUID, imageData: Data, fileName: String, pageNumber: Int, mimeType: String = "image/jpeg") async throws -> DocumentFile {
        Logger.info("📤 [UPLOAD] Starting upload for document \(documentId)...")
        Logger.info("📤 [UPLOAD] File: \(fileName), Size: \(imageData.count) bytes, MimeType: \(mimeType)")

        do {
            // Generate unique path
            let fileExtension = fileName.components(separatedBy: ".").last ?? "jpg"
            let uniqueFileName = "\(UUID().uuidString).\(fileExtension)"
            let filePath = "\(documentId.uuidString)/\(uniqueFileName)"
            
            Logger.info("📤 [UPLOAD] Bucket: \(bucketName), Path: \(filePath)")

            // Upload to storage
            let uploadResult = try await supabase.client.storage
                .from(bucketName)
                .upload(filePath, data: imageData, options: .init(contentType: mimeType))
            
            Logger.info("📤 [UPLOAD] Upload successful: \(uploadResult)")

            // Get public URL
            let fileUrl = try supabase.client.storage
                .from(bucketName)
                .getPublicURL(path: filePath)
            
            Logger.info("📤 [UPLOAD] Public URL generated: \(fileUrl.absoluteString)")

            // Create record in database
            let fileInsert = DocumentFileInsert(
                documentId: documentId,
                fileName: fileName,
                filePath: filePath,
                fileUrl: fileUrl.absoluteString,
                fileSize: imageData.count,
                mimeType: mimeType,
                pageNumber: pageNumber,
                width: nil,
                height: nil,
                thumbnailUrl: fileUrl.absoluteString
            )

            let savedFile: DocumentFile = try await supabase.client
                .from(filesTable)
                .insert(fileInsert)
                .select()
                .single()
                .execute()
                .value
            
            Logger.info("📤 [UPLOAD] Database record created: \(savedFile.id)")
            Logger.info("📤 [UPLOAD] Saved file URL: \(savedFile.fileUrl ?? "nil")")

            // Update local cache
            if let docIndex = documents.firstIndex(where: { $0.id == documentId }) {
                if documents[docIndex].files == nil {
                    documents[docIndex].files = []
                }
                documents[docIndex].files?.append(savedFile)
            }

            Logger.info("✅ [UPLOAD] Complete! File ID: \(savedFile.id)")
            return savedFile
        } catch {
            Logger.error("❌ [UPLOAD] Failed: \(error)")
            Logger.error("❌ [UPLOAD] Error type: \(type(of: error))")
            Logger.error("❌ [UPLOAD] Description: \(error.localizedDescription)")
            throw error
        }
    }

    func deleteFile(id: UUID, filePath: String) async throws {
        Logger.info("Deleting file \(id)...")

        do {
            // Delete from storage
            try await supabase.client.storage
                .from(bucketName)
                .remove(paths: [filePath])

            // Delete from database
            try await supabase.client
                .from(filesTable)
                .delete()
                .eq("id", value: id.uuidString)
                .execute()

            // Update local cache
            for i in 0..<documents.count {
                documents[i].files?.removeAll { $0.id == id }
            }

            Logger.info("Deleted file successfully")
        } catch {
            Logger.error("Failed to delete file: \(error)")
            throw error
        }
    }
}

// MARK: - Document Repository Error
enum DocumentRepositoryError: LocalizedError {
    case notAuthenticated
    case documentNotFound
    case fileUploadFailed
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .documentNotFound:
            return "Document not found"
        case .fileUploadFailed:
            return "Failed to upload file"
        case .invalidData:
            return "Invalid document data"
        }
    }
}
