import Foundation
import RevenueCat
import StoreKit

// MARK: - Founders Manager
/// Gerencia o período especial "Founders" do Naplet
/// Founders pagam menos e têm o preço travado para sempre
final class FoundersManager: ObservableObject {

    // MARK: - Singleton
    static let shared = FoundersManager()

    // MARK: - Published Properties
    @Published private(set) var isFoundersPeriod: Bool = false
    @Published private(set) var daysRemaining: Int = 0

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let foundersKey = "naplet_user_is_founder"
    private let purchaseDateKey = "naplet_founder_purchase_date"

    /// Data de término do período Founders (unificada com AppConfig)
    var foundersEndDate: Date {
        AppConfig.Subscription.foundersEndDate
    }

    // MARK: - Initialization

    private init() {
        updateFoundersStatus()
    }

    // MARK: - Public Methods

    /// Atualiza o status do período Founders
    func updateFoundersStatus() {
        let now = Date()
        isFoundersPeriod = now < foundersEndDate

        if isFoundersPeriod {
            let components = Calendar.current.dateComponents([.day], from: now, to: foundersEndDate)
            daysRemaining = max(0, components.day ?? 0)
        } else {
            daysRemaining = 0
        }

        #if DEBUG
        print("🌟 Founders Status: \(isFoundersPeriod ? "ATIVO" : "ENCERRADO")")
        print("📅 Dias restantes: \(daysRemaining)")
        #endif
    }

    /// Marca o usuário como Founder após compra bem-sucedida
    func markUserAsFounder() {
        userDefaults.set(true, forKey: foundersKey)
        userDefaults.set(Date(), forKey: purchaseDateKey)

        #if DEBUG
        print("🏆 Usuário marcado como FOUNDER!")
        #endif
    }

    /// Verifica se o usuário é Founder
    var isUserFounder: Bool {
        userDefaults.bool(forKey: foundersKey)
    }

    /// Data em que o usuário comprou como Founder
    var founderPurchaseDate: Date? {
        userDefaults.object(forKey: purchaseDateKey) as? Date
    }

    // MARK: - Computed Properties

    /// Texto do countdown para UI
    var countdownText: String {
        if daysRemaining == 0 {
            return "Oferta encerrada"
        } else if daysRemaining == 1 {
            return "ÚLTIMO DIA!"
        } else if daysRemaining <= 7 {
            return "Restam apenas \(daysRemaining) dias"
        } else {
            return "Restam \(daysRemaining) dias"
        }
    }

    /// Data formatada de término
    var formattedEndDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: foundersEndDate)
    }

    /// Qual offering usar baseado no período
    var currentOfferingIdentifier: String {
        isFoundersPeriod ? "founders" : "default"
    }

    /// Texto de urgência para UI
    var urgencyText: String? {
        guard isFoundersPeriod else { return nil }

        if daysRemaining <= 3 {
            return "⚡ Últimos dias!"
        } else if daysRemaining <= 7 {
            return "🔥 Oferta terminando em breve"
        } else if daysRemaining <= 14 {
            return "⏰ Tempo limitado"
        }
        return nil
    }
}

// MARK: - Purchase Service
@MainActor
final class PurchaseService: NSObject, ObservableObject {

    // MARK: - Singleton
    static let shared = PurchaseService()

    // MARK: - Published Properties
    @Published var isSubscribed = false
    @Published var currentOffering: Offering?
    @Published var customerInfo: CustomerInfo?
    @Published var isLoading = false

    // MARK: - Dependencies
    private var foundersManager: FoundersManager {
        FoundersManager.shared
    }

    // MARK: - Init
    private override init() {
        super.init()
    }

    // MARK: - Configuration

    /// Configure RevenueCat SDK
    func configure() {
        // Skip RevenueCat configuration in mock mode
        guard !AppEnvironment.current.useMockData else {
            Logger.info("PurchaseService: Running in mock mode, skipping RevenueCat configuration")
            // Check developer access even in mock mode
            checkDeveloperAccess()
            return
        }

        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .error
        #endif

        Purchases.configure(
            with: Configuration.Builder(withAPIKey: AppConfig.revenueCatAPIKey)
                .with(storeKitVersion: .storeKit2)
                .with(userDefaults: .standard)
                .build()
        )

        // Set delegate for customer info updates
        Purchases.shared.delegate = self

        #if DEBUG
        print("✅ RevenueCat configurado!")
        print("🔑 API Key: \(String(AppConfig.revenueCatAPIKey.prefix(20)))...")
        #endif
        Logger.info("RevenueCat configured successfully")

        // Fetch initial data
        Task {
            await refreshCustomerInfo()
            await fetchOfferings()
        }
    }

    // MARK: - Mock Methods (for development)
    #if DEBUG
    /// Mock subscribe for testing
    func mockSubscribe() {
        isSubscribed = true
        Logger.info("Mock subscription activated")
    }

    /// Mock unsubscribe for testing
    func mockUnsubscribe() {
        isSubscribed = false
        Logger.info("Mock subscription deactivated")
    }
    #endif

    // MARK: - Customer Info

    /// Refresh customer info from RevenueCat
    func refreshCustomerInfo() async {
        // Developer bypass check
        if isDeveloperUser {
            isSubscribed = true
            Logger.info("Developer access - skipping RevenueCat check")
            return
        }

        do {
            let info = try await Purchases.shared.customerInfo()
            customerInfo = info
            isSubscribed = info.entitlements[AppConfig.Subscription.premiumEntitlement]?.isActive == true
            Logger.info("Subscription status: \(isSubscribed)")
        } catch {
            Logger.error(error, context: "Failed to fetch customer info")
        }
    }

    // MARK: - Offerings

    /// Fetch available offerings
    /// Automaticamente seleciona o offering correto baseado no período Founders
    func fetchOfferings() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let offerings = try await Purchases.shared.offerings()

            // Atualiza status Founders
            foundersManager.updateFoundersStatus()

            // Seleciona offering baseado no período
            let targetOfferingId = foundersManager.currentOfferingIdentifier

            if let targetOffering = offerings.offering(identifier: targetOfferingId) {
                currentOffering = targetOffering
                Logger.info("Loaded offering: \(targetOfferingId) with \(targetOffering.availablePackages.count) packages")
            } else {
                // Fallback para offering atual
                currentOffering = offerings.current
                Logger.warning("Offering '\(targetOfferingId)' not found, using current")
            }

            Logger.info("Fetched offerings: \(offerings.all.count)")
        } catch {
            Logger.error(error, context: "Failed to fetch offerings")
        }
    }

    // MARK: - Purchase

    /// Purchase a package
    /// - Parameter package: The package to purchase
    /// - Returns: True if purchase was successful, false if cancelled
    func purchase(package: Package) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let result = try await Purchases.shared.purchase(package: package)
        customerInfo = result.customerInfo
        isSubscribed = result.customerInfo.entitlements[AppConfig.Subscription.premiumEntitlement]?.isActive == true

        // Se compra bem-sucedida durante período Founders, marca o usuário
        if !result.userCancelled && isSubscribed && foundersManager.isFoundersPeriod {
            foundersManager.markUserAsFounder()
            Logger.info("Founders purchase completed!")
        }

        Logger.info("Purchase completed. Subscribed: \(isSubscribed)")
        return !result.userCancelled
    }

    /// Purchase a specific product by ID
    func purchaseProduct(id: String) async throws -> Bool {
        guard let offering = currentOffering,
              let package = offering.availablePackages.first(where: { $0.storeProduct.productIdentifier == id }) else {
            throw PurchaseError.productNotFound
        }
        return try await purchase(package: package)
    }

    // MARK: - Restore

    /// Restore previous purchases
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        let info = try await Purchases.shared.restorePurchases()
        customerInfo = info
        isSubscribed = info.entitlements[AppConfig.Subscription.premiumEntitlement]?.isActive == true

        Logger.info("Purchases restored. Subscribed: \(isSubscribed)")
    }

    // MARK: - User Management

    /// Set the user ID for RevenueCat
    func setUserID(_ userID: String) async {
        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(userID)
            self.customerInfo = customerInfo
            isSubscribed = customerInfo.entitlements[AppConfig.Subscription.premiumEntitlement]?.isActive == true
            Logger.info("User ID set: \(userID)")
        } catch {
            Logger.error(error, context: "Failed to set user ID")
        }
    }

    /// Log out the current user
    func logOutUser() async {
        do {
            let customerInfo = try await Purchases.shared.logOut()
            self.customerInfo = customerInfo
            isSubscribed = false
            Logger.info("User logged out from RevenueCat")
        } catch {
            Logger.error(error, context: "Failed to log out user")
        }
    }

    // MARK: - Helpers

    /// Get monthly package if available
    var monthlyPackage: Package? {
        currentOffering?.monthly
    }

    /// Get annual package if available
    var annualPackage: Package? {
        currentOffering?.annual
    }

    /// Check if user has active subscription (includes developer bypass)
    var hasActiveSubscription: Bool {
        // Developer bypass - always has access
        if isDeveloperUser {
            return true
        }
        return customerInfo?.entitlements[AppConfig.Subscription.premiumEntitlement]?.isActive == true
    }

    /// Check if current user is a developer with free premium access
    var isDeveloperUser: Bool {
        let email = SupabaseService.shared.currentUser?.email
        let isDev = AppConfig.Developer.isDeveloper(email: email)
        #if DEBUG
        if isDev {
            print("🔓 Developer access granted for: \(email ?? "unknown")")
        }
        #endif
        return isDev
    }

    /// Get expiration date for current subscription
    var subscriptionExpirationDate: Date? {
        customerInfo?.entitlements[AppConfig.Subscription.premiumEntitlement]?.expirationDate
    }

    /// Check if subscription will renew
    var willRenew: Bool {
        customerInfo?.entitlements[AppConfig.Subscription.premiumEntitlement]?.willRenew == true
    }

    // MARK: - StoreKit 2 Fallback

    /// Direct StoreKit 2 purchase when RevenueCat is unavailable (e.g., sandbox issues)
    func purchaseViaStoreKit(productID: String) async throws -> Bool {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else {
            throw PurchaseError.productNotFound
        }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                isSubscribed = true

                // Sync with RevenueCat if possible
                Task {
                    await refreshCustomerInfo()
                }

                Logger.info("StoreKit 2 purchase successful: \(productID)")
                return true
            case .unverified:
                Logger.warning("StoreKit 2 purchase unverified: \(productID)")
                return false
            }
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Developer Access

    /// Verifica e ativa acesso de desenvolvedor
    /// Chamar após o login do usuário para garantir que o status seja atualizado
    func checkDeveloperAccess() {
        if isDeveloperUser {
            isSubscribed = true
            Logger.info("Developer access activated for: \(SupabaseService.shared.currentUser?.email ?? "unknown")")
            #if DEBUG
            print("🔓 Developer premium access activated!")
            #endif
        }
    }
}

// MARK: - PurchasesDelegate
extension PurchaseService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            // Developer bypass - always subscribed
            if self.isDeveloperUser {
                self.isSubscribed = true
            } else {
                self.isSubscribed = customerInfo.entitlements[AppConfig.Subscription.premiumEntitlement]?.isActive == true
            }
            Logger.info("Customer info updated via delegate")
        }
    }
}

// MARK: - Purchase Errors
enum PurchaseError: Error, LocalizedError {
    case productNotFound
    case purchaseFailed
    case restoreFailed

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "The requested product was not found."
        case .purchaseFailed:
            return "The purchase could not be completed."
        case .restoreFailed:
            return "Failed to restore purchases."
        }
    }
}
