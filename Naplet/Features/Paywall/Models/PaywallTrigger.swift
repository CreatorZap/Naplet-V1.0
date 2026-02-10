import Foundation
import SwiftUI

// MARK: - Paywall Trigger
/// Representa o contexto/motivo que abriu o paywall
/// Cada trigger tem copy personalizada para maximizar conversão
enum PaywallTrigger: String, CaseIterable {
    case inviteCaregiver = "invite_caregiver"
    case aiChatLimit = "ai_chat_limit"
    case pdfReport = "pdf_report"
    case historyLimit = "history_limit"
    case multipleBabies = "multiple_babies"
    case softPrompt = "soft_prompt"
    case settingsUpgrade = "settings_upgrade"

    // MARK: - Headlines

    var headline: String {
        switch self {
        case .inviteCaregiver:
            return "paywall.trigger.invite.headline".localized
        case .aiChatLimit:
            return "paywall.trigger.ai.headline".localized
        case .pdfReport:
            return "paywall.trigger.pdf.headline".localized
        case .historyLimit:
            return "paywall.trigger.history.headline".localized
        case .multipleBabies:
            return "paywall.trigger.babies.headline".localized
        case .softPrompt, .settingsUpgrade:
            return "paywall.trigger.general.headline".localized
        }
    }

    // MARK: - Subtitles

    var subtitle: String {
        switch self {
        case .inviteCaregiver:
            return "paywall.trigger.invite.subtitle".localized
        case .aiChatLimit:
            return "paywall.trigger.ai.subtitle".localized
        case .pdfReport:
            return "paywall.trigger.pdf.subtitle".localized
        case .historyLimit:
            return "paywall.trigger.history.subtitle".localized
        case .multipleBabies:
            return "paywall.trigger.babies.subtitle".localized
        case .softPrompt, .settingsUpgrade:
            return "paywall.trigger.general.subtitle".localized
        }
    }

    // MARK: - Icons

    var icon: String {
        switch self {
        case .inviteCaregiver:
            return "person.3.fill"
        case .aiChatLimit:
            return "brain.head.profile"
        case .pdfReport:
            return "doc.text.fill"
        case .historyLimit:
            return "calendar"
        case .multipleBabies:
            return "figure.2.and.child.holdinghands"
        case .softPrompt, .settingsUpgrade:
            return "crown.fill"
        }
    }

    // MARK: - Colors

    var accentColor: Color {
        switch self {
        case .inviteCaregiver:
            return NapletColors.primaryPurple
        case .aiChatLimit:
            return NapletColors.sleepActive
        case .pdfReport:
            return NapletColors.success
        case .historyLimit:
            return NapletColors.warning
        case .multipleBabies:
            return NapletColors.primaryPink
        case .softPrompt, .settingsUpgrade:
            return NapletColors.primaryPurple
        }
    }

    // MARK: - Analytics Event Name

    var analyticsName: String {
        "paywall_shown_\(rawValue)"
    }

    // MARK: - Priority Features to Show

    /// Features mais relevantes para este trigger (mostradas primeiro)
    var priorityFeatures: [String] {
        switch self {
        case .inviteCaregiver:
            return [
                "paywall.benefit.caregivers.title",
                "paywall.benefit.ai.title",
                "paywall.benefit.export.title"
            ]
        case .aiChatLimit:
            return [
                "paywall.benefit.ai.title",
                "paywall.benefit.stats.title",
                "paywall.benefit.history.title"
            ]
        case .pdfReport:
            return [
                "paywall.benefit.export.title",
                "paywall.benefit.stats.title",
                "paywall.benefit.history.title"
            ]
        case .historyLimit:
            return [
                "paywall.benefit.history.title",
                "paywall.benefit.stats.title",
                "paywall.benefit.ai.title"
            ]
        case .multipleBabies:
            return [
                "paywall.benefit.babies.title",
                "paywall.benefit.caregivers.title",
                "paywall.benefit.stats.title"
            ]
        case .softPrompt, .settingsUpgrade:
            return [
                "paywall.benefit.ai.title",
                "paywall.benefit.export.title",
                "paywall.benefit.caregivers.title"
            ]
        }
    }
}

// MARK: - Paywall Presentation Manager
/// Gerencia quando e como mostrar o paywall
@MainActor
final class PaywallPresentationManager: ObservableObject {
    static let shared = PaywallPresentationManager()

    @Published var showPaywall: Bool = false
    @Published var currentTrigger: PaywallTrigger = .softPrompt

    private let subscriptionManager = SubscriptionManager.shared

    private init() {}

    // MARK: - Present Paywall

    /// Apresenta o paywall se o usuário não for premium
    /// - Parameter trigger: O contexto que disparou o paywall
    /// - Returns: true se o paywall foi mostrado, false se usuário já é premium
    @discardableResult
    func presentIfNeeded(trigger: PaywallTrigger) -> Bool {
        guard !subscriptionManager.hasPremiumAccess else {
            return false
        }

        currentTrigger = trigger
        showPaywall = true

        // Track analytics
        trackPaywallShown(trigger: trigger)

        return true
    }

    /// Fecha o paywall
    func dismiss() {
        showPaywall = false
    }

    // MARK: - Check Feature Access

    /// Verifica se o usuário tem acesso a uma feature e mostra paywall se não tiver
    /// - Parameters:
    ///   - feature: A feature a verificar
    ///   - trigger: O trigger correspondente
    /// - Returns: true se tem acesso, false se paywall foi mostrado
    func checkAccess(for feature: PremiumFeature, trigger: PaywallTrigger) -> Bool {
        if subscriptionManager.hasPremiumAccess {
            return true
        }

        presentIfNeeded(trigger: trigger)
        return false
    }

    // MARK: - Analytics

    private func trackPaywallShown(trigger: PaywallTrigger) {
        Logger.info("Paywall shown - trigger: \(trigger.rawValue)")
        // TODO: Track with analytics service
    }
}

// MARK: - Premium Feature Enum
/// Features premium que podem ser verificadas
enum PremiumFeature: String {
    case inviteCaregivers
    case unlimitedAIChat
    case pdfReports
    case unlimitedHistory
    case advancedStats
    case multipleBabies
    case dataExport

    var correspondingTrigger: PaywallTrigger {
        switch self {
        case .inviteCaregivers:
            return .inviteCaregiver
        case .unlimitedAIChat:
            return .aiChatLimit
        case .pdfReports:
            return .pdfReport
        case .unlimitedHistory:
            return .historyLimit
        case .advancedStats:
            return .historyLimit
        case .multipleBabies:
            return .multipleBabies
        case .dataExport:
            return .pdfReport
        }
    }
}
