import SwiftUI

// MARK: - Rating Prompt View
/// Prompt inteligente que pergunta se o usuário está gostando do app
struct RatingPromptView: View {
    @ObservedObject var ratingManager = RatingManager.shared
    @State private var showFeedbackForm = false
    @State private var feedbackText = ""

    var body: some View {
        VStack(spacing: NapletSpacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(NapletColors.success.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(NapletColors.success)
            }

            // Title
            Text("rating.prompt.title".localized)
                .font(NapletTypography.title2())
                .foregroundColor(NapletColors.textPrimary)
                .multilineTextAlignment(.center)

            // Subtitle
            Text("rating.prompt.subtitle".localized)
                .font(NapletTypography.body())
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)

            // Buttons
            HStack(spacing: NapletSpacing.md) {
                // Pode melhorar
                Button(action: {
                    showFeedbackForm = true
                }) {
                    Text("rating.prompt.no".localized)
                        .font(NapletTypography.body(weight: .medium))
                        .foregroundColor(NapletColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, NapletSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(NapletColors.textMuted.opacity(0.3), lineWidth: 1)
                        )
                }

                // Sim, muito!
                Button(action: {
                    ratingManager.userLovesApp()
                }) {
                    Text("rating.prompt.yes".localized)
                        .font(NapletTypography.body(weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, NapletSpacing.md)
                        .background(NapletColors.gradientPrimary)
                        .cornerRadius(12)
                }
            }
        }
        .padding(NapletSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(NapletColors.backgroundSecondary)
        )
        .padding(.horizontal, NapletSpacing.xl)
        .sheet(isPresented: $showFeedbackForm) {
            FeedbackFormView(feedbackText: $feedbackText) {
                ratingManager.userNeedsImprovement()
            }
        }
    }
}

// MARK: - Feedback Form View
/// Formulário para coletar feedback quando usuário indica que pode melhorar
struct FeedbackFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var feedbackText: String
    var onSubmit: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                NapletColors.background
                    .ignoresSafeArea()

                VStack(spacing: NapletSpacing.lg) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(NapletColors.primaryPurple.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 36))
                            .foregroundColor(NapletColors.primaryPurple)
                    }

                    // Title
                    Text("rating.feedback.title".localized)
                        .font(NapletTypography.title2())
                        .foregroundColor(NapletColors.textPrimary)

                    // Subtitle
                    Text("rating.feedback.subtitle".localized)
                        .font(NapletTypography.body())
                        .foregroundColor(NapletColors.textSecondary)
                        .multilineTextAlignment(.center)

                    // Text Editor
                    ZStack(alignment: .topLeading) {
                        if feedbackText.isEmpty {
                            Text("rating.feedback.placeholder".localized)
                                .font(NapletTypography.body())
                                .foregroundColor(NapletColors.textMuted)
                                .padding(.horizontal, NapletSpacing.md)
                                .padding(.vertical, NapletSpacing.md + 8)
                        }

                        TextEditor(text: $feedbackText)
                            .font(NapletTypography.body())
                            .foregroundColor(NapletColors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .padding(NapletSpacing.sm)
                    }
                    .frame(minHeight: 150)
                    .background(NapletColors.backgroundTertiary)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(NapletColors.textMuted.opacity(0.2), lineWidth: 1)
                    )

                    // Send Button
                    NapletButton(
                        "rating.feedback.send".localized,
                        style: .primary,
                        isFullWidth: true
                    ) {
                        // TODO: Enviar feedback para analytics/email
                        Logger.info("Feedback submitted: \(feedbackText)")
                        onSubmit()
                        dismiss()
                    }
                    .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Spacer()
                }
                .padding(NapletSpacing.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(NapletColors.textMuted)
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        NapletColors.background
            .ignoresSafeArea()

        RatingPromptView()
    }
}

#Preview("Feedback Form") {
    FeedbackFormView(feedbackText: .constant("")) {
        #if DEBUG
        print("Submitted")
        #endif
    }
}
