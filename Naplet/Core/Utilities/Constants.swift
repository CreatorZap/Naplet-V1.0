import Foundation

// MARK: - App Constants
enum Constants {

    // MARK: - App Info
    enum App {
        static let name = "Naplet"
        static let bundleId = "com.naplet.app"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - API
    enum API {
        static let supabaseURL = "YOUR_SUPABASE_URL"
        static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
        static let timeout: TimeInterval = 30
    }

    // MARK: - Storage Keys
    enum StorageKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let currentBabyId = "currentBabyId"
        static let userId = "userId"
        static let notificationsEnabled = "notificationsEnabled"
        static let preferredTheme = "preferredTheme"
        static let hapticFeedbackEnabled = "hapticFeedbackEnabled"
    }

    // MARK: - Notifications
    enum Notifications {
        static let sleepReminderCategory = "SLEEP_REMINDER"
        static let napEndedCategory = "NAP_ENDED"
        static let dailySummaryCategory = "DAILY_SUMMARY"

        // Notification identifiers
        static let morningReminder = "morning_reminder"
        static let eveningReminder = "evening_reminder"
        static let napReminder = "nap_reminder"
    }

    // MARK: - Sleep Defaults
    enum SleepDefaults {
        /// Duração máxima recomendada de soneca em minutos por idade
        static func maxNapDuration(ageInMonths: Int) -> Int {
            switch ageInMonths {
            case 0...3: return 180  // 3 horas
            case 4...6: return 150  // 2.5 horas
            case 7...12: return 120 // 2 horas
            case 13...24: return 90 // 1.5 horas
            default: return 60      // 1 hora
            }
        }

        /// Número recomendado de sonecas por idade
        static func recommendedNaps(ageInMonths: Int) -> Int {
            switch ageInMonths {
            case 0...3: return 4
            case 4...6: return 3
            case 7...12: return 2
            case 13...18: return 1
            default: return 1
            }
        }

        /// Total de sono diário recomendado em horas
        static func recommendedDailySleep(ageInMonths: Int) -> Double {
            switch ageInMonths {
            case 0...3: return 16
            case 4...6: return 15
            case 7...12: return 14
            case 13...24: return 13
            case 25...36: return 12
            default: return 11
            }
        }

        /// Wake window recomendado em minutos
        static func recommendedWakeWindow(ageInMonths: Int) -> Int {
            switch ageInMonths {
            case 0...1: return 45
            case 2...3: return 75
            case 4...5: return 120
            case 6...7: return 150
            case 8...9: return 180
            case 10...12: return 210
            case 13...18: return 300
            default: return 360
            }
        }
    }

    // MARK: - Animation
    enum Animation {
        static let defaultDuration: Double = 0.3
        static let springResponse: Double = 0.5
        static let springDamping: Double = 0.8
    }

    // MARK: - Limits
    enum Limits {
        static let maxBabiesPerAccount = 5
        static let maxSleepRecordsPerDay = 20
        static let maxNotesLength = 500
    }

    // MARK: - Date Formats
    enum DateFormats {
        static let iso8601 = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        static let dateOnly = "yyyy-MM-dd"
        static let timeOnly = "HH:mm"
        static let displayDate = "MMM d, yyyy"
        static let displayTime = "h:mm a"
        static let displayDateTime = "MMM d, yyyy 'at' h:mm a"
    }
}

// MARK: - Feature Flags
enum FeatureFlags {
    static let enableAppleWatch = false
    static let enableSharing = false
    static let enableExport = true
    static let enableWidgets = true
    static let enableSiriShortcuts = false
    static let enableCloudSync = true
}

// MARK: - Debug
#if DEBUG
enum DebugConfig {
    static let showDebugMenu = true
    static let mockNetworkDelay: TimeInterval = 0.5
    static let logNetworkRequests = true
    static let useTestData = false
}
#endif
