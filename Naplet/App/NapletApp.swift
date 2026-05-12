import SwiftUI
import Supabase
import GoogleSignIn

// MARK: - Naplet App
@main
struct NapletApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var supabaseService = SupabaseService.shared
    @StateObject private var purchaseService = PurchaseService.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var watchConnectivity = iOSConnectivityManager.shared

    init() {
        // Configure services
        configureServices()

        // Configure appearance
        configureAppearance()

        // Activate Watch Connectivity early
        _ = iOSConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .withLocalization() // Enable real-time language switching
                .environmentObject(appState)
                .environmentObject(supabaseService)
                .environmentObject(purchaseService)
                .environmentObject(subscriptionManager)
                .environmentObject(localizationManager)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    // MARK: - Deep Link Handler

    private func handleDeepLink(_ url: URL) {
        // Handle Google Sign In callback
        if GIDSignIn.sharedInstance.handle(url) {
            Logger.info("Google Sign In handled URL")
            return
        }
        
        // Handle app-specific deep links
        guard url.scheme == "naplet" else { return }

        switch url.host {
        case "startSleep":
            NotificationCenter.default.post(name: .widgetRequestedStartSleep, object: nil)
            Logger.info("Deep link: startSleep")
        case "stopSleep":
            NotificationCenter.default.post(name: .widgetRequestedStopSleep, object: nil)
            Logger.info("Deep link: stopSleep")
        default:
            Logger.warning("Unknown deep link: \(url)")
        }
    }

    // MARK: - Configuration

    private func configureServices() {
        // Configure RevenueCat (will skip if in mock mode)
        PurchaseService.shared.configure()

        // Log configuration
        AppConfig.logConfiguration()
    }

    private func configureAppearance() {
        // Navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(NapletColors.background)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(NapletColors.background)

        // Tab bar item colors
        let normalColor = UIColor(NapletColors.textMuted)
        let selectedColor = UIColor(NapletColors.primaryPurple)

        tabAppearance.stackedLayoutAppearance.normal.iconColor = normalColor
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        tabAppearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}

// MARK: - App State
@MainActor
class AppState: ObservableObject {

    // MARK: - Published Properties
    @Published var isLoading: Bool = true
    @Published var hasCompletedOnboarding: Bool = false
    @Published var authState: AuthState = .unknown
    @Published var isRefreshingAfterLogin: Bool = false
    @Published var currentBaby: Baby?
    @Published var babies: [Baby] = []

    // MARK: - Services
    private var supabaseService: SupabaseService { SupabaseService.shared }
    private var purchaseService: PurchaseService { PurchaseService.shared }

    // MARK: - Initialization

    init() {
        // Conectar callback de auth state change do SupabaseService
        supabaseService.onSignedIn = { [weak self] user in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let profile = Profile(
                    id: user.id,
                    email: user.email,
                    displayName: user.userMetadata["display_name"]?.stringValue
                )
                self.authState = .authenticated(profile)
            }
        }

        // Escutar notificação de sign out
        NotificationCenter.default.addObserver(forName: NSNotification.Name("UserDidSignOut"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.authState = .unauthenticated
                self?.currentBaby = nil
                self?.babies = []
                self?.hasCompletedOnboarding = false
            }
        }

        Task {
            await checkAppState()
        }
    }

    // MARK: - Methods

    func checkAppState() async {
        Logger.info("Checking app state...")

        // Wait for Supabase to initialize (max 10 seconds timeout)
        let startTime = Date()
        let maxWait: TimeInterval = 10
        while !supabaseService.isInitialized {
            if Date().timeIntervalSince(startTime) > maxWait {
                Logger.warning("Supabase initialization timeout after \(maxWait)s - continuing without waiting")
                break
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }

        // In mock mode, use local data only
        if AppEnvironment.current.useMockData {
            await checkMockModeState()
        } else {
            await checkProductionModeState()
        }

        isLoading = false
    }

    // MARK: - Mock Mode State Check

    private func checkMockModeState() async {
        Logger.info("Running in mock mode - using local data")
        authState = .unauthenticated
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Constants.StorageKeys.hasCompletedOnboarding)
        loadBabyFromLocalStorage()
    }

    // MARK: - Production Mode State Check

    private func checkProductionModeState() async {
        // Check auth state from Supabase
        if let user = supabaseService.currentUser {
            Logger.info("User authenticated: \(user.email ?? "unknown")")

            // Create AppUser from Supabase user
            let appUser = Profile(
                id: user.id,
                email: user.email,
                displayName: user.userMetadata["display_name"]?.stringValue
            )
            authState = .authenticated(appUser)

            // Verificar acesso de desenvolvedor
            purchaseService.checkDeveloperAccess()

            // Set user ID for RevenueCat and sync subscription
            await purchaseService.setUserID(user.id.uuidString)
            await SubscriptionManager.shared.setUser(id: user.id.uuidString)

            // ✅ IMPORTANTE: Buscar bebês do Supabase
            await fetchBabiesFromSupabase(userId: user.id)

            // Determinar se precisa de onboarding baseado nos bebês
            if babies.isEmpty {
                // Sem bebês → precisa fazer onboarding
                hasCompletedOnboarding = false
                Logger.info("No babies found - showing onboarding")
            } else {
                // Tem bebês → já completou onboarding
                hasCompletedOnboarding = true
                currentBaby = babies.first
                Logger.info("Found \(babies.count) baby(ies) - skipping onboarding")
            }

        } else {
            Logger.info("No authenticated user")
            authState = .unauthenticated
            hasCompletedOnboarding = false
        }
    }

    // MARK: - Fetch Babies from Supabase

    private func fetchBabiesFromSupabase(userId: UUID) async {
        do {
            // Buscar bebês que o usuário é dono
            let ownedBabies: [Baby] = try await supabaseService.client
                .from("babies")
                .select()
                .eq("owner_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            // Buscar bebês compartilhados via caregiver
            let sharedBabiesResponse: [Baby] = try await supabaseService.client
                .from("babies")
                .select("*, caregivers!inner(*)")
                .eq("caregivers.user_id", value: userId.uuidString)
                .not("owner_id", operator: .eq, value: userId.uuidString)
                .execute()
                .value

            // Combinar e remover duplicados
            var allBabies = ownedBabies
            for baby in sharedBabiesResponse {
                if !allBabies.contains(where: { $0.id == baby.id }) {
                    allBabies.append(baby)
                }
            }

            babies = allBabies
            Logger.info("Fetched \(babies.count) babies from Supabase")

            // Definir bebê atual
            if let savedBabyId = UserDefaults.standard.string(forKey: Constants.StorageKeys.currentBabyId),
               let uuid = UUID(uuidString: savedBabyId),
               let savedBaby = babies.first(where: { $0.id == uuid }) {
                currentBaby = savedBaby
            } else {
                currentBaby = babies.first
                if let baby = currentBaby {
                    UserDefaults.standard.set(baby.id.uuidString, forKey: Constants.StorageKeys.currentBabyId)
                }
            }

        } catch {
            Logger.error(error, context: "Failed to fetch babies from Supabase")
            // Fallback para dados locais se a busca falhar
            loadBabyFromLocalStorage()
            hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Constants.StorageKeys.hasCompletedOnboarding)
        }
    }

    // MARK: - Local Storage Helpers

    private func loadBabyFromLocalStorage() {
        if let babyData = UserDefaults.standard.dictionary(forKey: "currentBaby"),
           let name = babyData["name"] as? String,
           let birthDateTimestamp = babyData["birthDate"] as? TimeInterval {
            let birthDate = Date(timeIntervalSince1970: birthDateTimestamp)
            let genderRaw = babyData["gender"] as? String
            let gender = genderRaw.flatMap { Baby.Gender(rawValue: $0) }

            currentBaby = Baby(
                name: name,
                birthDate: birthDate,
                gender: gender,
                ownerId: UUID()
            )
            Logger.info("Loaded baby from local storage: \(name)")
        }
    }

    // MARK: - Onboarding

    func completeOnboarding(baby: Baby? = nil) {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: Constants.StorageKeys.hasCompletedOnboarding)

        if let baby = baby {
            currentBaby = baby
            babies.append(baby)
            UserDefaults.standard.set(baby.id.uuidString, forKey: Constants.StorageKeys.currentBabyId)

            // Salvar localmente também (backup)
            saveBabyToLocalStorage(baby)
        }

        Logger.info("Onboarding completed")
    }

    private func saveBabyToLocalStorage(_ baby: Baby) {
        let babyData: [String: Any] = [
            "name": baby.name,
            "birthDate": baby.birthDate.timeIntervalSince1970,
            "gender": baby.gender?.rawValue as Any
        ]
        UserDefaults.standard.set(babyData, forKey: "currentBaby")
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await supabaseService.signOut()
            await purchaseService.logOutUser()

            authState = .unauthenticated
            currentBaby = nil
            babies = []
            hasCompletedOnboarding = false

            // Clear local storage
            UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.hasCompletedOnboarding)
            UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.userId)
            UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.currentBabyId)
            UserDefaults.standard.removeObject(forKey: "currentBaby")

            Logger.info("User signed out")
        } catch {
            Logger.error(error, context: "Failed to sign out")
        }
    }

    // MARK: - Baby Selection

    func selectBaby(_ baby: Baby) {
        currentBaby = baby
        UserDefaults.standard.set(baby.id.uuidString, forKey: Constants.StorageKeys.currentBabyId)
        Logger.info("Selected baby: \(baby.name)")
    }

    func addBaby(_ baby: Baby) {
        babies.append(baby)
        if currentBaby == nil {
            selectBaby(baby)
        }
    }

    func removeBaby(_ baby: Baby) {
        babies.removeAll { $0.id == baby.id }
        if currentBaby?.id == baby.id {
            currentBaby = babies.first
        }
    }

    // MARK: - Auth State Update

    func updateAuthState(user: Profile) {
        authState = .authenticated(user)
    }

    // MARK: - Refresh State (after login)

    func refreshAfterLogin() async {
        // Garantir que authState está autenticado
        if case .authenticated = authState {
            // OK, já autenticado
        } else if let user = supabaseService.currentUser {
            // Fallback: setar authState a partir do currentUser
            let profile = Profile(
                id: user.id,
                email: user.email,
                displayName: user.userMetadata["display_name"]?.stringValue
            )
            authState = .authenticated(profile)
        } else {
            return
        }
        guard let userId = supabaseService.currentUserId else { return }

        isRefreshingAfterLogin = true

        // Verificar acesso de desenvolvedor após login
        purchaseService.checkDeveloperAccess()

        // Configurar RevenueCat
        await purchaseService.setUserID(userId.uuidString)
        await SubscriptionManager.shared.setUser(id: userId.uuidString)

        // Buscar bebês do Supabase
        await fetchBabiesFromSupabase(userId: userId)

        if babies.isEmpty {
            hasCompletedOnboarding = false
        } else {
            hasCompletedOnboarding = true
        }

        isRefreshingAfterLogin = false
    }
}

// MARK: - JSON Value Extension
extension AnyJSON {
    var stringValue: String? {
        switch self {
        case .string(let value):
            return value
        default:
            return nil
        }
    }
}
