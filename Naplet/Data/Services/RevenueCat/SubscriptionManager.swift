import Foundation
import RevenueCat
import Combine

// MARK: - Subscription Manager
/// Gerencia o estado de assinatura sincronizando RevenueCat com Supabase
@MainActor
final class SubscriptionManager: ObservableObject {

    // MARK: - Singleton
    static let shared = SubscriptionManager()

    // MARK: - Dependencies
    private let purchaseService = PurchaseService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published Properties
    @Published private(set) var subscriptionStatus: Profile.SubscriptionStatus = .free
    @Published private(set) var expirationDate: Date?
    @Published private(set) var isLoading = false
    @Published var showPaywall = false

    // MARK: - Computed Properties

    /// Verifica se o usuário é premium (assinatura ativa ou desenvolvedor)
    var isPremium: Bool {
        // Developer bypass - sempre premium
        if purchaseService.isDeveloperUser {
            return true
        }
        return subscriptionStatus == .premium
    }

    /// Verifica se o usuário está no período trial
    var isTrial: Bool {
        subscriptionStatus == .trial
    }

    /// Verifica se o usuário é free
    var isFree: Bool {
        subscriptionStatus == .free
    }

    /// Verifica se tem acesso a funcionalidades premium (premium, trial ou desenvolvedor)
    var hasPremiumAccess: Bool {
        // Developer bypass - sempre tem acesso
        if purchaseService.isDeveloperUser {
            return true
        }
        return isPremium || isTrial
    }

    /// Dias restantes do trial
    var trialDaysRemaining: Int? {
        guard isTrial, let expirationDate = expirationDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
        return max(0, days)
    }

    // MARK: - Init
    private init() {
        observePurchaseService()
    }

    // MARK: - Observe Purchase Service
    private func observePurchaseService() {
        purchaseService.$isSubscribed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSubscribed in
                self?.updateSubscriptionStatus(isSubscribed: isSubscribed)
            }
            .store(in: &cancellables)

        purchaseService.$customerInfo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] customerInfo in
                self?.processCustomerInfo(customerInfo)
            }
            .store(in: &cancellables)
    }

    // MARK: - Update Status
    private func updateSubscriptionStatus(isSubscribed: Bool) {
        // Developer bypass - sempre premium
        if purchaseService.isDeveloperUser {
            subscriptionStatus = .premium
            return
        }

        if isSubscribed {
            subscriptionStatus = .premium
        } else if subscriptionStatus != .trial {
            subscriptionStatus = .free
        }
    }

    private func processCustomerInfo(_ customerInfo: CustomerInfo?) {
        guard let info = customerInfo else { return }

        // Check entitlement
        if let entitlement = info.entitlements[AppConfig.Subscription.premiumEntitlement] {
            if entitlement.isActive {
                subscriptionStatus = .premium
                expirationDate = entitlement.expirationDate
            } else {
                subscriptionStatus = .free
                expirationDate = nil
            }
        }

        // Sync with Supabase
        Task {
            await syncWithSupabase()
        }
    }

    // MARK: - Sync with Supabase

    /// Sincroniza o estado da assinatura com o Supabase
    func syncWithSupabase() async {
        guard let userId = SupabaseService.shared.currentUserId else { return }

        do {
            let update: [String: AnyEncodable] = [
                "subscription_status": AnyEncodable(subscriptionStatus.rawValue),
                "subscription_expires_at": AnyEncodable(expirationDate),
                "updated_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
            ]

            try await SupabaseService.shared.client
                .from("profiles")
                .update(update)
                .eq("id", value: userId.uuidString)
                .execute()

            Logger.info("Subscription status synced with Supabase: \(subscriptionStatus.rawValue)")
        } catch {
            Logger.error(error, context: "Failed to sync subscription with Supabase")
        }
    }

    // MARK: - Purchase Methods

    /// Compra um pacote
    func purchase(package: Package) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let success = try await purchaseService.purchase(package: package)

        if success {
            await syncWithSupabase()
        }

        return success
    }

    /// Restaura compras anteriores
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        try await purchaseService.restorePurchases()
        await syncWithSupabase()
    }

    // MARK: - Feature Access Control

    /// Verifica se tem acesso ao recurso de convites (multi-caregiver)
    var canInviteCaregivers: Bool {
        hasPremiumAccess
    }

    /// Verifica se tem acesso ao chat IA ilimitado
    var hasUnlimitedChat: Bool {
        hasPremiumAccess
    }

    /// Verifica se tem acesso a estatísticas detalhadas
    var hasDetailedStats: Bool {
        hasPremiumAccess
    }

    /// Verifica se pode adicionar mais bebês
    func canAddMoreBabies(currentCount: Int) -> Bool {
        let maxBabies = subscriptionStatus.maxBabies
        return currentCount < maxBabies
    }

    /// Verifica se tem acesso a exportação PDF
    var canExportPDF: Bool {
        hasPremiumAccess
    }

    // MARK: - Paywall Triggers

    /// Mostra o paywall se não for premium
    /// - Returns: true se o paywall foi mostrado, false se já é premium
    @discardableResult
    func requirePremium() -> Bool {
        if hasPremiumAccess {
            return false
        }
        showPaywall = true
        return true
    }

    /// Verifica acesso e mostra paywall se necessário
    /// - Parameter feature: Nome do recurso para analytics
    /// - Returns: true se tem acesso, false se precisa de upgrade
    func checkAccess(for feature: String) -> Bool {
        if hasPremiumAccess {
            return true
        }
        Logger.info("Feature blocked: \(feature) - showing paywall")
        showPaywall = true
        return false
    }

    // MARK: - User Management

    /// Configura o usuário no RevenueCat
    func setUser(id: String) async {
        await purchaseService.setUserID(id)
    }

    /// Faz logout do usuário
    func logoutUser() async {
        await purchaseService.logOutUser()
        subscriptionStatus = .free
        expirationDate = nil
    }

    // MARK: - Refresh

    /// Atualiza o estado da assinatura
    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        await purchaseService.refreshCustomerInfo()
        await purchaseService.fetchOfferings()
    }
}

// MARK: - AnyEncodable Helper
struct AnyEncodable: Encodable {
    private let value: Encodable?

    init<T: Encodable>(_ value: T?) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = value {
            try value.encode(to: encoder)
        } else {
            try container.encodeNil()
        }
    }
}
