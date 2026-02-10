import Foundation
import SwiftUI

// MARK: - Diaper Content Type
enum DiaperContent: String, Codable, CaseIterable {
    case dry = "dry"
    case wet = "wet"
    case dirty = "dirty"
    case mixed = "mixed"

    var displayName: String {
        switch self {
        case .dry: return "diaper.content.dry".localized
        case .wet: return "diaper.content.wet".localized
        case .dirty: return "diaper.content.dirty".localized
        case .mixed: return "diaper.content.mixed".localized
        }
    }

    var icon: String {
        switch self {
        case .dry: return "sun.max.fill"
        case .wet: return "drop.fill"
        case .dirty: return "leaf.fill"
        case .mixed: return "drop.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .dry: return NapletColors.success
        case .wet: return NapletColors.info
        case .dirty: return NapletColors.warning
        case .mixed: return NapletColors.primaryPurple
        }
    }
}

// MARK: - Diaper Record
struct DiaperRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let babyId: UUID
    var changedAt: Date
    var content: DiaperContent
    var weightGrams: Int?
    var notes: String?
    var recordedBy: UUID?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case changedAt = "changed_at"
        case content
        case weightGrams = "weight_grams"
        case notes
        case recordedBy = "recorded_by"
        case createdAt = "created_at"
    }

    init(
        id: UUID = UUID(),
        babyId: UUID,
        changedAt: Date = Date(),
        content: DiaperContent,
        weightGrams: Int? = nil,
        notes: String? = nil,
        recordedBy: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.babyId = babyId
        self.changedAt = changedAt
        self.content = content
        self.weightGrams = weightGrams
        self.notes = notes
        self.recordedBy = recordedBy
        self.createdAt = createdAt
    }

    // MARK: - Formatted Time
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: changedAt)
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: changedAt, relativeTo: Date())
    }
}

// MARK: - Diaper Record Insert DTO
struct DiaperRecordInsert: Codable {
    let babyId: UUID
    let changedAt: Date
    let content: String
    let weightGrams: Int?
    let notes: String?
    let recordedBy: UUID

    enum CodingKeys: String, CodingKey {
        case babyId = "baby_id"
        case changedAt = "changed_at"
        case content
        case weightGrams = "weight_grams"
        case notes
        case recordedBy = "recorded_by"
    }

    init(
        babyId: UUID,
        changedAt: Date,
        content: DiaperContent,
        weightGrams: Int?,
        notes: String?,
        recordedBy: UUID
    ) {
        self.babyId = babyId
        self.changedAt = changedAt
        self.content = content.rawValue
        self.weightGrams = weightGrams
        self.notes = notes
        self.recordedBy = recordedBy
    }
}

// MARK: - Diaper Statistics
struct DiaperStatistics {
    let wetCount: Int
    let dirtyCount: Int
    let mixedCount: Int
    let dryCount: Int
    let lastChange: DiaperRecord?

    var totalCount: Int {
        wetCount + dirtyCount + mixedCount + dryCount
    }

    var lastChangeTimeAgo: String? {
        lastChange?.timeAgo
    }

    static var empty: DiaperStatistics {
        DiaperStatistics(
            wetCount: 0,
            dirtyCount: 0,
            mixedCount: 0,
            dryCount: 0,
            lastChange: nil
        )
    }
}
