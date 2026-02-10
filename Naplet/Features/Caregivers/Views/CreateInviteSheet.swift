import SwiftUI

// MARK: - Create Invite Sheet
struct CreateInviteSheet: View {
    @ObservedObject var viewModel: CaregiverViewModel
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                NapletColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: NapletSpacing.lg) {
                        // Header Illustration
                        headerIllustration

                        // Role Selection
                        roleSelection

                        // Email (Optional)
                        emailField

                        // Create Button
                        createButton

                        // Created Invite Display
                        if let invite = viewModel.createdInvite {
                            createdInviteCard(invite)
                        }
                    }
                    .padding(NapletSpacing.lg)
                }
            }
            .navigationTitle("invite.create.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.Common.cancel.localized) {
                        dismiss()
                    }
                    .foregroundColor(NapletColors.primaryPurple)
                }
            }
            .onAppear {
                // Check premium access for inviting caregivers
                if !subscriptionManager.canInviteCaregivers {
                    showPaywall = true
                }
            }
            .sheet(isPresented: $showPaywall, onDismiss: {
                // Dismiss invite sheet if user didn't subscribe
                if !subscriptionManager.canInviteCaregivers {
                    dismiss()
                }
            }) {
                PaywallView()
            }
        }
    }

    // MARK: - Header Illustration
    private var headerIllustration: some View {
        VStack(spacing: NapletSpacing.md) {
            ZStack {
                Circle()
                    .fill(NapletColors.primaryPurple.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "person.badge.plus")
                    .font(.system(size: 36))
                    .foregroundColor(NapletColors.primaryPurple)
            }

            Text("invite.header.title".localized)
                .font(NapletTypography.headline())
                .foregroundColor(NapletColors.textPrimary)

            Text("invite.header.subtitle".localized)
                .font(NapletTypography.body())
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, NapletSpacing.md)
    }

    // MARK: - Role Selection
    private var roleSelection: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            Text("invite.role.title".localized)
                .font(NapletTypography.caption(weight: .semibold))
                .foregroundColor(NapletColors.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: NapletSpacing.sm) {
                ForEach(availableRoles, id: \.self) { role in
                    RoleSelectionRow(
                        role: role,
                        isSelected: viewModel.selectedRole == role,
                        onSelect: {
                            withAnimation {
                                viewModel.selectedRole = role
                            }
                        }
                    )
                }
            }
        }
    }

    private var availableRoles: [Caregiver.CaregiverRole] {
        // Owner cannot be selected for invites
        Caregiver.CaregiverRole.allCases.filter { $0 != .owner }
    }

    // MARK: - Email Field
    private var emailField: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            Text("invite.email.title".localized)
                .font(NapletTypography.caption(weight: .semibold))
                .foregroundColor(NapletColors.textSecondary)
                .textCase(.uppercase)

            NapletCard {
                TextField("invite.email.placeholder".localized, text: $viewModel.inviteEmail)
                    .font(NapletTypography.body())
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }

            Text("invite.email.hint".localized)
                .font(NapletTypography.caption())
                .foregroundColor(NapletColors.textMuted)
        }
    }

    // MARK: - Create Button
    private var createButton: some View {
        NapletButton(
            "invite.generate".localized,
            style: .primary,
            isLoading: viewModel.isLoading,
            isFullWidth: true
        ) {
            Task {
                await viewModel.createInvite()
            }
        }
        .disabled(viewModel.createdInvite != nil)
    }

    // MARK: - Created Invite Card
    private func createdInviteCard(_ invite: Invite) -> some View {
        VStack(spacing: NapletSpacing.md) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(NapletColors.success)

            Text("invite.success".localized)
                .font(NapletTypography.headline())
                .foregroundColor(NapletColors.textPrimary)

            // Code Display
            NapletCard {
                VStack(spacing: NapletSpacing.sm) {
                    Text("invite.codeLabel".localized)
                        .font(NapletTypography.caption())
                        .foregroundColor(NapletColors.textMuted)

                    Text(invite.inviteCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(NapletColors.primaryPurple)
                        .tracking(4)

                    Text("invite.validity".localized)
                        .font(NapletTypography.caption())
                        .foregroundColor(NapletColors.textSecondary)
                }
                .padding(.vertical, NapletSpacing.sm)
            }

            // Share Button
            Button {
                viewModel.showShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("invite.share".localized)
                }
                .font(NapletTypography.body(weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, NapletSpacing.md)
                .background(NapletColors.primaryPurple)
                .cornerRadius(12)
            }

            // Copy Button
            Button {
                UIPasteboard.general.string = invite.inviteCode
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("invite.copy".localized)
                }
                .font(NapletTypography.body(weight: .medium))
                .foregroundColor(NapletColors.primaryPurple)
            }

            // Done Button
            Button {
                dismiss()
            } label: {
                Text(L10n.Common.done.localized)
                    .font(NapletTypography.body(weight: .medium))
                    .foregroundColor(NapletColors.textSecondary)
            }
            .padding(.top, NapletSpacing.sm)
        }
        .padding(.vertical, NapletSpacing.md)
    }
}

// MARK: - Role Selection Row
struct RoleSelectionRow: View {
    let role: Caregiver.CaregiverRole
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            NapletCard {
                HStack(spacing: NapletSpacing.md) {
                    // Role Icon
                    Image(systemName: role.icon)
                        .font(.system(size: 20))
                        .foregroundColor(role.color)
                        .frame(width: 40, height: 40)
                        .background(role.color.opacity(0.1))
                        .clipShape(Circle())

                    // Role Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(role.displayName)
                            .font(NapletTypography.body(weight: .medium))
                            .foregroundColor(NapletColors.textPrimary)

                        Text(roleDescription(for: role))
                            .font(NapletTypography.caption())
                            .foregroundColor(NapletColors.textSecondary)
                    }

                    Spacer()

                    // Selection Indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? NapletColors.primaryPurple : NapletColors.textMuted)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func roleDescription(for role: Caregiver.CaregiverRole) -> String {
        switch role {
        case .owner:
            return L10n.Caregivers.Role.ownerDesc.localized
        case .parent:
            return L10n.Caregivers.Role.parentDesc.localized
        case .grandparent:
            return L10n.Caregivers.Role.grandparentDesc.localized
        case .nanny:
            return L10n.Caregivers.Role.nannyDesc.localized
        case .other:
            return L10n.Caregivers.Role.otherDesc.localized
        }
    }
}

// MARK: - Preview
#Preview {
    CreateInviteSheet(viewModel: CaregiverViewModel(baby: Baby.preview))
}
