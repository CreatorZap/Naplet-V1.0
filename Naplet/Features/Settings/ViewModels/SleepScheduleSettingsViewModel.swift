import Foundation
import SwiftUI

// MARK: - Sleep Schedule Settings ViewModel
@MainActor
final class SleepScheduleSettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var useCustomWakeTime: Bool = false
    @Published var customWakeTime: Date = Date()

    @Published var useCustomBedtime: Bool = false
    @Published var customBedtime: Date = Date()

    @Published var useCustomNapDuration: Bool = false
    @Published var customNapDuration: Int = 60

    @Published var useCustomWakeWindow: Bool = false
    @Published var customWakeWindow: Int = 120

    // MARK: - Private Properties

    private let baby: Baby
    private let calendar = Calendar.current

    // MARK: - Computed Properties

    var defaultWakeTimeFormatted: String {
        return String(format: "%02d:%02d", baby.recommendedWakeTime.hour, baby.recommendedWakeTime.minute)
    }

    var defaultBedtimeFormatted: String {
        return String(format: "%02d:%02d", baby.recommendedBedtime.hour, baby.recommendedBedtime.minute)
    }

    var defaultWakeWindowFormatted: String {
        let range = baby.recommendedWakeWindowMinutes
        return "\(range.lowerBound)-\(range.upperBound) min"
    }

    var hasLearnedData: Bool {
        return baby.sleepPreferences.hasReliableLearning
    }

    var daysOfData: Int {
        return baby.sleepPreferences.daysOfData
    }

    var learnedWakeTime: String? {
        return baby.sleepPreferences.learnedWakeTime?.formatted
    }

    var learnedBedtime: String? {
        return baby.sleepPreferences.learnedBedtime?.formatted
    }

    var learnedNapDuration: Int? {
        return baby.sleepPreferences.learnedNapDuration
    }

    var learnedWakeWindow: Int? {
        return baby.sleepPreferences.learnedWakeWindow
    }

    // MARK: - Init

    init(baby: Baby) {
        self.baby = baby
        loadCurrentPreferences()
    }

    // MARK: - Methods

    private func loadCurrentPreferences() {
        let prefs = baby.sleepPreferences

        // Wake Time
        if let customWake = prefs.customWakeTime {
            useCustomWakeTime = true
            customWakeTime = customWake.toDate()
        } else {
            useCustomWakeTime = false
            customWakeTime = TimeOfDay(hour: baby.recommendedWakeTime.hour, minute: baby.recommendedWakeTime.minute).toDate()
        }

        // Bedtime
        if let customBed = prefs.customBedtime {
            useCustomBedtime = true
            customBedtime = customBed.toDate()
        } else {
            useCustomBedtime = false
            customBedtime = TimeOfDay(hour: baby.recommendedBedtime.hour, minute: baby.recommendedBedtime.minute).toDate()
        }

        // Nap Duration
        if let customNap = prefs.customNapDuration {
            useCustomNapDuration = true
            customNapDuration = customNap
        } else {
            useCustomNapDuration = false
            customNapDuration = 60
        }

        // Wake Window
        if let customWindow = prefs.customWakeWindow {
            useCustomWakeWindow = true
            customWakeWindow = customWindow
        } else {
            useCustomWakeWindow = false
            let range = baby.recommendedWakeWindowMinutes
            customWakeWindow = (range.lowerBound + range.upperBound) / 2
        }
    }

    func getPreferences() -> BabySleepPreferences {
        var prefs = baby.sleepPreferences

        // Wake Time
        prefs.customWakeTime = useCustomWakeTime ? TimeOfDay(from: customWakeTime) : nil

        // Bedtime
        prefs.customBedtime = useCustomBedtime ? TimeOfDay(from: customBedtime) : nil

        // Nap Duration
        prefs.customNapDuration = useCustomNapDuration ? customNapDuration : nil

        // Wake Window
        prefs.customWakeWindow = useCustomWakeWindow ? customWakeWindow : nil

        return prefs
    }

    func resetToDefaults() {
        useCustomWakeTime = false
        useCustomBedtime = false
        useCustomNapDuration = false
        useCustomWakeWindow = false

        customWakeTime = TimeOfDay(hour: baby.recommendedWakeTime.hour, minute: baby.recommendedWakeTime.minute).toDate()
        customBedtime = TimeOfDay(hour: baby.recommendedBedtime.hour, minute: baby.recommendedBedtime.minute).toDate()
        customNapDuration = 60

        let range = baby.recommendedWakeWindowMinutes
        customWakeWindow = (range.lowerBound + range.upperBound) / 2
    }
}
