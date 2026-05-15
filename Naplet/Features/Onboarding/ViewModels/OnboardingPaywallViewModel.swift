//
//  OnboardingPaywallViewModel.swift
//  Naplet
//
//  ViewModel dedicado ao paywall pós-onboarding.
//  Mantém-se mínimo (versus PaywallViewModel que é reativo a triggers
//  contextuais). Aqui temos decisão binária: comprar Founders ou pular.
//

import Foundation
import RevenueCat

@MainActor
final class OnboardingPaywallViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var foundersPackage: Package?
    @Published private(set) var isLoading: Bool = true
    @Published private(set) var isPurchasing: Bool = false
    @Published private(set) var isRestoring: Bool = false
    @Published var errorMessage: String?

    // MARK: - Computed

    /// Dias restantes da oferta Founders (com base em AppConfig.foundersEndDate).
    /// Retorna 0 se já expirou.
    var daysRemainingInFounders: Int {
        let endDate = AppConfig.Subscription.foundersEndDate
        let now = Date()
        guard endDate > now else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: now, to: endDate).day ?? 0
        return max(0, days)
    }

    /// Texto formatado do countdown ("71 dias restantes" ou "1 dia restante").
    var countdownText: String {
        let days = daysRemainingInFounders
        if days == 1 {
            return "onboarding.paywall.founders.countdownSingular".localized
        }
        return String(format: "onboarding.paywall.founders.countdownPlural".localized, days)
    }

    // MARK: - Init

    init() {
        Task {
            await loadFoundersPackage()
        }
    }

    // MARK: - Load

    private func loadFoundersPackage() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let offerings = try await Purchases.shared.offerings()
            if let foundersOffering = offerings.offering(identifier: AppConfig.Subscription.foundersOfferingId) {
                self.foundersPackage = foundersOffering.annual
                Logger.info("[OnboardingPaywall] Founders package loaded")
            } else {
                Logger.warning("[OnboardingPaywall] Founders offering not found, will use fallback")
            }
        } catch {
            Logger.error(error, context: "[OnboardingPaywall] failed to load offerings")
        }
    }

    // MARK: - Purchase

    /// Compra o pacote Founders.
    /// - Returns: `true` se a compra foi concluída com sucesso (entitlement ativo).
    func purchaseFounders() async -> Bool {
        AnalyticsService.track("onboarding_paywall_cta_tap", properties: [
            "package": "founders_annual",
            "days_remaining": daysRemainingInFounders
        ])

        isPurchasing = true
        defer { isPurchasing = false }

        // Caminho preferencial: via Package do RevenueCat
        if let package = foundersPackage {
            do {
                let result = try await Purchases.shared.purchase(package: package)

                if result.userCancelled {
                    AnalyticsService.track("onboarding_paywall_cancelled")
                    return false
                }

                let isPremiumActive = result.customerInfo
                    .entitlements[AppConfig.Subscription.premiumEntitlement]?
                    .isActive == true

                if isPremiumActive {
                    AnalyticsService.track("onboarding_paywall_purchased", properties: [
                        "package": "founders_annual",
                        "transaction_id": result.transaction?.transactionIdentifier ?? "unknown"
                    ])
                    return true
                } else {
                    Logger.warning("[OnboardingPaywall] purchase completed but premium not active")
                    errorMessage = "onboarding.paywall.error.purchaseFailed".localized
                    return false
                }
            } catch {
                // Caso especial: productAlreadyPurchasedError.
                // Ocorre quando o Apple ID já tem a assinatura ativa (outra conta
                // Naplet ou sessão anterior). Sem este branch, a Apple devolve
                // mensagem técnica de beta tester e a UI fica em "Processando..."
                // até o defer resetar isPurchasing. Aqui transformamos o erro em
                // restore silencioso: se o restore traz Premium, é como se a
                // compra tivesse dado certo (return true → view avança).
                if let rcError = error as? RevenueCat.ErrorCode,
                   rcError == .productAlreadyPurchasedError {
                    AnalyticsService.track("onboarding_paywall_already_purchased_detected")
                    Logger.info("[OnboardingPaywall] productAlreadyPurchasedError → tentando restore automático")
                    let restored = await attemptRestorePurchases()
                    if restored {
                        AnalyticsService.track("onboarding_paywall_already_purchased_restored")
                        return true
                    }
                    AnalyticsService.track("onboarding_paywall_already_purchased_restore_failed")
                    errorMessage = "onboarding.paywall.error.restoreFailed".localized
                    return false
                }

                AnalyticsService.track("onboarding_paywall_purchase_failed", properties: [
                    "error": error.localizedDescription
                ])
                Logger.error(error, context: "[OnboardingPaywall] purchase failed")
                errorMessage = mapErrorToUserMessage(error)
                return false
            }
        }

        // Fallback: produto não disponível (offering Founders não retornou do servidor)
        Logger.warning("[OnboardingPaywall] no Founders package available, purchase blocked")
        errorMessage = "onboarding.paywall.error.unavailable".localized
        return false
    }

    // MARK: - Restore

    /// Restaura compras anteriores via RevenueCat.
    /// Retorna `true` se o entitlement premium ficou ativo após o restore.
    func restorePurchases() async -> Bool {
        AnalyticsService.track("onboarding_paywall_restore_tap")

        isRestoring = true
        defer { isRestoring = false }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()

            let isPremiumActive = customerInfo
                .entitlements[AppConfig.Subscription.premiumEntitlement]?
                .isActive == true

            if isPremiumActive {
                AnalyticsService.track("onboarding_paywall_restore_success")
                Logger.info("[OnboardingPaywall] Restore successful — premium active")
                return true
            } else {
                AnalyticsService.track("onboarding_paywall_restore_no_purchases")
                errorMessage = "onboarding.paywall.restore.noPurchases".localized
                return false
            }
        } catch {
            AnalyticsService.track("onboarding_paywall_restore_failed", properties: [
                "error": error.localizedDescription
            ])
            Logger.error(error, context: "[OnboardingPaywall] restore failed")
            errorMessage = mapErrorToUserMessage(error)
            return false
        }
    }

    // MARK: - Skip / Track

    func trackSkip() {
        AnalyticsService.track("onboarding_paywall_skipped")
    }

    func trackDismissByX() {
        AnalyticsService.track("onboarding_paywall_dismissed_x")
    }

    func trackShown() {
        AnalyticsService.track("onboarding_paywall_shown", properties: [
            "days_remaining": daysRemainingInFounders,
            "founders_available": foundersPackage != nil
        ])
    }

    // MARK: - Helpers

    /// Restore silencioso disparado a partir de purchaseFounders quando a Apple
    /// retorna productAlreadyPurchasedError. Diferente do restorePurchases()
    /// público (que mexe em isRestoring e analytics próprios), este NÃO toca
    /// em isRestoring — o caller já segura isPurchasing via defer — e NÃO
    /// seta errorMessage; quem decide o que mostrar é purchaseFounders.
    private func attemptRestorePurchases() async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            return customerInfo
                .entitlements[AppConfig.Subscription.premiumEntitlement]?
                .isActive == true
        } catch {
            Logger.error(error, context: "[OnboardingPaywall] auto-restore após productAlreadyPurchasedError falhou")
            return false
        }
    }

    private func mapErrorToUserMessage(_ error: Error) -> String {
        // 1. Erros de rede genéricos (URLSession)
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return "onboarding.paywall.error.networkFailed".localized
        }

        // 2. Erros específicos do RevenueCat
        if let rcError = error as? RevenueCat.ErrorCode {
            switch rcError {
            case .purchaseCancelledError:
                return "" // Cancelamento silencioso (não mostra alert)
            case .paymentPendingError:
                return "onboarding.paywall.error.paymentPending".localized
            case .productNotAvailableForPurchaseError,
                 .productAlreadyPurchasedError:
                return "onboarding.paywall.error.productUnavailable".localized
            case .receiptAlreadyInUseError:
                return "onboarding.paywall.error.receiptInUse".localized
            case .invalidReceiptError:
                return "onboarding.paywall.error.invalidReceipt".localized
            case .networkError:
                return "onboarding.paywall.error.networkFailed".localized
            case .storeProblemError:
                return "onboarding.paywall.error.storeProblem".localized
            case .invalidCredentialsError,
                 .operationAlreadyInProgressForProductError:
                return "onboarding.paywall.error.tryAgainLater".localized
            case .ineligibleError:
                return "onboarding.paywall.error.ineligible".localized
            default:
                return "onboarding.paywall.error.purchaseFailed".localized
            }
        }

        return "onboarding.paywall.error.purchaseFailed".localized
    }
}
