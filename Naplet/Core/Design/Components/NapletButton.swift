import SwiftUI

// MARK: - Naplet Button Styles
enum NapletButtonStyle {
    case primary
    case secondary
    case ghost
    case destructive
}

// MARK: - Naplet Button Size
enum NapletButtonSize {
    case small
    case medium
    case large

    var height: CGFloat {
        switch self {
        case .small: return NapletSpacing.buttonHeightSmall
        case .medium: return NapletSpacing.buttonHeightMedium
        case .large: return NapletSpacing.buttonHeightLarge
        }
    }

    var font: Font {
        switch self {
        case .small: return NapletTypography.footnote(weight: .semibold)
        case .medium: return NapletTypography.callout(weight: .semibold)
        case .large: return NapletTypography.headline(weight: .semibold)
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return NapletSpacing.md
        case .medium: return NapletSpacing.lg
        case .large: return NapletSpacing.xl
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }
}

// MARK: - Naplet Button
struct NapletButton: View {
    let title: String
    let style: NapletButtonStyle
    let size: NapletButtonSize
    let icon: String?
    let isLoading: Bool
    let isDisabled: Bool
    let isFullWidth: Bool
    let action: () -> Void

    @State private var isPressed = false

    init(
        _ title: String,
        style: NapletButtonStyle = .primary,
        size: NapletButtonSize = .medium,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        isFullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.isFullWidth = isFullWidth
        self.action = action
    }

    var body: some View {
        Button {
            guard !isLoading && !isDisabled else { return }
            triggerHaptic()
            action()
        } label: {
            HStack(spacing: NapletSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: size.iconSize, weight: .semibold))
                    }
                    Text(title)
                        .font(size.font)
                }
            }
            .foregroundColor(textColor)
            .frame(height: size.height)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, size.horizontalPadding)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
            .overlay(overlayView)
        }
        .disabled(isLoading || isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }

    // MARK: - Haptic Feedback
    private func triggerHaptic() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    // MARK: - Style Properties

    private var textColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return NapletColors.primaryPurple
        case .ghost:
            return NapletColors.primaryPurple
        case .destructive:
            return .white
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            NapletColors.gradientPrimary
        case .secondary:
            Color.clear
        case .ghost:
            Color.clear
        case .destructive:
            NapletColors.error
        }
    }

    @ViewBuilder
    private var overlayView: some View {
        switch style {
        case .primary:
            EmptyView()
        case .secondary:
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .stroke(NapletColors.primaryPurple, lineWidth: 1.5)
        case .ghost:
            EmptyView()
        case .destructive:
            EmptyView()
        }
    }
}

// MARK: - Preview
#Preview("Button Styles") {
    ZStack {
        NapletColors.background
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: NapletSpacing.lg) {
                // Primary Buttons
                VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                    Text("Primary")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    NapletButton("Small Primary", style: .primary, size: .small) {}
                    NapletButton("Medium Primary", style: .primary, size: .medium) {}
                    NapletButton("Large Primary", style: .primary, size: .large, isFullWidth: true) {}
                    NapletButton("With Icon", style: .primary, size: .medium, icon: "moon.fill") {}
                }

                Divider().background(NapletColors.backgroundTertiary)

                // Secondary Buttons
                VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                    Text("Secondary")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    NapletButton("Small Secondary", style: .secondary, size: .small) {}
                    NapletButton("Medium Secondary", style: .secondary, size: .medium) {}
                    NapletButton("Large Secondary", style: .secondary, size: .large, isFullWidth: true) {}
                }

                Divider().background(NapletColors.backgroundTertiary)

                // Ghost Buttons
                VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                    Text("Ghost")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    NapletButton("Small Ghost", style: .ghost, size: .small) {}
                    NapletButton("Medium Ghost", style: .ghost, size: .medium) {}
                    NapletButton("Large Ghost", style: .ghost, size: .large, isFullWidth: true) {}
                }

                Divider().background(NapletColors.backgroundTertiary)

                // States
                VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                    Text("States")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    NapletButton("Loading...", style: .primary, size: .medium, isLoading: true, isFullWidth: true) {}
                    NapletButton("Disabled", style: .primary, size: .medium, isDisabled: true, isFullWidth: true) {}
                    NapletButton("Loading Secondary", style: .secondary, size: .medium, isLoading: true, isFullWidth: true) {}
                }
            }
            .padding()
        }
    }
}
