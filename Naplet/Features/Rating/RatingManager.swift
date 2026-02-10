import Foundation
import StoreKit

// MARK: - Rating Manager
/// Gerencia o sistema de avaliação inteligente do app
@MainActor
class RatingManager: ObservableObject {

    // MARK: - Singleton
    static let shared = RatingManager()

    // MARK: - Published Properties
    @Published var shouldShowRatingPrompt = false

    // MARK: - UserDefaults Keys
    private let kSleepRecordCount = "rating_sleep_record_count"
    private let kConsecutiveDays = "rating_consecutive_days"
    private let kLastActiveDate = "rating_last_active_date"
    private let kHasRated = "rating_has_rated"
    private let kHasDeclined = "rating_has_declined"
    private let kDeclinedDate = "rating_declined_date"

    private let userDefaults = UserDefaults.standard

    // MARK: - Constants
    private let sleepCountThreshold = 5
    private let consecutiveDaysThreshold = 7
    private let declineCooldownDays = 30

    // MARK: - Init
    private init() {}

    // MARK: - Track Events

    /// Chamar quando um sono for registrado com sucesso
    func trackSleepRecorded() {
        guard !hasRated && !hasRecentlyDeclined else { return }

        let count = userDefaults.integer(forKey: kSleepRecordCount) + 1
        userDefaults.set(count, forKey: kSleepRecordCount)

        Logger.info("RatingManager: Sleep recorded - count: \(count)")

        // Trigger após 5 sonos
        if count >= sleepCountThreshold {
            shouldShowRatingPrompt = true
            Logger.info("RatingManager: Showing rating prompt (sleep count threshold)")
        }
    }

    /// Chamar no app launch para tracking de dias consecutivos
    func trackAppLaunch() {
        guard !hasRated && !hasRecentlyDeclined else { return }

        let today = Calendar.current.startOfDay(for: Date())

        if let lastDate = userDefaults.object(forKey: kLastActiveDate) as? Date {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            let daysDiff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 1 {
                // Dia consecutivo
                let days = userDefaults.integer(forKey: kConsecutiveDays) + 1
                userDefaults.set(days, forKey: kConsecutiveDays)

                Logger.info("RatingManager: Consecutive day - count: \(days)")

                // Trigger após 7 dias consecutivos
                if days >= consecutiveDaysThreshold {
                    shouldShowRatingPrompt = true
                    Logger.info("RatingManager: Showing rating prompt (consecutive days threshold)")
                }
            } else if daysDiff > 1 {
                // Reset se pulou um dia
                userDefaults.set(1, forKey: kConsecutiveDays)
                Logger.info("RatingManager: Consecutive days reset (gap detected)")
            }
            // daysDiff == 0 significa mesmo dia, não incrementa
        } else {
            // Primeiro acesso
            userDefaults.set(1, forKey: kConsecutiveDays)
        }

        userDefaults.set(today, forKey: kLastActiveDate)
    }

    // MARK: - User Actions

    /// Usuário indicou que ama o app - direcionar para App Store
    func userLovesApp() {
        Logger.info("RatingManager: User loves app - requesting App Store review")

        // Solicitar avaliação na App Store
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }

        userDefaults.set(true, forKey: kHasRated)
        shouldShowRatingPrompt = false
    }

    /// Usuário indicou que precisa melhorar - abrir feedback interno
    func userNeedsImprovement() {
        Logger.info("RatingManager: User needs improvement - declined rating")

        // Marcar como declined (pode perguntar novamente após cooldown)
        userDefaults.set(true, forKey: kHasDeclined)
        userDefaults.set(Date(), forKey: kDeclinedDate)
        shouldShowRatingPrompt = false
    }

    /// Fechar o prompt sem ação
    func dismissPrompt() {
        Logger.info("RatingManager: Prompt dismissed")
        shouldShowRatingPrompt = false
    }

    // MARK: - Computed Properties

    private var hasRated: Bool {
        userDefaults.bool(forKey: kHasRated)
    }

    private var hasRecentlyDeclined: Bool {
        guard userDefaults.bool(forKey: kHasDeclined),
              let declinedDate = userDefaults.object(forKey: kDeclinedDate) as? Date else {
            return false
        }

        // Pode perguntar novamente após cooldown
        let daysSinceDeclined = Calendar.current.dateComponents([.day], from: declinedDate, to: Date()).day ?? 0
        return daysSinceDeclined < declineCooldownDays
    }

    /// Número de sonos registrados
    var sleepRecordCount: Int {
        userDefaults.integer(forKey: kSleepRecordCount)
    }

    /// Dias consecutivos de uso
    var consecutiveDays: Int {
        userDefaults.integer(forKey: kConsecutiveDays)
    }

    // MARK: - Reset (para testes)

    func resetForTesting() {
        userDefaults.removeObject(forKey: kSleepRecordCount)
        userDefaults.removeObject(forKey: kConsecutiveDays)
        userDefaults.removeObject(forKey: kLastActiveDate)
        userDefaults.removeObject(forKey: kHasRated)
        userDefaults.removeObject(forKey: kHasDeclined)
        userDefaults.removeObject(forKey: kDeclinedDate)
        shouldShowRatingPrompt = false
        Logger.info("RatingManager: Reset for testing")
    }
}
