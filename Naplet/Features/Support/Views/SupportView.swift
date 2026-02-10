import SwiftUI
import StoreKit

// MARK: - Support View
struct SupportView: View {
    @State private var showFAQ = false
    @State private var showContactForm = false
    @Environment(\.dismiss) private var dismiss

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

                // Menu de opcoes
                VStack(spacing: NapletSpacing.sm) {
                    // Instagram
                    SupportOptionCard(
                        icon: "camera.fill",
                        iconColor: NapletColors.primaryPink,
                        title: "support.instagram.title".localized,
                        subtitle: "support.instagram.subtitle".localized
                    ) {
                        SupportActions.openInstagram()
                    }

                    // FAQ
                    SupportOptionCard(
                        icon: "questionmark.circle.fill",
                        iconColor: .blue,
                        title: "support.faq.title".localized,
                        subtitle: "support.faq.subtitle".localized
                    ) {
                        showFAQ = true
                    }

                    // Contato
                    SupportOptionCard(
                        icon: "envelope.fill",
                        iconColor: .green,
                        title: "support.contact.title".localized,
                        subtitle: "support.contact.subtitle".localized
                    ) {
                        showContactForm = true
                    }

                    // Avaliar na App Store
                    SupportOptionCard(
                        icon: "star.fill",
                        iconColor: .yellow,
                        title: "support.rate.title".localized,
                        subtitle: "support.rate.subtitle".localized
                    ) {
                        SupportActions.requestReview()
                    }

                    // Compartilhar
                    SupportOptionCard(
                        icon: "square.and.arrow.up.fill",
                        iconColor: NapletColors.primaryPurple,
                        title: "support.share.title".localized,
                        subtitle: "support.share.subtitle".localized
                    ) {
                        SupportActions.shareApp()
                    }
                }
                .padding(.horizontal, NapletSpacing.md)

                // Secao "Em Breve"
                ComingSoonSection()
                    .padding(.horizontal, NapletSpacing.md)
                    .padding(.top, NapletSpacing.sm)

                // Versao do app
                VStack(spacing: 4) {
                    Text("Naplet v\(AppConfig.appVersion)")
                        .font(NapletTypography.caption())
                        .foregroundColor(NapletColors.textSecondary)

                    Text("support.madeWithLove".localized)
                        .font(NapletTypography.caption())
                        .foregroundColor(NapletColors.textMuted)
                }
                .padding(.vertical, NapletSpacing.lg)
            }
        }
        .background(NapletColors.background)
        .sheet(isPresented: $showFAQ) {
            FAQView()
        }
        .sheet(isPresented: $showContactForm) {
            ContactFormView()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: NapletSpacing.sm) {
            ZStack {
                Circle()
                    .fill(NapletColors.primaryPurple.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(NapletColors.primaryPurple)
            }

            Text("support.title".localized)
                .font(NapletTypography.title2())
                .fontWeight(.bold)
                .foregroundColor(NapletColors.textPrimary)

            Text("support.subtitle".localized)
                .font(NapletTypography.subheadline())
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, NapletSpacing.md)
    }
}

// MARK: - Support Option Card
struct SupportOptionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            NapletCard {
                HStack(spacing: NapletSpacing.md) {
                    // Icone
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(iconColor)
                    }

                    // Textos
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(NapletTypography.body())
                            .fontWeight(.medium)
                            .foregroundColor(NapletColors.textPrimary)

                        Text(subtitle)
                            .font(NapletTypography.caption())
                            .foregroundColor(NapletColors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Chevron
                    NapletIcon("chevron.right", size: .small, color: NapletColors.textMuted)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Coming Soon Section
struct ComingSoonSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.md) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(NapletColors.primaryPurple)

                Text("support.comingSoon.title".localized)
                    .font(NapletTypography.headline())
                    .fontWeight(.semibold)
                    .foregroundColor(NapletColors.textPrimary)
            }

            Text("support.comingSoon.subtitle".localized)
                .font(NapletTypography.caption())
                .foregroundColor(NapletColors.textSecondary)

            // Cards de features em breve
            VStack(spacing: NapletSpacing.sm) {
                ComingSoonCard(
                    iconName: "music.note.list",
                    title: "support.comingSoon.sounds.title".localized,
                    description: "support.comingSoon.sounds.desc".localized,
                    progress: 0.7
                )

                ComingSoonCard(
                    iconName: "book.fill",
                    title: "support.comingSoon.course.title".localized,
                    description: "support.comingSoon.course.desc".localized,
                    progress: 0.4
                )
            }

            // CTA para Instagram
            Button(action: {
                SupportActions.openInstagram()
            }) {
                HStack {
                    Image(systemName: "bell.fill")
                        .font(.caption)

                    Text("support.comingSoon.notify".localized)
                        .font(NapletTypography.caption())
                        .fontWeight(.medium)
                }
                .foregroundColor(NapletColors.primaryPurple)
            }
            .padding(.top, NapletSpacing.xs)
        }
        .padding(NapletSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(NapletColors.primaryPurple.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Coming Soon Card
struct ComingSoonCard: View {
    let iconName: String
    let title: String
    let description: String
    let progress: Double

    var body: some View {
        HStack(spacing: NapletSpacing.sm) {
            // Icon
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(NapletColors.primaryPurple)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(NapletColors.backgroundSecondary)
                )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(NapletTypography.subheadline())
                    .fontWeight(.medium)
                    .foregroundColor(NapletColors.textPrimary)

                Text(description)
                    .font(NapletTypography.caption())
                    .foregroundColor(NapletColors.textSecondary)
                    .lineLimit(2)

                // Barra de progresso
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(NapletColors.backgroundSecondary)
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(NapletColors.primaryPurple)
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }

            Spacer()

            // Badge de status
            Text("support.comingSoon.badge".localized)
                .font(NapletTypography.caption())
                .fontWeight(.medium)
                .foregroundColor(NapletColors.primaryPurple)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(NapletColors.primaryPurple.opacity(0.15))
                )
        }
        .padding(NapletSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(NapletColors.backgroundSecondary.opacity(0.5))
        )
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SupportView()
    }
}
