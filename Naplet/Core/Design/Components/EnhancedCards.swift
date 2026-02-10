import SwiftUI

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = NapletSpacing.lg

    init(padding: CGFloat = NapletSpacing.lg, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(NapletColors.backgroundSecondary.opacity(0.8))

                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
    }
}

// MARK: - Gradient Border Card
struct GradientBorderCard<Content: View>: View {
    let content: Content
    let isActive: Bool

    init(isActive: Bool = false, @ViewBuilder content: () -> Content) {
        self.isActive = isActive
        self.content = content()
    }

    var body: some View {
        content
            .padding(NapletSpacing.lg)
            .background(NapletColors.backgroundSecondary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isActive ? NapletColors.gradientPrimary : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom),
                        lineWidth: 2
                    )
            )
            .shadow(color: isActive ? NapletColors.glowPurple : .clear, radius: 10)
    }
}

// MARK: - Neumorphic Card
struct NeumorphicCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(NapletSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(NapletColors.backgroundSecondary)
                    .shadow(color: Color.black.opacity(0.5), radius: 10, x: 5, y: 5)
                    .shadow(color: NapletColors.backgroundTertiary.opacity(0.3), radius: 10, x: -5, y: -5)
            )
    }
}

// MARK: - Action Card with Icon
struct ActionCardEnhanced: View {
    let icon: String
    let title: String
    let subtitle: String?
    let gradientColors: [Color]
    let action: () -> Void

    @State private var isPressed = false

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        gradientColors: [Color] = [NapletColors.primaryPurple, NapletColors.primaryPink],
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.gradientColors = gradientColors
        self.action = action
    }

    var body: some View {
        VStack(spacing: NapletSpacing.sm) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(NapletColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(NapletColors.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NapletSpacing.md)
        .padding(.horizontal, NapletSpacing.sm)
        .background(NapletColors.backgroundSecondary)
        .cornerRadius(16)
        .scaleEffect(isPressed ? 0.96 : 1)
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Press Events Modifier
struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        GlassCard {
            HStack(spacing: NapletSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.system(size: NapletTypography.title2, weight: .bold))
                        .foregroundColor(NapletColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(label)
                        .font(.system(size: NapletTypography.caption))
                        .foregroundColor(NapletColors.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Tip Card
struct TipCard: View {
    let icon: String
    let title: String
    let message: String
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: NapletSpacing.md) {
            ZStack {
                Circle()
                    .fill(NapletColors.primaryBlue.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(NapletColors.primaryBlue)
            }

            VStack(alignment: .leading, spacing: NapletSpacing.xs) {
                Text(title)
                    .font(.system(size: NapletTypography.subheadline, weight: .semibold))
                    .foregroundColor(NapletColors.textPrimary)

                Text(message)
                    .font(.system(size: NapletTypography.caption))
                    .foregroundColor(NapletColors.textSecondary)
                    .lineLimit(3)
            }

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(NapletColors.textMuted)
                        .padding(8)
                        .background(NapletColors.backgroundTertiary)
                        .clipShape(Circle())
                }
            }
        }
        .padding(NapletSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(NapletColors.primaryBlue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview
#Preview("Enhanced Cards") {
    ScrollView {
        VStack(spacing: 20) {
            GlassCard {
                Text("Glass Card")
                    .foregroundColor(.white)
            }

            GradientBorderCard(isActive: true) {
                Text("Active Gradient Border Card")
                    .foregroundColor(.white)
            }

            StatCard(
                icon: "moon.fill",
                iconColor: NapletColors.primaryPurple,
                value: "2h 30m",
                label: "Total sleep"
            )

            ActionCardEnhanced(
                icon: "moon.zzz.fill",
                title: "Start Nap",
                subtitle: "Track sleep"
            ) {}

            TipCard(
                icon: "lightbulb.fill",
                title: "Sleep Tip",
                message: "Babies need consistent sleep schedules for better rest."
            ) {}
        }
        .padding()
    }
    .background(NapletColors.background)
}
