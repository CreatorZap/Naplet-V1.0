import Foundation

// MARK: - Widget Sleep Data
struct WidgetSleepData: Codable {
    let babyName: String
    let isSleeping: Bool
    let sleepType: String? // "nap" or "night"
    let sleepStartTime: Date?
    let todayTotalSleepMinutes: Int
    let todayNapsCount: Int
    let lastUpdated: Date

    static let placeholder = WidgetSleepData(
        babyName: "Baby",
        isSleeping: false,
        sleepType: nil,
        sleepStartTime: nil,
        todayTotalSleepMinutes: 0,
        todayNapsCount: 0,
        lastUpdated: Date()
    )

    var sleepDuration: TimeInterval? {
        guard isSleeping, let startTime = sleepStartTime else { return nil }
        return Date().timeIntervalSince(startTime)
    }

    var formattedTotalSleep: String {
        let hours = todayTotalSleepMinutes / 60
        let minutes = todayTotalSleepMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var formattedDuration: String {
        guard let duration = sleepDuration else { return "--:--" }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        }
        return String(format: "%dm", minutes)
    }
}

// MARK: - Widget Data Manager
struct WidgetDataManager {
    static let appGroupIdentifier = "group.app.naplet.ios"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    static func saveWidgetData(_ data: WidgetSleepData) {
        guard let defaults = sharedDefaults else { return }

        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: "widgetSleepData")
        }
    }

    static func loadWidgetData() -> WidgetSleepData {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: "widgetSleepData"),
              let decoded = try? JSONDecoder().decode(WidgetSleepData.self, from: data)
        else {
            return .placeholder
        }
        return decoded
    }
}
