import SwiftUI

// MARK: - Content View
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var supabaseService: SupabaseService

    // DEBUG: Estado para bypass de login
    #if DEBUG
    @State private var devBypassLogin = false
    #endif

    var body: some View {
        Group {
            if appState.isLoading {
                loadingView
            } else if AppEnvironment.current.useMockData {
                // Mock mode: skip auth, go directly to onboarding/main
                mockModeFlow
            } else {
                // Production mode: require auth
                #if DEBUG
                if devBypassLogin {
                    // Dev bypass: go to onboarding without real auth
                    mockModeFlow
                } else {
                    productionModeFlow
                }
                #else
                productionModeFlow
                #endif
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isLoading)
        .animation(.easeInOut(duration: 0.3), value: appState.hasCompletedOnboarding)
        #if DEBUG
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BypassLogin"))) { _ in
            withAnimation {
                devBypassLogin = true
            }
        }
        #endif
    }

    // MARK: - Mock Mode Flow
    @ViewBuilder
    private var mockModeFlow: some View {
        if appState.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView()
        }
    }

    // MARK: - Production Mode Flow
    @ViewBuilder
    private var productionModeFlow: some View {
        if supabaseService.currentUser != nil {
            // User is authenticated
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        } else {
            // User is not authenticated - show Sign In with Apple
            SignInView()
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        ZStack {
            NapletColors.background
                .ignoresSafeArea()

            VStack(spacing: NapletSpacing.lg) {
                // App Icon/Logo
                ZStack {
                    Circle()
                        .fill(NapletColors.gradientPrimary)
                        .frame(width: 100, height: 100)

                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }

                // App Name
                Text("Naplet")
                    .font(NapletTypography.largeTitle())
                    .foregroundStyle(NapletColors.gradientPrimary)

                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: NapletColors.primaryPurple))
                    .scaleEffect(1.2)
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard
    @ObservedObject private var localizationManager = LocalizationManager.shared

    enum Tab {
        case dashboard
        case history
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("tabs.home".localized, systemImage: "house.fill")
                }
                .tag(Tab.dashboard)

            SleepHistoryView()
                .tabItem {
                    Label("tabs.history".localized, systemImage: "clock.fill")
                }
                .tag(Tab.history)

            SettingsView()
                .tabItem {
                    Label("tabs.settings".localized, systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(NapletColors.primaryPurple)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToHistory"))) { _ in
            withAnimation { selectedTab = .history }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToSettings"))) { _ in
            withAnimation { selectedTab = .settings }
        }
        .id(localizationManager.refreshID) // Force rebuild when language changes
        .detectScreenshot() // Shows Instagram tag reminder when user takes screenshot
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(SupabaseService.shared)
}
