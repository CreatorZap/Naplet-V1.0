import SwiftUI

// MARK: - Naplet Text Field
/// Campo de texto estilizado com fundo backgroundTertiary, borda que muda para primaryPurple no focus
struct NapletTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var icon: String? = nil
    var errorMessage: String? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.xs) {
            HStack(spacing: NapletSpacing.sm) {
                // Leading icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(isFocused ? NapletColors.primaryPurple : NapletColors.textMuted)
                        .frame(width: 24)
                }

                // Text field
                Group {
                    if isSecure {
                        SecureField("", text: $text)
                            .placeholder(when: text.isEmpty) {
                                Text(placeholder)
                                    .foregroundColor(NapletColors.textMuted)
                            }
                    } else {
                        TextField("", text: $text)
                            .placeholder(when: text.isEmpty) {
                                Text(placeholder)
                                    .foregroundColor(NapletColors.textMuted)
                            }
                    }
                }
                .keyboardType(keyboardType)
                .font(NapletTypography.body())
                .foregroundColor(NapletColors.textPrimary)
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

                // Clear button
                if !text.isEmpty && isFocused {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(NapletColors.textMuted)
                    }
                }
            }
            .padding(.horizontal, NapletSpacing.md)
            .frame(height: 52)
            .background(NapletColors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)

            // Error message
            if let errorMessage = errorMessage {
                HStack(spacing: NapletSpacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(errorMessage)
                        .font(NapletTypography.caption())
                }
                .foregroundColor(NapletColors.error)
            }
        }
    }

    private var borderColor: Color {
        if errorMessage != nil {
            return NapletColors.error
        } else if isFocused {
            return NapletColors.primaryPurple
        } else {
            return NapletColors.backgroundTertiary
        }
    }
}

// MARK: - Placeholder View Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Naplet Text Area
/// Campo de texto multi-linha
struct NapletTextArea: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 100
    var maxHeight: CGFloat = 200

    @FocusState private var isFocused: Bool

    var body: some View {
        TextEditor(text: $text)
            .font(NapletTypography.body())
            .foregroundColor(NapletColors.textPrimary)
            .focused($isFocused)
            .scrollContentBackground(.hidden)
            .padding(NapletSpacing.sm)
            .frame(minHeight: minHeight, maxHeight: maxHeight)
            .background(NapletColors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? NapletColors.primaryPurple : NapletColors.backgroundTertiary, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(NapletTypography.body())
                        .foregroundColor(NapletColors.textMuted)
                        .padding(.horizontal, NapletSpacing.sm + 5)
                        .padding(.vertical, NapletSpacing.sm + 8)
                        .allowsHitTesting(false)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Naplet Search Field
/// Campo de busca estilizado
struct NapletSearchField: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    var onSubmit: (() -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: NapletSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(NapletColors.textMuted)

            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(NapletColors.textMuted)
                }
                .font(NapletTypography.body())
                .foregroundColor(NapletColors.textPrimary)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit {
                    onSubmit?()
                }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(NapletColors.textMuted)
                }
            }
        }
        .padding(.horizontal, NapletSpacing.md)
        .frame(height: 44)
        .background(NapletColors.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

// MARK: - Preview
#Preview("Text Fields") {
    struct PreviewWrapper: View {
        @State private var email = ""
        @State private var password = ""
        @State private var name = "John Doe"
        @State private var notes = ""
        @State private var search = ""
        @State private var errorEmail = ""

        var body: some View {
            ZStack {
                NapletColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: NapletSpacing.lg) {
                        // Basic Text Field
                        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                            Text("Basic Text Field")
                                .font(NapletTypography.headline())
                                .foregroundColor(NapletColors.textPrimary)

                            NapletTextField(
                                placeholder: "Enter your email",
                                text: $email,
                                keyboardType: .emailAddress,
                                icon: "envelope"
                            )
                        }

                        // Secure Field
                        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                            Text("Secure Field")
                                .font(NapletTypography.headline())
                                .foregroundColor(NapletColors.textPrimary)

                            NapletTextField(
                                placeholder: "Enter password",
                                text: $password,
                                isSecure: true,
                                icon: "lock"
                            )
                        }

                        // With Error
                        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                            Text("With Error")
                                .font(NapletTypography.headline())
                                .foregroundColor(NapletColors.textPrimary)

                            NapletTextField(
                                placeholder: "Enter email",
                                text: $errorEmail,
                                keyboardType: .emailAddress,
                                icon: "envelope",
                                errorMessage: "Please enter a valid email address"
                            )
                        }

                        // Filled State
                        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                            Text("Filled State")
                                .font(NapletTypography.headline())
                                .foregroundColor(NapletColors.textPrimary)

                            NapletTextField(
                                placeholder: "Your name",
                                text: $name,
                                icon: "person"
                            )
                        }

                        // Search Field
                        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                            Text("Search Field")
                                .font(NapletTypography.headline())
                                .foregroundColor(NapletColors.textPrimary)

                            NapletSearchField(text: $search, placeholder: "Search babies...")
                        }

                        // Text Area
                        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                            Text("Text Area")
                                .font(NapletTypography.headline())
                                .foregroundColor(NapletColors.textPrimary)

                            NapletTextArea(
                                placeholder: "Add notes about the sleep session...",
                                text: $notes
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }

    return PreviewWrapper()
}
