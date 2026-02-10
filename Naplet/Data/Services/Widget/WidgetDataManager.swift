import Foundation
import WidgetKit

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
}

// MARK: - Widget Data Manager
struct WidgetDataManager {
    static let appGroupIdentifier = "group.app.naplet.ios"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    static func saveWidgetData(_ data: WidgetSleepData) {
        guard let defaults = sharedDefaults else {
            Logger.warning("Failed to access App Group UserDefaults for widget")
            return
        }

        do {
            let encoded = try JSONEncoder().encode(data)
            defaults.set(encoded, forKey: "widgetSleepData")
            Logger.info("Widget data saved successfully")
        } catch {
            Logger.error("Failed to encode widget data: \(error)")
        }
    }

    static func loadWidgetData() -> WidgetSleepData {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: "widgetSleepData")
        else {
            return .placeholder
        }

        do {
            return try JSONDecoder().decode(WidgetSleepData.self, from: data)
        } catch {
            Logger.error("Failed to decode widget data: \(error)")
            return .placeholder
        }
    }

    static func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        Logger.info("Widget timelines reloaded")
    }

    static func updateWidget(
        babyName: String,
        isSleeping: Bool,
        sleepType: String?,
        sleepStartTime: Date?,
        todayTotalSleepMinutes: Int,
        todayNapsCount: Int
    ) {
        let data = WidgetSleepData(
            babyName: babyName,
            isSleeping: isSleeping,
            sleepType: sleepType,
            sleepStartTime: sleepStartTime,
            todayTotalSleepMinutes: todayTotalSleepMinutes,
            todayNapsCount: todayNapsCount,
            lastUpdated: Date()
        )

        saveWidgetData(data)
        reloadWidgets()
    }
}

// MARK: - Widget Notification Names
extension Notification.Name {
    static let widgetRequestedStartSleep = Notification.Name("widgetRequestedStartSleep")
    static let widgetRequestedStopSleep = Notification.Name("widgetRequestedStopSleep")
}
