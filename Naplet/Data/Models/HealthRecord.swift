import Foundation
import SwiftUI

// MARK: - Health Record Type
enum HealthRecordType: String, Codable, CaseIterable {
    case temperature = "temperature"
    case medication = "medication"

    var displayName: String {
        switch self {
        case .temperature: return "health.temperature".localized
        case .medication: return "health.medication".localized
        }
    }

    var icon: String {
        switch self {
        case .temperature: return "thermometer.medium"
        case .medication: return "pills.fill"
        }
    }

    var color: Color {
        switch self {
        case .temperature: return NapletColors.error
        case .medication: return NapletColors.primaryCyan
        }
    }
}

// MARK: - Health Record
struct HealthRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let babyId: UUID
    let type: HealthRecordType
    var recordedAt: Date
    var temperatureCelsius: Double?
    var medicationName: String?
    var medicationDose: String?
    var notes: String?
    var recordedBy: UUID?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case type
        case recordedAt = "recorded_at"
        case temperatureCelsius = "temperature_celsius"
        case medicationName = "medication_name"
        case medicationDose = "medication_dose"
        case notes
        case recordedBy = "recorded_by"
        case createdAt = "created_at"
    }

    init(
        id: UUID = UUID(),
        babyId: UUID,
        type: HealthRecordType,
        recordedAt: Date = Date(),
        temperatureCelsius: Double? = nil,
        medicationName: String? = nil,
        medicationDose: String? = nil,
        notes: String? = nil,
        recordedBy: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.babyId = babyId
        self.type = type
        self.recordedAt = recordedAt
        self.temperatureCelsius = temperatureCelsius
        self.medicationName = medicationName
        self.medicationDose = medicationDose
        self.notes = notes
        self.recordedBy = recordedBy
        self.createdAt = createdAt
    }

    // MARK: - Formatted Values
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: recordedAt)
    }

    var formattedTemperature: String? {
        guard let temp = temperatureCelsius else { return nil }
        return String(format: "%.1f°C", temp)
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: recordedAt, relativeTo: Date())
    }

    // MARK: - Temperature Status
    var temperatureStatus: TemperatureStatus? {
        guard let temp = temperatureCelsius else { return nil }
        return TemperatureStatus.from(celsius: temp)
    }
}

// MARK: - Temperature Status
enum TemperatureStatus {
    case low       // < 36.0
    case normal    // 36.0 - 37.5
    case elevated  // 37.5 - 38.0
    case fever     // 38.0 - 39.0
    case highFever // > 39.0

    var displayName: String {
        switch self {
        case .low: return "health.temp.low".localized
        case .normal: return "health.temp.normal".localized
        case .elevated: return "health.temp.elevated".localized
        case .fever: return "health.temp.fever".localized
        case .highFever: return "health.temp.highFever".localized
        }
    }

    var color: Color {
        switch self {
        case .low: return NapletColors.info
        case .normal: return NapletColors.success
        case .elevated: return NapletColors.warning
        case .fever: return Color.orange
        case .highFever: return NapletColors.error
        }
    }

    static func from(celsius: Double) -> TemperatureStatus {
        switch celsius {
        case ..<36.0: return .low
        case 36.0..<37.5: return .normal
        case 37.5..<38.0: return .elevated
        case 38.0..<39.0: return .fever
        default: return .highFever
        }
    }
}

// MARK: - Health Record Insert DTO
struct HealthRecordInsert: Codable {
    let babyId: UUID
    let type: String
    let recordedAt: Date
    let temperatureCelsius: Double?
    let medicationName: String?
    let medicationDose: String?
    let notes: String?
    let recordedBy: UUID

    enum CodingKeys: String, CodingKey {
        case babyId = "baby_id"
        case type
        case recordedAt = "recorded_at"
        case temperatureCelsius = "temperature_celsius"
        case medicationName = "medication_name"
        case medicationDose = "medication_dose"
        case notes
        case recordedBy = "recorded_by"
    }

    init(
        babyId: UUID,
        type: HealthRecordType,
        recordedAt: Date,
        temperatureCelsius: Double? = nil,
        medicationName: String? = nil,
        medicationDose: String? = nil,
        notes: String? = nil,
        recordedBy: UUID
    ) {
        self.babyId = babyId
        self.type = type.rawValue
        self.recordedAt = recordedAt
        self.temperatureCelsius = temperatureCelsius
        self.medicationName = medicationName
        self.medicationDose = medicationDose
        self.notes = notes
        self.recordedBy = recordedBy
    }
}
