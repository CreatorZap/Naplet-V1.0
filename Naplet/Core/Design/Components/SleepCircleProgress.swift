import SwiftUI

// MARK: - Sleep Circle Progress
/// Componente hero do app - Círculo de progresso estilo Napper
struct SleepCircleProgress: View {
    let nextNapIn: TimeInterval
    let predictedNaps: [Date]
    let onTap: () -> Void

    @State private var animatedProgress: CGFloat = 0
    @State private var isPressed = false

    // Assuming a wake window of 2-3 hours for progress calculation
    private let maxWakeWindow: TimeInterval = 3 * 60 * 60 // 3 hours in seconds

    private var progress: CGFloat {
        let elapsed = maxWakeWindow - nextNapIn
        return min(max(elapsed / maxWakeWindow, 0), 1)
    }

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            onTap()
        }) {
            ZStack {
                // Background circle with dots for predicted naps
                predictedNapDots

                // Background track
                Circle()
                    .stroke(
                        NapletColors.backgroundTertiary,
                        lineWidth: 12
                    )
                    .frame(width: circleSize, height: circleSize)

                // Gradient progress arc
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                NapletColors.primaryPurple,
                                NapletColors.primaryPink,
                                NapletColors.primaryPurple
                            ]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: circleSize, height: circleSize)
                    .rotationEffect(.degrees(-90))

                // Glow effect on progress end
                Circle()
                    .fill(NapletColors.primaryPink)
                    .frame(width: 16, height: 16)
                    .shadow(color: NapletColors.primaryPink.opacity(0.6), radius: 8, x: 0, y: 0)
                    .offset(y: -circleSize / 2)
                    .rotationEffect(.degrees(360.0 * Double(animatedProgress) - 90.0))
                    .opacity(animatedProgress > 0.01 ? 1 : 0)

                // Center content
                centerContent
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: nextNapIn) { _, _ in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = progress
            }
        }
    }

    private var circleSize: CGFloat { 240 }

    // MARK: - Center Content
    private var centerContent: some View {
        VStack(spacing: NapletSpacing.xs) {
            Text("dashboard.nextNapIn".localized)
                .font(NapletTypography.caption(weight: .medium))
                .foregroundColor(NapletColors.textSecondary)

            Text(formatTime(nextNapIn))
                .font(NapletTypography.numberDisplay(size: 48, weight: .bold))
                .foregroundColor(NapletColors.textPrimary)

            Text(nextNapIn > 60 ? "min" : "sec")
                .font(NapletTypography.subheadline(weight: .medium))
                .foregroundColor(NapletColors.textMuted)
        }
    }

    // MARK: - Predicted Nap Dots
    private var predictedNapDots: some View {
        ZStack {
            ForEach(Array(predictedNaps.enumerated()), id: \.offset) { index, napDate in
                let angle = angleForNap(at: index, total: predictedNaps.count)
                Circle()
                    .fill(NapletColors.sleepActive.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .offset(y: -(circleSize / 2 + 24))
                    .rotationEffect(.degrees(angle))
            }
        }
    }

    // MARK: - Helpers
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)"
        }
        return "\(max(minutes, 0))"
    }

    private func angleForNap(at index: Int, total: Int) -> Double {
        guard total > 0 else { return 0 }
        // Distribute dots evenly around the circle
        let spacing = 360.0 / Double(max(total, 1))
        return spacing * Double(index) - 90
    }
}

// MARK: - Compact Sleep Circle
/// Versão menor do círculo para cards e listas
struct CompactSleepCircle: View {
    let progress: CGFloat
    let label: String
    let size: CGFloat

    @State private var animatedProgress: CGFloat = 0

    init(progress: CGFloat, label: String, size: CGFloat = 60) {
        self.progress = progress
        self.label = label
        self.size = size
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    NapletColors.backgroundTertiary,
                    lineWidth: 4
                )
                .frame(width: size, height: size)

            // Progress arc
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    NapletColors.gradientPrimary,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Center label
            Text(label)
                .font(NapletTypography.footnote(weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Sleep Timer Display
/// Display de timer grande para tela de sono ativo
struct SleepTimerDisplay: View {
    let elapsedTime: TimeInterval
    let isActive: Bool

    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            // Outer glow ring when active
            if isActive {
                Circle()
                    .stroke(
                        NapletColors.gradientPrimary,
                        lineWidth: 3
                    )
                    .frame(width: 280, height: 280)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .opacity(pulseAnimation ? 0.5 : 0.8)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
            }

            // Main circle
            Circle()
                .fill(NapletColors.backgroundSecondary)
                .frame(width: 260, height: 260)
                .shadow(
                    color: isActive ? NapletColors.primaryPurple.opacity(0.3) : .clear,
                    radius: 30,
                    x: 0,
                    y: 10
                )

            // Timer content
            VStack(spacing: NapletSpacing.sm) {
                if isActive {
                    NapletAnimatedIcon("moon.zzz.fill", size: .large, color: NapletColors.sleepActive, animation: .pulse)
                } else {
                    NapletIcon("moon.fill", size: .large, color: NapletColors.textMuted)
                }

                Text(formatElapsedTime(elapsedTime))
                    .font(NapletTypography.timerDisplay())
                    .foregroundColor(NapletColors.textPrimary)
                    .monospacedDigit()

                Text(isActive ? "Sleeping" : "Not tracking")
                    .font(NapletTypography.subheadline())
                    .foregroundColor(isActive ? NapletColors.sleepActive : NapletColors.textMuted)
            }
        }
        .onAppear {
            if isActive {
                pulseAnimation = true
            }
        }
        .onChange(of: isActive) { _, newValue in
            pulseAnimation = newValue
        }
    }

    private func formatElapsedTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Preview
#Preview("Sleep Circle Progress") {
    ZStack {
        NapletColors.background
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: NapletSpacing.xxl) {
                // Main sleep circle
                VStack(spacing: NapletSpacing.md) {
                    Text("Main Circle")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    SleepCircleProgress(
                        nextNapIn: 45 * 60, // 45 minutes
                        predictedNaps: [
                            Date().addingTimeInterval(45 * 60),
                            Date().addingTimeInterval(3 * 60 * 60),
                            Date().addingTimeInterval(6 * 60 * 60)
                        ]
                    ) {
                        #if DEBUG
                        print("Circle tapped")
                        #endif
                    }
                }

                // Compact circles
                VStack(spacing: NapletSpacing.md) {
                    Text("Compact Circles")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    HStack(spacing: NapletSpacing.lg) {
                        CompactSleepCircle(progress: 0.25, label: "25%")
                        CompactSleepCircle(progress: 0.5, label: "50%")
                        CompactSleepCircle(progress: 0.75, label: "75%")
                        CompactSleepCircle(progress: 1.0, label: "100%")
                    }
                }

                // Timer displays
                VStack(spacing: NapletSpacing.lg) {
                    Text("Timer Displays")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    SleepTimerDisplay(elapsedTime: 3725, isActive: true) // 1h 2m 5s

                    SleepTimerDisplay(elapsedTime: 0, isActive: false)
                }
            }
            .padding()
        }
    }
}
