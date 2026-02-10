import Foundation
import RevenueCat
import Combine

// MARK: - Paywall View Model
@MainActor
final class PaywallViewModel: ObservableObject {

    // MARK: - Dependencies
    private let purchaseService = PurchaseService.shared
    private let subscriptionManager = SubscriptionManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published Properties
    @Published var selectedPackage: Package?
    @Published var packages: [Package] = []
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var errorMessage: String?
    @Published var purchaseSuccess = false

    // MARK: - Trigger
    let trigger: PaywallTrigger

    // MARK: - Founders Period Properties
    @Published var foundersPackage: Package?
    @Published var regularAnnualPackage: Package?
    @Published var regularMonthlyPackage: Package?

    // MARK: - Plan Selection (for regular period)
    @Published var selectedPlanType: PlanType = .annual

    // MARK: - Fallback Prices (until Apple approves products)
    private enum FallbackPrices {
        static let foundersAnnual = "R$ 59,90"
        static let foundersMonthlyEquivalent = "R$ 4,99"
        static let premiumAnnual = "R$ 89,90"
        static let premiumMonthlyEquivalent = "R$ 7,49"
        static let premiumMonthly = "R$ 12,90"
        static let foundersDiscountPercent = 33 // (89.90 - 59.90) / 89.90 ≈ 33%
        static let annualSavingsPercent = 42 // (12.90 * 12 - 89.90) / (12.90 * 12) ≈ 42%
    }

    // MARK: - Benefits
    /// Benefits ordenados por relevância ao trigger
    var benefits: [PaywallBenefit] {
        var allBenefits = [
            PaywallBenefit(
                icon: "sparkles",
                titleKey: "paywall.benefit.ai.title",
                descriptionKey: "paywall.benefit.ai.description"
            ),
            PaywallBenefit(
                icon: "doc.text.fill",
                titleKey: "paywall.benefit.export.title",
                descriptionKey: "paywall.benefit.export.description"
            ),
            PaywallBenefit(
                icon: "person.2.fill",
                titleKey: "paywall.benefit.caregivers.title",
                descriptionKey: "paywall.benefit.caregivers.description"
            ),
            PaywallBenefit(
                icon: "chart.bar.fill",
                titleKey: "paywall.benefit.stats.title",
                descriptionKey: "paywall.benefit.stats.description"
            ),
            PaywallBenefit(
                icon: "clock.arrow.circlepath",
                titleKey: "paywall.benefit.history.title",
                descriptionKey: "paywall.benefit.history.description"
            ),
            PaywallBenefit(
                icon: "figure.2.and.child.holdinghands",
                titleKey: "paywall.benefit.babies.title",
                descriptionKey: "paywall.benefit.babies.description"
            )
        ]

        // Reordenar baseado no trigger - features prioritárias primeiro
        let priorityKeys = trigger.priorityFeatures
        allBenefits.sort { benefit1, benefit2 in
            let index1 = priorityKeys.firstIndex(of: benefit1.titleKey) ?? Int.max
            let index2 = priorityKeys.firstIndex(of: benefit2.titleKey) ?? Int.max
            return index1 < index2
        }

        return allBenefits
    }

    // MARK: - Founders Exclusive Benefit
    let founderBenefit = PaywallBenefit(
        icon: "star.fill",
        titleKey: "paywall.benefit.founder.title",
        descriptionKey: "paywall.benefit.founder.description"
    )

    // MARK: - Computed Properties

    /// Verifica se está no período Founders
    var isFoundersPeriod: Bool {
        AppConfig.Subscription.isFoundersPeriod
    }

    /// Dias restantes do período Founders
    var foundersDaysRemaining: Int {
        AppConfig.Subscription.foundersDaysRemaining
    }

    /// Data de fim formatada do período Founders
    var foundersEndDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale.current
        return formatter.string(from: AppConfig.Subscription.foundersEndDate)
    }

    /// Pacote mensal
    var monthlyPackage: Package? {
        regularMonthlyPackage ?? purchaseService.monthlyPackage
    }

    /// Pacote anual (regular)
    var annualPackage: Package? {
        regularAnnualPackage ?? purchaseService.annualPackage
    }

    /// Preço formatado do pacote mensal (com fallback)
    var monthlyPriceString: String {
        if let price = monthlyPackage?.localizedPriceString, !price.isEmpty, price != "--" {
            return price
        }
        return FallbackPrices.premiumMonthly
    }

    /// Preço formatado do pacote anual regular (com fallback)
    var annualPriceString: String {
        if let price = annualPackage?.localizedPriceString, !price.isEmpty, price != "--" {
            return price
        }
        return FallbackPrices.premiumAnnual
    }

    /// Preço formatado do pacote Founders (com fallback)
    var foundersPriceString: String {
        if let price = foundersPackage?.localizedPriceString, !price.isEmpty, price != "--" {
            return price
        }
        return FallbackPrices.foundersAnnual
    }

    /// Preço mensal equivalente do plano Founders (com fallback)
    var foundersMonthlyEquivalent: String {
        if let founders = foundersPackage,
           let priceFormatter = founders.storeProduct.priceFormatter {
            let monthlyPrice = founders.storeProduct.price as Decimal / 12
            if let formatted = priceFormatter.string(from: monthlyPrice as NSNumber), !formatted.isEmpty {
                return formatted
            }
        }
        return FallbackPrices.foundersMonthlyEquivalent
    }

    /// Economia do plano Founders em relação ao regular (com fallback)
    var foundersSavingsAmount: String {
        guard let founders = foundersPackage,
              let regular = annualPackage,
              let priceFormatter = founders.storeProduct.priceFormatter else {
            return "R$ 30,00" // Fallback: 89.90 - 59.90
        }

        let savings = (regular.storeProduct.price as Decimal) - (founders.storeProduct.price as Decimal)
        return priceFormatter.string(from: savings as NSNumber) ?? "R$ 30,00"
    }

    /// Porcentagem de desconto Founders (com fallback)
    var foundersDiscountPercentage: Int {
        guard let founders = foundersPackage,
              let regular = annualPackage else {
            return FallbackPrices.foundersDiscountPercent
        }

        let foundersPrice = founders.storeProduct.price as Decimal
        let regularPrice = regular.storeProduct.price as Decimal

        guard regularPrice > 0 else { return FallbackPrices.foundersDiscountPercent }

        let discount = ((regularPrice - foundersPrice) / regularPrice) * 100
        return Int(truncating: discount as NSNumber)
    }

    /// Economia do plano anual em porcentagem (com fallback)
    var annualSavingsPercentage: Int {
        guard let monthly = monthlyPackage?.storeProduct.price as Decimal?,
              let annual = annualPackage?.storeProduct.price as Decimal? else {
            return FallbackPrices.annualSavingsPercent
        }

        let monthlyTotal = monthly * 12
        guard monthlyTotal > 0 else { return FallbackPrices.annualSavingsPercent }

        let savings = ((monthlyTotal - annual) / monthlyTotal) * 100
        return Int(truncating: savings as NSNumber)
    }

    /// Preço mensal equivalente do plano anual (com fallback)
    var annualMonthlyEquivalent: String {
        if let annual = annualPackage,
           let priceFormatter = annual.storeProduct.priceFormatter {
            let monthlyPrice = annual.storeProduct.price as Decimal / 12
            if let formatted = priceFormatter.string(from: monthlyPrice as NSNumber), !formatted.isEmpty {
                return formatted
            }
        }
        return FallbackPrices.premiumMonthlyEquivalent
    }

    // MARK: - Init
    init(trigger: PaywallTrigger = .softPrompt) {
        self.trigger = trigger
        observePurchaseService()
        loadPackages()
    }

    // MARK: - Observe Purchase Service
    private func observePurchaseService() {
        purchaseService.$currentOffering
            .receive(on: DispatchQueue.main)
            .sink { [weak self] offering in
                self?.updatePackages(from: offering)
            }
            .store(in: &cancellables)

        purchaseService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
    }

    private func updatePackages(from offering: Offering?) {
        guard let offering = offering else {
            packages = []
            return
        }

        packages = offering.availablePackages

        // Atualiza pacotes regulares
        regularAnnualPackage = offering.annual
        regularMonthlyPackage = offering.monthly

        // Seleciona pacote padrão
        if selectedPackage == nil {
            if isFoundersPeriod, let founders = foundersPackage {
                selectedPackage = founders
            } else {
                selectedPackage = annualPackage ?? monthlyPackage
            }
        }
    }

    // MARK: - Load Packages
    func loadPackages() {
        Task {
            isLoading = true

            // Carrega offerings
            await purchaseService.fetchOfferings()

            // Se está no período Founders, tenta carregar o offering especial
            if isFoundersPeriod {
                await loadFoundersOffering()
            }

            isLoading = false
        }
    }

    /// Carrega o offering de Founders separadamente
    private func loadFoundersOffering() async {
        do {
            let offerings = try await Purchases.shared.offerings()

            // Tenta obter o offering "founders"
            if let foundersOffering = offerings.offering(identifier: AppConfig.Subscription.foundersOfferingId) {
                foundersPackage = foundersOffering.annual
            }

            // Garante que temos o offering default também para comparação
            if let defaultOffering = offerings.current ?? offerings.offering(identifier: AppConfig.Subscription.defaultOfferingId) {
                regularAnnualPackage = defaultOffering.annual
                regularMonthlyPackage = defaultOffering.monthly
            }

            // Seleciona Founders por padrão se disponível
            if let founders = foundersPackage {
                selectedPackage = founders
            }
        } catch {
            Logger.error(error, context: "Failed to load founders offering")
        }
    }

    // MARK: - Purchase

    /// Realiza a compra do pacote selecionado
    func purchase() async {
        guard let package = selectedPackage else {
            errorMessage = "paywall.error.noPackage".localized
            return
        }

        isPurchasing = true
        errorMessage = nil

        do {
            let success = try await subscriptionManager.purchase(package: package)

            if success {
                purchaseSuccess = true

                // Track se foi compra Founders
                let isFoundersPurchase = package.identifier == foundersPackage?.identifier
                Logger.info("Purchase completed - Trigger: \(trigger.rawValue), Founders: \(isFoundersPurchase)")

                // Marcar usuário como Founder no perfil se aplicável
                if isFoundersPurchase {
                    await markUserAsFounder()
                }

                // Track conversion
                trackPurchaseConversion()
            } else {
                Logger.info("Purchase cancelled by user")
            }
        } catch {
            errorMessage = error.localizedDescription
            Logger.error(error, context: "Purchase failed")
        }

        isPurchasing = false
    }

    /// Marca o usuário como Founder no Supabase
    private func markUserAsFounder() async {
        // TODO: Implementar marcação de Founder no perfil
        Logger.info("User marked as Founder")
    }

    /// Rastreia conversão com informações do trigger
    private func trackPurchaseConversion() {
        let params: [String: Any] = [
            "trigger": trigger.rawValue,
            "plan": selectedPlanType.rawValue,
            "is_founders": isFoundersPeriod,
            "price": isFoundersPeriod ? foundersPriceString : annualPriceString
        ]
        Logger.info("Purchase conversion: \(params)")
        // TODO: Analytics.logEvent("premium_purchased", parameters: params)
    }

    // MARK: - Restore Purchases

    /// Restaura compras anteriores
    func restorePurchases() async {
        isPurchasing = true
        errorMessage = nil

        do {
            try await subscriptionManager.restorePurchases()

            if subscriptionManager.isPremium {
                purchaseSuccess = true
                Logger.info("Purchases restored successfully")
            } else {
                errorMessage = "paywall.error.noPurchases".localized
            }
        } catch {
            errorMessage = error.localizedDescription
            Logger.error(error, context: "Restore failed")
        }

        isPurchasing = false
    }

    // MARK: - Select Package

    /// Seleciona um pacote
    func selectPackage(_ package: Package) {
        selectedPackage = package
    }

    /// Seleciona plano por tipo (para período regular)
    func selectPlan(_ type: PlanType) {
        selectedPlanType = type
        switch type {
        case .monthly:
            selectedPackage = monthlyPackage
        case .annual:
            selectedPackage = annualPackage
        }
    }

    /// Verifica se um pacote está selecionado
    func isSelected(_ package: Package) -> Bool {
        selectedPackage?.identifier == package.identifier
    }
}

// MARK: - Plan Type
enum PlanType: String, CaseIterable {
    case monthly = "monthly"
    case annual = "annual"

    var displayName: String {
        switch self {
        case .monthly:
            return "paywall.monthly".localized
        case .annual:
            return "paywall.annual".localized
        }
    }
}

// MARK: - Paywall Benefit Model
struct PaywallBenefit: Identifiable {
    let id = UUID()
    let icon: String
    let titleKey: String
    let descriptionKey: String

    var title: String {
        titleKey.localized
    }

    var description: String {
        descriptionKey.localized
    }
}
