//
//  OnboardingPaywallStepView.swift
//  Naplet
//
//  Tela 11 do onboarding: paywall com oferta Founders.
//  Aparece entre LoadingStepView e CompletionStepView.
//

import SwiftUI

struct OnboardingPaywallStepView: View {

    // MARK: - Properties

    @ObservedObject var onboardingViewModel: OnboardingViewModel
    @StateObject private var viewModel = OnboardingPaywallViewModel()

    @State private var showTerms: Bool = false
    @State private var showPrivacy: Bool = false

    /// Nome do bebê para personalização da copy.
    /// Cai para "seu bebê" se não disponível.
    private var babyName: String {
        let name = onboardingViewModel.babyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty
            ? NSLocalizedString("baby.fallback.name", value: "seu bebê", comment: "")
            : name
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            NapletColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                closeButton

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        foundersHeroCard
                        pillarsSection
                        trialCard
                        ctaSection
                        finePrintSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            viewModel.trackShown()
        }
        .alert("Erro", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showTerms) {
            TermsOfServiceView()
                .modifier(SheetBackgroundCompat())
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
                .modifier(SheetBackgroundCompat())
        }
    }

    // MARK: - Close Button

    private var closeButton: some View {
        HStack {
            Spacer()
            Button {
                viewModel.trackDismissByX()
                advanceToCompletion()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(NapletColors.textMuted)
                    .frame(width: 36, height: 36)
                    .background(NapletColors.backgroundCard)
                    .clipShape(Circle())
            }
            .padding(.trailing, 20)
            .padding(.top, 12)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("onboarding.paywall.header.title".localized)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Text(String(format: "onboarding.paywall.header.subtitle".localized, babyName))
                .font(.system(size: 15))
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
    }

    // MARK: - Founders Hero Card

    private var foundersHeroCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(NapletColors.primaryPink)
                Text("onboarding.paywall.founders.badge".localized)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(NapletColors.primaryPink)
                    .tracking(0.5)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(NapletColors.primaryPink.opacity(0.15))
            .clipShape(Capsule())

            Text("onboarding.paywall.founders.deadline".localized)
                .font(.system(size: 13))
                .foregroundColor(NapletColors.textSecondary)

            VStack(spacing: 4) {
                Text("onboarding.paywall.founders.priceAnnual".localized)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(NapletColors.primaryPurple)

                Text("onboarding.paywall.founders.priceLabel".localized)
                    .font(.system(size: 13))
                    .foregroundColor(NapletColors.textMuted)
            }
            .padding(.top, 4)

            Text("onboarding.paywall.founders.priceRegular".localized)
                .font(.system(size: 13))
                .foregroundColor(NapletColors.textMuted)
                .strikethrough()

            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 11))
                Text(viewModel.countdownText)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(NapletColors.primaryPink)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(NapletColors.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NapletColors.primaryPurple, lineWidth: 2)
        )
    }

    // MARK: - Pillars

    private var pillarsSection: some View {
        VStack(spacing: 12) {
            pillarCard(
                icon: "sparkles",
                titleKey: "onboarding.paywall.pillar.ai.title",
                bodyKey: "onboarding.paywall.pillar.ai.body",
                bodyArg: babyName
            )
            pillarCard(
                icon: "doc.text.fill",
                titleKey: "onboarding.paywall.pillar.pdf.title",
                bodyKey: "onboarding.paywall.pillar.pdf.body",
                bodyArg: nil
            )
            pillarCard(
                icon: "person.3.fill",
                titleKey: "onboarding.paywall.pillar.family.title",
                bodyKey: "onboarding.paywall.pillar.family.body",
                bodyArg: nil
            )
        }
    }

    private func pillarCard(icon: String, titleKey: String, bodyKey: String, bodyArg: String?) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(titleKey.localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(bodyArg.map { String(format: bodyKey.localized, $0) } ?? bodyKey.localized)
                    .font(.system(size: 13))
                    .foregroundColor(NapletColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(NapletColors.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(NapletColors.textMuted.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Trial Card

    private var trialCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.system(size: 18))
                .foregroundColor(NapletColors.success)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("onboarding.paywall.trial.title".localized)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text("onboarding.paywall.trial.body".localized)
                    .font(.system(size: 13))
                    .foregroundColor(NapletColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(NapletColors.success.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(NapletColors.success, lineWidth: 1.5)
        )
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                handlePurchaseTap()
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                        Text("onboarding.paywall.cta.purchasing".localized)
                            .font(.system(size: 17, weight: .semibold))
                    } else {
                        Text("onboarding.paywall.cta.primary".localized)
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 28))
            }
            .disabled(viewModel.isPurchasing)
            .opacity(viewModel.isPurchasing ? 0.85 : 1.0)

            Button {
                handleSkipTap()
            } label: {
                Text("onboarding.paywall.cta.secondary".localized)
                    .font(.system(size: 15))
                    .foregroundColor(NapletColors.textSecondary)
                    .padding(.vertical, 12)
            }
            .disabled(viewModel.isPurchasing)
        }
        .padding(.top, 8)
    }

    // MARK: - Fine Print

    private var finePrintSection: some View {
        VStack(spacing: 8) {
            Divider()
                .background(NapletColors.textMuted.opacity(0.3))
                .padding(.vertical, 8)

            HStack(spacing: 16) {
                Button {
                    handleRestore()
                } label: {
                    if viewModel.isRestoring {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: NapletColors.textMuted))
                            .scaleEffect(0.6)
                    } else {
                        Text("onboarding.paywall.fineprint.restore".localized)
                            .font(.system(size: 12))
                            .foregroundColor(NapletColors.textMuted)
                    }
                }
                .disabled(viewModel.isRestoring || viewModel.isPurchasing)

                Text("·")
                    .foregroundColor(NapletColors.textMuted)

                Button("onboarding.paywall.fineprint.terms".localized) {
                    AnalyticsService.track("onboarding_paywall_terms_tap")
                    showTerms = true
                }
                .font(.system(size: 12))
                .foregroundColor(NapletColors.textMuted)

                Text("·")
                    .foregroundColor(NapletColors.textMuted)

                Button("onboarding.paywall.fineprint.privacy".localized) {
                    AnalyticsService.track("onboarding_paywall_privacy_tap")
                    showPrivacy = true
                }
                .font(.system(size: 12))
                .foregroundColor(NapletColors.textMuted)
            }

            Text("onboarding.paywall.fineprint.autorenewal".localized)
                .font(.system(size: 11))
                .foregroundColor(NapletColors.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.top, 4)
        }
    }

    // MARK: - Actions

    private func handlePurchaseTap() {
        Task {
            let success = await viewModel.purchaseFounders()
            if success {
                advanceToCompletion()
            }
            // Se falhou, errorMessage já está populado e alert vai aparecer
        }
    }

    private func handleSkipTap() {
        viewModel.trackSkip()
        advanceToCompletion()
    }

    private func handleRestore() {
        Task {
            let success = await viewModel.restorePurchases()
            if success {
                advanceToCompletion()
            }
            // Se não houve compra anterior ou deu erro, errorMessage já foi setado e alert vai aparecer
        }
    }

    private func advanceToCompletion() {
        withAnimation {
            onboardingViewModel.currentStep = .completion
        }
    }
}

// MARK: - Preview

#if DEBUG
struct OnboardingPaywallStepView_Previews: PreviewProvider {
    static var previews: some View {
        let mockVM = OnboardingViewModel()
        mockVM.babyName = "Alice"
        return OnboardingPaywallStepView(onboardingViewModel: mockVM)
            .preferredColorScheme(.dark)
    }
}
#endif
