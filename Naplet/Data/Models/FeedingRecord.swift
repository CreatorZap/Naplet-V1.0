import Foundation

// MARK: - Feeding Record Model
struct FeedingRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let babyId: UUID
    let type: FeedingType
    let startTime: Date
    var endTime: Date?

    // Para amamentacao
    var breastSide: BreastSide?
    var durationLeftSeconds: Int?
    var durationRightSeconds: Int?

    // Para mamadeira
    var bottleAmountMl: Double?
    var bottleType: BottleContentType?

    // Para ordenha (pumping)
    var pumpingMode: PumpingMode?
    var pumpingLeftMl: Int?
    var pumpingRightMl: Int?
    var pumpingTotalMl: Int?

    // Metadata
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    var isActive: Bool { endTime == nil }

    var totalDurationSeconds: Int {
        guard let end = endTime else {
            return Int(Date().timeIntervalSince(startTime))
        }
        return Int(end.timeIntervalSince(startTime))
    }

    var durationFormatted: String {
        let minutes = totalDurationSeconds / 60
        let seconds = totalDurationSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var totalBreastDurationSeconds: Int {
        return (durationLeftSeconds ?? 0) + (durationRightSeconds ?? 0)
    }

    var breastDurationFormatted: String {
        let total = totalBreastDurationSeconds
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case type
        case startTime = "start_time"
        case endTime = "end_time"
        case breastSide = "breast_side"
        case durationLeftSeconds = "duration_left_seconds"
        case durationRightSeconds = "duration_right_seconds"
        case bottleAmountMl = "bottle_amount_ml"
        case bottleType = "bottle_type"
        case pumpingMode = "pumping_mode"
        case pumpingLeftMl = "pumping_left_ml"
        case pumpingRightMl = "pumping_right_ml"
        case pumpingTotalMl = "pumping_total_ml"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Init
    init(
        id: UUID = UUID(),
        babyId: UUID,
        type: FeedingType,
        startTime: Date = Date(),
        endTime: Date? = nil,
        breastSide: BreastSide? = nil,
        durationLeftSeconds: Int? = nil,
        durationRightSeconds: Int? = nil,
        bottleAmountMl: Double? = nil,
        bottleType: BottleContentType? = nil,
        pumpingMode: PumpingMode? = nil,
        pumpingLeftMl: Int? = nil,
        pumpingRightMl: Int? = nil,
        pumpingTotalMl: Int? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.babyId = babyId
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.breastSide = breastSide
        self.durationLeftSeconds = durationLeftSeconds
        self.durationRightSeconds = durationRightSeconds
        self.bottleAmountMl = bottleAmountMl
        self.bottleType = bottleType
        self.pumpingMode = pumpingMode
        self.pumpingLeftMl = pumpingLeftMl
        self.pumpingRightMl = pumpingRightMl
        self.pumpingTotalMl = pumpingTotalMl
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Pumping Computed Properties
    var totalPumpingMl: Int {
        if pumpingMode == .total {
            return pumpingTotalMl ?? 0
        }
        return (pumpingLeftMl ?? 0) + (pumpingRightMl ?? 0)
    }

    // MARK: - Preview
    static var preview: FeedingRecord {
        FeedingRecord(
            babyId: UUID(),
            type: .breast,
            startTime: Date().addingTimeInterval(-1800),
            endTime: Date(),
            breastSide: .both,
            durationLeftSeconds: 600,
            durationRightSeconds: 900
        )
    }

    static var previewBottle: FeedingRecord {
        FeedingRecord(
            babyId: UUID(),
            type: .bottle,
            startTime: Date().addingTimeInterval(-600),
            endTime: Date(),
            bottleAmountMl: 120,
            bottleType: .formula
        )
    }
}

// MARK: - Feeding Type
enum FeedingType: String, Codable, CaseIterable {
    case breast = "breast"
    case bottle = "bottle"
    case solid = "solid"
    case pumping = "pumping"

    var displayName: String {
        switch self {
        case .breast: return "feeding.type.breast".localized
        case .bottle: return "feeding.type.bottle".localized
        case .solid: return "feeding.type.solid".localized
        case .pumping: return "feeding.type.pumping".localized
        }
    }

    var icon: String {
        switch self {
        case .breast: return "figure.and.child.holdinghands"
        case .bottle: return "waterbottle"
        case .solid: return "fork.knife"
        case .pumping: return "drop.degreesign"
        }
    }

    var color: SwiftUI.Color {
        switch self {
        case .breast: return NapletColors.primaryPurple
        case .bottle: return NapletColors.info
        case .solid: return NapletColors.warning
        case .pumping: return NapletColors.primaryPink
        }
    }
}

// MARK: - Pumping Mode
enum PumpingMode: String, Codable, CaseIterable {
    case total = "total"
    case perSide = "per_side"

    var displayName: String {
        switch self {
        case .total: return "feeding.pumping.total".localized
        case .perSide: return "feeding.pumping.perSide".localized
        }
    }
}

// MARK: - Breast Side
enum BreastSide: String, Codable, CaseIterable {
    case left = "left"
    case right = "right"
    case both = "both"

    var displayName: String {
        switch self {
        case .left: return "feeding.breast.left".localized
        case .right: return "feeding.breast.right".localized
        case .both: return "feeding.breast.both".localized
        }
    }

    var shortName: String {
        switch self {
        case .left: return "E"
        case .right: return "D"
        case .both: return "E+D"
        }
    }

    var icon: String {
        switch self {
        case .left: return "arrow.left.circle.fill"
        case .right: return "arrow.right.circle.fill"
        case .both: return "arrow.left.arrow.right.circle.fill"
        }
    }
}

// MARK: - Bottle Content Type
enum BottleContentType: String, Codable, CaseIterable {
    case breastMilk = "breast_milk"
    case formula = "formula"
    case mixed = "mixed"

    var displayName: String {
        switch self {
        case .breastMilk: return "feeding.bottle.breastMilk".localized
        case .formula: return "feeding.bottle.formula".localized
        case .mixed: return "feeding.bottle.mixed".localized
        }
    }

    var icon: String {
        switch self {
        case .breastMilk: return "drop.fill"
        case .formula: return "flask.fill"
        case .mixed: return "drop.halffull"
        }
    }
}

import SwiftUI
