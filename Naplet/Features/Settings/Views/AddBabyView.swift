import SwiftUI

// MARK: - Add Baby View
struct AddBabyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var name: String = ""
    @State private var birthDate: Date = Date()
    @State private var gender: Baby.Gender?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NapletSpacing.xl) {
                    // Header
                    headerView

                    // Form
                    formView

                    // Error Message
                    if let error = errorMessage {
                        HStack(spacing: NapletSpacing.xs) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 14))
                            Text(error)
                                .font(.system(size: NapletTypography.footnote))
                        }
                        .foregroundColor(NapletColors.error)
                        .padding(.horizontal, NapletSpacing.md)
                        .padding(.vertical, NapletSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(NapletColors.error.opacity(0.1))
                        )
                    }

                    // Save Button
                    saveButton
                }
                .padding(.horizontal, NapletSpacing.lg)
                .padding(.vertical, NapletSpacing.xl)
            }
            .background(NapletColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        HapticManager.shared.lightImpact()
                        dismiss()
                    }
                    .foregroundColor(NapletColors.primaryPurple)
                }
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: NapletSpacing.md) {
            ZStack {
                Circle()
                    .fill(NapletColors.primaryPurple.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(NapletColors.primaryPurple)
            }

            Text("settings.addBaby".localized)
                .font(NapletTypography.title2())
                .foregroundColor(NapletColors.textPrimary)

            Text("settings.addBaby.subtitle".localized)
                .font(NapletTypography.body())
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Form
    private var formView: some View {
        VStack(spacing: NapletSpacing.lg) {
            // Baby Name
            VStack(alignment: .leading, spacing: NapletSpacing.xs) {
                Text("onboarding.babyName.label".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)

                HStack(spacing: NapletSpacing.sm) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundColor(NapletColors.textMuted)
                        .frame(width: 24)

                    TextField("onboarding.babyName.placeholder".localized, text: $name)
                        .font(.system(size: NapletTypography.body))
                        .foregroundColor(NapletColors.textPrimary)
                }
                .padding(.horizontal, NapletSpacing.md)
                .padding(.vertical, NapletSpacing.md)
                .background(NapletColors.backgroundCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(NapletColors.textMuted.opacity(0.2), lineWidth: 1)
                )
            }

            // Birth Date
            VStack(alignment: .leading, spacing: NapletSpacing.xs) {
                Text("onboarding.babyBirth.label".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)

                DatePicker(
                    "",
                    selection: $birthDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .padding(.vertical, NapletSpacing.sm)
                .background(NapletColors.backgroundCard)
                .cornerRadius(12)
            }

            // Gender Selection
            VStack(alignment: .leading, spacing: NapletSpacing.xs) {
                Text("onboarding.babyGender.label".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)

                HStack(spacing: NapletSpacing.md) {
                    genderButton(.male, icon: "figure.stand", label: "onboarding.gender.boy".localized)
                    genderButton(.female, icon: "figure.stand.dress", label: "onboarding.gender.girl".localized)
                }
            }
        }
    }

    private func genderButton(_ genderValue: Baby.Gender, icon: String, label: String) -> some View {
        Button {
            HapticManager.shared.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                gender = genderValue
            }
        } label: {
            VStack(spacing: NapletSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                Text(label)
                    .font(NapletTypography.body(weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NapletSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(gender == genderValue ? NapletColors.primaryPurple.opacity(0.15) : NapletColors.backgroundCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(gender == genderValue ? NapletColors.primaryPurple : NapletColors.textMuted.opacity(0.2), lineWidth: gender == genderValue ? 2 : 1)
            )
            .foregroundColor(gender == genderValue ? NapletColors.primaryPurple : NapletColors.textSecondary)
        }
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            HapticManager.shared.lightImpact()
            Task {
                await saveBaby()
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Text("common.save".localized)
                        .font(.system(size: NapletTypography.body, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(isValid && !isLoading ? NapletColors.gradientPrimary : LinearGradient(colors: [NapletColors.textMuted], startPoint: .leading, endPoint: .trailing))
            .foregroundColor(.white)
            .cornerRadius(14)
            .shadow(color: isValid ? NapletColors.primaryPurple.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
        }
        .disabled(!isValid || isLoading)
        .padding(.top, NapletSpacing.md)
    }

    // MARK: - Save Baby
    private func saveBaby() async {
        guard isValid else {
            errorMessage = "baby.error.enterName".localized
            HapticManager.shared.error()
            return
        }

        guard let userId = SupabaseService.shared.currentUser?.id else {
            errorMessage = "error.userNotAuthenticated".localized
            HapticManager.shared.error()
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let baby = Baby(
                name: name.trimmingCharacters(in: .whitespaces),
                birthDate: birthDate,
                gender: gender,
                ownerId: userId
            )

            // Salvar no Supabase
            try await SupabaseService.shared.client
                .from("babies")
                .insert(baby)
                .execute()

            Logger.info("Baby created: \(baby.name)")
            HapticManager.shared.success()

            // Atualizar estado do app
            await appState.refreshAfterLogin()

            dismiss()

        } catch {
            Logger.error(error, context: "Failed to create baby")
            errorMessage = "baby.error.saveFailed".localized
            HapticManager.shared.error()
        }

        isLoading = false
    }
}

#Preview {
    AddBabyView()
        .environmentObject(AppState())
}
