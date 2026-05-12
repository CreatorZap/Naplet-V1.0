import Foundation
import RevenueCat
import StoreKit
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

    // MARK: - Loading State
    @Published var isLoadingPrices = true
    @Published var loadError = false
    @Published var retryCount = 0

    // MARK: - StoreKit 2 Fallback Prices (localized)
    private var storeKitProducts: [String: Product] = [:]

    // MARK: - Fallback Display (USD prices matching App Store Connect)
    private enum FallbackPrices {
        static let foundersAnnual = "$14.99"
        static let foundersMonthlyEquivalent = "$1.25"
        static let premiumAnnual = "$21.99"
        static let premiumMonthlyEquivalent = "$1.83"
        static let premiumMonthly = "$3.49"
        static let foundersSavingsAmount = "$7.00"
        static let foundersDiscountPercent = 32
        static let annualSavingsPercent = 42
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

    /// Preço formatado do pacote mensal (RevenueCat → StoreKit 2 → USD fallback)
    var monthlyPriceString: String {
        if let price = monthlyPackage?.localizedPriceString, !price.isEmpty, price != "--", price != "---" {
            return price
        }
        if let product = storeKitProducts["naplet_premium_monthly"] {
            return product.displayPrice
        }
        return FallbackPrices.premiumMonthly
    }

    /// Preço formatado do pacote anual regular (RevenueCat → StoreKit 2 → USD fallback)
    var annualPriceString: String {
        if let price = annualPackage?.localizedPriceString, !price.isEmpty, price != "--", price != "---" {
            return price
        }
        if let product = storeKitProducts["naplet_premium_annual"] {
            return product.displayPrice
        }
        return FallbackPrices.premiumAnnual
    }

    /// Preço formatado do pacote Founders (RevenueCat → StoreKit 2 → USD fallback)
    var foundersPriceString: String {
        if let price = foundersPackage?.localizedPriceString, !price.isEmpty, price != "--", price != "---" {
            return price
        }
        if let product = storeKitProducts["naplet_founders_annual"] {
            return product.displayPrice
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
        // StoreKit 2 fallback: calculate monthly from annual
        if let product = storeKitProducts["naplet_founders_annual"] {
            let monthly = product.price / 12
            return monthly.formatted(product.priceFormatStyle)
        }
        return FallbackPrices.foundersMonthlyEquivalent
    }

    /// Economia do plano Founders em relação ao regular (com fallback)
    var foundersSavingsAmount: String {
        // RevenueCat path
        if let founders = foundersPackage,
           let regular = annualPackage,
           let priceFormatter = founders.storeProduct.priceFormatter {
            let savings = (regular.storeProduct.price as Decimal) - (founders.storeProduct.price as Decimal)
            if let formatted = priceFormatter.string(from: savings as NSNumber) {
                return formatted
            }
        }
        // StoreKit 2 fallback
        if let founders = storeKitProducts["naplet_founders_annual"],
           let regular = storeKitProducts["naplet_premium_annual"] {
            let savings = regular.price - founders.price
            return savings.formatted(founders.priceFormatStyle)
        }
        return FallbackPrices.foundersSavingsAmount
    }

    /// Porcentagem de desconto Founders (com fallback)
    var foundersDiscountPercentage: Int {
        // RevenueCat path
        if let founders = foundersPackage,
           let regular = annualPackage {
            let foundersPrice = founders.storeProduct.price as Decimal
            let regularPrice = regular.storeProduct.price as Decimal
            guard regularPrice > 0 else { return FallbackPrices.foundersDiscountPercent }
            let discount = ((regularPrice - foundersPrice) / regularPrice) * 100
            return Int(truncating: discount as NSNumber)
        }
        // StoreKit 2 fallback
        if let founders = storeKitProducts["naplet_founders_annual"],
           let regular = storeKitProducts["naplet_premium_annual"] {
            guard regular.price > 0 else { return FallbackPrices.foundersDiscountPercent }
            let discount = ((regular.price - founders.price) / regular.price) * 100
            return Int(truncating: discount as NSNumber)
        }
        return FallbackPrices.foundersDiscountPercent
    }

    /// Economia do plano anual em porcentagem (com fallback)
    var annualSavingsPercentage: Int {
        // RevenueCat path
        if let monthly = monthlyPackage?.storeProduct.price as Decimal?,
           let annual = annualPackage?.storeProduct.price as Decimal? {
            let monthlyTotal = monthly * 12
            guard monthlyTotal > 0 else { return FallbackPrices.annualSavingsPercent }
            let savings = ((monthlyTotal - annual) / monthlyTotal) * 100
            return Int(truncating: savings as NSNumber)
        }
        // StoreKit 2 fallback
        if let monthly = storeKitProducts["naplet_premium_monthly"],
           let annual = storeKitProducts["naplet_premium_annual"] {
            let monthlyTotal = monthly.price * 12
            guard monthlyTotal > 0 else { return FallbackPrices.annualSavingsPercent }
            let savings = ((monthlyTotal - annual.price) / monthlyTotal) * 100
            return Int(truncating: savings as NSNumber)
        }
        return FallbackPrices.annualSavingsPercent
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
        // StoreKit 2 fallback
        if let product = storeKitProducts["naplet_premium_annual"] {
            let monthly = product.price / 12
            return monthly.formatted(product.priceFormatStyle)
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
            isLoadingPrices = true
            loadError = false
            isLoading = true

            // Carrega offerings
            await purchaseService.fetchOfferings()

            // Se está no período Founders, tenta carregar o offering especial
            if isFoundersPeriod {
                await loadFoundersOffering()
            }

            // Verifica se carregou pacotes
            if packages.isEmpty && foundersPackage == nil {
                loadError = true
                // Fallback: load localized prices via StoreKit 2
                await loadStoreKitPrices()
            }

            isLoading = false
            isLoadingPrices = false
        }
    }

    /// Retry loading offerings after failure
    func retryLoadOfferings() {
        loadPackages()
    }

    /// Load localized prices via StoreKit 2 when RevenueCat is unavailable
    private func loadStoreKitPrices() async {
        do {
            let productIDs: Set<String> = [
                "naplet_founders_annual",
                "naplet_premium_annual",
                "naplet_premium_monthly"
            ]
            let products = try await Product.products(for: productIDs)
            for product in products {
                storeKitProducts[product.id] = product
            }
            if !storeKitProducts.isEmpty {
                Logger.info("StoreKit 2 fallback prices loaded: \(storeKitProducts.keys.joined(separator: ", "))")
            }
        } catch {
            Logger.error(error, context: "Failed to load StoreKit 2 fallback prices")
        }
    }

    /// Called by CTA button — always attempts purchase, never gets stuck
    func ctaAction() async {
        // Has RevenueCat package: buy normally
        if selectedPackage != nil {
            await purchase()
            return
        }

        // No package — try one silent RevenueCat reload, then StoreKit 2
        if retryCount == 0 {
            retryCount += 1
            isPurchasing = true

            // Silent retry: reload offerings from RevenueCat
            await purchaseService.fetchOfferings()
            if isFoundersPeriod {
                await loadFoundersOffering()
            }

            // If reload worked, buy via RevenueCat
            if selectedPackage != nil {
                isPurchasing = false
                await purchase()
                return
            }

            isPurchasing = false
        }

        // RevenueCat unavailable — purchase directly via StoreKit 2
        await purchaseWithStoreKit2()
    }

    /// Direct StoreKit 2 purchase (no RevenueCat dependency)
    func purchaseWithStoreKit2() async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        let productID: String
        if isFoundersPeriod {
            productID = "naplet_founders_annual"
        } else if selectedPlanType == .annual {
            productID = "naplet_premium_annual"
        } else {
            productID = "naplet_premium_monthly"
        }

        do {
            let success = try await purchaseService.purchaseViaStoreKit(productID: productID)

            if success {
                purchaseSuccess = true
                Logger.info("StoreKit 2 direct purchase completed - Product: \(productID)")

                if isFoundersPeriod {
                    await markUserAsFounder()
                }
                trackPurchaseConversion()
            } else {
                Logger.info("StoreKit 2 purchase cancelled by user")
            }
        } catch {
            errorMessage = "paywall.error.purchaseFailed".localized
            Logger.error(error, context: "StoreKit 2 direct purchase failed")
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
