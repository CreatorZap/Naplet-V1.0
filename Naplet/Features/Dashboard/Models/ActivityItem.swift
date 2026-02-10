import Foundation
import SwiftUI

// MARK: - Activity Type
enum ActivityType {
    case sleep(SleepRecord)
    case feeding(FeedingRecord)
    case diaper(DiaperRecord)
    case bath(BathRecord)
    case health(HealthRecord)

    var timestamp: Date {
        switch self {
        case .sleep(let record): return record.startTime
        case .feeding(let record): return record.startTime
        case .diaper(let record): return record.changedAt
        case .bath(let record): return record.startTime
        case .health(let record): return record.recordedAt
        }
    }

    var icon: String {
        switch self {
        case .sleep(let record): return record.type.icon
        case .feeding(let record): return record.type.icon
        case .diaper(let record): return record.content.icon
        case .bath: return "bathtub.fill"
        case .health(let record): return record.type.icon
        }
    }

    var title: String {
        switch self {
        case .sleep(let record): return record.type.displayName
        case .feeding(let record): return record.type.displayName
        case .diaper(let record): return record.content.displayName
        case .bath: return "bath.title".localized
        case .health(let record): return record.type.displayName
        }
    }

    var subtitle: String {
        switch self {
        case .sleep(let record):
            return record.timeRangeFormatted
        case .feeding(let record):
            return record.startTime.formatted(date: .omitted, time: .shortened)
        case .diaper(let record):
            return record.changedAt.formatted(date: .omitted, time: .shortened)
        case .bath(let record):
            return record.startTime.formatted(date: .omitted, time: .shortened)
        case .health(let record):
            return record.recordedAt.formatted(date: .omitted, time: .shortened)
        }
    }

    var detail: String? {
        switch self {
        case .sleep(let record):
            return record.isActive ? "dashboard.status.active".localized : record.durationFormatted
        case .feeding(let record):
            return feedingSummary(record)
        case .diaper(let record):
            return record.notes
        case .bath(let record):
            return bathDurationFormatted(record)
        case .health(let record):
            return healthSummary(record)
        }
    }

    var color: Color {
        switch self {
        case .sleep(let record):
            return record.type == .nap ? NapletColors.primaryPurple : NapletColors.primaryBlue
        case .feeding:
            return Color(hex: "#F59E0B") // Orange/Amber
        case .diaper:
            return NapletColors.info
        case .bath:
            return NapletColors.primaryCyan
        case .health(let record):
            return record.type == .temperature ? NapletColors.warning : NapletColors.primaryCyan
        }
    }

    var isActive: Bool {
        switch self {
        case .sleep(let record): return record.isActive
        case .feeding(let record): return record.isActive
        default: return false
        }
    }

    // MARK: - Helper Methods

    private func feedingSummary(_ record: FeedingRecord) -> String {
        switch record.type {
        case .breast:
            let totalSec = (record.durationLeftSeconds ?? 0) + (record.durationRightSeconds ?? 0)
            let mins = totalSec / 60
            return "\(mins) min"
        case .bottle:
            if let amount = record.bottleAmountMl {
                return "\(Int(amount)) ml"
            }
            return ""
        case .solid:
            return record.notes ?? ""
        case .pumping:
            let total = record.totalPumpingMl
            return total > 0 ? "\(total) ml" : ""
        }
    }

    private func bathDurationFormatted(_ record: BathRecord) -> String {
        guard let end = record.endTime else { return "" }
        let duration = end.timeIntervalSince(record.startTime)
        let mins = Int(duration / 60)
        return "\(mins) min"
    }

    private func healthSummary(_ record: HealthRecord) -> String {
        switch record.type {
        case .temperature:
            if let temp = record.temperatureCelsius {
                return String(format: "%.1f°C", temp)
            }
            return ""
        case .medication:
            return record.medicationName ?? ""
        }
    }
}

// MARK: - Activity Item
struct ActivityItem: Identifiable {
    let id: UUID
    let type: ActivityType

    var sortDate: Date { type.timestamp }

    init(type: ActivityType) {
        switch type {
        case .sleep(let r): self.id = r.id
        case .feeding(let r): self.id = r.id
        case .diaper(let r): self.id = r.id
        case .bath(let r): self.id = r.id
        case .health(let r): self.id = r.id
        }
        self.type = type
    }
}
