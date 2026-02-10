import SwiftUI

// MARK: - Action Button
/// Botão de ação rápida do dashboard estilo Napper (Acordar, Soneca, Mamadeira, etc)
struct ActionButton: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    @State private var isPressed = false

    init(
        icon: String,
        iconColor: Color = NapletColors.primaryPurple,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        } label: {
            VStack(spacing: NapletSpacing.sm) {
                // Icon container with 3D-style effect
                ZStack {
                    // Background shadow layer
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                        .offset(y: 2)

                    // Main icon circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    iconColor.opacity(0.2),
                                    iconColor.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 56, height: 56)

                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                // Labels
                VStack(spacing: 2) {
                    Text(title)
                        .font(NapletTypography.subheadline(weight: .semibold))
                        .foregroundColor(NapletColors.textPrimary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(NapletTypography.caption())
                        .foregroundColor(NapletColors.textMuted)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NapletSpacing.md)
            .padding(.horizontal, NapletSpacing.sm)
            .background(NapletColors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Action Button Grid
/// Grid de botões de ação para o dashboard
struct ActionButtonGrid: View {
    let actions: [ActionItem]
    let columns: Int

    init(actions: [ActionItem], columns: Int = 2) {
        self.actions = actions
        self.columns = columns
    }

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: NapletSpacing.md), count: columns),
            spacing: NapletSpacing.md
        ) {
            ForEach(actions) { action in
                ActionButton(
                    icon: action.icon,
                    iconColor: action.iconColor,
                    title: action.title,
                    subtitle: action.subtitle,
                    action: action.action
                )
            }
        }
    }
}

// MARK: - Action Item Model
struct ActionItem: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    init(
        icon: String,
        iconColor: Color = NapletColors.primaryPurple,
        title: String,
        subtitle: String,
        action: @escaping () -> Void = {}
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
}

// MARK: - Quick Action Button
/// Botão de ação rápida compacto (para usar em linha)
struct QuickActionButton: View {
    let icon: String
    let iconColor: Color
    let label: String
    let action: () -> Void

    @State private var isPressed = false

    init(
        icon: String,
        iconColor: Color = NapletColors.primaryPurple,
        label: String,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.label = label
        self.action = action
    }

    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        } label: {
            HStack(spacing: NapletSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)

                Text(label)
                    .font(NapletTypography.subheadline(weight: .medium))
                    .foregroundColor(NapletColors.textPrimary)
            }
            .padding(.horizontal, NapletSpacing.md)
            .padding(.vertical, NapletSpacing.sm)
            .background(NapletColors.backgroundSecondary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Large Action Button
/// Botão de ação grande para ações primárias (ex: iniciar sono)
struct LargeActionButton: View {
    let icon: String
    let title: String
    let subtitle: String?
    let isActive: Bool
    let action: () -> Void

    @State private var isPressed = false

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isActive = isActive
        self.action = action
    }

    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            action()
        } label: {
            HStack(spacing: NapletSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isActive ? NapletColors.sleepActive.opacity(0.2) : NapletColors.backgroundTertiary)
                        .frame(width: 64, height: 64)

                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(isActive ? NapletColors.sleepActive : NapletColors.primaryPurple)
                }

                // Labels
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(NapletTypography.subheadline())
                            .foregroundColor(NapletColors.textSecondary)
                    }
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(NapletColors.textMuted)
            }
            .padding(NapletSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(NapletColors.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isActive ? NapletColors.sleepActive.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: isActive ? NapletColors.sleepActive.opacity(0.2) : NapletColors.primaryPurple.opacity(0.08),
                radius: isActive ? 15 : 10,
                x: 0,
                y: 5
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview
#Preview("Action Buttons") {
    ZStack {
        NapletColors.background
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: NapletSpacing.xl) {
                // Single Action Buttons
                VStack(alignment: .leading, spacing: NapletSpacing.md) {
                    Text("Action Buttons")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    HStack(spacing: NapletSpacing.md) {
                        ActionButton(
                            icon: "sun.max.fill",
                            iconColor: NapletColors.awakeColor,
                            title: "Wake Up",
                            subtitle: "2h 15min ago"
                        ) {}

                        ActionButton(
                            icon: "moon.zzz.fill",
                            iconColor: NapletColors.sleepActive,
                            title: "Nap",
                            subtitle: "Not tracked"
                        ) {}
                    }

                    HStack(spacing: NapletSpacing.md) {
                        ActionButton(
                            icon: "drop.fill",
                            iconColor: NapletColors.primaryBlue,
                            title: "Feeding",
                            subtitle: "45 min ago"
                        ) {}

                        ActionButton(
                            icon: "heart.fill",
                            iconColor: NapletColors.primaryPink,
                            title: "Diaper",
                            subtitle: "1h ago"
                        ) {}
                    }
                }

                // Action Button Grid
                VStack(alignment: .leading, spacing: NapletSpacing.md) {
                    Text("Action Grid (2 columns)")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    ActionButtonGrid(actions: [
                        ActionItem(icon: "sun.max.fill", iconColor: NapletColors.awakeColor, title: "Wake Up", subtitle: "Track wake time"),
                        ActionItem(icon: "moon.zzz.fill", iconColor: NapletColors.sleepActive, title: "Nap", subtitle: "Start nap timer"),
                        ActionItem(icon: "drop.fill", iconColor: NapletColors.primaryBlue, title: "Feeding", subtitle: "Log feeding"),
                        ActionItem(icon: "heart.fill", iconColor: NapletColors.primaryPink, title: "Diaper", subtitle: "Log change")
                    ])
                }

                // Quick Action Buttons
                VStack(alignment: .leading, spacing: NapletSpacing.md) {
                    Text("Quick Actions")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: NapletSpacing.sm) {
                            QuickActionButton(icon: "plus", iconColor: NapletColors.success, label: "Add") {}
                            QuickActionButton(icon: "pencil", iconColor: NapletColors.primaryPurple, label: "Edit") {}
                            QuickActionButton(icon: "chart.bar.fill", iconColor: NapletColors.primaryBlue, label: "Stats") {}
                            QuickActionButton(icon: "bell.fill", iconColor: NapletColors.warning, label: "Remind") {}
                        }
                    }
                }

                // Large Action Buttons
                VStack(alignment: .leading, spacing: NapletSpacing.md) {
                    Text("Large Actions")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    LargeActionButton(
                        icon: "moon.zzz.fill",
                        title: "Start Sleep Tracking",
                        subtitle: "Tap to begin tracking sleep",
                        isActive: false
                    ) {}

                    LargeActionButton(
                        icon: "moon.zzz.fill",
                        title: "Currently Sleeping",
                        subtitle: "1h 23min - Tap to stop",
                        isActive: true
                    ) {}
                }
            }
            .padding()
        }
    }
}
