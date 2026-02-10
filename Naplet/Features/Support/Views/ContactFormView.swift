import SwiftUI

// MARK: - Contact Form View
struct ContactFormView: View {
    @StateObject private var viewModel = ContactFormViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    enum Field {
        case name, email, subject, message
    }

    var body: some View {
        ScrollView {
            VStack(spacing: NapletSpacing.lg) {
                // Drag Indicator
                Capsule()
                    .fill(NapletColors.textMuted.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, NapletSpacing.sm)

                // Header
                headerSection

                // Formulario
                formSection

                // Info de debug
                debugInfoSection

                // Botao de enviar
                submitButton
            }
            .padding(.horizontal, NapletSpacing.md)
            .padding(.bottom, NapletSpacing.lg)
        }
        .background(NapletColors.background)
        .alert("support.contact.success.title".localized, isPresented: $viewModel.showSuccessAlert) {
            Button(L10n.Common.ok.localized) {
                dismiss()
            }
        } message: {
            Text("support.contact.success.message".localized)
        }
        .alert(L10n.Error.generic.localized, isPresented: $viewModel.showErrorAlert) {
            Button(L10n.Common.ok.localized) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: NapletSpacing.sm) {
            Image(systemName: "envelope.open.fill")
                .font(.system(size: 48))
                .foregroundStyle(NapletColors.gradientPrimary)

            Text("support.contact.title".localized)
                .font(NapletTypography.title2())
                .fontWeight(.bold)
                .foregroundColor(NapletColors.textPrimary)

            Text("support.contact.subtitle".localized)
                .font(NapletTypography.subheadline())
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, NapletSpacing.md)
    }

    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: NapletSpacing.md) {
            // Nome
            FormFieldView(
                title: "support.contact.name".localized,
                placeholder: "support.contact.name.placeholder".localized,
                text: $viewModel.name,
                isRequired: false
            )
            .focused($focusedField, equals: .name)

            // Email
            FormFieldView(
                title: "support.contact.email".localized,
                placeholder: "support.contact.email.placeholder".localized,
                text: $viewModel.email,
                keyboardType: .emailAddress,
                isRequired: true
            )
            .focused($focusedField, equals: .email)

            // Categoria
            categoryPicker

            // Assunto
            FormFieldView(
                title: "support.contact.subject".localized,
                placeholder: "support.contact.subject.placeholder".localized,
                text: $viewModel.subject,
                isRequired: true
            )
            .focused($focusedField, equals: .subject)

            // Mensagem
            messageField
        }
    }

    // MARK: - Category Picker
    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.xs) {
            Text("support.contact.category".localized)
                .font(NapletTypography.caption())
                .fontWeight(.semibold)
                .foregroundColor(NapletColors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NapletSpacing.xs) {
                    ForEach(TicketCategory.allCases) { category in
                        CategoryChip(
                            title: category.localizedName,
                            icon: category.icon,
                            isSelected: viewModel.selectedCategory == category
                        ) {
                            viewModel.selectedCategory = category
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Message Field
    private var messageField: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.xs) {
            HStack {
                Text("support.contact.message".localized)
                    .font(NapletTypography.caption())
                    .fontWeight(.semibold)
                    .foregroundColor(NapletColors.textSecondary)

                Text("*")
                    .foregroundColor(.red)
            }

            TextEditor(text: $viewModel.message)
                .frame(minHeight: 120)
                .padding(NapletSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(NapletColors.backgroundSecondary)
                )
                .focused($focusedField, equals: .message)
                .scrollContentBackground(.hidden)
                .foregroundColor(NapletColors.textPrimary)

            Text("support.contact.message.hint".localized)
                .font(NapletTypography.caption())
                .foregroundColor(NapletColors.textMuted)
        }
    }

    // MARK: - Debug Info Section
    private var debugInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("support.contact.debugInfo".localized)
                .font(NapletTypography.caption())
                .foregroundColor(NapletColors.textSecondary)

            Text("App: \(viewModel.appVersion) | \(viewModel.deviceInfo)")
                .font(NapletTypography.caption())
                .foregroundColor(NapletColors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: {
            viewModel.submitTicket()
        }) {
            HStack {
                if viewModel.isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("support.contact.send".localized)
                }
            }
            .font(NapletTypography.headline())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NapletSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.isFormValid ? NapletColors.primaryPurple : NapletColors.textMuted)
            )
        }
        .disabled(!viewModel.isFormValid || viewModel.isSubmitting)
    }
}

// MARK: - Form Field View
struct FormFieldView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isRequired: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.xs) {
            HStack(spacing: 4) {
                Text(title)
                    .font(NapletTypography.caption())
                    .fontWeight(.semibold)
                    .foregroundColor(NapletColors.textSecondary)

                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                }
            }

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .sentences)
                .padding(NapletSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(NapletColors.backgroundSecondary)
                )
                .foregroundColor(NapletColors.textPrimary)
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)

                Text(title)
                    .font(NapletTypography.caption())
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : NapletColors.textSecondary)
            .padding(.horizontal, NapletSpacing.sm)
            .padding(.vertical, NapletSpacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? NapletColors.primaryPurple : NapletColors.backgroundSecondary)
            )
        }
    }
}

// MARK: - Preview
#Preview {
    ContactFormView()
}
