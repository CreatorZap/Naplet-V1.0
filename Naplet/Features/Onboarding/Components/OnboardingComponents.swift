import SwiftUI

// MARK: - BadgeStyle
/// Style options for ExclusiveBadge
enum BadgeStyle {
    case exclusive
    case bestValue
    case new

    var backgroundColor: Color {
        switch self {
        case .exclusive:
            return NapletColors.primaryPurple.opacity(0.2)
        case .bestValue:
            return NapletColors.success.opacity(0.2)
        case .new:
            return NapletColors.primaryPink.opacity(0.2)
        }
    }

    var textColor: Color {
        switch self {
        case .exclusive:
            return NapletColors.primaryPurple
        case .bestValue:
            return NapletColors.success
        case .new:
            return NapletColors.primaryPink
        }
    }
}

// MARK: - MicrocopyText
/// Component for explanatory microcopy in onboarding steps
struct MicrocopyText: View {
    let text: String
    var iconName: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let icon = iconName {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(NapletColors.textMuted)
            }

            Text(text)
                .font(.caption)
                .foregroundColor(NapletColors.textMuted)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - ExclusiveBadge
/// Badge to highlight exclusive features in onboarding
struct ExclusiveBadge: View {
    let text: String
    var style: BadgeStyle = .exclusive

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(style.textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(style.backgroundColor)
            .cornerRadius(4)
    }
}

// MARK: - SocialProofBanner
/// Social proof banner for onboarding welcome screen
struct SocialProofBanner: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.3.fill")
                .font(.caption)
                .foregroundColor(NapletColors.primaryPurple)

            Text(text)
                .font(.caption)
                .foregroundColor(NapletColors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(NapletColors.backgroundSecondary)
        .cornerRadius(20)
    }
}

// MARK: - OnboardingTipCard
/// Tip card for completion screen with recommended action
struct OnboardingTipCard: View {
    let title: String
    let text: String
    var iconName: String = "lightbulb.fill"

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(NapletColors.warning)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(NapletColors.textPrimary)

                Text(text)
                    .font(.caption)
                    .foregroundColor(NapletColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(NapletColors.backgroundSecondary)
        .cornerRadius(12)
    }
}

// MARK: - OnboardingDifferentialCard
/// Card for differentials screen with badge support
struct OnboardingDifferentialCard: View {
    let iconName: String
    let title: String
    let description: String
    var badgeText: String? = nil
    var badgeStyle: BadgeStyle = .exclusive

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(NapletColors.primaryPurple)
                .frame(width: 40, height: 40)
                .background(NapletColors.primaryPurple.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(NapletColors.textPrimary)

                    if let badge = badgeText {
                        ExclusiveBadge(text: badge, style: badgeStyle)
                    }
                }

                Text(description)
                    .font(.caption)
                    .foregroundColor(NapletColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(NapletColors.backgroundSecondary)
        .cornerRadius(12)
    }
}

// MARK: - Onboarding Progress Indicator (Apple Style)
struct OnboardingProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    var showStepText: Bool = true

    private var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStep + 1) / Double(totalSteps)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Barra de progresso contínua (estilo Apple)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(NapletColors.backgroundTertiary)
                        .frame(height: 4)

                    // Progress
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 4)

            // Texto "X de Y" discreto
            if showStepText {
                Text("\(currentStep + 1) \("common.of".localized) \(totalSteps)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(NapletColors.textMuted)
            }
        }
        .padding(.horizontal, NapletSpacing.lg)
    }
}

// MARK: - Onboarding Primary Button
struct OnboardingPrimaryButton: View {
    let title: String
    let icon: String?
    let isDisabled: Bool
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: {
            if !isDisabled && !isLoading {
                HapticManager.shared.lightImpact()
            }
            action()
        }) {
            HStack(spacing: NapletSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.body.weight(.semibold))
                    }
                    Text(title)
                        .font(NapletTypography.body(weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NapletSpacing.md)
            .background(
                LinearGradient(
                    colors: isDisabled ? [NapletColors.backgroundTertiary, NapletColors.backgroundTertiary] : [NapletColors.primaryPurple, NapletColors.primaryPink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .disabled(isDisabled || isLoading)
        .padding(.horizontal, NapletSpacing.lg)
    }
}

// MARK: - Onboarding Secondary Button
struct OnboardingSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: NapletSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body.weight(.medium))
                }
                Text(title)
                    .font(NapletTypography.body(weight: .medium))
            }
            .foregroundColor(NapletColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NapletSpacing.md)
            .background(NapletColors.backgroundSecondary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(NapletColors.backgroundTertiary, lineWidth: 1)
            )
        }
        .padding(.horizontal, NapletSpacing.lg)
    }
}

// MARK: - Onboarding Text Button
struct OnboardingTextButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(NapletTypography.subheadline())
                .foregroundColor(NapletColors.textSecondary)
        }
    }
}

// MARK: - Onboarding Back Button
struct OnboardingBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.title2.weight(.medium))
                .foregroundColor(NapletColors.textSecondary)
                .frame(width: 44, height: 44)
        }
    }
}

// MARK: - Benefit Card
struct BenefitCard: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color

    init(icon: String, title: String, description: String, iconColor: Color = NapletColors.primaryPurple) {
        self.icon = icon
        self.title = title
        self.description = description
        self.iconColor = iconColor
    }

    var body: some View {
        HStack(alignment: .top, spacing: NapletSpacing.md) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: NapletSpacing.xs) {
                Text(title)
                    .font(NapletTypography.headline())
                    .foregroundColor(NapletColors.textPrimary)

                Text(description)
                    .font(NapletTypography.subheadline())
                    .foregroundColor(NapletColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(NapletSpacing.md)
        .background(NapletColors.backgroundSecondary)
        .cornerRadius(16)
    }
}

// MARK: - Selectable Option Card
struct SelectableOptionCard: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    init(_ title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            HStack(spacing: NapletSpacing.md) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundColor(isSelected ? NapletColors.primaryPurple : NapletColors.textSecondary)
                        .frame(width: 24)
                }

                Text(title)
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textPrimary)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? NapletColors.primaryPurple : NapletColors.backgroundTertiary, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(NapletColors.primaryPurple)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(NapletSpacing.md)
            .background(isSelected ? NapletColors.primaryPurple.opacity(0.1) : NapletColors.backgroundSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? NapletColors.primaryPurple : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Selectable Checkbox Card
struct SelectableCheckboxCard: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    init(_ title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            HStack(spacing: NapletSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? NapletColors.primaryPurple : NapletColors.backgroundTertiary, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(NapletColors.primaryPurple)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                    }
                }

                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundColor(isSelected ? NapletColors.primaryPurple : NapletColors.textSecondary)
                        .frame(width: 24)
                }

                Text(title)
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textPrimary)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(NapletSpacing.md)
            .background(isSelected ? NapletColors.primaryPurple.opacity(0.1) : NapletColors.backgroundSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? NapletColors.primaryPurple : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Confirmation Row
struct ConfirmationRow: View {
    let label: String
    let value: String
    let onEdit: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(NapletTypography.caption())
                    .foregroundColor(NapletColors.textSecondary)

                Text(value)
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textPrimary)
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.body)
                    .foregroundColor(NapletColors.primaryPurple)
            }
        }
        .padding(NapletSpacing.md)
    }
}

// MARK: - Loading Spinner
struct OnboardingLoadingView: View {
    let message: String

    var body: some View {
        VStack(spacing: NapletSpacing.xl) {
            // Animated spinner
            ZStack {
                Circle()
                    .stroke(NapletColors.backgroundTertiary, lineWidth: 4)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .modifier(RotatingModifier())
            }

            Text(message)
                .font(NapletTypography.body())
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut, value: message)
        }
    }
}

// MARK: - Rotating Modifier
struct RotatingModifier: ViewModifier {
    @State private var isRotating = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(
                .linear(duration: 1)
                .repeatForever(autoreverses: false),
                value: isRotating
            )
            .onAppear {
                isRotating = true
            }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var animate = false

    let colors: [Color] = [
        NapletColors.primaryPurple,
        NapletColors.primaryPink,
        NapletColors.primaryBlue,
        NapletColors.primaryCyan,
        NapletColors.warning,
        NapletColors.success
    ]

    var body: some View {
        ZStack {
            ForEach(0..<30, id: \.self) { index in
                ConfettiPiece(color: colors[index % colors.count])
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: animate ? CGFloat.random(in: 200...600) : -100
                    )
                    .rotationEffect(.degrees(animate ? Double.random(in: 0...360) : 0))
                    .opacity(animate ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2)) {
                animate = true
            }
        }
    }
}

struct ConfettiPiece: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 8, height: 14)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        NapletColors.background.ignoresSafeArea()

        VStack(spacing: 20) {
            OnboardingProgressIndicator(currentStep: 2, totalSteps: 12)

            BenefitCard(
                icon: "brain.head.profile",
                title: "Menos estresse",
                description: "Saiba exatamente quando seu bebê precisa dormir."
            )

            SelectableOptionCard("Instagram / Facebook", icon: "camera.fill", isSelected: true) {}

            SelectableCheckboxCard("Sonecas mais longas", icon: "bed.double.fill", isSelected: true) {}

            OnboardingPrimaryButton("Continuar", icon: "arrow.right") {}

            OnboardingSecondaryButton("Já tenho um convite", icon: "ticket.fill") {}

            OnboardingTextButton(title: "Pular por enquanto") {}
        }
        .padding()
    }
}
