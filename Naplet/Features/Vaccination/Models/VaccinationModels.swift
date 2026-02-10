import Foundation
import SwiftUI

// MARK: - Vaccine
/// Representa uma vacina do calendário vacinal
/// Matches the actual Supabase vaccines table schema
struct Vaccine: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let nameEn: String?
    let description: String?
    let descriptionEn: String?
    let ageMonths: Int
    let doseNumber: Int
    let totalDoses: Int
    let isRequired: Bool
    let isPrivate: Bool
    let protectionInfo: String?
    let sideEffects: String?
    let postVaccineTips: String?
    let intervalDays: Int?
    let createdAt: Date?
    let updatedAt: Date?

    // MARK: - Computed Properties

    /// Texto formatado da idade recomendada
    var recommendedAgeText: String {
        if ageMonths == 0 {
            return "vaccination.age.birth".localized
        } else if ageMonths < 12 {
            return String(format: "vaccination.age.months".localized, ageMonths)
        } else {
            let years = ageMonths / 12
            let months = ageMonths % 12
            if months == 0 {
                return String(format: "vaccination.age.years".localized, years)
            } else {
                return String(format: "vaccination.age.yearsMonths".localized, years, months)
            }
        }
    }

    /// Texto da dose (ex: "1ª dose", "2ª dose")
    var doseText: String {
        if totalDoses == 1 {
            return "vaccination.dose.single".localized
        }
        return String(format: "vaccination.dose.number".localized, doseNumber, totalDoses)
    }

    /// Alias for compatibility - maps ageMonths to recommendedAgeMonths
    var recommendedAgeMonths: Int { ageMonths }

    /// Category based on isRequired and isPrivate flags
    var category: VaccineCategory {
        if isPrivate {
            return .special
        } else if isRequired {
            return .mandatory
        } else {
            return .recommended
        }
    }

    /// Localized name based on current locale
    var localizedName: String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "pt"
        if languageCode == "en", let englishName = nameEn, !englishName.isEmpty {
            return englishName
        }
        return name
    }

    /// Localized description based on current locale
    var localizedDescription: String? {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "pt"
        if languageCode == "en", let englishDesc = descriptionEn, !englishDesc.isEmpty {
            return englishDesc
        }
        return description
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case nameEn = "name_en"
        case description
        case descriptionEn = "description_en"
        case ageMonths = "age_months"
        case doseNumber = "dose_number"
        case totalDoses = "total_doses"
        case isRequired = "is_required"
        case isPrivate = "is_private"
        case protectionInfo = "protection_info"
        case sideEffects = "side_effects"
        case postVaccineTips = "post_vaccine_tips"
        case intervalDays = "interval_days"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Custom Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        nameEn = try container.decodeIfPresent(String.self, forKey: .nameEn)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        descriptionEn = try container.decodeIfPresent(String.self, forKey: .descriptionEn)
        ageMonths = try container.decodeIfPresent(Int.self, forKey: .ageMonths) ?? 0
        doseNumber = try container.decodeIfPresent(Int.self, forKey: .doseNumber) ?? 1
        totalDoses = try container.decodeIfPresent(Int.self, forKey: .totalDoses) ?? 1
        isRequired = try container.decodeIfPresent(Bool.self, forKey: .isRequired) ?? true
        isPrivate = try container.decodeIfPresent(Bool.self, forKey: .isPrivate) ?? false
        protectionInfo = try container.decodeIfPresent(String.self, forKey: .protectionInfo)
        sideEffects = try container.decodeIfPresent(String.self, forKey: .sideEffects)
        postVaccineTips = try container.decodeIfPresent(String.self, forKey: .postVaccineTips)
        intervalDays = try container.decodeIfPresent(Int.self, forKey: .intervalDays)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    // MARK: - Init for previews/testing
    init(
        id: UUID,
        name: String,
        nameEn: String? = nil,
        description: String? = nil,
        descriptionEn: String? = nil,
        ageMonths: Int,
        doseNumber: Int,
        totalDoses: Int,
        isRequired: Bool,
        isPrivate: Bool = false,
        protectionInfo: String? = nil,
        sideEffects: String? = nil,
        postVaccineTips: String? = nil,
        intervalDays: Int? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.nameEn = nameEn
        self.description = description
        self.descriptionEn = descriptionEn
        self.ageMonths = ageMonths
        self.doseNumber = doseNumber
        self.totalDoses = totalDoses
        self.isRequired = isRequired
        self.isPrivate = isPrivate
        self.protectionInfo = protectionInfo
        self.sideEffects = sideEffects
        self.postVaccineTips = postVaccineTips
        self.intervalDays = intervalDays
        self.createdAt = createdAt
        self.updatedAt = nil
    }
}

// MARK: - Vaccine Category
/// Categorias de vacinas
enum VaccineCategory: String, Codable, CaseIterable, Identifiable {
    case mandatory = "mandatory"
    case recommended = "recommended"
    case special = "special"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mandatory: return "vaccination.category.mandatory".localized
        case .recommended: return "vaccination.category.recommended".localized
        case .special: return "vaccination.category.special".localized
        }
    }

    var color: Color {
        switch self {
        case .mandatory: return NapletColors.primaryCyan
        case .recommended: return NapletColors.primaryPurple
        case .special: return NapletColors.warning
        }
    }

    var icon: String {
        switch self {
        case .mandatory: return "checkmark.shield.fill"
        case .recommended: return "shield.fill"
        case .special: return "star.fill"
        }
    }
}

// MARK: - Baby Vaccination
/// Registro de vacinação de um bebê
struct BabyVaccination: Identifiable, Codable, Equatable {
    let id: UUID
    let babyId: UUID
    let vaccineId: UUID
    var status: VaccinationStatus
    var applicationDate: Date?      // Maps to application_date in DB
    var scheduledDate: Date?        // Maps to scheduled_date in DB
    var batchNumber: String?        // Maps to batch_number in DB
    var location: String?
    var healthProfessional: String? // Maps to health_professional in DB
    var reactions: String?          // Maps to reactions in DB
    var notes: String?
    var recordedBy: UUID?           // Maps to recorded_by in DB
    var createdAt: Date?
    var updatedAt: Date?

    // MARK: - CodingKeys - Match exact DB column names

    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case vaccineId = "vaccine_id"
        case status
        case applicationDate = "application_date"
        case scheduledDate = "scheduled_date"
        case batchNumber = "batch_number"
        case location
        case healthProfessional = "health_professional"
        case reactions
        case notes
        case recordedBy = "recorded_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        babyId: UUID,
        vaccineId: UUID,
        status: VaccinationStatus = .pending,
        applicationDate: Date? = nil,
        scheduledDate: Date? = nil,
        batchNumber: String? = nil,
        location: String? = nil,
        healthProfessional: String? = nil,
        reactions: String? = nil,
        notes: String? = nil,
        recordedBy: UUID? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.babyId = babyId
        self.vaccineId = vaccineId
        self.status = status
        self.applicationDate = applicationDate
        self.scheduledDate = scheduledDate
        self.batchNumber = batchNumber
        self.location = location
        self.healthProfessional = healthProfessional
        self.reactions = reactions
        self.notes = notes
        self.recordedBy = recordedBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        babyId = try container.decode(UUID.self, forKey: .babyId)
        vaccineId = try container.decode(UUID.self, forKey: .vaccineId)

        // Decode status - handle string or nil
        if let statusString = try? container.decodeIfPresent(String.self, forKey: .status) {
            status = VaccinationStatus(rawValue: statusString) ?? .pending
        } else {
            status = .pending
        }

        batchNumber = try container.decodeIfPresent(String.self, forKey: .batchNumber)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        healthProfessional = try container.decodeIfPresent(String.self, forKey: .healthProfessional)
        reactions = try container.decodeIfPresent(String.self, forKey: .reactions)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        recordedBy = try container.decodeIfPresent(UUID.self, forKey: .recordedBy)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)

        // Parse dates - Supabase can return DATE as string "YYYY-MM-DD" or timestamp
        applicationDate = try? container.decodeIfPresent(Date.self, forKey: .applicationDate)
        scheduledDate = try? container.decodeIfPresent(Date.self, forKey: .scheduledDate)
    }
}

// MARK: - Vaccination Status
/// Status da vacinação
enum VaccinationStatus: String, Codable, CaseIterable, Identifiable {
    case pending = "pending"
    case completed = "completed"
    case overdue = "overdue"
    case skipped = "skipped"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pending: return "vaccination.status.pending".localized
        case .completed: return "vaccination.status.completed".localized
        case .overdue: return "vaccination.status.overdue".localized
        case .skipped: return "vaccination.status.skipped".localized
        }
    }

    var color: Color {
        switch self {
        case .pending: return NapletColors.primaryBlue
        case .completed: return NapletColors.success
        case .overdue: return NapletColors.error
        case .skipped: return NapletColors.textMuted
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .completed: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .skipped: return "forward.fill"
        }
    }
}

// MARK: - Vaccination With Details
/// Combinação de vacinação com dados da vacina
struct VaccinationWithDetails: Identifiable, Equatable {
    let id: UUID
    let vaccination: BabyVaccination
    let vaccine: Vaccine

    /// Verifica se a vacina está atrasada baseado na idade do bebê
    func isOverdue(babyBirthDate: Date) -> Bool {
        guard vaccination.status == .pending else { return false }

        let calendar = Calendar.current
        let babyAgeMonths = calendar.dateComponents([.month], from: babyBirthDate, to: Date()).month ?? 0

        // Considera atrasado se passou 2 meses da idade recomendada
        return babyAgeMonths > vaccine.ageMonths + 2
    }

    /// Verifica se está na janela recomendada
    func isInRecommendedWindow(babyBirthDate: Date) -> Bool {
        guard vaccination.status == .pending else { return false }

        let calendar = Calendar.current
        let babyAgeMonths = calendar.dateComponents([.month], from: babyBirthDate, to: Date()).month ?? 0

        let minAge = max(0, vaccine.ageMonths - 1)
        let maxAge = vaccine.ageMonths + 2

        return babyAgeMonths >= minAge && babyAgeMonths <= maxAge
    }

    /// Data recomendada para aplicação
    func recommendedDate(babyBirthDate: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: vaccine.ageMonths, to: babyBirthDate) ?? Date()
    }
}

// MARK: - Vaccination Progress
/// Progresso geral da vacinação
struct VaccinationProgress {
    let total: Int
    let completed: Int
    let pending: Int
    let overdue: Int

    var completedPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total) * 100
    }

    var isUpToDate: Bool {
        overdue == 0
    }
}

// MARK: - Insert DTO
/// DTO para inserção de vacinação - matches DB column names
struct BabyVaccinationInsert: Codable {
    let babyId: UUID
    let vaccineId: UUID
    let status: String
    let applicationDate: Date?
    let scheduledDate: Date?
    let batchNumber: String?
    let location: String?
    let healthProfessional: String?
    let reactions: String?
    let notes: String?
    let recordedBy: UUID?

    enum CodingKeys: String, CodingKey {
        case babyId = "baby_id"
        case vaccineId = "vaccine_id"
        case status
        case applicationDate = "application_date"
        case scheduledDate = "scheduled_date"
        case batchNumber = "batch_number"
        case location
        case healthProfessional = "health_professional"
        case reactions
        case notes
        case recordedBy = "recorded_by"
    }

    init(from vaccination: BabyVaccination, userId: UUID?) {
        self.babyId = vaccination.babyId
        self.vaccineId = vaccination.vaccineId
        self.status = vaccination.status.rawValue
        self.applicationDate = vaccination.applicationDate
        self.scheduledDate = vaccination.scheduledDate
        self.batchNumber = vaccination.batchNumber
        self.location = vaccination.location
        self.healthProfessional = vaccination.healthProfessional
        self.reactions = vaccination.reactions
        self.notes = vaccination.notes
        self.recordedBy = userId
    }
}

// MARK: - Update DTO
/// DTO para atualização de vacinação - matches DB column names
struct BabyVaccinationUpdate: Codable {
    let status: String?
    let applicationDate: Date?
    let scheduledDate: Date?
    let batchNumber: String?
    let location: String?
    let healthProfessional: String?
    let reactions: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case status
        case applicationDate = "application_date"
        case scheduledDate = "scheduled_date"
        case batchNumber = "batch_number"
        case location
        case healthProfessional = "health_professional"
        case reactions
        case notes
    }
}

// MARK: - Age Group
/// Grupos de idade para organização das vacinas
enum VaccineAgeGroup: CaseIterable, Identifiable {
    case birth
    case twoMonths
    case threeMonths
    case fourMonths
    case fiveMonths
    case sixMonths
    case nineMonths
    case twelveMonths
    case fifteenMonths
    case eighteenMonths
    case fourYears
    case fiveYears

    var id: String { displayName }

    var displayName: String {
        switch self {
        case .birth: return "vaccination.age.birth".localized
        case .twoMonths: return "2 " + "vaccination.age.monthsShort".localized
        case .threeMonths: return "3 " + "vaccination.age.monthsShort".localized
        case .fourMonths: return "4 " + "vaccination.age.monthsShort".localized
        case .fiveMonths: return "5 " + "vaccination.age.monthsShort".localized
        case .sixMonths: return "6 " + "vaccination.age.monthsShort".localized
        case .nineMonths: return "9 " + "vaccination.age.monthsShort".localized
        case .twelveMonths: return "12 " + "vaccination.age.monthsShort".localized
        case .fifteenMonths: return "15 " + "vaccination.age.monthsShort".localized
        case .eighteenMonths: return "18 " + "vaccination.age.monthsShort".localized
        case .fourYears: return "4 " + "vaccination.age.yearsShort".localized
        case .fiveYears: return "5 " + "vaccination.age.yearsShort".localized
        }
    }

    var months: Int {
        switch self {
        case .birth: return 0
        case .twoMonths: return 2
        case .threeMonths: return 3
        case .fourMonths: return 4
        case .fiveMonths: return 5
        case .sixMonths: return 6
        case .nineMonths: return 9
        case .twelveMonths: return 12
        case .fifteenMonths: return 15
        case .eighteenMonths: return 18
        case .fourYears: return 48
        case .fiveYears: return 60
        }
    }

    static func from(months: Int) -> VaccineAgeGroup {
        switch months {
        case 0: return .birth
        case 1...2: return .twoMonths
        case 3: return .threeMonths
        case 4: return .fourMonths
        case 5: return .fiveMonths
        case 6...8: return .sixMonths
        case 9...11: return .nineMonths
        case 12...14: return .twelveMonths
        case 15...17: return .fifteenMonths
        case 18...47: return .eighteenMonths
        case 48...59: return .fourYears
        default: return .fiveYears
        }
    }
}
