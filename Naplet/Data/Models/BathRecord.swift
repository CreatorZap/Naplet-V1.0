import Foundation
import SwiftUI

// MARK: - Bath Type Enum
enum BathType: String, Codable, CaseIterable {
    case bathtub = "bathtub"
    case shower = "shower"
    case sponge = "sponge"

    var displayName: String {
        switch self {
        case .bathtub: return "bath.type.bathtub".localized
        case .shower: return "bath.type.shower".localized
        case .sponge: return "bath.type.sponge".localized
        }
    }

    var icon: String {
        switch self {
        case .bathtub: return "bathtub.fill"
        case .shower: return "shower.fill"
        case .sponge: return "drop.fill"
        }
    }

    var color: Color {
        switch self {
        case .bathtub: return NapletColors.primaryCyan
        case .shower: return NapletColors.primaryBlue
        case .sponge: return NapletColors.info
        }
    }
}

// MARK: - Bath Mood Enum
enum BathMood: String, Codable, CaseIterable {
    case loved = "loved"
    case neutral = "neutral"
    case cried = "cried"

    var displayName: String {
        switch self {
        case .loved: return "bath.mood.loved".localized
        case .neutral: return "bath.mood.neutral".localized
        case .cried: return "bath.mood.cried".localized
        }
    }

    var icon: String {
        switch self {
        case .loved: return "heart.fill"
        case .neutral: return "hand.thumbsup.fill"
        case .cried: return "cloud.rain.fill"
        }
    }

    var color: Color {
        switch self {
        case .loved: return NapletColors.success
        case .neutral: return NapletColors.warning
        case .cried: return NapletColors.error
        }
    }
}

// MARK: - Bath Record Model
struct BathRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let babyId: UUID
    var startTime: Date
    var endTime: Date?
    var durationMinutes: Int?
    var bathType: BathType
    var mood: BathMood?
    var notes: String?
    var recordedBy: UUID?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case durationMinutes = "duration_minutes"
        case bathType = "bath_type"
        case mood
        case notes
        case recordedBy = "recorded_by"
        case createdAt = "created_at"
    }

    init(
        id: UUID = UUID(),
        babyId: UUID,
        startTime: Date = Date(),
        endTime: Date? = nil,
        durationMinutes: Int? = nil,
        bathType: BathType = .bathtub,
        mood: BathMood? = nil,
        notes: String? = nil,
        recordedBy: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.babyId = babyId
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.bathType = bathType
        self.mood = mood
        self.notes = notes
        self.recordedBy = recordedBy
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    var isActive: Bool {
        endTime == nil
    }

    var calculatedDuration: Int {
        if let duration = durationMinutes {
            return duration
        }
        if let end = endTime {
            return Int(end.timeIntervalSince(startTime) / 60)
        }
        return Int(Date().timeIntervalSince(startTime) / 60)
    }

    var formattedDuration: String {
        let minutes = calculatedDuration
        if minutes < 1 {
            return "common.lessThanMinute".localized
        } else if minutes == 1 {
            return "1 min"
        } else {
            return "\(minutes) min"
        }
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: startTime, relativeTo: Date())
    }
}

// MARK: - Bath Record Insert DTO
struct BathRecordInsert: Codable {
    let babyId: UUID
    let startTime: Date
    let endTime: Date?
    let durationMinutes: Int?
    let bathType: String
    let mood: String?
    let notes: String?
    let recordedBy: UUID

    enum CodingKeys: String, CodingKey {
        case babyId = "baby_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case durationMinutes = "duration_minutes"
        case bathType = "bath_type"
        case mood
        case notes
        case recordedBy = "recorded_by"
    }

    init(
        babyId: UUID,
        startTime: Date,
        endTime: Date?,
        durationMinutes: Int?,
        bathType: BathType,
        mood: BathMood?,
        notes: String?,
        recordedBy: UUID
    ) {
        self.babyId = babyId
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.bathType = bathType.rawValue
        self.mood = mood?.rawValue
        self.notes = notes
        self.recordedBy = recordedBy
    }
}

// MARK: - Bath Statistics
struct BathStatistics {
    let totalBathsToday: Int
    let bathtubCount: Int
    let showerCount: Int
    let spongeCount: Int
    let lastBath: BathRecord?

    var lastBathTimeAgo: String? {
        lastBath?.timeAgo
    }

    static var empty: BathStatistics {
        BathStatistics(
            totalBathsToday: 0,
            bathtubCount: 0,
            showerCount: 0,
            spongeCount: 0,
            lastBath: nil
        )
    }
}
