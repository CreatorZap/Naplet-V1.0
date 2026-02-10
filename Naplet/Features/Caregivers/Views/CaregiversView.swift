import SwiftUI

// MARK: - Caregivers View
struct CaregiversView: View {
    @StateObject private var viewModel: CaregiverViewModel
    @Environment(\.dismiss) private var dismiss

    init(baby: Baby) {
        _viewModel = StateObject(wrappedValue: CaregiverViewModel(baby: baby))
    }

    var body: some View {
        ZStack {
            NapletColors.background
                .ignoresSafeArea()

            Group {
                if viewModel.isLoading && viewModel.caregivers.isEmpty {
                    VStack {
                        // Drag Indicator
                        Capsule()
                            .fill(NapletColors.textMuted.opacity(0.3))
                            .frame(width: 36, height: 5)
                            .padding(.top, NapletSpacing.sm)

                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: NapletColors.primaryPurple))
                        Spacer()
                    }
                } else {
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

                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(NapletColors.primaryPurple)
                                }

                                Text(L10n.Caregivers.title.localized)
                                    .font(NapletTypography.title2())
                                    .foregroundColor(NapletColors.textPrimary)

                                if viewModel.canInvite {
                                    Button {
                                        viewModel.resetInviteForm()
                                        viewModel.showCreateInvite = true
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 18))
                                            Text("caregivers.create".localized)
                                                .fontWeight(.semibold)
                                        }
                                        .font(NapletTypography.subheadline())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, NapletSpacing.lg)
                                        .padding(.vertical, NapletSpacing.sm)
                                        .background(NapletColors.primaryPurple)
                                        .cornerRadius(20)
                                    }
                                    .padding(.top, NapletSpacing.xs)
                                }
                            }

                            // Info Card
                            infoCard

                            // Active Caregivers
                            if !viewModel.activeCaregivers.isEmpty {
                                caregiversSection(
                                    title: L10n.Caregivers.active.localized,
                                    caregivers: viewModel.activeCaregivers
                                )
                            }

                            // Pending Invites
                            if !viewModel.pendingInvites.isEmpty {
                                pendingInvitesSection
                            }

                            // Empty State
                            if viewModel.activeCaregivers.isEmpty && viewModel.pendingInvites.isEmpty {
                                emptyState
                            }

                            Spacer(minLength: 100)
                        }
                    }
                }
            }
        }
        .onAppear { }
        .sheet(isPresented: $viewModel.showCreateInvite) {
            CreateInviteSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if viewModel.createdInvite != nil {
                ShareSheet(items: [viewModel.shareMessage])
            }
        }
        .alert(L10n.Common.error.localized, isPresented: $viewModel.showError) {
            Button(L10n.Common.ok.localized, role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "caregivers.error".localized)
        }
        .task {
            await viewModel.loadData()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }

    // MARK: - Info Card
    private var infoCard: some View {
        NapletCard {
            HStack(spacing: NapletSpacing.md) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 24))
                    .foregroundColor(NapletColors.primaryPurple)
                    .frame(width: 40, height: 40)
                    .background(NapletColors.primaryPurple.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("caregivers.shareTitle".localized)
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    Text("caregivers.shareDescription".localized)
                        .font(NapletTypography.caption())
                        .foregroundColor(NapletColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
        }
        .padding(.horizontal, NapletSpacing.lg)
    }

    // MARK: - Caregivers Section
    private func caregiversSection(title: String, caregivers: [Caregiver]) -> some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            Text(title)
                .font(NapletTypography.caption(weight: .semibold))
                .foregroundColor(NapletColors.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, NapletSpacing.lg)

            VStack(spacing: NapletSpacing.sm) {
                ForEach(caregivers) { caregiver in
                    CaregiverRow(
                        caregiver: caregiver,
                        canRemove: viewModel.canRemoveCaregivers && !caregiver.isOwner,
                        onRemove: {
                            Task {
                                await viewModel.removeCaregiver(caregiver)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, NapletSpacing.lg)
        }
    }

    // MARK: - Pending Invites Section
    private var pendingInvitesSection: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            Text(L10n.Caregivers.pending.localized)
                .font(NapletTypography.caption(weight: .semibold))
                .foregroundColor(NapletColors.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, NapletSpacing.lg)

            VStack(spacing: NapletSpacing.sm) {
                ForEach(viewModel.pendingInvites) { invite in
                    InviteRow(
                        invite: invite,
                        onCancel: {
                            Task {
                                await viewModel.cancelInvite(invite)
                            }
                        },
                        onShare: {
                            viewModel.createdInvite = invite
                            viewModel.showShareSheet = true
                        }
                    )
                }
            }
            .padding(.horizontal, NapletSpacing.lg)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: NapletSpacing.md) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(NapletColors.textMuted)

            Text("caregivers.empty.title".localized)
                .font(NapletTypography.headline())
                .foregroundColor(NapletColors.textPrimary)

            Text("caregivers.empty.description".localized)
                .font(NapletTypography.body())
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)

            if viewModel.canInvite {
                Button {
                    viewModel.resetInviteForm()
                    viewModel.showCreateInvite = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("caregivers.create".localized)
                    }
                    .font(NapletTypography.body(weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, NapletSpacing.lg)
                    .padding(.vertical, NapletSpacing.md)
                    .background(NapletColors.primaryPurple)
                    .cornerRadius(12)
                }
                .padding(.top, NapletSpacing.sm)
            }
        }
        .padding(NapletSpacing.xl)
    }
}

// MARK: - Caregiver Row
struct CaregiverRow: View {
    let caregiver: Caregiver
    let canRemove: Bool
    let onRemove: () -> Void

    @State private var showRemoveAlert = false

    var body: some View {
        NapletCard {
            HStack(spacing: NapletSpacing.md) {
                // Role Icon
                Image(systemName: caregiver.role.icon)
                    .font(.system(size: 20))
                    .foregroundColor(caregiver.role.color)
                    .frame(width: 40, height: 40)
                    .background(caregiver.role.color.opacity(0.1))
                    .clipShape(Circle())

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(caregiver.displayName ?? "caregivers.default".localized)
                        .font(NapletTypography.body(weight: .medium))
                        .foregroundColor(NapletColors.textPrimary)

                    Text(caregiver.role.displayName)
                        .font(NapletTypography.caption())
                        .foregroundColor(caregiver.role.color)
                }

                Spacer()

                // Status Badge
                if caregiver.isOwner {
                    Text(L10n.Caregivers.Role.owner.localized)
                        .font(NapletTypography.caption(weight: .medium))
                        .foregroundColor(NapletColors.warning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(NapletColors.warning.opacity(0.1))
                        .cornerRadius(8)
                }

                // Remove Button
                if canRemove {
                    Button {
                        showRemoveAlert = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(NapletColors.error.opacity(0.7))
                    }
                }
            }
        }
        .alert("caregivers.remove.title".localized, isPresented: $showRemoveAlert) {
            Button(L10n.Common.cancel.localized, role: .cancel) {}
            Button("caregivers.remove.button".localized, role: .destructive) {
                onRemove()
            }
        } message: {
            Text("caregivers.remove.confirm".localized(with: caregiver.displayName ?? "caregivers.default".localized))
        }
    }
}

// MARK: - Invite Row
struct InviteRow: View {
    let invite: Invite
    let onCancel: () -> Void
    let onShare: () -> Void

    @State private var showCancelAlert = false

    var body: some View {
        NapletCard {
            VStack(spacing: NapletSpacing.sm) {
                HStack {
                    // Code Display
                    VStack(alignment: .leading, spacing: 2) {
                        Text("invite.codeLabel".localized)
                            .font(NapletTypography.caption())
                            .foregroundColor(NapletColors.textMuted)

                        Text(invite.inviteCode)
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(NapletColors.primaryPurple)
                    }

                    Spacer()

                    // Role Badge
                    HStack(spacing: 4) {
                        Image(systemName: invite.role.icon)
                        Text(invite.role.displayName)
                    }
                    .font(NapletTypography.caption(weight: .medium))
                    .foregroundColor(invite.role.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(invite.role.color.opacity(0.1))
                    .cornerRadius(8)
                }

                Divider()

                HStack {
                    // Expiry Info
                    if let email = invite.email {
                        Label(email, systemImage: "envelope.fill")
                            .font(NapletTypography.caption())
                            .foregroundColor(NapletColors.textSecondary)
                    } else {
                        Label(expiryText, systemImage: "clock.fill")
                            .font(NapletTypography.caption())
                            .foregroundColor(NapletColors.textSecondary)
                    }

                    Spacer()

                    // Actions
                    HStack(spacing: NapletSpacing.sm) {
                        Button {
                            onShare()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundColor(NapletColors.primaryPurple)
                        }

                        Button {
                            showCancelAlert = true
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(NapletColors.error.opacity(0.7))
                        }
                    }
                }
            }
        }
        .alert("invite.cancel.title".localized, isPresented: $showCancelAlert) {
            Button(L10n.Common.back.localized, role: .cancel) {}
            Button("invite.cancel.button".localized, role: .destructive) {
                onCancel()
            }
        } message: {
            Text("invite.cancel.confirm".localized)
        }
    }

    private var expiryText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "Expira \(formatter.localizedString(for: invite.expiresAt, relativeTo: Date()))"
    }
}

// MARK: - Preview
#Preview {
    CaregiversView(baby: Baby.preview)
}
