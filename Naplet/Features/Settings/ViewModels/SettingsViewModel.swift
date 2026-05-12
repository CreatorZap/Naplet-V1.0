import Foundation
import SwiftUI

// MARK: - Settings ViewModel
@MainActor
class SettingsViewModel: ObservableObject {

    // MARK: - Dependencies
    private let supabaseService: SupabaseService

    // MARK: - Published Properties
    @Published var user: AppUser?
    @Published var babies: [Baby] = []
    @Published var selectedBabyId: UUID?
    @Published var isSigningOut: Bool = false
    @Published var signOutError: String?
    @Published var isDeletingAccount: Bool = false
    @Published var deleteAccountError: String?

    // Preferences
    @Published var notificationsEnabled: Bool {
        didSet {
            savePreference(key: Constants.StorageKeys.notificationsEnabled, value: notificationsEnabled)
        }
    }
    @Published var hapticFeedbackEnabled: Bool {
        didSet {
            savePreference(key: Constants.StorageKeys.hapticFeedbackEnabled, value: hapticFeedbackEnabled)
        }
    }
    @Published var use24HourFormat: Bool {
        didSet {
            UserDefaults.standard.set(use24HourFormat, forKey: "use24HourFormat")
        }
    }
    @Published var showWakeWindows: Bool {
        didSet {
            UserDefaults.standard.set(showWakeWindows, forKey: "showWakeWindows")
        }
    }

    @Published var aiDataSharingEnabled: Bool {
        didSet {
            if aiDataSharingEnabled {
                AIConsentManager.grantConsent()
            } else {
                AIConsentManager.revokeConsent()
            }
        }
    }

    // Sheets
    @Published var showAddBaby: Bool = false
    @Published var showEditProfile: Bool = false
    @Published var selectedBabyForSleepSchedule: Baby?

    // MARK: - Initialization

    init(supabaseService: SupabaseService? = nil) {
        self.supabaseService = supabaseService ?? SupabaseService.shared

        // Load preferences from UserDefaults
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: Constants.StorageKeys.notificationsEnabled)
        self.hapticFeedbackEnabled = UserDefaults.standard.object(forKey: Constants.StorageKeys.hapticFeedbackEnabled) as? Bool ?? true
        self.use24HourFormat = UserDefaults.standard.bool(forKey: "use24HourFormat")
        self.showWakeWindows = UserDefaults.standard.object(forKey: "showWakeWindows") as? Bool ?? true
        self.aiDataSharingEnabled = AIConsentManager.hasConsent

        loadData()
    }

    // MARK: - Methods

    func loadData() {
        // Load user from Supabase if authenticated
        if let supabaseUser = supabaseService.currentUser {
            // Fetch full profile from Supabase (includes avatarUrl and displayName)
            Task {
                await fetchProfileFromSupabase(userId: supabaseUser.id)
                await fetchBabiesFromSupabase()
            }
        } else {
            #if DEBUG
            // Use preview data in debug mode
            if AppEnvironment.current.useMockData {
                user = AppUser.preview
                babies = Baby.previewList
                selectedBabyId = babies.first?.id
            }
            #endif
        }
    }
    
    private func fetchProfileFromSupabase(userId: UUID) async {
        do {
            let profile: Profile = try await supabaseService.client
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                self.user = profile
            }
            
            Logger.info("SettingsViewModel: Profile loaded - \(profile.displayName ?? "no name"), avatar: \(profile.avatarUrl != nil ? "yes" : "no")")
        } catch {
            Logger.error("SettingsViewModel: Failed to fetch profile: \(error)")
            
            // Fallback to basic user info from auth
            if let supabaseUser = supabaseService.currentUser {
                await MainActor.run {
                    self.user = Profile(
                        id: supabaseUser.id,
                        email: supabaseUser.email,
                        displayName: supabaseUser.userMetadata["full_name"]?.stringValue
                    )
                }
            }
        }
    }
    
    private func fetchBabiesFromSupabase() async {
        guard let userId = supabaseService.currentUser?.id else { return }
        
        do {
            let fetchedBabies: [Baby] = try await supabaseService.client
                .from("babies")
                .select()
                .eq("owner_id", value: userId.uuidString)
                .execute()
                .value
            
            await MainActor.run {
                self.babies = fetchedBabies
                // Select the first baby if none selected
                if self.selectedBabyId == nil {
                    self.selectedBabyId = fetchedBabies.first?.id
                }
            }
            
            Logger.info("SettingsViewModel: Fetched \(fetchedBabies.count) babies")
        } catch {
            Logger.error("SettingsViewModel: Failed to fetch babies: \(error)")
            
            #if DEBUG
            // Fallback to mock data if fetch fails
            if AppEnvironment.current.useMockData {
                await MainActor.run {
                    self.babies = Baby.previewList
                    self.selectedBabyId = self.babies.first?.id
                }
            }
            #endif
        }
    }

    func signOut() {
        isSigningOut = true
        signOutError = nil

        Task {
            do {
                // Sign out from Supabase
                try await supabaseService.signOut()

                // Clear local user data
                UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.userId)
                UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.hasCompletedOnboarding)
                UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.currentBabyId)
                UserDefaults.standard.removeObject(forKey: "currentBaby")

                user = nil
                babies = []
                selectedBabyId = nil

                // Notificar o app para atualizar o estado de auth
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("UserDidSignOut"), object: nil)
                }

                Logger.info("User signed out successfully")
            } catch {
                signOutError = "error.signOutFailed".localized
                Logger.error("Sign out failed: \(error.localizedDescription)")
            }

            isSigningOut = false
        }
    }

    func deleteAccount() {
        isDeletingAccount = true
        deleteAccountError = nil

        Task {
            do {
                // Delete account and all data from Supabase
                try await supabaseService.deleteAccount()

                // Clear ALL local user data
                UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.userId)
                UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.hasCompletedOnboarding)
                UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.currentBabyId)
                UserDefaults.standard.removeObject(forKey: "currentBaby")
                UserDefaults.standard.removeObject(forKey: "selectedSleepGoals")
                AIConsentManager.revokeConsent()

                user = nil
                babies = []
                selectedBabyId = nil

                // Notificar o app para atualizar o estado de auth
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("UserDidSignOut"), object: nil)
                }

                Logger.info("Account deleted successfully")
            } catch {
                deleteAccountError = "settings.deleteAccount.error".localized
                Logger.error("Account deletion failed: \(error.localizedDescription)")
            }

            isDeletingAccount = false
        }
    }

    func selectBaby(_ baby: Baby) {
        selectedBabyId = baby.id
        UserDefaults.standard.set(baby.id.uuidString, forKey: Constants.StorageKeys.currentBabyId)
    }

    func deleteBaby(_ baby: Baby) {
        babies.removeAll { $0.id == baby.id }
        if selectedBabyId == baby.id {
            selectedBabyId = babies.first?.id
        }
    }
    
    func deleteBabyFromSupabase(_ baby: Baby) async {
        do {
            // Delete baby from Supabase
            try await supabaseService.client
                .from("babies")
                .delete()
                .eq("id", value: baby.id.uuidString)
                .execute()
            
            // Remove from local list
            await MainActor.run {
                babies.removeAll { $0.id == baby.id }
                if selectedBabyId == baby.id {
                    selectedBabyId = babies.first?.id
                }
            }
            
            Logger.info("Baby \(baby.name) deleted successfully")
        } catch {
            Logger.error("Failed to delete baby: \(error)")
        }
    }

    func updateProfile(displayName: String) {
        user?.displayName = displayName
        user?.updatedAt = Date()
        // TODO: Update in Supabase
    }

    /// Atualiza as preferencias de sono do bebe
    func updateBabySleepPreferences(_ baby: Baby, preferences: BabySleepPreferences) async {
        guard let index = babies.firstIndex(where: { $0.id == baby.id }) else { return }

        var updatedBaby = babies[index]
        updatedBaby.sleepPreferences = preferences

        // Atualizar localmente
        babies[index] = updatedBaby

        // Atualizar no Supabase
        do {
            try await supabaseService.client
                .from("babies")
                .update(["sleep_preferences": preferences])
                .eq("id", value: baby.id.uuidString)
                .execute()

            Logger.info("SettingsViewModel: Sleep preferences updated for \(baby.name)")
        } catch {
            Logger.error("SettingsViewModel: Failed to update sleep preferences: \(error)")
        }
    }

    // MARK: - Private Methods

    private func savePreference(key: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: key)
    }
}

// MARK: - Edit Profile ViewModel
@MainActor
class EditProfileViewModel: ObservableObject {

    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func loadUser(_ user: AppUser) {
        displayName = user.displayName ?? ""
        email = user.email ?? ""
    }

    func saveChanges() async -> Bool {
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "error.enterDisplayName".localized
            return false
        }

        isLoading = true
        // TODO: Update in Supabase
        try? await Task.sleep(nanoseconds: 500_000_000)
        isLoading = false

        return true
    }
}

// MARK: - Add Baby ViewModel
@MainActor
class AddBabyViewModel: ObservableObject {

    @Published var name: String = ""
    @Published var birthDate: Date = Date()
    @Published var gender: Baby.Gender?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func createBaby(ownerId: UUID) -> Baby? {
        guard isValid else {
            errorMessage = "baby.error.enterName".localized
            return nil
        }

        return Baby(
            name: name.trimmingCharacters(in: .whitespaces),
            birthDate: birthDate,
            gender: gender,
            ownerId: ownerId
        )
    }

    func saveBaby(ownerId: UUID) async -> Baby? {
        guard let baby = createBaby(ownerId: ownerId) else { return nil }

        isLoading = true
        // TODO: Save to Supabase
        try? await Task.sleep(nanoseconds: 500_000_000)
        isLoading = false

        return baby
    }
}
