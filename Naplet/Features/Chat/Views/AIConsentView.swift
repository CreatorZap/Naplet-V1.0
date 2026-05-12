import SwiftUI

// MARK: - AI Consent Manager
//
// Versão atual do consent: 1.
// Incrementar quando os termos mudarem (ex: novo provedor de IA, novos dados).
// Usuários com versão diferente da currentVersion verão a tela de consent novamente.

enum AIConsentManager {
    static let currentVersion = 1

    private static let hasConsentKey = "aiConsent.hasConsent"
    private static let consentDateKey = "aiConsent.consentDate"
    private static let consentVersionKey = "aiConsent.version"

    /// Verdadeiro apenas se o usuário consentiu E na versão atual dos termos.
    /// Consent antigo (versão menor) deixa de ser válido automaticamente.
    static var hasConsent: Bool {
        let stored = UserDefaults.standard.bool(forKey: hasConsentKey)
        let version = UserDefaults.standard.integer(forKey: consentVersionKey)
        return stored && version == currentVersion
    }

    /// Data em que o usuário concedeu o consent na versão atual.
    static var consentDate: Date? {
        UserDefaults.standard.object(forKey: consentDateKey) as? Date
    }

    /// Concede consent na versão atual. Chamado pelo AIConsentView e pelo toggle de Settings.
    static func grantConsent() {
        UserDefaults.standard.set(true, forKey: hasConsentKey)
        UserDefaults.standard.set(Date(), forKey: consentDateKey)
        UserDefaults.standard.set(currentVersion, forKey: consentVersionKey)
    }

    /// Revoga consent. Chamado pelo toggle de Settings, ao deletar conta e ao desistir.
    static func revokeConsent() {
        UserDefaults.standard.set(false, forKey: hasConsentKey)
        UserDefaults.standard.removeObject(forKey: consentDateKey)
        UserDefaults.standard.removeObject(forKey: consentVersionKey)
    }
}

// MARK: - Sheet Background Compat
//
// `.presentationBackground` é iOS 16.4+. O target do Naplet é iOS 16+.
// Em iOS 16.0–16.3 cai no fallback de `.background(...)` para garantir o tom escuro.

private struct SheetBackgroundCompat: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationBackground(NapletColors.background)
        } else {
            content.background(NapletColors.background.ignoresSafeArea())
        }
    }
}

// MARK: - AI Consent View
//
// Apresentada como `.sheet` em duas situações (Apple Guideline 5.1.2(i)):
//   1. Auto-show na primeira aparição do Dashboard, se enableAIChat && !hasConsent
//   2. Ao tocar no card de "AI Chat" no Dashboard, se !hasConsent
//
// O closure `onConsent` é chamado SOMENTE quando o usuário aprova (botão "Enable AI Chat").
// "Not Now", botão X e dismiss não disparam o closure — apenas fecham o sheet.

struct AIConsentView: View {

    // MARK: - Dependencies
    @Environment(\.dismiss) private var dismiss
    let onConsent: () -> Void

    // MARK: - Local State
    @State private var checkboxChecked: Bool = false
    @State private var showPrivacyPolicy: Bool = false
    @State private var ctaScale: CGFloat = 1.0

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            closeButtonBar

            ScrollView {
                VStack(spacing: NapletSpacing.lg) {
                    heroIcon
                    titleBlock
                    dataSharedCard
                    neverSharedCard
                    processingNote
                    consentCheckbox
                    enableButton
                    notNowButton
                    privacyPolicyLink
                    poweredByFooter
                }
                .padding(.horizontal, NapletSpacing.lg)
                .padding(.top, NapletSpacing.sm)
                .padding(.bottom, NapletSpacing.xxl)
            }
        }
        .background(NapletColors.background.ignoresSafeArea())
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
                .modifier(SheetBackgroundCompat())
        }
    }

    // MARK: - Close Button (top-right, fixed)

    private var closeButtonBar: some View {
        HStack {
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(NapletColors.textMuted)
            }
        }
        .padding(.horizontal, NapletSpacing.lg)
        .padding(.top, NapletSpacing.md)
    }

    // MARK: - Hero Icon (lua Naplet + centelha de IA)

    private var heroIcon: some View {
        ZStack {
            // Background circle com gradient roxo→magenta (80x80, leve)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .opacity(0.18)

            // Camada principal: lua Naplet (identidade)
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Camada secundária: sparkle no canto superior direito
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(NapletColors.primaryPink)
                .offset(x: 28, y: -28)
        }
        .padding(.bottom, NapletSpacing.xs)
    }

    // MARK: - Title + Description

    private var titleBlock: some View {
        VStack(spacing: NapletSpacing.sm) {
            Text("aiConsent.title".localized)
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundColor(NapletColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("aiConsent.description".localized)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Data Shared Card (glassmorphism, cores de marca por linha)

    private var dataSharedCard: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.md) {
            Text("aiConsent.dataShared".localized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)
                .textCase(.uppercase)

            dataRow(
                icon: "figure.child.circle.fill",
                text: "aiConsent.data.babyInfo".localized,
                color: NapletColors.primaryPurple
            )
            dataRow(
                icon: "moon.zzz.fill",
                text: "aiConsent.data.sleepRecords".localized,
                color: NapletColors.primaryBlue
            )
            dataRow(
                icon: "bubble.left.and.text.bubble.right.fill",
                text: "aiConsent.data.chatMessages".localized,
                color: NapletColors.primaryPink
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NapletSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    NapletColors.primaryPurple.opacity(0.3),
                                    NapletColors.primaryPink.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    private func dataRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: NapletSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)

            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(NapletColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    // MARK: - Never Shared Card (privacidade ativa, borda success)

    private var neverSharedCard: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.md) {
            HStack(spacing: NapletSpacing.sm) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(NapletColors.success)

                Text("aiConsent.neverShared.title".localized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(NapletColors.textPrimary)
                    .textCase(.uppercase)
            }

            neverSharedRow(icon: "location.slash", text: "aiConsent.neverShared.location".localized)
            neverSharedRow(icon: "photo.on.rectangle.angled", text: "aiConsent.neverShared.media".localized)
            neverSharedRow(icon: "creditcard.trianglebadge.exclamationmark", text: "aiConsent.neverShared.payment".localized)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NapletSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(NapletColors.success.opacity(0.4), lineWidth: 1)
                )
        )
    }

    private func neverSharedRow(icon: String, text: String) -> some View {
        HStack(spacing: NapletSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(NapletColors.textSecondary)
                .frame(width: 24, height: 24)

            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(NapletColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    // MARK: - Processing Note

    private var processingNote: some View {
        HStack(alignment: .top, spacing: NapletSpacing.sm) {
            Image(systemName: "info.circle")
                .font(.system(size: 13))
                .foregroundColor(NapletColors.textMuted)

            Text("aiConsent.processingNote".localized)
                .font(.system(size: 13))
                .foregroundColor(NapletColors.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, NapletSpacing.xs)
    }

    // MARK: - Consent Checkbox

    private var consentCheckbox: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                checkboxChecked.toggle()
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(alignment: .top, spacing: NapletSpacing.md) {
                Image(systemName: checkboxChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundColor(checkboxChecked ? NapletColors.primaryPurple : NapletColors.textMuted)

                Text("aiConsent.checkbox".localized)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(NapletColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Primary CTA — "Enable AI Chat"

    private var enableButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            AIConsentManager.grantConsent()
            onConsent()
            dismiss()
        } label: {
            Text("aiConsent.enable".localized)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Group {
                        if checkboxChecked {
                            LinearGradient(
                                colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            NapletColors.backgroundTertiary
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!checkboxChecked)
        .opacity(checkboxChecked ? 1.0 : 0.6)
        .scaleEffect(ctaScale)
        .onChange(of: checkboxChecked) { newValue in
            guard newValue else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                ctaScale = 1.04
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    ctaScale = 1.0
                }
            }
        }
    }

    // MARK: - Secondary — "Not Now"

    private var notNowButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dismiss()
        } label: {
            Text("aiConsent.notNow".localized)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(NapletColors.textSecondary)
        }
    }

    // MARK: - Tertiary — Privacy Policy Link

    private var privacyPolicyLink: some View {
        Button {
            showPrivacyPolicy = true
        } label: {
            HStack(spacing: NapletSpacing.xs) {
                Image(systemName: "doc.text")
                    .font(.system(size: 13))
                Text("aiConsent.readPrivacyPolicy".localized)
                    .font(.system(size: 13, weight: .regular))
            }
            .foregroundColor(NapletColors.primaryPurple)
        }
        .padding(.top, NapletSpacing.xs)
    }

    // MARK: - Powered By Footer

    private var poweredByFooter: some View {
        Text("aiConsent.poweredBy".localized)
            .font(.system(size: 11, weight: .regular))
            .foregroundColor(NapletColors.textMuted)
            .multilineTextAlignment(.center)
            .padding(.top, NapletSpacing.md)
            .padding(.horizontal, NapletSpacing.lg)
    }
}

// MARK: - Preview

#if DEBUG
struct AIConsentView_Previews: PreviewProvider {
    static var previews: some View {
        AIConsentView(onConsent: {})
            .preferredColorScheme(.dark)
    }
}
#endif
