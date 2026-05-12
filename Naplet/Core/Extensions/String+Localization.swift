import Foundation

// MARK: - String Localization Extension
extension String {
    /// Returns the localized version of the string using LocalizationManager
    /// This enables real-time language switching without app restart
    var localized: String {
        LocalizationManager.shared.localizedString(self)
    }

    /// Returns the localized version of the string with format arguments
    /// - Parameter arguments: The arguments to substitute in the format string
    /// - Returns: The formatted localized string
    func localized(with arguments: CVarArg...) -> String {
        LocalizationManager.shared.localizedString(self, withArray: arguments)
    }

    /// Returns the localized version of the string with an array of arguments
    /// - Parameter arguments: Array of arguments to substitute in the format string
    /// - Returns: The formatted localized string
    func localized(withArray arguments: [CVarArg]) -> String {
        LocalizationManager.shared.localizedString(self, withArray: arguments)
    }
}

// MARK: - Localization Keys
/// Namespace for all localization keys used in the app
/// Usage: L10n.common.ok.localized or Text(L10n.dashboard.greeting.morning.localized)
enum L10n {
    // MARK: - Common
    enum Common {
        static let ok = "common.ok"
        static let cancel = "common.cancel"
        static let save = "common.save"
        static let delete = "common.delete"
        static let edit = "common.edit"
        static let done = "common.done"
        static let close = "common.close"
        static let error = "common.error"
        static let success = "common.success"
        static let loading = "common.loading"
        static let retry = "common.retry"
        static let yes = "common.yes"
        static let no = "common.no"
        static let skip = "common.skip"
        static let next = "common.next"
        static let back = "common.back"
        static let `continue` = "common.continue"
    }

    // MARK: - Auth
    enum Auth {
        static let welcome = "auth.welcome"
        static let tagline = "auth.tagline"
        static let signIn = "auth.signIn"
        static let signUp = "auth.signUp"
        static let email = "auth.email"
        static let password = "auth.password"
        static let confirmPassword = "auth.confirmPassword"
        static let name = "auth.name"
        static let forgotPassword = "auth.forgotPassword"
        static let noAccount = "auth.noAccount"
        static let hasAccount = "auth.hasAccount"
        static let signInWithApple = "auth.signInWithApple"
        static let termsNotice = "auth.termsNotice"
        static let skipLogin = "auth.skipLogin"

        enum Error {
            static let invalidEmail = "auth.error.invalidEmail"
            static let weakPassword = "auth.error.weakPassword"
            static let passwordMismatch = "auth.error.passwordMismatch"
            static let generic = "auth.error.generic"
            static let signIn = "auth.error.signIn"
            static let signOut = "auth.error.signOut"
        }
    }

    // MARK: - Onboarding
    enum Onboarding {
        enum Welcome {
            static let title = "onboarding.welcome.title"
            static let subtitle = "onboarding.welcome.subtitle"
        }

        static let getStarted = "onboarding.getStarted"

        enum BabyInfo {
            static let title = "onboarding.babyInfo.title"
            static let subtitle = "onboarding.babyInfo.subtitle"
            static let nameLabel = "onboarding.babyInfo.nameLabel"
            static let namePlaceholder = "onboarding.babyInfo.namePlaceholder"
            static let birthDate = "onboarding.babyInfo.birthDate"
            static let gender = "onboarding.babyInfo.gender"

            enum Gender {
                static let male = "onboarding.babyInfo.gender.male"
                static let female = "onboarding.babyInfo.gender.female"
            }
        }

        enum Goals {
            static let title = "onboarding.goals.title"
            static let subtitle = "onboarding.goals.subtitle"
        }

        enum Notifications {
            static let title = "onboarding.notifications.title"
            static let subtitle = "onboarding.notifications.subtitle"
            static let enable = "onboarding.notifications.enable"
            static let skip = "onboarding.notifications.skip"
        }
    }

    // MARK: - Dashboard
    enum Dashboard {
        enum Greeting {
            static let morning = "dashboard.greeting.morning"
            static let afternoon = "dashboard.greeting.afternoon"
            static let evening = "dashboard.greeting.evening"
            static let night = "dashboard.greeting.night"
        }

        enum Status {
            static let sleeping = "dashboard.status.sleeping"
            static let awake = "dashboard.status.awake"
            static let active = "dashboard.status.active"
            static let readyForSleep = "dashboard.status.readyForSleep"
        }

        enum Stats {
            static let totalSleep = "dashboard.stats.totalSleep"
            static let naps = "dashboard.stats.naps"
            static let sleepDuration = "dashboard.stats.sleepDuration"
        }

        enum QuickActions {
            static let title = "dashboard.quickActions.title"
            static let nap = "dashboard.quickActions.nap"
            static let nightSleep = "dashboard.quickActions.nightSleep"
            static let statistics = "dashboard.quickActions.statistics"
            static let settings = "dashboard.quickActions.settings"
            static let aiChat = "dashboard.quickActions.aiChat"
            static let report = "dashboard.quickActions.report"
        }

        static let todayActivity = "dashboard.todayActivity"
        static let noRecords = "dashboard.noRecords"
        static let noRecordsSubtitle = "dashboard.noRecordsSubtitle"
        static let wakeWindow = "dashboard.wakeWindow"
        static let startSleep = "dashboard.startSleep"
        static let wakeUp = "dashboard.wakeUp"

        enum Error {
            static let startSleep = "dashboard.error.startSleep"
            static let stopSleep = "dashboard.error.stopSleep"
        }
    }

    // MARK: - Sleep Quality
    enum SleepQuality {
        static let title = "sleepQuality.title"
        static let excellent = "sleepQuality.excellent"
        static let good = "sleepQuality.good"
        static let fair = "sleepQuality.fair"
        static let poor = "sleepQuality.poor"
        static let notes = "sleepQuality.notes"
        static let notesPlaceholder = "sleepQuality.notesPlaceholder"
    }

    // MARK: - Sleep Types
    enum SleepType {
        static let nap = "sleepType.nap"
        static let night = "sleepType.night"
    }

    // MARK: - History
    enum History {
        static let title = "history.title"

        enum Period {
            static let week = "history.period.week"
            static let twoWeeks = "history.period.twoWeeks"
            static let month = "history.period.month"
        }

        static let summary = "history.summary"
        static let dailyBreakdown = "history.dailyBreakdown"
        static let sleepDuration = "history.sleepDuration"
        static let noRecords = "history.noRecords"
        static let avgDailySleep = "history.avgDailySleep"
        static let avgNapsPerDay = "history.avgNapsPerDay"
        static let bestDay = "history.bestDay"
        static let totalRecords = "history.totalRecords"
        static let today = "history.today"
        static let yesterday = "history.yesterday"
        static let naps = "history.naps"
        static let night = "history.night"
        static let hours = "history.hours"
    }
    
    // MARK: - Statistics
    enum Statistics {
        static let title = "statistics.title"
        static let subtitle = "statistics.subtitle"
        static let totalSleep = "statistics.totalSleep"
        static let distribution = "statistics.distribution"
        static let nightPeriod = "statistics.nightPeriod"
        static let dayPeriod = "statistics.dayPeriod"
        static let wakeTime = "statistics.wakeTime"
        static let bedtime = "statistics.bedtime"
        static let napsPerDay = "statistics.napsPerDay"
        static let average = "statistics.average"
        static let avgNapDuration = "statistics.avgNapDuration"
        static let totalNaps = "statistics.totalNaps"
        static let earliestWake = "statistics.earliestWake"
        static let latestWake = "statistics.latestWake"
        static let avgNightSleep = "statistics.avgNightSleep"
        static let avgBedtime = "statistics.avgBedtime"
        
        enum Tab {
            static let summary = "statistics.tab.summary"
            static let naps = "statistics.tab.naps"
            static let wakeTime = "statistics.tab.wakeTime"
            static let nightSleep = "statistics.tab.nightSleep"
        }
    }

    // MARK: - Settings
    enum Settings {
        static let title = "settings.title"
        static let profile = "settings.profile"
        static let baby = "settings.baby"
        static let addBaby = "settings.addBaby"
        static let notifications = "settings.notifications"
        static let caregivers = "settings.caregivers"
        static let acceptInvite = "settings.acceptInvite"
        static let preferences = "settings.preferences"
        static let hapticFeedback = "settings.hapticFeedback"
        static let use24Hour = "settings.use24Hour"
        static let showWakeWindows = "settings.showWakeWindows"
        static let about = "settings.about"
        static let privacyPolicy = "settings.privacyPolicy"
        static let termsOfService = "settings.termsOfService"
        static let version = "settings.version"
        static let signOut = "settings.signOut"
    }

    // MARK: - Caregivers
    enum Caregivers {
        static let title = "caregivers.title"
        static let active = "caregivers.active"
        static let pending = "caregivers.pending"
        static let invite = "caregivers.invite"

        enum Role {
            static let owner = "caregivers.role.owner"
            static let parent = "caregivers.role.parent"
            static let grandparent = "caregivers.role.grandparent"
            static let nanny = "caregivers.role.nanny"
            static let other = "caregivers.role.other"
            static let ownerDesc = "caregivers.role.ownerDesc"
            static let parentDesc = "caregivers.role.parentDesc"
            static let grandparentDesc = "caregivers.role.grandparentDesc"
            static let nannyDesc = "caregivers.role.nannyDesc"
            static let otherDesc = "caregivers.role.otherDesc"
        }
    }

    // MARK: - AI Chat
    enum AIChat {
        static let title = "aiChat.title"
        static let subtitle = "aiChat.subtitle"
        static let welcome = "aiChat.welcome"
        static let placeholder = "aiChat.placeholder"
        static let error = "aiChat.error"
        static let remainingMessages = "aiChat.remainingMessages"
        static let suggestedQuestions = "aiChat.suggestedQuestions"
    }

    // MARK: - AI Consent
    enum AIConsent {
        static let title = "aiConsent.title"
        static let description = "aiConsent.description"
        static let dataShared = "aiConsent.dataShared"
        static let dataBabyInfo = "aiConsent.data.babyInfo"
        static let dataSleepRecords = "aiConsent.data.sleepRecords"
        static let dataChatMessages = "aiConsent.data.chatMessages"
        static let processingNote = "aiConsent.processingNote"
        static let checkbox = "aiConsent.checkbox"
        static let enable = "aiConsent.enable"
        static let notNow = "aiConsent.notNow"
        static let readPrivacyPolicy = "aiConsent.readPrivacyPolicy"
    }

    // MARK: - Report
    enum Report {
        static let title = "report.title"
        static let subtitle = "report.subtitle"
        static let period = "report.period"
        static let summary = "report.summary"
        static let generate = "report.generate"
        static let share = "report.share"
        static let preview = "report.preview"
        static let error = "report.error"
    }
    
    // MARK: - Feeding
    enum Feeding {
        static let title = "feeding.title"
        static let selectType = "feeding.selectType"
        static let lastFeeding = "feeding.lastFeeding"
        static let stop = "feeding.stop"
        static let active = "feeding.active"
        static let todayStats = "feeding.todayStats"
        static let todayHistory = "feeding.todayHistory"
        static let suggested = "feeding.suggested"
        static let amount = "feeding.amount"
        static let totalTime = "feeding.totalTime"
        
        enum FeedingType {
            static let breast = "feeding.type.breast"
            static let bottle = "feeding.type.bottle"
            static let solid = "feeding.type.solid"
        }
        
        enum Breast {
            static let start = "feeding.breast.start"
            static let selectSide = "feeding.breast.selectSide"
            static let left = "feeding.breast.left"
            static let right = "feeding.breast.right"
            static let both = "feeding.breast.both"
            static let lastSide = "feeding.breast.lastSide"
        }
        
        enum Bottle {
            static let start = "feeding.bottle.start"
            static let amount = "feeding.bottle.amount"
            static let type = "feeding.bottle.type"
            static let breastMilk = "feeding.bottle.breastMilk"
            static let formula = "feeding.bottle.formula"
            static let mixed = "feeding.bottle.mixed"
        }
        
        enum Solid {
            static let title = "feeding.solid.title"
            static let subtitle = "feeding.solid.subtitle"
            static let notes = "feeding.solid.notes"
            static let notesPlaceholder = "feeding.solid.notesPlaceholder"
            static let suggestions = "feeding.solid.suggestions"
            static let save = "feeding.solid.save"
        }
        
        enum History {
            static let title = "feeding.history.title"
            static let summary = "feeding.history.summary"
            static let total = "feeding.history.total"
            static let empty = "feeding.history.empty"
            static let emptySubtitle = "feeding.history.emptySubtitle"
        }
        
        enum Error {
            static let load = "feeding.error.load"
            static let start = "feeding.error.start"
            static let stop = "feeding.error.stop"
            static let save = "feeding.error.save"
        }
    }

    // MARK: - Errors
    enum Error {
        static let generic = "error.generic"
        static let network = "error.network"
        static let server = "error.server"
        static let unknown = "error.unknown"
    }

    // MARK: - Medication Schedule
    enum Medication {
        static let title = "medication.title"
        static let schedules = "medication.schedules"
        static let addSchedule = "medication.addSchedule"
        static let editSchedule = "medication.editSchedule"
        static let noSchedules = "medication.noSchedules"
        static let noSchedulesSubtitle = "medication.noSchedulesSubtitle"
        static let nextMedication = "medication.nextMedication"
        static let medicationName = "medication.medicationName"
        static let dose = "medication.dose"
        static let dosePlaceholder = "medication.dosePlaceholder"
        static let notes = "medication.notes"
        static let notesPlaceholder = "medication.notesPlaceholder"

        enum Frequency {
            static let title = "medication.frequency.title"
            static let every4h = "medication.frequency.every4h"
            static let every6h = "medication.frequency.every6h"
            static let every8h = "medication.frequency.every8h"
            static let every12h = "medication.frequency.every12h"
            static let onceDaily = "medication.frequency.onceDaily"
            static let twiceDaily = "medication.frequency.twiceDaily"
            static let threeTimesDaily = "medication.frequency.threeTimesDaily"
            static let asNeeded = "medication.frequency.asNeeded"
            static let custom = "medication.frequency.custom"
        }

        enum Duration {
            static let title = "medication.duration.title"
            static let continuous = "medication.duration.continuous"
            static let days = "medication.duration.days"
            static let until = "medication.duration.until"
        }

        enum DurationType {
            static let continuous = "medication.durationType.continuous"
            static let days = "medication.durationType.days"
            static let untilDate = "medication.durationType.untilDate"
        }

        enum Stock {
            static let title = "medication.stock.title"
            static let enableControl = "medication.stock.enableControl"
            static let dosesRemaining = "medication.stock.dosesRemaining"
            static let lowStockAlert = "medication.stock.lowStockAlert"
            static let lowStockWarning = "medication.stock.lowStockWarning"
            static let outOfStock = "medication.stock.outOfStock"
        }

        enum Reminder {
            static let times = "medication.reminder.times"
            static let addTime = "medication.reminder.addTime"
            static let given = "medication.reminder.given"
            static let skip = "medication.reminder.skip"
            static let snooze = "medication.reminder.snooze"
        }

        enum Status {
            static let given = "medication.status.given"
            static let skipped = "medication.status.skipped"
            static let snoozed = "medication.status.snoozed"
            static let missed = "medication.status.missed"
            static let active = "medication.status.active"
            static let paused = "medication.status.paused"
        }

        enum Action {
            static let pause = "medication.action.pause"
            static let resume = "medication.action.resume"
            static let delete = "medication.action.delete"
            static let updateStock = "medication.action.updateStock"
        }

        enum Error {
            static let load = "medication.error.load"
            static let save = "medication.error.save"
            static let log = "medication.error.log"
            static let snooze = "medication.error.snooze"
            static let skip = "medication.error.skip"
            static let pause = "medication.error.pause"
            static let resume = "medication.error.resume"
            static let delete = "medication.error.delete"
            static let stock = "medication.error.stock"
        }

        enum Tab {
            static let record = "medication.tab.record"
            static let schedule = "medication.tab.schedule"
        }
    }
}
