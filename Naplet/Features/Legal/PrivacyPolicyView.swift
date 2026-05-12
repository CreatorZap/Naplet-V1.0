import SwiftUI

// MARK: - Privacy Policy View
/// Exibe a política de privacidade do app
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            NapletColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: NapletSpacing.lg) {
                    // Drag Indicator
                    Capsule()
                        .fill(NapletColors.textMuted.opacity(0.3))
                        .frame(width: 36, height: 5)
                        .padding(.top, NapletSpacing.sm)
                        .frame(maxWidth: .infinity)

                    // Header Icon
                    VStack(spacing: NapletSpacing.sm) {
                        ZStack {
                            Circle()
                                .fill(NapletColors.primaryPurple.opacity(0.2))
                                .frame(width: 60, height: 60)

                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 28))
                                .foregroundColor(NapletColors.primaryPurple)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Header
                    Text("legal.privacy.title".localized)
                        .font(NapletTypography.title1())
                        .foregroundColor(NapletColors.textPrimary)

                    Text("legal.lastUpdate".localized)
                        .font(NapletTypography.caption())
                        .foregroundColor(NapletColors.textMuted)

                    // Sections
                    Group {
                        LegalSectionView(
                            title: "legal.privacy.section1.title".localized,
                            content: "legal.privacy.section1.content".localized
                        )

                        LegalSectionView(
                            title: "legal.privacy.section2.title".localized,
                            content: "legal.privacy.section2.content".localized
                        )

                        LegalSectionView(
                            title: "legal.privacy.section3.title".localized,
                            content: "legal.privacy.section3.content".localized
                        )

                        LegalSectionView(
                            title: "legal.privacy.section4.title".localized,
                            content: "legal.privacy.section4.content".localized
                        )

                        LegalSectionView(
                            title: "legal.privacy.section5.title".localized,
                            content: "legal.privacy.section5.content".localized
                        )

                        LegalSectionView(
                            title: "legal.privacy.section6.title".localized,
                            content: "legal.privacy.section6.content".localized
                        )

                        LegalSectionView(
                            title: "legal.privacy.section7.title".localized,
                            content: "legal.privacy.section7.content".localized
                        )
                    }
                }
                .padding(NapletSpacing.lg)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }
}

// MARK: - Legal Section View
/// Componente reutilizável para seções de documentos legais
struct LegalSectionView: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            Text(title)
                .font(NapletTypography.headline())
                .foregroundColor(NapletColors.textPrimary)

            Text(content)
                .font(NapletTypography.body())
                .foregroundColor(NapletColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, NapletSpacing.sm)
    }
}

// MARK: - Preview
#Preview {
    PrivacyPolicyView()
}
