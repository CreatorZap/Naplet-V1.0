import SwiftUI
import RevenueCat

// MARK: - Paywall View (Naplet Design System)
struct PaywallView: View {
    @StateObject private var viewModel: PaywallViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var appearAnimation = false

    init(trigger: PaywallTrigger = .softPrompt) {
        _viewModel = StateObject(wrappedValue: PaywallViewModel(trigger: trigger))
    }

    var body: some View {
        ZStack {
            // Background com gradiente Naplet
            LinearGradient(
                colors: [
                    NapletColors.background,
                    NapletColors.cardBackground,
                    NapletColors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    benefitsSection
                    pricingSection
                    socialProofSection
                    ctaSection
                    trustSection
                    footerSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }

            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .alert("paywall.error.title".localized, isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("common.ok".localized) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: viewModel.purchaseSuccess) { _, success in
            if success { dismiss() }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Ícone animado com gradiente
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                NapletColors.primaryPurple.opacity(0.3),
                                NapletColors.primaryPink.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(appearAnimation ? 1.0 : 0.8)

                Image(systemName: viewModel.isFoundersPeriod ? "star.fill" : viewModel.trigger.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 20)

            // Badge
            if viewModel.isFoundersPeriod {
                Text("paywall.badge.launch_offer".localized)
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(NapletColors.primaryPurple)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(NapletColors.primaryPurple.opacity(0.15))
                    )
            } else {
                Text("paywall.badge.naplet_pro".localized)
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(NapletColors.primaryPurple)
            }

            // Title
            Text(viewModel.isFoundersPeriod ? "paywall.founders.title".localized : viewModel.trigger.cleanHeadline)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(NapletColors.textPrimary)
                .multilineTextAlignment(.center)

            // Subtitle
            Text(viewModel.isFoundersPeriod ? "paywall.founders.subtitle".localized : viewModel.trigger.cleanSubtitle)
                .font(.system(size: 16))
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(spacing: 12) {
            ForEach(Array(viewModel.benefits.prefix(5).enumerated()), id: \.element.id) { index, benefit in
                NapletBenefitRow(benefit: benefit, delay: Double(index) * 0.05)
            }

            if viewModel.isFoundersPeriod {
                NapletBenefitRow(
                    benefit: viewModel.founderBenefit,
                    isHighlighted: true,
                    delay: 0.3
                )
            }
        }
    }

    // MARK: - Pricing Section
    private var pricingSection: some View {
        VStack(spacing: 16) {
            if viewModel.isFoundersPeriod {
                foundersPriceCard
            } else {
                regularPriceCards
            }
        }
    }

    // MARK: - Founders Price Card
    private var foundersPriceCard: some View {
        VStack(spacing: 16) {
            // Badge
            HStack(spacing: 6) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 14))
                Text("paywall.badge.founders_special".localized)
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1)
            }
            .foregroundColor(NapletColors.success)

            // Preço principal (do RevenueCat)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(viewModel.foundersPriceString)
                    .font(.system(size: 48, weight: .bold))
                Text("paywall.period.year".localized)
                    .font(.system(size: 18))
                    .foregroundColor(NapletColors.textSecondary)
            }
            .foregroundColor(NapletColors.textPrimary)

            // Preço riscado + economia (do RevenueCat)
            HStack(spacing: 12) {
                Text(viewModel.annualPriceString)
                    .strikethrough()
                    .foregroundColor(NapletColors.textMuted)

                if viewModel.foundersDiscountPercentage > 0 {
                    Text(String(format: "paywall.savings.percentage".localized, viewModel.foundersDiscountPercentage))
                        .foregroundColor(NapletColors.success)
                        .fontWeight(.semibold)
                }
            }
            .font(.system(size: 14))

            // Por mês (calculado do RevenueCat)
            Text(String(format: "paywall.monthly_equivalent".localized, viewModel.foundersMonthlyEquivalent))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(NapletColors.primaryPurple)

            // Validade
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                Text(String(format: "paywall.founders.valid_until".localized, viewModel.foundersEndDateFormatted))
                    .font(.system(size: 13))
            }
            .foregroundColor(NapletColors.textSecondary)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            NapletColors.primaryPurple.opacity(0.15),
                            NapletColors.cardBackground
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(NapletColors.primaryPurple.opacity(0.5), lineWidth: 1)
                )
        )
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 30)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: appearAnimation)
    }

    // MARK: - Regular Price Cards
    private var regularPriceCards: some View {
        VStack(spacing: 12) {
            // Annual (Best Value)
            if let annual = viewModel.annualPackage {
                NapletPackageCard(
                    package: annual,
                    isSelected: viewModel.isSelected(annual),
                    isBestValue: true,
                    monthlyEquivalent: viewModel.annualMonthlyEquivalent,
                    savingsPercentage: viewModel.annualSavingsPercentage
                ) {
                    viewModel.selectPackage(annual)
                }
            }

            // Monthly
            if let monthly = viewModel.monthlyPackage {
                NapletPackageCard(
                    package: monthly,
                    isSelected: viewModel.isSelected(monthly),
                    isBestValue: false,
                    monthlyEquivalent: nil,
                    savingsPercentage: 0
                ) {
                    viewModel.selectPackage(monthly)
                }
            }
        }
    }

    // MARK: - CTA Section
    private var ctaSection: some View {
        Button {
            Task {
                await viewModel.ctaAction()
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isLoadingPrices || viewModel.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    // Always show purchase text — never "Try Again"
                    Text(viewModel.isFoundersPeriod ? "paywall.cta.founders".localized : "paywall.cta.subscribe".localized)
                        .font(.system(size: 18, weight: .bold))
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
            .cornerRadius(16)
            .shadow(color: NapletColors.primaryPurple.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .disabled(viewModel.isLoadingPrices || viewModel.isPurchasing)
        .opacity((viewModel.isLoadingPrices || viewModel.isPurchasing) ? 0.6 : 1)
        .scaleEffect(appearAnimation ? 1 : 0.95)
        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.5), value: appearAnimation)
    }

    // MARK: - Social Proof Section
    private var socialProofSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 28))
                .foregroundStyle(
                    LinearGradient(
                        colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("paywall.social.join_family".localized)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(NapletColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("paywall.social.join_subtitle".localized)
                .font(.system(size: 14))
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
        .opacity(appearAnimation ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.5), value: appearAnimation)
    }

    // MARK: - Trust Section
    private var trustSection: some View {
        HStack(spacing: 20) {
            NapletTrustBadge(icon: "checkmark.seal.fill", text: "paywall.trust.free_trial".localized)
            NapletTrustBadge(icon: "arrow.uturn.backward", text: "paywall.trust.cancel_anytime".localized)
            if viewModel.isFoundersPeriod {
                NapletTrustBadge(icon: "lock.fill", text: "paywall.trust.locked_price".localized)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 16) {
            Button {
                Task { await viewModel.restorePurchases() }
            } label: {
                Text("paywall.restore".localized)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(NapletColors.primaryPurple)
            }
            .disabled(viewModel.isPurchasing)

            // Texto legal obrigatorio Apple (auto-renovacao)
            Text("paywall.auto_renew_disclaimer".localized)
                .font(.caption2)
                .foregroundColor(NapletColors.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 20) {
                if let termsURL = URL(string: "https://naplet.app/terms") {
                    Link("paywall.terms".localized, destination: termsURL)
                }
                Text("•").foregroundColor(NapletColors.textMuted)
                if let privacyURL = URL(string: "https://naplet.app/privacy") {
                    Link("paywall.privacy".localized, destination: privacyURL)
                }
            }
            .font(.system(size: 13))
            .foregroundColor(NapletColors.textMuted)
        }
        .padding(.top, 8)
    }

    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(NapletColors.primaryPurple)

                Text("paywall.loading".localized)
                    .font(.subheadline)
                    .foregroundColor(NapletColors.textSecondary)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(NapletColors.cardBackground)
            )
        }
    }
}

// MARK: - Naplet Benefit Row
struct NapletBenefitRow: View {
    let benefit: PaywallBenefit
    var isHighlighted: Bool = false
    var delay: Double = 0

    @State private var appeared = false

    /// Cor de fundo padronizada para ícones
    private let iconBackground = Color(hex: "#252542")

    var body: some View {
        HStack(spacing: 16) {
            // Ícone com fundo padronizado #252542
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHighlighted ? NapletColors.primaryPurple.opacity(0.2) : iconBackground)
                    .frame(width: 48, height: 48)

                Image(systemName: benefit.icon)
                    .font(.system(size: 20))
                    .foregroundColor(NapletColors.primaryPurple)
            }

            // Textos
            VStack(alignment: .leading, spacing: 4) {
                Text(benefit.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(NapletColors.textPrimary)

                Text(benefit.description)
                    .font(.system(size: 13))
                    .foregroundColor(NapletColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            // Checkmark com círculo para garantir visibilidade
            ZStack {
                Circle()
                    .fill(NapletColors.success.opacity(0.15))
                    .frame(width: 28, height: 28)

                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(NapletColors.success)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isHighlighted ? NapletColors.primaryPurple.opacity(0.3) : NapletColors.primaryPurple.opacity(0.15), lineWidth: 1)
                )
        )
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                appeared = true
            }
        }
    }
}

// MARK: - Naplet Trust Badge
struct NapletTrustBadge: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(NapletColors.primaryPurple)

            Text(text)
                .font(.system(size: 11))
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Naplet Package Card
struct NapletPackageCard: View {
    let package: Package
    let isSelected: Bool
    let isBestValue: Bool
    let monthlyEquivalent: String?
    let savingsPercentage: Int
    let onSelect: () -> Void

    // Fallback prices (matching App Store Connect USD prices)
    private var fallbackPrice: String {
        switch package.packageType {
        case .annual: return "$21.99"
        case .monthly: return "$3.49"
        default: return package.localizedPriceString
        }
    }

    private var displayPrice: String {
        let price = package.localizedPriceString
        if price.isEmpty {
            return fallbackPrice
        }
        return price
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // Best Value Badge
                if isBestValue && savingsPercentage > 0 {
                    HStack {
                        Spacer()
                        Text(String(format: "paywall.package.save".localized, savingsPercentage))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(NapletColors.success)
                            )
                    }
                    .padding(.bottom, 8)
                }

                HStack {
                    // Package Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(packageTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(NapletColors.textPrimary)

                        if let equivalent = monthlyEquivalent, !equivalent.isEmpty {
                            Text(String(format: "paywall.package.equivalent".localized, equivalent))
                                .font(.system(size: 13))
                                .foregroundColor(NapletColors.textSecondary)
                        }
                    }

                    Spacer()

                    // Price (with fallback)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(displayPrice)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(NapletColors.textPrimary)

                        Text(periodText)
                            .font(.system(size: 13))
                            .foregroundColor(NapletColors.textSecondary)
                    }

                    // Selection Indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? NapletColors.primaryPurple : NapletColors.textMuted)
                        .padding(.leading, 12)
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(NapletColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? NapletColors.primaryPurple : NapletColors.primaryPurple.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var packageTitle: String {
        switch package.packageType {
        case .annual: return "paywall.package.annual".localized
        case .monthly: return "paywall.package.monthly".localized
        case .weekly: return "paywall.package.weekly".localized
        case .lifetime: return "paywall.package.lifetime".localized
        default: return package.storeProduct.localizedTitle
        }
    }

    private var periodText: String {
        switch package.packageType {
        case .annual: return "paywall.period.year".localized
        case .monthly: return "paywall.period.month".localized
        case .weekly: return "paywall.period.week".localized
        case .lifetime: return "paywall.period.lifetime".localized
        default: return ""
        }
    }
}

// MARK: - PaywallTrigger Extension
extension PaywallTrigger {
    var cleanHeadline: String {
        switch self {
        case .inviteCaregiver: return "paywall.trigger.invite.headline".localized
        case .aiChatLimit: return "paywall.trigger.ai.headline".localized
        case .pdfReport: return "paywall.trigger.pdf.headline".localized
        case .historyLimit: return "paywall.trigger.history.headline".localized
        case .multipleBabies: return "paywall.trigger.babies.headline".localized
        case .softPrompt, .settingsUpgrade: return "paywall.trigger.default.headline".localized
        }
    }

    var cleanSubtitle: String {
        switch self {
        case .inviteCaregiver: return "paywall.trigger.invite.subtitle".localized
        case .aiChatLimit: return "paywall.trigger.ai.subtitle".localized
        case .pdfReport: return "paywall.trigger.pdf.subtitle".localized
        case .historyLimit: return "paywall.trigger.history.subtitle".localized
        case .multipleBabies: return "paywall.trigger.babies.subtitle".localized
        case .softPrompt, .settingsUpgrade: return "paywall.trigger.default.subtitle".localized
        }
    }
}

// MARK: - Preview
#Preview("Founders Period") {
    PaywallView(trigger: .softPrompt)
}

#Preview("AI Chat Limit") {
    PaywallView(trigger: .aiChatLimit)
}

#Preview("Invite Caregiver") {
    PaywallView(trigger: .inviteCaregiver)
}
