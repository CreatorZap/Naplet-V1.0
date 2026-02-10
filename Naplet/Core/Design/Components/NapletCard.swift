import SwiftUI

// MARK: - Naplet Card
/// Card container reutilizável com fundo backgroundSecondary, corner radius 20pt e glow suave
struct NapletCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(NapletSpacing.md)
            .background(NapletColors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(
                color: NapletColors.primaryPurple.opacity(0.08),
                radius: 20,
                x: 0,
                y: 8
            )
    }
}

// MARK: - Sleep Card (Especializado para tracking de sono)
struct SleepCard<Content: View>: View {
    let isActive: Bool
    let content: () -> Content

    init(
        isActive: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isActive = isActive
        self.content = content
    }

    var body: some View {
        content()
            .padding(NapletSpacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(NapletColors.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isActive ? NapletColors.gradientPrimary : LinearGradient(
                                    colors: [Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isActive ? 2 : 0
                            )
                    )
            )
            .shadow(
                color: isActive ? NapletColors.primaryPurple.opacity(0.25) : NapletColors.primaryPurple.opacity(0.08),
                radius: isActive ? 20 : 15,
                x: 0,
                y: isActive ? 8 : 5
            )
    }
}

// MARK: - Stats Card
struct StatsCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let iconColor: Color

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color = NapletColors.primaryPurple
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
    }

    var body: some View {
        NapletCard {
            VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: NapletSpacing.iconMedium))
                        .foregroundColor(iconColor)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: NapletSpacing.xs) {
                    Text(title)
                        .font(NapletTypography.caption())
                        .foregroundColor(NapletColors.textSecondary)

                    Text(value)
                        .font(NapletTypography.statsNumber())
                        .foregroundColor(NapletColors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(NapletTypography.caption())
                            .foregroundColor(NapletColors.textMuted)
                    }
                }
            }
        }
    }
}

// MARK: - Gradient Card
struct GradientCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(NapletSpacing.md)
            .background(NapletColors.gradientPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(
                color: NapletColors.primaryPurple.opacity(0.3),
                radius: 20,
                x: 0,
                y: 10
            )
    }
}

// MARK: - Preview
#Preview("Card Variations") {
    ZStack {
        NapletColors.background
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: NapletSpacing.lg) {
                // Basic Card
                VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                    Text("Basic Card")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    NapletCard {
                        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                            Text("Card Title")
                                .font(NapletTypography.headline())
                                .foregroundColor(NapletColors.textPrimary)
                            Text("This is a basic card with subtle glow effect in dark mode.")
                                .font(NapletTypography.body())
                                .foregroundColor(NapletColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Sleep Cards
                VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                    Text("Sleep Cards")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    SleepCard(isActive: false) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(NapletColors.sleepActive)
                            Text("Inactive Sleep Card")
                                .foregroundColor(NapletColors.textPrimary)
                            Spacer()
                        }
                    }

                    SleepCard(isActive: true) {
                        HStack {
                            Image(systemName: "moon.zzz.fill")
                                .foregroundColor(NapletColors.sleepActive)
                            Text("Active Sleep Card - Sleeping")
                                .foregroundColor(NapletColors.textPrimary)
                            Spacer()
                        }
                    }
                }

                // Stats Cards
                VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                    Text("Stats Cards")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    HStack(spacing: NapletSpacing.md) {
                        StatsCard(
                            title: "Total Sleep",
                            value: "8h 30m",
                            subtitle: "Today",
                            icon: "moon.fill",
                            iconColor: NapletColors.sleepActive
                        )

                        StatsCard(
                            title: "Naps",
                            value: "2",
                            subtitle: "3h 15m total",
                            icon: "sun.max.fill",
                            iconColor: NapletColors.napColor
                        )
                    }
                }

                // Gradient Card
                VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                    Text("Gradient Card")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    GradientCard {
                        VStack(spacing: NapletSpacing.sm) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                            Text("Premium Feature")
                                .font(NapletTypography.headline())
                                .foregroundColor(.white)
                            Text("Unlock advanced sleep analytics")
                                .font(NapletTypography.caption())
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, NapletSpacing.md)
                    }
                }
            }
            .padding()
        }
    }
}
