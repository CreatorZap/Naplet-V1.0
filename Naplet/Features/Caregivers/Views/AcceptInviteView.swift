import SwiftUI

// MARK: - Accept Invite View
struct AcceptInviteView: View {
    @StateObject private var viewModel: AcceptInviteViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCodeFieldFocused: Bool

    init() {
        _viewModel = StateObject(wrappedValue: AcceptInviteViewModel())
    }

    var body: some View {
        ZStack {
            NapletColors.background
                .ignoresSafeArea()

            VStack {
                // Drag Indicator
                Capsule()
                    .fill(NapletColors.textMuted.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, NapletSpacing.sm)

                if viewModel.acceptedSuccessfully {
                    successView
                } else {
                    inputView
                }
            }
        }
        .alert(L10n.Common.error.localized, isPresented: $viewModel.showError) {
            Button(L10n.Common.ok.localized, role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? L10n.Common.error.localized)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }

    // MARK: - Input View
    private var inputView: some View {
        VStack(spacing: NapletSpacing.xl) {
            Spacer()

            // Illustration
            VStack(spacing: NapletSpacing.md) {
                ZStack {
                    Circle()
                        .fill(NapletColors.primaryPurple.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 44))
                        .foregroundColor(NapletColors.primaryPurple)
                }

                Text("invite.accept.enterCode".localized)
                    .font(NapletTypography.title3())
                    .foregroundColor(NapletColors.textPrimary)

                Text("invite.accept.description".localized)
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, NapletSpacing.lg)
            }

            // Code Input
            codeInputField

            // Accept Button
            NapletButton(
                "invite.accept.button".localized,
                style: .primary,
                isLoading: viewModel.isAccepting,
                isFullWidth: true
            ) {
                Task {
                    await viewModel.acceptInvite()
                }
            }
            .disabled(viewModel.inviteCode.count < 8)
            .padding(.horizontal, NapletSpacing.lg)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Code Input Field
    private var codeInputField: some View {
        VStack(spacing: NapletSpacing.sm) {
            TextField("", text: $viewModel.inviteCode)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .tracking(6)
                .textCase(.uppercase)
                .autocapitalization(.allCharacters)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .focused($isCodeFieldFocused)
                .onChange(of: viewModel.inviteCode) { _, newValue in
                    // Limit to 8 characters and uppercase
                    viewModel.inviteCode = String(newValue.uppercased().prefix(8))
                }
                .padding(.vertical, NapletSpacing.lg)
                .padding(.horizontal, NapletSpacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(NapletColors.backgroundSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isCodeFieldFocused ? NapletColors.primaryPurple : Color.clear,
                                    lineWidth: 2
                                )
                        )
                )
                .padding(.horizontal, NapletSpacing.lg)

            // Helper Text
            HStack {
                Text("invite.characters".localized(with: viewModel.inviteCode.count))
                    .font(NapletTypography.caption())
                    .foregroundColor(
                        viewModel.inviteCode.count == 8
                            ? NapletColors.success
                            : NapletColors.textMuted
                    )

                if viewModel.inviteCode.count == 8 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(NapletColors.success)
                }
            }
        }
        .onAppear {
            isCodeFieldFocused = true
        }
    }

    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: NapletSpacing.xl) {
            Spacer()

            // Success Animation
            VStack(spacing: NapletSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(NapletColors.success.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(NapletColors.success)
                }

                Text("invite.accepted".localized)
                    .font(NapletTypography.title2())
                    .foregroundColor(NapletColors.textPrimary)

                Text("invite.accepted.description".localized)
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, NapletSpacing.xl)
            }

            Spacer()

            // Continue Button
            NapletButton(
                L10n.Common.continue.localized,
                style: .primary,
                isFullWidth: true
            ) {
                dismiss()
            }
            .padding(.horizontal, NapletSpacing.lg)
            .padding(.bottom, NapletSpacing.xl)
        }
    }
}

// MARK: - Accept Invite View Model
@MainActor
class AcceptInviteViewModel: ObservableObject {
    @Published var inviteCode = ""
    @Published var isAccepting = false
    @Published var acceptedSuccessfully = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let repository = CaregiverRepository()

    func acceptInvite() async {
        guard inviteCode.count == 8 else {
            errorMessage = "invite.error.length".localized
            showError = true
            return
        }

        isAccepting = true
        errorMessage = nil

        do {
            // Try RPC first
            let response = try await repository.acceptInvite(code: inviteCode)

            if response.success {
                acceptedSuccessfully = true
                NotificationCenter.default.post(name: .caregiverAccepted, object: nil)
                Logger.info("Invite accepted successfully")
            } else {
                errorMessage = response.error ?? "Falha ao aceitar convite"
                showError = true
            }
        } catch {
            // Try manual method as fallback
            do {
                _ = try await repository.acceptInviteManual(code: inviteCode)
                acceptedSuccessfully = true
                NotificationCenter.default.post(name: .caregiverAccepted, object: nil)
                Logger.info("Invite accepted via manual method")
            } catch {
                Logger.error("Failed to accept invite: \(error)")
                errorMessage = error.localizedDescription
                showError = true
            }
        }

        isAccepting = false
    }
}

// MARK: - Preview
#Preview {
    AcceptInviteView()
}
