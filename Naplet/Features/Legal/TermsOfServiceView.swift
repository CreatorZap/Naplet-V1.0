import SwiftUI

// MARK: - Terms of Service View
/// Exibe os termos de serviço do app
struct TermsOfServiceView: View {
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

                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 28))
                                .foregroundColor(NapletColors.primaryPurple)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Header
                    Text("legal.terms.title".localized)
                        .font(NapletTypography.title1())
                        .foregroundColor(NapletColors.textPrimary)

                    Text("legal.lastUpdate".localized)
                        .font(NapletTypography.caption())
                        .foregroundColor(NapletColors.textMuted)

                    // Sections
                    Group {
                        LegalSectionView(
                            title: "legal.terms.section1.title".localized,
                            content: "legal.terms.section1.content".localized
                        )

                        LegalSectionView(
                            title: "legal.terms.section2.title".localized,
                            content: "legal.terms.section2.content".localized
                        )

                        LegalSectionView(
                            title: "legal.terms.section3.title".localized,
                            content: "legal.terms.section3.content".localized
                        )

                        LegalSectionView(
                            title: "legal.terms.section4.title".localized,
                            content: "legal.terms.section4.content".localized
                        )

                        LegalSectionView(
                            title: "legal.terms.section5.title".localized,
                            content: "legal.terms.section5.content".localized
                        )

                        LegalSectionView(
                            title: "legal.terms.section6.title".localized,
                            content: "legal.terms.section6.content".localized
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

// MARK: - Preview
#Preview {
    TermsOfServiceView()
}
