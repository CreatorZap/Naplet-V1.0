import Foundation
import SwiftUI
import PhotosUI

// MARK: - Documents ViewModel
@MainActor
class DocumentsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var documentTypes: [DocumentType] = []
    @Published var documents: [BabyDocument] = []
    @Published var selectedDocument: BabyDocument?

    @Published var isLoading = false
    @Published var isUploading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // Filters
    @Published var searchText = ""
    @Published var selectedTypeFilter: DocumentType?
    @Published var showOnlyFavorites = false
    @Published var showOnlyExpiring = false

    // MARK: - Private Properties

    private let repository = DocumentRepository.shared
    private let baby: Baby

    // MARK: - Computed Properties

    var filteredDocuments: [BabyDocument] {
        var result = documents

        // Filter by text
        if !searchText.isEmpty {
            let search = searchText.lowercased()
            result = result.filter { doc in
                doc.title.localizedCaseInsensitiveContains(search) ||
                (doc.documentNumber?.localizedCaseInsensitiveContains(search) ?? false) ||
                (doc.documentType?.localizedName.localizedCaseInsensitiveContains(search) ?? false)
            }
        }

        // Filter by type
        if let typeFilter = selectedTypeFilter {
            result = result.filter { $0.documentTypeId == typeFilter.id }
        }

        // Filter by favorites
        if showOnlyFavorites {
            result = result.filter { $0.isFavorite }
        }

        // Filter by expiring
        if showOnlyExpiring {
            result = result.filter { doc in
                doc.expirationStatus == .expired || doc.expirationStatus == .expiringSoon
            }
        }

        return result
    }

    var expiringDocumentsCount: Int {
        documents.filter { $0.expirationStatus == .expiringSoon || $0.expirationStatus == .expired }.count
    }

    var documentsByType: [(DocumentType, [BabyDocument])] {
        let grouped = Dictionary(grouping: filteredDocuments) { doc -> UUID in
            doc.documentTypeId
        }

        return documentTypes.compactMap { type in
            guard let docs = grouped[type.id], !docs.isEmpty else { return nil }
            return (type, docs)
        }
    }

    var hasDocuments: Bool {
        !documents.isEmpty
    }

    // MARK: - Initialization

    init(baby: Baby) {
        self.baby = baby
    }

    // MARK: - Load Data

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load document types if not already loaded
            if documentTypes.isEmpty {
                Logger.info("Loading document types...")
                documentTypes = try await repository.fetchDocumentTypes()
                Logger.info("Document types loaded: \(documentTypes.count)")
            }

            // Load documents for baby
            Logger.info("Loading documents for baby: \(baby.id)...")
            documents = try await repository.fetchDocuments(babyId: baby.id)
            Logger.info("Loaded \(documentTypes.count) types and \(documents.count) documents")
        } catch let error as DecodingError {
            Logger.error("DecodingError loading documents: \(error)")
            errorMessage = "documents.error.load".localized
            showError = true
        } catch {
            Logger.error("Error loading documents: \(error.localizedDescription)")
            errorMessage = "documents.error.load".localized
            showError = true
        }

        isLoading = false
    }

    func refresh() async {
        await loadData()
    }

    // MARK: - Document Actions

    func createDocument(
        typeId: UUID,
        title: String,
        documentNumber: String?,
        issueDate: Date?,
        expirationDate: Date?,
        issuingAuthority: String?,
        notes: String?
    ) async -> BabyDocument? {
        isLoading = true

        do {
            let insert = BabyDocumentInsert(
                babyId: baby.id,
                documentTypeId: typeId,
                title: title,
                documentNumber: documentNumber,
                issueDate: issueDate,
                expirationDate: expirationDate,
                issuingAuthority: issuingAuthority,
                notes: notes,
                uploadedBy: SupabaseService.shared.currentUserId,
                isFavorite: false
            )

            let document = try await repository.createDocument(insert)
            documents.insert(document, at: 0)

            Logger.info("Created document: \(document.title)")
            isLoading = false
            return document
        } catch {
            Logger.error("Error creating document: \(error)")
            errorMessage = "documents.error.create".localized
            showError = true
            isLoading = false
            return nil
        }
    }

    func updateDocument(_ document: BabyDocument) async {
        do {
            let updated = try await repository.updateDocument(document)
            if let index = documents.firstIndex(where: { $0.id == document.id }) {
                documents[index] = updated
            }
            Logger.info("Updated document: \(document.title)")
        } catch {
            Logger.error("Error updating document: \(error)")
            errorMessage = "documents.error.update".localized
            showError = true
        }
    }

    func deleteDocument(_ document: BabyDocument) async {
        do {
            try await repository.deleteDocument(id: document.id)
            documents.removeAll { $0.id == document.id }
            Logger.info("Deleted document: \(document.title)")
        } catch {
            Logger.error("Error deleting document: \(error)")
            errorMessage = "documents.error.delete".localized
            showError = true
        }
    }

    func toggleFavorite(_ document: BabyDocument) async {
        let newValue = !document.isFavorite

        do {
            try await repository.toggleFavorite(documentId: document.id, isFavorite: newValue)
            if let index = documents.firstIndex(where: { $0.id == document.id }) {
                documents[index].isFavorite = newValue
            }
            Logger.info("Toggled favorite for: \(document.title)")
        } catch {
            Logger.error("Error toggling favorite: \(error)")
            errorMessage = "documents.error.update".localized
            showError = true
        }
    }

    // MARK: - File Upload

    func uploadImage(to document: BabyDocument, imageData: Data, fileName: String = "documento.jpg") async {
        isUploading = true
        
        Logger.info("📤 [VM-UPLOAD] Starting upload to document: \(document.id)")
        Logger.info("📤 [VM-UPLOAD] File name: \(fileName), Data size: \(imageData.count)")

        do {
            let pageNumber = (document.files?.count ?? 0) + 1
            
            // Detect mime type from file extension
            let mimeType = detectMimeType(from: fileName, data: imageData)
            Logger.info("📤 [VM-UPLOAD] Detected MIME type: \(mimeType)")
            
            let file = try await repository.uploadFile(
                documentId: document.id,
                imageData: imageData,
                fileName: fileName,
                pageNumber: pageNumber,
                mimeType: mimeType
            )

            // Update local document
            if let index = documents.firstIndex(where: { $0.id == document.id }) {
                if documents[index].files == nil {
                    documents[index].files = []
                }
                documents[index].files?.append(file)
            }

            Logger.info("✅ [VM-UPLOAD] Uploaded file to document: \(document.title)")
        } catch {
            Logger.error("❌ [VM-UPLOAD] Error uploading file: \(error)")
            errorMessage = "documents.error.upload".localized
            showError = true
        }

        isUploading = false
    }
    
    /// Detect MIME type from file name extension or data signature
    private func detectMimeType(from fileName: String, data: Data) -> String {
        let ext = fileName.components(separatedBy: ".").last?.lowercased() ?? ""
        
        switch ext {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "heic", "heif":
            return "image/heic"
        case "pdf":
            return "application/pdf"
        default:
            // Try to detect from data signature
            if data.count >= 4 {
                let bytes = [UInt8](data.prefix(4))
                
                // JPEG: FF D8 FF
                if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
                    return "image/jpeg"
                }
                // PNG: 89 50 4E 47
                if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
                    return "image/png"
                }
                // PDF: 25 50 44 46 (%PDF)
                if bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46 {
                    return "application/pdf"
                }
            }
            return "image/jpeg" // Default
        }
    }

    func deleteFile(_ file: DocumentFile, from document: BabyDocument) async {
        do {
            try await repository.deleteFile(id: file.id, filePath: file.filePath)

            if let docIndex = documents.firstIndex(where: { $0.id == document.id }) {
                documents[docIndex].files?.removeAll { $0.id == file.id }
            }

            Logger.info("Deleted file from document: \(document.title)")
        } catch {
            Logger.error("Error deleting file: \(error)")
            errorMessage = "documents.error.deleteFile".localized
            showError = true
        }
    }

    // MARK: - Filter Actions

    func clearFilters() {
        searchText = ""
        selectedTypeFilter = nil
        showOnlyFavorites = false
        showOnlyExpiring = false
    }

    func selectTypeFilter(_ type: DocumentType?) {
        if selectedTypeFilter?.id == type?.id {
            selectedTypeFilter = nil
        } else {
            selectedTypeFilter = type
        }
    }
}

// MARK: - Document Filter
enum DocumentFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case favorites = "favorites"
    case expiring = "expiring"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "documents.filter.all".localized
        case .favorites: return "documents.filter.favorites".localized
        case .expiring: return "documents.filter.expiring".localized
        }
    }

    var icon: String {
        switch self {
        case .all: return "doc.fill"
        case .favorites: return "star.fill"
        case .expiring: return "exclamationmark.triangle.fill"
        }
    }
}
