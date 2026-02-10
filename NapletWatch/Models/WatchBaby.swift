import Foundation

// MARK: - Watch Baby Model
struct WatchBaby: Codable {
    let id: UUID
    let name: String
    let ageDescription: String
    let recommendedWakeWindow: Int // in minutes
}

// MARK: - Watch Sleep Type
enum WatchSleepType: String, Codable {
    case nap
    case night

    var displayName: String {
        switch self {
        case .nap: return "Soneca"
        case .night: return "Noite"
        }
    }

    var icon: String {
        switch self {
        case .nap: return "moon.zzz.fill"
        case .night: return "moon.stars.fill"
        }
    }
}

// MARK: - Watch Sleep Data
struct WatchSleepData: Codable {
    let isSleeping: Bool
    let sleepType: WatchSleepType?
    let startTime: Date?
    let todayTotalSleep: Int // in minutes
    let todayNaps: Int
}
