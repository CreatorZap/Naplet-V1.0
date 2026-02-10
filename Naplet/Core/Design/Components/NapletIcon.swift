import SwiftUI

// MARK: - Naplet Icon Sizes
enum NapletIconSize {
    case small      // 16pt
    case medium     // 24pt
    case large      // 32pt
    case xLarge     // 48pt

    var value: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 24
        case .large: return 32
        case .xLarge: return 48
        }
    }
}

// MARK: - Naplet Icon
/// Wrapper para ícones SF Symbols com estilo consistente
struct NapletIcon: View {
    let name: String
    let size: NapletIconSize
    let color: Color

    init(
        _ name: String,
        size: NapletIconSize = .medium,
        color: Color = NapletColors.textPrimary
    ) {
        self.name = name
        self.size = size
        self.color = color
    }

    var body: some View {
        Image(systemName: name)
            .font(.system(size: size.value))
            .foregroundColor(color)
    }
}

// MARK: - Naplet Gradient Icon
/// Ícone com gradiente primário
struct NapletGradientIcon: View {
    let name: String
    let size: NapletIconSize

    init(
        _ name: String,
        size: NapletIconSize = .medium
    ) {
        self.name = name
        self.size = size
    }

    var body: some View {
        Image(systemName: name)
            .font(.system(size: size.value))
            .foregroundStyle(NapletColors.gradientPrimary)
    }
}

// MARK: - Icon Button
struct NapletIconButton: View {
    let icon: String
    let size: NapletIconSize
    let color: Color
    let backgroundColor: Color?
    let action: () -> Void

    @State private var isPressed = false

    init(
        icon: String,
        size: NapletIconSize = .medium,
        color: Color = NapletColors.textPrimary,
        backgroundColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.color = color
        self.backgroundColor = backgroundColor
        self.action = action
    }

    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        } label: {
            NapletIcon(icon, size: size, color: color)
                .frame(width: buttonSize, height: buttonSize)
                .background(backgroundColor ?? Color.clear)
                .clipShape(Circle())
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var buttonSize: CGFloat {
        switch size {
        case .small: return 32
        case .medium: return 44
        case .large: return 56
        case .xLarge: return 72
        }
    }
}

// MARK: - Sleep Status Icon
struct SleepStatusIcon: View {
    let isAsleep: Bool
    let size: NapletIconSize

    init(isAsleep: Bool, size: NapletIconSize = .large) {
        self.isAsleep = isAsleep
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(isAsleep ? NapletColors.sleepActive.opacity(0.2) : NapletColors.awakeColor.opacity(0.2))
                .frame(width: backgroundSize, height: backgroundSize)

            NapletIcon(
                isAsleep ? "moon.zzz.fill" : "sun.max.fill",
                size: size,
                color: isAsleep ? NapletColors.sleepActive : NapletColors.awakeColor
            )
        }
    }

    private var backgroundSize: CGFloat {
        size.value * 2
    }
}

// MARK: - Animated Icon
struct NapletAnimatedIcon: View {
    let icon: String
    let size: NapletIconSize
    let color: Color
    let animation: IconAnimation

    @State private var isAnimating = false

    enum IconAnimation {
        case pulse
        case rotate
        case bounce
    }

    init(
        _ icon: String,
        size: NapletIconSize = .medium,
        color: Color = NapletColors.primaryPurple,
        animation: IconAnimation = .pulse
    ) {
        self.icon = icon
        self.size = size
        self.color = color
        self.animation = animation
    }

    var body: some View {
        NapletIcon(icon, size: size, color: color)
            .scaleEffect(animationScale)
            .opacity(animationOpacity)
            .rotationEffect(animationRotation)
            .offset(y: animationOffset)
            .onAppear {
                isAnimating = true
            }
            .animation(animationStyle, value: isAnimating)
    }

    private var animationScale: CGFloat {
        guard animation == .pulse else { return 1.0 }
        return isAnimating ? 1.1 : 1.0
    }

    private var animationOpacity: Double {
        guard animation == .pulse else { return 1.0 }
        return isAnimating ? 0.8 : 1.0
    }

    private var animationRotation: Angle {
        guard animation == .rotate else { return .zero }
        return isAnimating ? .degrees(360) : .zero
    }

    private var animationOffset: CGFloat {
        guard animation == .bounce else { return 0 }
        return isAnimating ? -5 : 0
    }

    private var animationStyle: Animation {
        switch animation {
        case .pulse:
            return .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
        case .rotate:
            return .linear(duration: 1.5).repeatForever(autoreverses: false)
        case .bounce:
            return .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
        }
    }
}

// MARK: - Preview
#Preview("Icons") {
    ZStack {
        NapletColors.background
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: NapletSpacing.xl) {
                // Basic icons - Sizes
                VStack(alignment: .leading, spacing: NapletSpacing.md) {
                    Text("Icon Sizes")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    HStack(spacing: NapletSpacing.lg) {
                        VStack {
                            NapletIcon("moon.fill", size: .small)
                            Text("16pt")
                                .font(NapletTypography.caption())
                                .foregroundColor(NapletColors.textMuted)
                        }

                        VStack {
                            NapletIcon("moon.fill", size: .medium)
                            Text("24pt")
                                .font(NapletTypography.caption())
                                .foregroundColor(NapletColors.textMuted)
                        }

                        VStack {
                            NapletIcon("moon.fill", size: .large)
                            Text("32pt")
                                .font(NapletTypography.caption())
                                .foregroundColor(NapletColors.textMuted)
                        }

                        VStack {
                            NapletIcon("moon.fill", size: .xLarge)
                            Text("48pt")
                                .font(NapletTypography.caption())
                                .foregroundColor(NapletColors.textMuted)
                        }
                    }
                }

                // Icon colors
                VStack(alignment: .leading, spacing: NapletSpacing.md) {
                    Text("Icon Colors")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    HStack(spacing: NapletSpacing.lg) {
                        NapletIcon("star.fill", size: .large, color: NapletColors.primaryPurple)
                        NapletIcon("star.fill", size: .large, color: NapletColors.primaryPink)
                        NapletIcon("star.fill", size: .large, color: NapletColors.sleepActive)
                        NapletIcon("star.fill", size: .large, color: NapletColors.awakeColor)
                        NapletGradientIcon("star.fill", size: .large)
                    }
                }

                // Icon buttons
                VStack(alignment: .leading, spacing: NapletSpacing.md) {
                    Text("Icon Buttons")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    HStack(spacing: NapletSpacing.md) {
                        NapletIconButton(
                            icon: "gear",
                            backgroundColor: NapletColors.backgroundSecondary
                        ) {}

                        NapletIconButton(
                            icon: "plus",
                            color: .white,
                            backgroundColor: NapletColors.primaryPurple
                        ) {}

                        NapletIconButton(
                            icon: "bell.fill",
                            size: .large,
                            color: NapletColors.primaryPink,
                            backgroundColor: NapletColors.backgroundTertiary
                        ) {}
                    }
                }

                // Sleep status icons
                VStack(alignment: .leading, spacing: NapletSpacing.md) {
                    Text("Sleep Status Icons")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    HStack(spacing: NapletSpacing.xl) {
                        VStack {
                            SleepStatusIcon(isAsleep: true)
                            Text("dashboard.status.sleeping".localized)
                                .font(NapletTypography.caption())
                                .foregroundColor(NapletColors.textSecondary)
                        }

                        VStack {
                            SleepStatusIcon(isAsleep: false)
                            Text("dashboard.status.awake".localized)
                                .font(NapletTypography.caption())
                                .foregroundColor(NapletColors.textSecondary)
                        }
                    }
                }

                // Animated icons
                VStack(alignment: .leading, spacing: NapletSpacing.md) {
                    Text("Animated Icons")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    HStack(spacing: NapletSpacing.xl) {
                        VStack {
                            NapletAnimatedIcon("moon.zzz.fill", size: .large, animation: .pulse)
                            Text("Pulse")
                                .font(NapletTypography.caption())
                                .foregroundColor(NapletColors.textMuted)
                        }

                        VStack {
                            NapletAnimatedIcon("arrow.clockwise", size: .large, animation: .rotate)
                            Text("Rotate")
                                .font(NapletTypography.caption())
                                .foregroundColor(NapletColors.textMuted)
                        }

                        VStack {
                            NapletAnimatedIcon("heart.fill", size: .large, color: NapletColors.primaryPink, animation: .bounce)
                            Text("Bounce")
                                .font(NapletTypography.caption())
                                .foregroundColor(NapletColors.textMuted)
                        }
                    }
                }
            }
            .padding()
        }
    }
}
