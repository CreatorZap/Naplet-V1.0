import Foundation
import SwiftUI
import UserNotifications

// MARK: - Onboarding ViewModel
@MainActor
class OnboardingViewModel: ObservableObject {

    // MARK: - Navigation
    @Published var currentStep: OnboardingStep = .welcome
    @Published var isOnboardingComplete = false

    // MARK: - Baby Data
    @Published var babyName: String = ""
    @Published var babyBirthDate: Date = Date()
    @Published var babyGender: Baby.Gender? = nil
    @Published var babyNotBornYet: Bool = false
    @Published var birthDateWasSelected: Bool = false
    @Published var genderWasSelected: Bool = false

    // MARK: - User Data
    @Published var relationship: CaregiverRelationship = .mother
    @Published var attribution: AttributionSource? = nil
    @Published var selectedGoals: Set<SleepGoal> = []

    // MARK: - Loading State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var loadingMessage: String = ""

    // MARK: - Dependencies
    private let babyRepository = BabyRepository()

    // MARK: - Onboarding Steps (12 telas)
    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case benefits = 1
        case differentials = 2
        case attribution = 3
        case goals = 4
        case babyName = 5
        case babyBirth = 6
        case babyGender = 7
        case relationship = 8
        case confirmation = 9
        case loading = 10
        case paywall = 11
        case completion = 12
    }

    // MARK: - Caregiver Relationship
    enum CaregiverRelationship: String, CaseIterable, Identifiable, Codable {
        case mother = "mother"
        case father = "father"
        case grandparent = "grandparent"
        case nanny = "nanny"
        case other = "other"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .mother: return "onboarding_relationship_mother".localized
            case .father: return "onboarding_relationship_father".localized
            case .grandparent: return "onboarding_relationship_grandparent".localized
            case .nanny: return "onboarding_relationship_nanny".localized
            case .other: return "onboarding_relationship_other".localized
            }
        }

        var icon: String {
            switch self {
            case .mother: return "figure.stand.dress"
            case .father: return "figure.stand"
            case .grandparent: return "figure.2.arms.open"
            case .nanny: return "heart.fill"
            case .other: return "person.fill"
            }
        }
    }

    // MARK: - Attribution Source
    enum AttributionSource: String, CaseIterable, Identifiable, Codable {
        case instagram = "instagram"
        case appstore = "appstore"
        case influencer = "influencer"
        case tiktok = "tiktok"
        case google = "google"
        case parentGroup = "parent_group"
        case friend = "friend"
        case other = "other"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .instagram: return "onboarding_attribution_instagram".localized
            case .appstore: return "onboarding_attribution_appstore".localized
            case .influencer: return "onboarding_attribution_influencer".localized
            case .tiktok: return "onboarding_attribution_tiktok".localized
            case .google: return "onboarding_attribution_google".localized
            case .parentGroup: return "onboarding_attribution_group".localized
            case .friend: return "onboarding_attribution_friend".localized
            case .other: return "onboarding_attribution_other".localized
            }
        }

        var icon: String {
            switch self {
            case .instagram: return "camera.fill"
            case .appstore: return "app.badge.fill"
            case .influencer: return "star.fill"
            case .tiktok: return "play.rectangle.fill"
            case .google: return "magnifyingglass"
            case .parentGroup: return "person.3.fill"
            case .friend: return "heart.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }

    // MARK: - Sleep Goals
    enum SleepGoal: String, CaseIterable, Identifiable, Codable {
        case longerNaps = "longer_naps"
        case fasterSleep = "faster_sleep"
        case sleepThroughNight = "sleep_through_night"
        case fewerWakings = "fewer_wakings"
        case establishRoutine = "establish_routine"
        case moreEnergy = "more_energy"
        case trackFeeding = "track_feeding"
        case shareWithFamily = "share_with_family"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .longerNaps: return "onboarding_goal_longer_naps".localized
            case .fasterSleep: return "onboarding_goal_faster_sleep".localized
            case .sleepThroughNight: return "onboarding_goal_sleep_through".localized
            case .fewerWakings: return "onboarding_goal_fewer_wakings".localized
            case .establishRoutine: return "onboarding_goal_routine".localized
            case .moreEnergy: return "onboarding_goal_energy".localized
            case .trackFeeding: return "onboarding_goal_feeding".localized
            case .shareWithFamily: return "onboarding_goal_family".localized
            }
        }

        var icon: String {
            switch self {
            case .longerNaps: return "bed.double.fill"
            case .fasterSleep: return "clock.fill"
            case .sleepThroughNight: return "moon.stars.fill"
            case .fewerWakings: return "zzz"
            case .establishRoutine: return "calendar"
            case .moreEnergy: return "bolt.fill"
            case .trackFeeding: return "fork.knife"
            case .shareWithFamily: return "person.2.fill"
            }
        }
    }

    // MARK: - Computed Properties

    var canProceedFromBabyName: Bool {
        !babyName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var isFirstStep: Bool {
        currentStep == .welcome
    }

    var progress: Double {
        Double(currentStep.rawValue) / Double(OnboardingStep.allCases.count - 1)
    }

    var totalSteps: Int {
        OnboardingStep.allCases.count
    }

    var showProgressIndicator: Bool {
        currentStep != .welcome
            && currentStep != .loading
            && currentStep != .paywall
            && currentStep != .completion
    }

    var formattedBirthDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: babyBirthDate)
    }

    var genderDisplayName: String {
        guard let gender = babyGender else {
            return "onboarding_gender_not_specified".localized
        }
        return gender.displayName
    }

    // MARK: - Birth Date Validation
    var isValidBirthDate: Bool {
        if babyNotBornYet {
            return true
        }

        guard birthDateWasSelected else { return false }

        let now = Date()
        let fiveYearsAgo = Calendar.current.date(byAdding: .year, value: -5, to: now) ?? now

        return babyBirthDate <= now && babyBirthDate >= fiveYearsAgo
    }

    var canConfirmOnboarding: Bool {
        let nameValid = !babyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let birthValid = isValidBirthDate
        return nameValid && birthValid
    }

    // MARK: - Navigation Methods

    func nextStep() {
        guard canProceedFromCurrentStep() else { return }

        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex < OnboardingStep.allCases.count - 1 else {
            return
        }

        HapticManager.shared.lightImpact()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            currentStep = OnboardingStep.allCases[currentIndex + 1]
        }
    }

    private func canProceedFromCurrentStep() -> Bool {
        switch currentStep {
        case .babyName:
            return canProceedFromBabyName
        case .babyBirth:
            return isValidBirthDate
        case .babyGender:
            return genderWasSelected
        case .confirmation:
            return canConfirmOnboarding
        default:
            return true
        }
    }

    func previousStep() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else { return }

        // Haptic feedback para voltar
        HapticManager.shared.lightImpact()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            currentStep = OnboardingStep.allCases[currentIndex - 1]
        }
    }

    func goToStep(_ step: OnboardingStep) {
        // Haptic feedback para navegação direta
        HapticManager.shared.lightImpact()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            currentStep = step
        }
    }

    func skipAttribution() {
        attribution = nil
        nextStep()
    }

    func skipGoals() {
        selectedGoals = []
        nextStep()
    }

    // MARK: - Selection Haptics

    /// Chame ao selecionar uma opção (attribution, goals, gender, etc)
    func selectOption() {
        HapticManager.shared.selection()
    }

    // MARK: - Start Loading Sequence
    func startLoadingSequence() async {
        let messages = [
            "onboarding_loading_1".localized,
            String(format: "onboarding_loading_2".localized, babyName),
            "onboarding_loading_3".localized,
            "onboarding_loading_4".localized
        ]

        for message in messages {
            await MainActor.run {
                withAnimation {
                    loadingMessage = message
                }
            }
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        }

        // Save baby data first (but don't complete onboarding yet)
        await saveBabyData()

        // Go to paywall screen with success haptic
        // After paywall (purchase or skip), user advances to completion
        await MainActor.run {
            HapticManager.shared.success()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                currentStep = .paywall
            }
        }
    }
    
    // MARK: - Save Baby Data (without completing onboarding)
    private func saveBabyData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Try to save to Supabase if authenticated
            if SupabaseService.shared.currentUser != nil {
                let baby = try await babyRepository.createBaby(
                    name: babyName,
                    birthDate: babyBirthDate,
                    gender: babyGender
                )

                // Save additional onboarding data
                await saveOnboardingData()

                Logger.info("Baby saved to Supabase: \(baby.id)")
            } else {
                // Fallback: save locally
                saveBabyLocally()
                Logger.info("Baby saved locally (not authenticated)")
            }

            // Save goals locally
            let goalsArray = selectedGoals.map { $0.rawValue }
            UserDefaults.standard.set(goalsArray, forKey: "selectedSleepGoals")

        } catch {
            Logger.error("Failed to save baby: \(error)")
            // Fallback: save locally if failed
            saveBabyLocally()
        }

        isLoading = false
    }

    // MARK: - Complete Onboarding (called when user taps button on celebration screen)
    func completeOnboarding() async {
        // Mark onboarding as complete in UserDefaults
        UserDefaults.standard.set(true, forKey: Constants.StorageKeys.hasCompletedOnboarding)
        
        await MainActor.run {
            withAnimation {
                isOnboardingComplete = true
            }
        }
    }

    private func saveOnboardingData() async {
        // Save attribution and goals to user profile if needed
        if let attribution = attribution {
            UserDefaults.standard.set(attribution.rawValue, forKey: "onboarding_attribution")
        }
        UserDefaults.standard.set(relationship.rawValue, forKey: "onboarding_relationship")
    }

    private func saveBabyLocally() {
        // Save baby data to UserDefaults
        let babyData: [String: Any] = [
            "name": babyName,
            "birthDate": babyBirthDate.timeIntervalSince1970,
            "gender": babyGender?.rawValue ?? ""
        ]
        UserDefaults.standard.set(babyData, forKey: "currentBaby")

        Logger.info("Baby saved locally: \(babyName)")
    }

    // MARK: - Notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.error("Notification permission error: \(error.localizedDescription)")
                } else {
                    Logger.info("Notifications permission: \(granted)")
                    UserDefaults.standard.set(granted, forKey: Constants.StorageKeys.notificationsEnabled)
                }
            }
        }
    }

    func createBaby(ownerId: UUID) -> Baby {
        Baby(
            name: babyName.trimmingCharacters(in: .whitespaces),
            birthDate: babyBirthDate,
            gender: babyGender,
            ownerId: ownerId
        )
    }
}
