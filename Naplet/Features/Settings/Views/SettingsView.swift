import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showCaregiversView = false
    @State private var showAcceptInviteView = false
    @State private var babyToDelete: Baby?
    @State private var showDeleteBabyAlert = false
    @State private var showLanguagePicker = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showProfileView = false
    @State private var showSupportView = false
    @State private var babyToEdit: Baby?
    @State private var showNotificationSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: NapletSpacing.lg) {
                // Drag Indicator
                Capsule()
                    .fill(NapletColors.textMuted.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, NapletSpacing.sm)

                // Header
                VStack(spacing: NapletSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(NapletColors.primaryPurple.opacity(0.2))
                            .frame(width: 80, height: 80)

                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 36))
                            .foregroundColor(NapletColors.primaryPurple)
                    }

                    Text(L10n.Settings.title.localized)
                        .font(NapletTypography.title2())
                        .foregroundColor(NapletColors.textPrimary)
                }

                // Profile Section
                profileSection

                // Baby Section
                babySection

                // Caregivers Section
                caregiversSection

                // Preferences Section
                preferencesSection

                // Notifications Section
                notificationsSection

                // About Section
                aboutSection

                // Logout Button
                logoutButton
            }
            .padding(NapletSpacing.md)
        }
        .background(NapletColors.background)
        .id(localizationManager.refreshID) // Force rebuild when language changes
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageDidChange"))) { _ in
            // Force view update when language changes
            #if DEBUG
            print("[SettingsView] Received LanguageDidChange notification")
            #endif
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }

    // MARK: - Profile Section
    private var profileSection: some View {
        SettingsSection(title: L10n.Settings.profile.localized) {
            Button {
                showProfileView = true
            } label: {
                NapletCard {
                    HStack(spacing: NapletSpacing.md) {
                        // Avatar com foto
                        UserAvatarView(
                            profile: viewModel.user,
                            size: .large,
                            showBorder: true
                        )

                        VStack(alignment: .leading, spacing: NapletSpacing.xs) {
                            Text(viewModel.user?.displayName ?? "User")
                                .font(NapletTypography.headline())
                                .foregroundColor(NapletColors.textPrimary)

                            Text(viewModel.user?.email ?? "")
                                .font(NapletTypography.subheadline())
                                .foregroundColor(NapletColors.textSecondary)

                            Text(subscriptionStatusDisplayName)
                                .font(NapletTypography.caption(weight: .medium))
                                .foregroundColor(NapletColors.primaryPurple)
                        }

                        Spacer()

                        NapletIcon("chevron.right", size: .small, color: NapletColors.textMuted)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Baby Section
    private var babySection: some View {
        SettingsSection(title: L10n.Settings.baby.localized) {
            VStack(spacing: NapletSpacing.sm) {
                ForEach(viewModel.babies) { baby in
                    babyRow(baby)
                }

                // Add Baby Button
                Button {
                    viewModel.showAddBaby = true
                } label: {
                    NapletCard {
                        HStack {
                            NapletIcon("plus.circle.fill", color: NapletColors.primaryPurple)
                            Text(L10n.Settings.addBaby.localized)
                                .font(NapletTypography.body())
                                .foregroundColor(NapletColors.primaryPurple)
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private func babyRow(_ baby: Baby) -> some View {
        HStack(spacing: NapletSpacing.md) {
            // Baby photo or initial
            if let photoURL = baby.photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        babyInitialCircle(baby)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(NapletColors.primaryPurple.opacity(0.3), lineWidth: 2)
                            )
                    case .failure:
                        babyInitialCircle(baby)
                    @unknown default:
                        babyInitialCircle(baby)
                    }
                }
            } else {
                babyInitialCircle(baby)
            }

            VStack(alignment: .leading, spacing: NapletSpacing.xs) {
                Text(baby.name)
                    .font(NapletTypography.headline())
                    .foregroundColor(NapletColors.textPrimary)

                Text(baby.ageDescription)
                    .font(NapletTypography.caption())
                    .foregroundColor(NapletColors.textSecondary)
            }

            Spacer()

            // Edit button
            Button {
                babyToEdit = baby
            } label: {
                NapletIcon("chevron.right", size: .small, color: NapletColors.textMuted)
            }
        }
        .padding(NapletSpacing.md)
        .background(NapletColors.backgroundSecondary)
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectBaby(baby)
        }
        .contextMenu {
            Button {
                babyToEdit = baby
            } label: {
                Label("common.edit".localized, systemImage: "pencil")
            }

            Button(role: .destructive) {
                babyToDelete = baby
                showDeleteBabyAlert = true
            } label: {
                Label("settings.deleteBaby".localized, systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                babyToDelete = baby
                showDeleteBabyAlert = true
            } label: {
                Label("settings.deleteBaby".localized, systemImage: "trash")
            }

            Button {
                babyToEdit = baby
            } label: {
                Label("common.edit".localized, systemImage: "pencil")
            }
            .tint(NapletColors.primaryPurple)
        }
        .alert("settings.deleteBaby.title".localized, isPresented: $showDeleteBabyAlert) {
            Button(L10n.Common.cancel.localized, role: .cancel) {
                babyToDelete = nil
            }
            Button("settings.deleteBaby.confirm".localized, role: .destructive) {
                if let baby = babyToDelete {
                    Task {
                        await viewModel.deleteBabyFromSupabase(baby)
                    }
                }
                babyToDelete = nil
            }
        } message: {
            Text("settings.deleteBaby.message".localized)
        }
        .sheet(item: $babyToEdit) { baby in
            EditBabyProfileView(baby: baby) {
                // On delete callback
                viewModel.loadData()
            }
            .presentationBackground(NapletColors.background)
        }
    }

    // MARK: - Baby Initial Circle
    private func babyInitialCircle(_ baby: Baby) -> some View {
        Circle()
            .fill(NapletColors.backgroundTertiary)
            .frame(width: 44, height: 44)
            .overlay(
                Text(baby.initial)
                    .font(NapletTypography.headline())
                    .foregroundColor(NapletColors.textPrimary)
            )
    }

    // MARK: - Caregivers Section
    private var caregiversSection: some View {
        SettingsSection(title: L10n.Settings.caregivers.localized) {
            VStack(spacing: NapletSpacing.sm) {
                // Manage Caregivers
                Button {
                    showCaregiversView = true
                } label: {
                    NapletCard {
                        HStack {
                            NapletIcon("person.2.fill", size: .medium, color: NapletColors.primaryPurple)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.Caregivers.title.localized)
                                    .font(NapletTypography.body())
                                    .foregroundColor(NapletColors.textPrimary)

                                Text("settings.caregivers.subtitle".localized)
                                    .font(NapletTypography.caption())
                                    .foregroundColor(NapletColors.textMuted)
                            }

                            Spacer()

                            NapletIcon("chevron.right", size: .small, color: NapletColors.textMuted)
                        }
                    }
                }

                // Accept Invite
                Button {
                    showAcceptInviteView = true
                } label: {
                    NapletCard {
                        HStack {
                            NapletIcon("envelope.open.fill", size: .medium, color: NapletColors.primaryPink)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.Settings.acceptInvite.localized)
                                    .font(NapletTypography.body())
                                    .foregroundColor(NapletColors.textPrimary)

                                Text("settings.acceptInvite.subtitle".localized)
                                    .font(NapletTypography.caption())
                                    .foregroundColor(NapletColors.textMuted)
                            }

                            Spacer()

                            NapletIcon("chevron.right", size: .small, color: NapletColors.textMuted)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showCaregiversView) {
            if let baby = selectedBaby {
                CaregiversView(baby: baby)
                    .presentationBackground(NapletColors.background)
            } else {
                // Fallback when no baby is selected
                VStack(spacing: NapletSpacing.lg) {
                    // Drag Indicator
                    Capsule()
                        .fill(NapletColors.textMuted.opacity(0.3))
                        .frame(width: 36, height: 5)
                        .padding(.top, NapletSpacing.sm)

                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(NapletColors.textMuted)

                    Text("settings.noBabySelected".localized)
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    Text("settings.addBabyFirst".localized)
                        .font(NapletTypography.body())
                        .foregroundColor(NapletColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(NapletColors.background)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(24)
            }
        }
        .sheet(isPresented: $showAcceptInviteView) {
            AcceptInviteView()
                .presentationBackground(NapletColors.background)
        }
    }

    // MARK: - Preferences Section
    private var preferencesSection: some View {
        SettingsSection(title: L10n.Settings.preferences.localized) {
            VStack(spacing: NapletSpacing.sm) {
                // Sleep Schedule Settings
                if let baby = selectedBaby {
                    Button {
                        viewModel.selectedBabyForSleepSchedule = baby
                    } label: {
                        NapletCard {
                            HStack {
                                NapletIcon("clock.badge.checkmark.fill", size: .medium, color: NapletColors.primaryCyan)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("settings.sleepSchedule".localized)
                                        .font(NapletTypography.body())
                                        .foregroundColor(NapletColors.textPrimary)

                                    Text("settings.sleepSchedule.subtitle".localized)
                                        .font(NapletTypography.caption())
                                        .foregroundColor(NapletColors.textMuted)
                                }

                                Spacer()

                                NapletIcon("chevron.right", size: .small, color: NapletColors.textMuted)
                            }
                        }
                    }
                    .sheet(item: $viewModel.selectedBabyForSleepSchedule) { baby in
                        SleepScheduleSettingsView(baby: baby) { newPreferences in
                            Task {
                                await viewModel.updateBabySleepPreferences(baby, preferences: newPreferences)
                            }
                        }
                        .presentationBackground(NapletColors.background)
                    }
                }

                // Language Selector
                Button {
                    showLanguagePicker = true
                } label: {
                    NapletCard {
                        HStack {
                            NapletIcon("globe", size: .medium, color: NapletColors.primaryPurple)

                            Text("settings.language".localized)
                                .font(NapletTypography.body())
                                .foregroundColor(NapletColors.textPrimary)

                            Spacer()

                            HStack(spacing: 4) {
                                Text(localizationManager.currentLanguageFlag)
                                Text(localizationManager.currentLanguageDisplay)
                                    .font(NapletTypography.subheadline())
                                    .foregroundColor(NapletColors.textSecondary)
                            }

                            NapletIcon("chevron.right", size: .small, color: NapletColors.textMuted)
                        }
                    }
                }
                .sheet(isPresented: $showLanguagePicker) {
                    LanguageSelectionSheet()
                        .presentationBackground(NapletColors.background)
                }

                SettingsToggleRow(
                    icon: "hand.tap.fill",
                    title: L10n.Settings.hapticFeedback.localized,
                    isOn: $viewModel.hapticFeedbackEnabled
                )

                SettingsToggleRow(
                    icon: "clock",
                    title: L10n.Settings.use24Hour.localized,
                    isOn: $viewModel.use24HourFormat
                )

                SettingsToggleRow(
                    icon: "timer",
                    title: L10n.Settings.showWakeWindows.localized,
                    isOn: $viewModel.showWakeWindows
                )
            }
        }
    }

    // MARK: - Notifications Section
    private var notificationsSection: some View {
        SettingsSection(title: L10n.Settings.notifications.localized) {
            VStack(spacing: NapletSpacing.sm) {
                SettingsToggleRow(
                    icon: "bell.fill",
                    title: L10n.Settings.notifications.localized,
                    isOn: $viewModel.notificationsEnabled
                )

                Button {
                    showNotificationSettings = true
                } label: {
                    NapletCard {
                        HStack {
                            NapletIcon("bell.badge.fill", size: .medium, color: NapletColors.primaryPurple)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("settings.notificationSettings".localized)
                                    .font(NapletTypography.body())
                                    .foregroundColor(NapletColors.textPrimary)

                                Text("settings.notifications.subtitle".localized)
                                    .font(NapletTypography.caption())
                                    .foregroundColor(NapletColors.textMuted)
                            }

                            Spacer()

                            NapletIcon("chevron.right", size: .small, color: NapletColors.textMuted)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showNotificationSettings) {
            NavigationStack {
                NotificationSettingsView(baby: selectedBaby)
            }
            .presentationBackground(NapletColors.background)
        }
    }

    // MARK: - Helper
    private var selectedBaby: Baby? {
        guard let selectedId = viewModel.selectedBabyId else {
            return viewModel.babies.first
        }
        return viewModel.babies.first { $0.id == selectedId }
    }

    /// Retorna o nome do status da assinatura, priorizando SubscriptionManager (que verifica desenvolvedor)
    private var subscriptionStatusDisplayName: String {
        if subscriptionManager.isPremium {
            return "subscription.tier.premium".localized
        } else if subscriptionManager.isTrial {
            return "subscription.tier.trial".localized
        } else {
            return "subscription.tier.free".localized
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        SettingsSection(title: L10n.Settings.about.localized) {
            VStack(spacing: NapletSpacing.sm) {
                // Support / Help
                SettingsNavigationRow(
                    icon: "questionmark.circle.fill",
                    title: "support.title".localized
                ) {
                    showSupportView = true
                }

                SettingsNavigationRow(
                    icon: "doc.text.fill",
                    title: L10n.Settings.privacyPolicy.localized
                ) {
                    showPrivacyPolicy = true
                }

                SettingsNavigationRow(
                    icon: "doc.plaintext.fill",
                    title: L10n.Settings.termsOfService.localized
                ) {
                    showTermsOfService = true
                }

                SettingsInfoRow(
                    icon: "info.circle.fill",
                    title: L10n.Settings.version.localized,
                    value: "\(Constants.App.version) (\(Constants.App.build))"
                )

                #if DEBUG
                SettingsNavigationRow(
                    icon: "arrow.counterclockwise",
                    title: "settings.resetOnboarding".localized
                ) {
                    UserDefaults.standard.set(false, forKey: Constants.StorageKeys.hasCompletedOnboarding)
                    UserDefaults.standard.removeObject(forKey: "currentBaby")
                    UserDefaults.standard.removeObject(forKey: "selectedSleepGoals")
                }
                #endif
            }
        }
        .sheet(isPresented: $showSupportView) {
            SupportView()
                .presentationBackground(NapletColors.background)
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
                .presentationBackground(NapletColors.background)
        }
        .sheet(isPresented: $showTermsOfService) {
            TermsOfServiceView()
                .presentationBackground(NapletColors.background)
        }
        .sheet(isPresented: $showProfileView, onDismiss: {
            // Recarrega o perfil quando fechar
            viewModel.loadData()
        }) {
            ProfileView()
                .presentationBackground(NapletColors.background)
        }
        .sheet(isPresented: $viewModel.showAddBaby, onDismiss: {
            // Recarrega os bebês quando fechar
            viewModel.loadData()
        }) {
            AddBabyView()
                .presentationBackground(NapletColors.background)
        }
    }

    // MARK: - Logout Button
    private var logoutButton: some View {
        VStack(spacing: NapletSpacing.sm) {
            if let error = viewModel.signOutError {
                Text(error)
                    .font(NapletTypography.footnote())
                    .foregroundColor(NapletColors.error)
                    .multilineTextAlignment(.center)
            }

            NapletButton(
                L10n.Settings.signOut.localized,
                style: .destructive,
                isLoading: viewModel.isSigningOut,
                isFullWidth: true
            ) {
                viewModel.signOut()
            }
        }
        .padding(.top, NapletSpacing.lg)
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            Text(title)
                .font(NapletTypography.caption(weight: .semibold))
                .foregroundColor(NapletColors.textSecondary)
                .textCase(.uppercase)

            content()
        }
    }
}

// MARK: - Settings Rows
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        NapletCard {
            HStack {
                NapletIcon(icon, size: .medium, color: NapletColors.primaryPurple)

                Text(title)
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textPrimary)

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(NapletColors.primaryPurple)
            }
        }
    }
}

struct SettingsNavigationRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            NapletCard {
                HStack {
                    NapletIcon(icon, size: .medium, color: NapletColors.primaryPurple)

                    Text(title)
                        .font(NapletTypography.body())
                        .foregroundColor(NapletColors.textPrimary)

                    Spacer()

                    NapletIcon("chevron.right", size: .small, color: NapletColors.textMuted)
                }
            }
        }
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        NapletCard {
            HStack {
                NapletIcon(icon, size: .medium, color: NapletColors.primaryPurple)

                Text(title)
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textPrimary)

                Spacer()

                Text(value)
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textSecondary)
            }
        }
    }
}

// MARK: - Language Selection Sheet (Real-time)
struct LanguageSelectionSheet: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            NapletColors.background
                .ignoresSafeArea()

            VStack(spacing: NapletSpacing.lg) {
                // Drag Indicator
                Capsule()
                    .fill(NapletColors.textMuted.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, NapletSpacing.sm)

                // Header
                VStack(spacing: NapletSpacing.sm) {
                    Image(systemName: "globe")
                        .font(.system(size: 50))
                        .foregroundStyle(NapletColors.gradientPrimary)

                    Text("language.title".localized)
                        .font(NapletTypography.title2())
                        .foregroundColor(NapletColors.textPrimary)

                    Text("language.subtitle".localized)
                        .font(NapletTypography.subheadline())
                        .foregroundColor(NapletColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Language Options
                VStack(spacing: NapletSpacing.sm) {
                    ForEach(AppLanguage.allCases) { language in
                        LanguageOptionRow(
                            language: language,
                            isSelected: localizationManager.selectedLanguage == language
                        ) {
                            #if DEBUG
                            print("[LanguageSheet] User selected: \(language.rawValue)")
                            print("[LanguageSheet] Bundle path before: \(Bundle.main.path(forResource: language.languageCode, ofType: "lproj") ?? "NOT FOUND")")
                            #endif

                            // Muda idioma em tempo real!
                            withAnimation(.easeInOut(duration: 0.2)) {
                                localizationManager.selectedLanguage = language
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }

                            #if DEBUG
                            print("[LanguageSheet] After setting: selectedLanguage = \(localizationManager.selectedLanguage.rawValue)")
                            #endif
                        }
                    }
                }
                .padding(.horizontal, NapletSpacing.md)

                Spacer()

                // Note - No restart needed!
                Text("language.autoApply".localized)
                    .font(NapletTypography.caption())
                    .foregroundColor(NapletColors.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, NapletSpacing.lg)
                    .padding(.bottom, NapletSpacing.lg)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
        .id(localizationManager.refreshID) // Force rebuild when language changes
    }
}

// MARK: - Language Option Row
struct LanguageOptionRow: View {
    let language: AppLanguage
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            NapletCard {
                HStack(spacing: NapletSpacing.md) {
                    // Flag/Icon
                    Text(language.flag)
                        .font(.title2)

                    // Language name
                    Text(language.displayName)
                        .font(NapletTypography.body())
                        .foregroundColor(NapletColors.textPrimary)

                    Spacer()

                    // Checkmark if selected
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(NapletColors.success)
                            .font(.system(size: 22))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? NapletColors.primaryPurple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}
