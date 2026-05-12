import SwiftUI

// MARK: - Onboarding View (Main Container)
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            NapletColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator (hidden on welcome, loading, completion)
                if viewModel.showProgressIndicator {
                    OnboardingProgressIndicator(
                        currentStep: viewModel.currentStep.rawValue,
                        totalSteps: viewModel.totalSteps
                    )
                    .padding(.top, NapletSpacing.md)
                }

                // Content (Group+switch instead of TabView to prevent swipe bypass)
                Group {
                    switch viewModel.currentStep {
                    case .welcome:
                        WelcomeStepView(viewModel: viewModel)
                    case .benefits:
                        BenefitsStepView(viewModel: viewModel)
                    case .differentials:
                        DifferentialsStepView(viewModel: viewModel)
                    case .attribution:
                        AttributionStepView(viewModel: viewModel)
                    case .goals:
                        GoalsStepView(viewModel: viewModel)
                    case .babyName:
                        BabyNameStepView(viewModel: viewModel)
                    case .babyBirth:
                        BabyBirthStepView(viewModel: viewModel)
                    case .babyGender:
                        BabyGenderStepView(viewModel: viewModel)
                    case .relationship:
                        RelationshipStepView(viewModel: viewModel)
                    case .confirmation:
                        ConfirmationStepView(viewModel: viewModel)
                    case .loading:
                        LoadingStepView(viewModel: viewModel)
                    case .completion:
                        CompletionStepView(viewModel: viewModel)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.currentStep)
            }
        }
        .onChange(of: viewModel.isOnboardingComplete) { _, isComplete in
            Logger.debug("🔄 isOnboardingComplete changed to: \(isComplete)")
            if isComplete {
                Logger.debug("✅ Completing onboarding...")
                withAnimation {
                    appState.completeOnboarding()
                }
                Logger.debug("✅ appState.hasCompletedOnboarding = \(appState.hasCompletedOnboarding)")
                // Note: Don't call checkAppState() here as it may reset hasCompletedOnboarding
                // if there's no authenticated user (dev bypass mode)
            }
        }
    }
}

// MARK: - Tela 1: Welcome
struct WelcomeStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var appState: AppState
    @State private var showAcceptInvite = false
    @State private var showLogin = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: NapletSpacing.xl) {
                    Spacer(minLength: NapletSpacing.xl)

                    // Logo and Illustration
                    VStack(spacing: NapletSpacing.lg) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Naplet")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(NapletColors.textPrimary)
                    }

                    // Title and Subtitle
                    VStack(spacing: NapletSpacing.md) {
                        Text("onboarding_welcome_title".localized)
                            .font(NapletTypography.title1())
                            .foregroundColor(NapletColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("onboarding_welcome_subtitle".localized)
                            .font(NapletTypography.body())
                            .foregroundColor(NapletColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, NapletSpacing.lg)
                    }

                    // Social Proof
                    SocialProofBanner(text: "onboarding_welcome_social_proof".localized)
                        .padding(.top, NapletSpacing.md)

                    Spacer(minLength: NapletSpacing.xl)
                }
            }

            // Buttons
            VStack(spacing: NapletSpacing.md) {
                OnboardingPrimaryButton("onboarding_welcome_cta".localized) {
                    viewModel.nextStep()
                }

                OnboardingSecondaryButton("onboarding_welcome_invite".localized, icon: "ticket.fill") {
                    showAcceptInvite = true
                }

                OnboardingTextButton(title: "onboarding_welcome_login".localized) {
                    showLogin = true
                }
                .padding(.top, NapletSpacing.sm)
            }
            .padding(.bottom, NapletSpacing.xxl)
        }
        .sheet(isPresented: $showAcceptInvite) {
            AcceptInviteView()
                .presentationBackground(NapletColors.background)
        }
        .sheet(isPresented: $showLogin) {
            SignInView()
                .presentationBackground(NapletColors.background)
        }
    }
}

// MARK: - Tela 2: Benefits
struct BenefitsStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: NapletSpacing.lg) {
            // Back button
            HStack {
                OnboardingBackButton { viewModel.previousStep() }
                Spacer()
            }
            .padding(.horizontal, NapletSpacing.md)

            ScrollView(showsIndicators: false) {
                VStack(spacing: NapletSpacing.xl) {
                    // Header
                    VStack(spacing: NapletSpacing.sm) {
                        Text("onboarding_benefits_title".localized)
                            .font(NapletTypography.largeTitle())
                            .foregroundColor(NapletColors.textPrimary)

                        Text("onboarding_benefits_subtitle".localized)
                            .font(NapletTypography.body())
                            .foregroundColor(NapletColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, NapletSpacing.md)
                    }
                    .padding(.top, NapletSpacing.lg)

                    // Benefit Cards
                    VStack(spacing: NapletSpacing.md) {
                        BenefitCard(
                            icon: "brain.head.profile",
                            title: "onboarding_benefit_1_title".localized,
                            description: "onboarding_benefit_1_desc".localized,
                            iconColor: NapletColors.primaryPurple
                        )

                        BenefitCard(
                            icon: "moon.zzz.fill",
                            title: "onboarding_benefit_2_title".localized,
                            description: "onboarding_benefit_2_desc".localized,
                            iconColor: NapletColors.primaryPink
                        )

                        BenefitCard(
                            icon: "person.2.fill",
                            title: "onboarding_benefit_3_title".localized,
                            description: "onboarding_benefit_3_desc".localized,
                            iconColor: NapletColors.primaryBlue
                        )
                    }
                    .padding(.horizontal, NapletSpacing.lg)
                }
            }

            Spacer()

            OnboardingPrimaryButton("onboarding_benefits_cta".localized, icon: "arrow.right") {
                viewModel.nextStep()
            }
            .padding(.bottom, NapletSpacing.xxl)
        }
    }
}

// MARK: - Tela 3: Differentials
struct DifferentialsStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: NapletSpacing.lg) {
            // Back button
            HStack {
                OnboardingBackButton { viewModel.previousStep() }
                Spacer()
            }
            .padding(.horizontal, NapletSpacing.md)

            ScrollView(showsIndicators: false) {
                VStack(spacing: NapletSpacing.xl) {
                    // Header
                    VStack(spacing: NapletSpacing.sm) {
                        Text("onboarding_diff_title".localized)
                            .font(NapletTypography.title1())
                            .foregroundColor(NapletColors.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("onboarding_diff_subtitle".localized)
                            .font(NapletTypography.body())
                            .foregroundColor(NapletColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, NapletSpacing.md)
                    }
                    .padding(.top, NapletSpacing.lg)

                    // Differential Cards with Badges
                    VStack(spacing: NapletSpacing.md) {
                        OnboardingDifferentialCard(
                            iconName: "cpu.fill",
                            title: "onboarding_diff_1_title".localized,
                            description: "onboarding_diff_1_desc".localized,
                            badgeText: "onboarding_diff_1_badge".localized,
                            badgeStyle: .exclusive
                        )

                        OnboardingDifferentialCard(
                            iconName: "doc.text.fill",
                            title: "onboarding_diff_2_title".localized,
                            description: "onboarding_diff_2_desc".localized,
                            badgeText: "onboarding_diff_2_badge".localized,
                            badgeStyle: .exclusive
                        )

                        OnboardingDifferentialCard(
                            iconName: "dollarsign.circle.fill",
                            title: "onboarding_diff_3_title".localized,
                            description: "onboarding_diff_3_desc".localized,
                            badgeText: "onboarding_diff_3_badge".localized,
                            badgeStyle: .bestValue
                        )
                    }
                    .padding(.horizontal, NapletSpacing.lg)
                }
            }

            Spacer()

            OnboardingPrimaryButton("common.continue".localized, icon: "arrow.right") {
                viewModel.nextStep()
            }
            .padding(.bottom, NapletSpacing.xxl)
        }
    }
}

// MARK: - Tela 4: Attribution
struct AttributionStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: NapletSpacing.lg) {
            // Back button
            HStack {
                OnboardingBackButton { viewModel.previousStep() }
                Spacer()
            }
            .padding(.horizontal, NapletSpacing.md)

            ScrollView(showsIndicators: false) {
                VStack(spacing: NapletSpacing.xl) {
                    // Header
                    VStack(spacing: NapletSpacing.sm) {
                        Text("onboarding_attribution_title".localized)
                            .font(NapletTypography.title1())
                            .foregroundColor(NapletColors.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("onboarding_attribution_subtitle".localized)
                            .font(NapletTypography.body())
                            .foregroundColor(NapletColors.textSecondary)
                    }
                    .padding(.top, NapletSpacing.lg)

                    // Options
                    VStack(spacing: NapletSpacing.sm) {
                        ForEach(OnboardingViewModel.AttributionSource.allCases) { source in
                            SelectableOptionCard(
                                source.displayName,
                                icon: source.icon,
                                isSelected: viewModel.attribution == source
                            ) {
                                viewModel.attribution = source
                            }
                        }
                    }
                    .padding(.horizontal, NapletSpacing.lg)
                }
            }

            Spacer()

            VStack(spacing: NapletSpacing.md) {
                OnboardingPrimaryButton("common.next".localized, icon: "arrow.right") {
                    viewModel.nextStep()
                }
                .disabled(viewModel.attribution == nil)
                .opacity(viewModel.attribution == nil ? 0.5 : 1.0)

                OnboardingTextButton(title: "onboarding_skip".localized) {
                    viewModel.skipAttribution()
                }
            }
            .padding(.bottom, NapletSpacing.xxl)
        }
    }
}

// MARK: - Tela 5: Goals
struct GoalsStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: NapletSpacing.lg) {
            // Back button
            HStack {
                OnboardingBackButton { viewModel.previousStep() }
                Spacer()
            }
            .padding(.horizontal, NapletSpacing.md)

            ScrollView(showsIndicators: false) {
                VStack(spacing: NapletSpacing.xl) {
                    // Header
                    VStack(spacing: NapletSpacing.sm) {
                        Text("onboarding_goals_title".localized)
                            .font(NapletTypography.title1())
                            .foregroundColor(NapletColors.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("onboarding_goals_subtitle".localized)
                            .font(NapletTypography.body())
                            .foregroundColor(NapletColors.textSecondary)
                            .multilineTextAlignment(.center)

                        MicrocopyText(
                            text: "onboarding_goals_microcopy".localized,
                            iconName: "lightbulb"
                        )
                        .padding(.top, NapletSpacing.xs)
                    }
                    .padding(.top, NapletSpacing.lg)

                    // Goals Checkboxes
                    VStack(spacing: NapletSpacing.sm) {
                        ForEach(OnboardingViewModel.SleepGoal.allCases) { goal in
                            SelectableCheckboxCard(
                                goal.displayName,
                                icon: goal.icon,
                                isSelected: viewModel.selectedGoals.contains(goal)
                            ) {
                                if viewModel.selectedGoals.contains(goal) {
                                    viewModel.selectedGoals.remove(goal)
                                } else {
                                    viewModel.selectedGoals.insert(goal)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, NapletSpacing.lg)
                }
            }

            Spacer()

            VStack(spacing: NapletSpacing.md) {
                OnboardingPrimaryButton("common.continue".localized, icon: "arrow.right") {
                    viewModel.nextStep()
                }
                .disabled(viewModel.selectedGoals.isEmpty)
                .opacity(viewModel.selectedGoals.isEmpty ? 0.5 : 1.0)

                OnboardingTextButton(title: "onboarding_goals_skip".localized) {
                    viewModel.skipGoals()
                }
            }
            .padding(.bottom, NapletSpacing.xxl)
        }
    }
}

// MARK: - Tela 6: Baby Name
struct BabyNameStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                OnboardingBackButton { viewModel.previousStep() }
                Spacer()
            }
            .padding(.horizontal, NapletSpacing.md)

            ScrollView(showsIndicators: false) {
                VStack(spacing: NapletSpacing.lg) {
                    Spacer(minLength: NapletSpacing.xl)

                    // Illustration
                    Image(systemName: "face.smiling.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Header
                    VStack(spacing: NapletSpacing.sm) {
                        Text("onboarding_baby_name_title".localized)
                            .font(NapletTypography.title1())
                            .foregroundColor(NapletColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("onboarding_baby_name_subtitle".localized)
                            .font(NapletTypography.body())
                            .foregroundColor(NapletColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Text Field
                    TextField("", text: $viewModel.babyName)
                        .placeholder(when: viewModel.babyName.isEmpty) {
                            Text("onboarding_baby_name_placeholder".localized)
                                .foregroundColor(NapletColors.textMuted)
                        }
                        .font(NapletTypography.title2())
                        .foregroundColor(NapletColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(NapletColors.backgroundSecondary)
                        .cornerRadius(16)
                        .padding(.horizontal, NapletSpacing.xl)
                        .focused($isNameFocused)

                    Text("onboarding_baby_name_hint".localized)
                        .font(NapletTypography.caption())
                        .foregroundColor(NapletColors.textMuted)

                    Spacer(minLength: NapletSpacing.xl)
                }
            }

            OnboardingPrimaryButton(
                "common.next".localized,
                icon: "arrow.right",
                isDisabled: !viewModel.canProceedFromBabyName
            ) {
                viewModel.nextStep()
            }
            .padding(.bottom, NapletSpacing.xxl)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
            }
        }
    }
}

// MARK: - Tela 7: Baby Birth
struct BabyBirthStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                OnboardingBackButton { viewModel.previousStep() }
                Spacer()
            }
            .padding(.horizontal, NapletSpacing.md)

            ScrollView(showsIndicators: false) {
                VStack(spacing: NapletSpacing.lg) {
                    Spacer(minLength: NapletSpacing.xl)

                    // Illustration
                    Image(systemName: "birthday.cake.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [NapletColors.primaryPink, NapletColors.warning],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Header
                    VStack(spacing: NapletSpacing.sm) {
                        Text(String(format: "onboarding_baby_birth_title".localized, viewModel.babyName))
                            .font(NapletTypography.title1())
                            .foregroundColor(NapletColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(String(format: "onboarding_baby_birth_subtitle".localized, viewModel.babyName))
                            .font(NapletTypography.body())
                            .foregroundColor(NapletColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, NapletSpacing.lg)

                        MicrocopyText(
                            text: "onboarding_baby_birth_microcopy".localized,
                            iconName: "info.circle"
                        )
                    }

                    // Toggle for not born yet
                    Toggle(isOn: $viewModel.babyNotBornYet) {
                        Text("onboarding_baby_not_born".localized)
                            .font(NapletTypography.body())
                            .foregroundColor(NapletColors.textPrimary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: NapletColors.primaryPurple))
                    .padding(.horizontal, NapletSpacing.xl)
                    .padding(.vertical, NapletSpacing.md)
                    .background(NapletColors.backgroundSecondary)
                    .cornerRadius(12)
                    .padding(.horizontal, NapletSpacing.lg)
                    .onChange(of: viewModel.babyNotBornYet) { _, newValue in
                        if newValue {
                            viewModel.birthDateWasSelected = true
                        }
                    }

                    // Date Picker
                    if !viewModel.babyNotBornYet {
                        DatePicker(
                            "",
                            selection: $viewModel.babyBirthDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .padding(.horizontal, NapletSpacing.lg)
                        .onChange(of: viewModel.babyBirthDate) { _, _ in
                            viewModel.birthDateWasSelected = true
                        }
                    }

                    Spacer(minLength: NapletSpacing.xl)
                }
            }

            OnboardingPrimaryButton(
                "common.next".localized,
                icon: "arrow.right",
                isDisabled: !viewModel.isValidBirthDate
            ) {
                viewModel.nextStep()
            }
            .padding(.bottom, NapletSpacing.xxl)
        }
    }
}

// MARK: - Tela 8: Baby Gender
struct BabyGenderStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                OnboardingBackButton { viewModel.previousStep() }
                Spacer()
            }
            .padding(.horizontal, NapletSpacing.md)

            ScrollView(showsIndicators: false) {
                VStack(spacing: NapletSpacing.lg) {
                    Spacer(minLength: NapletSpacing.xl)

                    // Illustration
                    Image(systemName: "figure.2.and.child.holdinghands")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [NapletColors.primaryBlue, NapletColors.primaryPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    // Header
                    VStack(spacing: NapletSpacing.sm) {
                        Text(String(format: "onboarding_baby_gender_title".localized, viewModel.babyName))
                            .font(NapletTypography.title1())
                            .foregroundColor(NapletColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, NapletSpacing.lg)

                        Text("onboarding_baby_gender_subtitle".localized)
                            .font(NapletTypography.body())
                            .foregroundColor(NapletColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Gender Options
                    VStack(spacing: NapletSpacing.md) {
                        SelectableOptionCard(
                            "onboarding_gender_male".localized,
                            icon: "figure.stand",
                            isSelected: viewModel.babyGender == .male
                        ) {
                            viewModel.babyGender = .male
                            viewModel.genderWasSelected = true
                        }

                        SelectableOptionCard(
                            "onboarding_gender_female".localized,
                            icon: "figure.stand.dress",
                            isSelected: viewModel.babyGender == .female
                        ) {
                            viewModel.babyGender = .female
                            viewModel.genderWasSelected = true
                        }

                        SelectableOptionCard(
                            "onboarding_gender_not_specified".localized,
                            icon: "questionmark.circle",
                            isSelected: viewModel.genderWasSelected && viewModel.babyGender == nil
                        ) {
                            viewModel.babyGender = nil
                            viewModel.genderWasSelected = true
                        }
                    }
                    .padding(.horizontal, NapletSpacing.lg)

                    Spacer(minLength: NapletSpacing.xl)
                }
            }

            OnboardingPrimaryButton(
                "common.next".localized,
                icon: "arrow.right",
                isDisabled: !viewModel.genderWasSelected
            ) {
                viewModel.nextStep()
            }
            .padding(.bottom, NapletSpacing.xxl)
        }
    }
}

// MARK: - Tela 9: Relationship
struct RelationshipStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                OnboardingBackButton { viewModel.previousStep() }
                Spacer()
            }
            .padding(.horizontal, NapletSpacing.md)

            ScrollView(showsIndicators: false) {
                VStack(spacing: NapletSpacing.lg) {
                    Spacer(minLength: NapletSpacing.xl)

                    // Illustration
                    Image(systemName: "heart.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [NapletColors.primaryPink, NapletColors.primaryPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Header
                    VStack(spacing: NapletSpacing.sm) {
                        Text(String(format: "onboarding_relationship_title".localized, viewModel.babyName))
                            .font(NapletTypography.title1())
                            .foregroundColor(NapletColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, NapletSpacing.lg)

                        Text("onboarding_relationship_subtitle".localized)
                            .font(NapletTypography.body())
                            .foregroundColor(NapletColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Relationship Options
                    VStack(spacing: NapletSpacing.sm) {
                        ForEach(OnboardingViewModel.CaregiverRelationship.allCases) { relationship in
                            SelectableOptionCard(
                                relationship.displayName,
                                icon: relationship.icon,
                                isSelected: viewModel.relationship == relationship
                            ) {
                                viewModel.relationship = relationship
                            }
                        }
                    }
                    .padding(.horizontal, NapletSpacing.lg)

                    Spacer(minLength: NapletSpacing.xl)
                }
            }

            OnboardingPrimaryButton("common.next".localized, icon: "arrow.right") {
                viewModel.nextStep()
            }
            .padding(.bottom, NapletSpacing.xxl)
        }
    }
}

// MARK: - Tela 10: Confirmation
struct ConfirmationStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: NapletSpacing.lg) {
            // Back button
            HStack {
                OnboardingBackButton { viewModel.previousStep() }
                Spacer()
            }
            .padding(.horizontal, NapletSpacing.md)

            ScrollView(showsIndicators: false) {
                VStack(spacing: NapletSpacing.xl) {
                    // Header
                    VStack(spacing: NapletSpacing.sm) {
                        Text("onboarding_confirm_title".localized)
                            .font(NapletTypography.largeTitle())
                            .foregroundColor(NapletColors.textPrimary)

                        Text("onboarding_confirm_subtitle".localized)
                            .font(NapletTypography.body())
                            .foregroundColor(NapletColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, NapletSpacing.lg)

                    // Confirmation Card
                    VStack(spacing: 0) {
                        ConfirmationRow(
                            label: "onboarding_confirm_name".localized,
                            value: viewModel.babyName
                        ) {
                            viewModel.goToStep(.babyName)
                        }

                        Divider()
                            .background(NapletColors.backgroundTertiary)

                        ConfirmationRow(
                            label: "onboarding_confirm_birth".localized,
                            value: viewModel.babyNotBornYet ? "onboarding_baby_not_born".localized : viewModel.formattedBirthDate
                        ) {
                            viewModel.goToStep(.babyBirth)
                        }

                        Divider()
                            .background(NapletColors.backgroundTertiary)

                        ConfirmationRow(
                            label: "onboarding_confirm_gender".localized,
                            value: viewModel.genderDisplayName
                        ) {
                            viewModel.goToStep(.babyGender)
                        }

                        Divider()
                            .background(NapletColors.backgroundTertiary)

                        ConfirmationRow(
                            label: "onboarding_confirm_you_are".localized,
                            value: viewModel.relationship.displayName
                        ) {
                            viewModel.goToStep(.relationship)
                        }
                    }
                    .background(NapletColors.backgroundSecondary)
                    .cornerRadius(16)
                    .padding(.horizontal, NapletSpacing.lg)
                }
            }

            Spacer()

            OnboardingPrimaryButton(
                "onboarding_confirm_cta".localized,
                icon: "checkmark",
                isDisabled: !viewModel.canConfirmOnboarding
            ) {
                viewModel.goToStep(.loading)
                Task {
                    await viewModel.startLoadingSequence()
                }
            }
            .padding(.bottom, NapletSpacing.xxl)
        }
    }
}

// MARK: - Tela 11: Loading
struct LoadingStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack {
            Spacer()

            OnboardingLoadingView(message: viewModel.loadingMessage)

            Spacer()
        }
    }
}

// MARK: - Tela 12: Completion
struct CompletionStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            VStack(spacing: NapletSpacing.xl) {
                Spacer()

                // Celebration Icon
                ZStack {
                    Circle()
                        .fill(NapletColors.success.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(NapletColors.success)
                }

                // Header
                VStack(spacing: NapletSpacing.md) {
                    Text("onboarding_complete_title".localized)
                        .font(NapletTypography.largeTitle())
                        .foregroundColor(NapletColors.textPrimary)

                    Text("onboarding_complete_welcome".localized)
                        .font(NapletTypography.title3())
                        .foregroundColor(NapletColors.primaryPurple)

                    Text("onboarding_complete_message".localized)
                        .font(NapletTypography.body())
                        .foregroundColor(NapletColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, NapletSpacing.xl)
                }

                // Tip Card
                OnboardingTipCard(
                    title: "onboarding_complete_tip_title".localized,
                    text: "onboarding_complete_tip_text".localized
                )
                .padding(.horizontal, NapletSpacing.lg)
                .padding(.top, NapletSpacing.md)

                Spacer()

                // Complete Button
                OnboardingPrimaryButton("onboarding_complete_cta".localized, icon: "arrow.right") {
                    Logger.debug("Complete button tapped - finishing onboarding")
                    HapticManager.shared.success()
                    // Request notifications before completing
                    viewModel.requestNotificationPermission()
                    // Complete onboarding after a small delay for visual feedback
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                        await viewModel.completeOnboarding()
                    }
                }
                .padding(.bottom, NapletSpacing.xxl)
            }

            // Confetti
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                showConfetti = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
