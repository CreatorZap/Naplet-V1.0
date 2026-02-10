import SwiftUI

// MARK: - Floating Stars Background
struct FloatingStarsView: View {
    @State private var animate = false
    let starCount: Int

    init(starCount: Int = 20) {
        self.starCount = starCount
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<starCount, id: \.self) { index in
                    StarView(animate: animate, index: index)
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct StarView: View {
    let animate: Bool
    let index: Int
    @State private var opacity: Double = 0.5
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: CGFloat((index % 3) + 1) * 4))
            .foregroundColor(NapletColors.primaryPurple.opacity(opacity))
            .scaleEffect(scale)
            .onAppear {
                guard animate else { return }
                withAnimation(
                    Animation.easeInOut(duration: Double.random(in: 1.5...3.0))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1)
                ) {
                    opacity = Double.random(in: 0.3...0.9)
                    scale = CGFloat.random(in: 0.6...1.2)
                }
            }
    }
}

// MARK: - Pulsing Circle
struct PulsingCircle: View {
    @State private var isPulsing = false
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: size * 1.5, height: size * 1.5)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 0 : 0.5)

            // Middle glow
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size * 1.2, height: size * 1.2)
                .scaleEffect(isPulsing ? 1.1 : 1.0)

            // Inner circle
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Breathing Animation Modifier
struct BreathingModifier: ViewModifier {
    @State private var isBreathing = false
    let intensity: CGFloat
    let duration: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(isBreathing ? 1 + intensity : 1)
            .animation(
                Animation.easeInOut(duration: duration)
                    .repeatForever(autoreverses: true),
                value: isBreathing
            )
            .onAppear {
                isBreathing = true
            }
    }
}

extension View {
    func breathing(intensity: CGFloat = 0.05, duration: Double = 2.0) -> some View {
        modifier(BreathingModifier(intensity: intensity, duration: duration))
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            Color.white.opacity(0.2),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + phase * geometry.size.width * 3)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 2.0)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Animated Moon Icon
struct AnimatedMoonIcon: View {
    @State private var rotation: Double = 0
    @State private var glowOpacity: Double = 0.5
    let size: CGFloat
    let isAnimating: Bool

    init(size: CGFloat = 60, isAnimating: Bool = true) {
        self.size = size
        self.isAnimating = isAnimating
    }

    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            NapletColors.primaryPurple.opacity(glowOpacity),
                            NapletColors.primaryPink.opacity(glowOpacity * 0.5),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.3,
                        endRadius: size
                    )
                )
                .frame(width: size * 2, height: size * 2)

            // Moon icon
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: size))
                .foregroundStyle(NapletColors.gradientPrimary)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            guard isAnimating else { return }

            withAnimation(
                Animation.easeInOut(duration: 3)
                    .repeatForever(autoreverses: true)
            ) {
                rotation = 10
                glowOpacity = 0.8
            }
        }
    }
}

// MARK: - Sleep Status Indicator
struct SleepStatusIndicator: View {
    let isSleeping: Bool
    @State private var animate = false

    var body: some View {
        HStack(spacing: NapletSpacing.sm) {
            ZStack {
                if isSleeping {
                    // Sleeping indicator with pulse
                    Circle()
                        .fill(NapletColors.primaryPurple.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .scaleEffect(animate ? 1.5 : 1)
                        .opacity(animate ? 0 : 1)

                    Circle()
                        .fill(NapletColors.primaryPurple)
                        .frame(width: 12, height: 12)
                } else {
                    // Awake indicator
                    Circle()
                        .fill(NapletColors.warning)
                        .frame(width: 12, height: 12)
                }
            }
            .frame(width: 24, height: 24)

            Text(isSleeping ? "dashboard.status.sleeping".localized : "dashboard.status.awake".localized)
                .font(.system(size: NapletTypography.subheadline, weight: .medium))
                .foregroundColor(NapletColors.textSecondary)
        }
        .onAppear {
            if isSleeping {
                withAnimation(
                    Animation.easeOut(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    animate = true
                }
            }
        }
        .onChange(of: isSleeping) { _, newValue in
            animate = false
            if newValue {
                withAnimation(
                    Animation.easeOut(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    animate = true
                }
            }
        }
    }
}

// MARK: - Floating Zzz Animation
struct FloatingZzzView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Text("z")
                    .font(.system(size: CGFloat(14 + index * 4), weight: .bold))
                    .foregroundColor(NapletColors.primaryPurple.opacity(0.8 - Double(index) * 0.2))
                    .offset(
                        x: CGFloat(index * 8),
                        y: animate ? CGFloat(-20 - index * 15) : 0
                    )
                    .opacity(animate ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(
                Animation.easeOut(duration: 2)
                    .repeatForever(autoreverses: false)
            ) {
                animate = true
            }
        }
    }
}

// MARK: - Circular Progress with Glow
struct GlowingCircularProgress: View {
    let progress: Double
    let lineWidth: CGFloat
    let gradient: LinearGradient

    @State private var animatedProgress: Double = 0

    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        gradient: LinearGradient = NapletColors.gradientPrimary
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.gradient = gradient
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    NapletColors.backgroundTertiary,
                    lineWidth: lineWidth
                )

            // Progress circle with glow
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    gradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: NapletColors.glowPurple, radius: 8)

            // Glow at the end point
            if animatedProgress > 0 {
                Circle()
                    .fill(NapletColors.primaryPurple)
                    .frame(width: lineWidth, height: lineWidth)
                    .offset(y: -UIScreen.main.bounds.width / 4)
                    .rotationEffect(.degrees(360 * animatedProgress - 90))
                    .shadow(color: NapletColors.glowPurple, radius: 8)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Preview
#Preview("Animated Components") {
    ZStack {
        NapletColors.background.ignoresSafeArea()

        VStack(spacing: 40) {
            AnimatedMoonIcon(size: 60)

            SleepStatusIndicator(isSleeping: true)

            PulsingCircle(color: NapletColors.primaryPurple, size: 20)

            GlowingCircularProgress(progress: 0.7)
                .frame(width: 100, height: 100)
        }
    }
}
