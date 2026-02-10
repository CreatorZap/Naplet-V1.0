import Foundation
import SwiftUI

// MARK: - Document Type
/// Representa um tipo de documento da carteira
struct DocumentType: Codable, Identifiable, Equatable {
    let id: UUID
    let code: String
    let name: String
    let nameEn: String
    let nameEs: String
    let description: String?
    let icon: String
    let color: String
    let hasExpiration: Bool
    let orderIndex: Int
    let isActive: Bool
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, code, name, description, icon, color
        case nameEn = "name_en"
        case nameEs = "name_es"
        case hasExpiration = "has_expiration"
        case orderIndex = "order_index"
        case isActive = "is_active"
        case createdAt = "created_at"
    }

    // Nome localizado
    var localizedName: String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "pt"
        switch languageCode {
        case "en": return nameEn
        case "es": return nameEs
        default: return name
        }
    }

    // Cor como SwiftUI Color
    var swiftUIColor: Color {
        Color(hex: color)
    }

    /// SF Symbol icon based on document type code
    var sfSymbol: String {
        switch code {
        case "birth_certificate":
            return "doc.text.fill"
        case "rg":
            return "person.text.rectangle.fill"
        case "cpf":
            return "creditcard.fill"
        case "passport":
            return "airplane.circle.fill"
        case "vaccination_card":
            return "syringe.fill"
        case "sus_card":
            return "cross.case.fill"
        case "health_insurance":
            return "building.columns.fill"
        case "baptism_certificate":
            return "book.closed.fill"
        case "medical_exams":
            return "waveform.path.ecg.rectangle.fill"
        case "prescriptions":
            return "pills.fill"
        case "medical_reports":
            return "list.clipboard.fill"
        case "special_photos":
            return "photo.fill"
        case "other":
            return "paperclip"
        default:
            return "doc.fill"
        }
    }

    // Custom decoding para lidar com campos opcionais
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        code = try container.decode(String.self, forKey: .code)
        name = try container.decode(String.self, forKey: .name)
        nameEn = try container.decodeIfPresent(String.self, forKey: .nameEn) ?? name
        nameEs = try container.decodeIfPresent(String.self, forKey: .nameEs) ?? name
        description = try container.decodeIfPresent(String.self, forKey: .description)
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? "doc.fill"
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? "#7C3AED"
        hasExpiration = try container.decodeIfPresent(Bool.self, forKey: .hasExpiration) ?? false
        orderIndex = try container.decodeIfPresent(Int.self, forKey: .orderIndex) ?? 0
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        
        // Decode timestamp from ISO8601 string (Supabase format)
        if let dateString = try container.decodeIfPresent(String.self, forKey: .createdAt), !dateString.isEmpty {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                createdAt = date
            } else {
                isoFormatter.formatOptions = [.withInternetDateTime]
                createdAt = isoFormatter.date(from: dateString)
            }
        } else {
            createdAt = nil
        }
    }

    // Init para previews/testes
    init(
        id: UUID = UUID(),
        code: String,
        name: String,
        nameEn: String? = nil,
        nameEs: String? = nil,
        description: String? = nil,
        icon: String = "doc.fill",
        color: String = "#7C3AED",
        hasExpiration: Bool = false,
        orderIndex: Int = 0,
        isActive: Bool = true,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.code = code
        self.name = name
        self.nameEn = nameEn ?? name
        self.nameEs = nameEs ?? name
        self.description = description
        self.icon = icon
        self.color = color
        self.hasExpiration = hasExpiration
        self.orderIndex = orderIndex
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

// MARK: - Document Type Code Enum
enum DocumentTypeCode: String, CaseIterable {
    case birthCertificate = "birth_certificate"
    case rg = "rg"
    case cpf = "cpf"
    case passport = "passport"
    case vaccinationCard = "vaccination_card"
    case susCard = "sus_card"
    case healthInsurance = "health_insurance"
    case baptismCertificate = "baptism_certificate"
    case medicalExams = "medical_exams"
    case prescriptions = "prescriptions"
    case medicalReports = "medical_reports"
    case specialPhotos = "special_photos"
    case other = "other"
}

// MARK: - Baby Document
/// Representa um documento do bebe
struct BabyDocument: Codable, Identifiable, Equatable {
    let id: UUID
    let babyId: UUID
    let documentTypeId: UUID
    var title: String
    var documentNumber: String?
    var issueDate: Date?
    var expirationDate: Date?
    var issuingAuthority: String?
    var notes: String?
    let uploadedBy: UUID?
    var isFavorite: Bool
    let createdAt: Date?
    var updatedAt: Date?

    // Relacionamentos (populated quando necessario)
    var documentType: DocumentType?
    var files: [DocumentFile]?

    enum CodingKeys: String, CodingKey {
        case id, title, notes
        case babyId = "baby_id"
        case documentTypeId = "document_type_id"
        case documentNumber = "document_number"
        case issueDate = "issue_date"
        case expirationDate = "expiration_date"
        case issuingAuthority = "issuing_authority"
        case uploadedBy = "uploaded_by"
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case documentType = "document_types"
        case files = "document_files"
    }

    // Computed properties
    var isExpired: Bool {
        guard let expiration = expirationDate else { return false }
        return expiration < Date()
    }

    var daysUntilExpiration: Int? {
        guard let expiration = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expiration).day
    }

    var expirationStatus: ExpirationStatus {
        guard let days = daysUntilExpiration else { return .noExpiration }
        if days < 0 { return .expired }
        if days <= 30 { return .expiringSoon }
        return .valid
    }

    var thumbnailURL: URL? {
        guard let urlString = files?.first?.fileUrl else { return nil }
        return URL(string: urlString)
    }

    var fileCount: Int {
        files?.count ?? 0
    }

    // Custom decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        babyId = try container.decode(UUID.self, forKey: .babyId)
        documentTypeId = try container.decode(UUID.self, forKey: .documentTypeId)
        title = try container.decode(String.self, forKey: .title)
        documentNumber = try container.decodeIfPresent(String.self, forKey: .documentNumber)
        
        // Decode dates from strings (Supabase returns "yyyy-MM-dd" for date columns)
        issueDate = Self.decodeDateFromString(container: container, forKey: .issueDate)
        expirationDate = Self.decodeDateFromString(container: container, forKey: .expirationDate)
        
        issuingAuthority = try container.decodeIfPresent(String.self, forKey: .issuingAuthority)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        uploadedBy = try container.decodeIfPresent(UUID.self, forKey: .uploadedBy)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        
        // Decode timestamps from strings (Supabase returns ISO8601 format)
        createdAt = Self.decodeTimestampFromString(container: container, forKey: .createdAt)
        updatedAt = Self.decodeTimestampFromString(container: container, forKey: .updatedAt)
        
        documentType = try container.decodeIfPresent(DocumentType.self, forKey: .documentType)
        files = try container.decodeIfPresent([DocumentFile].self, forKey: .files)
    }
    
    // Helper to decode date from "yyyy-MM-dd" string
    private static func decodeDateFromString(container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Date? {
        guard let dateString = try? container.decodeIfPresent(String.self, forKey: key), !dateString.isEmpty else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dateString)
    }
    
    // Helper to decode timestamp from ISO8601 string
    private static func decodeTimestampFromString(container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Date? {
        guard let dateString = try? container.decodeIfPresent(String.self, forKey: key), !dateString.isEmpty else {
            return nil
        }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateString) {
            return date
        }
        // Try without fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: dateString)
    }

    // Init para previews/testes
    init(
        id: UUID = UUID(),
        babyId: UUID,
        documentTypeId: UUID,
        title: String,
        documentNumber: String? = nil,
        issueDate: Date? = nil,
        expirationDate: Date? = nil,
        issuingAuthority: String? = nil,
        notes: String? = nil,
        uploadedBy: UUID? = nil,
        isFavorite: Bool = false,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        documentType: DocumentType? = nil,
        files: [DocumentFile]? = nil
    ) {
        self.id = id
        self.babyId = babyId
        self.documentTypeId = documentTypeId
        self.title = title
        self.documentNumber = documentNumber
        self.issueDate = issueDate
        self.expirationDate = expirationDate
        self.issuingAuthority = issuingAuthority
        self.notes = notes
        self.uploadedBy = uploadedBy
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.documentType = documentType
        self.files = files
    }
}

// MARK: - Expiration Status
enum ExpirationStatus {
    case noExpiration
    case valid
    case expiringSoon
    case expired

    var color: Color {
        switch self {
        case .noExpiration, .valid: return NapletColors.success
        case .expiringSoon: return NapletColors.warning
        case .expired: return NapletColors.error
        }
    }

    var icon: String {
        switch self {
        case .noExpiration: return "checkmark.circle.fill"
        case .valid: return "checkmark.circle.fill"
        case .expiringSoon: return "exclamationmark.triangle.fill"
        case .expired: return "xmark.circle.fill"
        }
    }
}

// MARK: - Document File
/// Representa um arquivo/pagina de um documento
struct DocumentFile: Codable, Identifiable, Equatable {
    let id: UUID
    let documentId: UUID
    let fileName: String
    let filePath: String
    var fileUrl: String?
    let fileSize: Int?
    let mimeType: String
    let pageNumber: Int
    let width: Int?
    let height: Int?
    var thumbnailUrl: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, width, height
        case documentId = "document_id"
        case fileName = "file_name"
        case filePath = "file_path"
        case fileUrl = "file_url"
        case fileSize = "file_size"
        case mimeType = "mime_type"
        case pageNumber = "page_number"
        case thumbnailUrl = "thumbnail_url"
        case createdAt = "created_at"
    }

    var fileURL: URL? {
        guard let urlString = fileUrl else { return nil }
        return URL(string: urlString)
    }

    var thumbnailURL: URL? {
        guard let urlString = thumbnailUrl ?? fileUrl else { return nil }
        return URL(string: urlString)
    }

    var isPDF: Bool {
        mimeType == "application/pdf"
    }

    var isImage: Bool {
        mimeType.hasPrefix("image/")
    }

    var formattedFileSize: String {
        guard let size = fileSize else { return "" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    // Custom decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        documentId = try container.decode(UUID.self, forKey: .documentId)
        fileName = try container.decode(String.self, forKey: .fileName)
        filePath = try container.decode(String.self, forKey: .filePath)
        fileUrl = try container.decodeIfPresent(String.self, forKey: .fileUrl)
        fileSize = try container.decodeIfPresent(Int.self, forKey: .fileSize)
        mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType) ?? "image/jpeg"
        pageNumber = try container.decodeIfPresent(Int.self, forKey: .pageNumber) ?? 1
        width = try container.decodeIfPresent(Int.self, forKey: .width)
        height = try container.decodeIfPresent(Int.self, forKey: .height)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        
        // Decode timestamp from ISO8601 string (Supabase format)
        if let dateString = try container.decodeIfPresent(String.self, forKey: .createdAt), !dateString.isEmpty {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                createdAt = date
            } else {
                isoFormatter.formatOptions = [.withInternetDateTime]
                createdAt = isoFormatter.date(from: dateString)
            }
        } else {
            createdAt = nil
        }
    }

    // Init para previews/testes
    init(
        id: UUID = UUID(),
        documentId: UUID,
        fileName: String,
        filePath: String,
        fileUrl: String? = nil,
        fileSize: Int? = nil,
        mimeType: String = "image/jpeg",
        pageNumber: Int = 1,
        width: Int? = nil,
        height: Int? = nil,
        thumbnailUrl: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.documentId = documentId
        self.fileName = fileName
        self.filePath = filePath
        self.fileUrl = fileUrl
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.pageNumber = pageNumber
        self.width = width
        self.height = height
        self.thumbnailUrl = thumbnailUrl
        self.createdAt = createdAt
    }
}

// MARK: - Insert DTOs

/// DTO para insercao de documento
struct BabyDocumentInsert: Codable {
    let babyId: UUID
    let documentTypeId: UUID
    let title: String
    let documentNumber: String?
    let issueDate: String?
    let expirationDate: String?
    let issuingAuthority: String?
    let notes: String?
    let uploadedBy: UUID?
    let isFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case title, notes
        case babyId = "baby_id"
        case documentTypeId = "document_type_id"
        case documentNumber = "document_number"
        case issueDate = "issue_date"
        case expirationDate = "expiration_date"
        case issuingAuthority = "issuing_authority"
        case uploadedBy = "uploaded_by"
        case isFavorite = "is_favorite"
    }

    init(
        babyId: UUID,
        documentTypeId: UUID,
        title: String,
        documentNumber: String? = nil,
        issueDate: Date? = nil,
        expirationDate: Date? = nil,
        issuingAuthority: String? = nil,
        notes: String? = nil,
        uploadedBy: UUID? = nil,
        isFavorite: Bool = false
    ) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        self.babyId = babyId
        self.documentTypeId = documentTypeId
        self.title = title
        self.documentNumber = documentNumber
        self.issueDate = issueDate.map { dateFormatter.string(from: $0) }
        self.expirationDate = expirationDate.map { dateFormatter.string(from: $0) }
        self.issuingAuthority = issuingAuthority
        self.notes = notes
        self.uploadedBy = uploadedBy
        self.isFavorite = isFavorite
    }
}

/// DTO para insercao de arquivo
struct DocumentFileInsert: Codable {
    let documentId: UUID
    let fileName: String
    let filePath: String
    let fileUrl: String?
    let fileSize: Int?
    let mimeType: String
    let pageNumber: Int
    let width: Int?
    let height: Int?
    let thumbnailUrl: String?

    enum CodingKeys: String, CodingKey {
        case width, height
        case documentId = "document_id"
        case fileName = "file_name"
        case filePath = "file_path"
        case fileUrl = "file_url"
        case fileSize = "file_size"
        case mimeType = "mime_type"
        case pageNumber = "page_number"
        case thumbnailUrl = "thumbnail_url"
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension DocumentType {
    static let preview = DocumentType(
        code: "birth_certificate",
        name: "Certidao de Nascimento",
        nameEn: "Birth Certificate",
        nameEs: "Acta de Nacimiento",
        description: "Documento oficial de registro civil",
        icon: "doc.text.fill",
        color: "#7C3AED",
        hasExpiration: false,
        orderIndex: 1
    )

    static let previewList: [DocumentType] = [
        .preview,
        DocumentType(code: "rg", name: "RG", icon: "person.text.rectangle.fill", color: "#EC4899", hasExpiration: true, orderIndex: 2),
        DocumentType(code: "cpf", name: "CPF", icon: "creditcard.fill", color: "#3B82F6", orderIndex: 3),
        DocumentType(code: "passport", name: "Passaporte", icon: "airplane.circle.fill", color: "#10B981", hasExpiration: true, orderIndex: 4)
    ]
}

extension BabyDocument {
    static let preview = BabyDocument(
        babyId: UUID(),
        documentTypeId: UUID(),
        title: "Certidao de Nascimento",
        documentNumber: "123456",
        issueDate: Date(),
        isFavorite: true,
        documentType: .preview
    )
}
#endif
