import SwiftUI

// MARK: - Breast Feeding Start Sheet
struct BreastFeedingStartSheet: View {
    @ObservedObject var viewModel: FeedingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            NapletColors.background
                .ignoresSafeArea()

            VStack(spacing: NapletSpacing.xl) {
                // Drag Indicator
                Capsule()
                    .fill(NapletColors.textMuted.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, NapletSpacing.sm)

                // Header
                VStack(spacing: NapletSpacing.sm) {
                    Image(systemName: "figure.and.child.holdinghands")
                        .font(.system(size: 48))
                        .foregroundColor(NapletColors.primaryPurple)

                    Text("feeding.breast.start".localized)
                        .font(NapletTypography.title2())
                        .foregroundColor(NapletColors.textPrimary)

                    Text("feeding.breast.selectSide".localized)
                        .font(NapletTypography.body())
                        .foregroundColor(NapletColors.textSecondary)
                }
                .padding(.top, NapletSpacing.md)

                // Side Selection
                HStack(spacing: NapletSpacing.lg) {
                    SideSelectionButton(
                        side: .left,
                        isSuggested: viewModel.suggestedSide == .left
                    ) {
                        startFeeding(side: .left)
                    }

                    SideSelectionButton(
                        side: .right,
                        isSuggested: viewModel.suggestedSide == .right
                    ) {
                        startFeeding(side: .right)
                    }
                }
                .padding(.horizontal, NapletSpacing.lg)

                // Last side info
                if let lastSide = viewModel.lastBreastSide {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                        Text("feeding.breast.lastSide".localized(with: lastSide.displayName))
                            .font(NapletTypography.caption())
                    }
                    .foregroundColor(NapletColors.textMuted)
                }

                Spacer()
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }

    private func startFeeding(side: BreastSide) {
        Task {
            await viewModel.startBreastFeeding(side: side)
            dismiss()
        }
    }
}

// MARK: - Side Selection Button
struct SideSelectionButton: View {
    let side: BreastSide
    let isSuggested: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: NapletSpacing.md) {
                // Side indicator
                ZStack {
                    Circle()
                        .fill(NapletColors.primaryPurple.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Text(side.shortName)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(NapletColors.primaryPurple)
                }

                // Label
                Text(side.displayName)
                    .font(NapletTypography.headline())
                    .foregroundColor(NapletColors.textPrimary)

                // Suggested badge
                if isSuggested {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                        Text("feeding.suggested".localized)
                            .font(NapletTypography.caption(weight: .medium))
                    }
                    .foregroundColor(NapletColors.success)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(NapletColors.success.opacity(0.1))
                    .cornerRadius(12)
                } else {
                    // Placeholder for alignment
                    Text(" ")
                        .font(NapletTypography.caption())
                        .padding(.vertical, 6)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NapletSpacing.lg)
            .background(NapletColors.cardBackground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSuggested ? NapletColors.success : NapletColors.cardBackground, lineWidth: 2)
            )
        }
    }
}

// MARK: - Breast Feeding Active View
struct BreastFeedingActiveView: View {
    @ObservedObject var viewModel: FeedingViewModel

    var body: some View {
        VStack(spacing: NapletSpacing.xl) {
            // Main timer display
            VStack(spacing: NapletSpacing.sm) {
                Text("feeding.totalTime".localized)
                    .font(NapletTypography.caption())
                    .foregroundColor(NapletColors.textMuted)

                Text(viewModel.totalBreastTimeFormatted)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(NapletColors.textPrimary)
            }

            // Side timers with switch
            HStack(spacing: NapletSpacing.lg) {
                // Left side
                BreastSideTimerLarge(
                    side: .left,
                    time: viewModel.leftTimeFormatted,
                    isActive: viewModel.currentSide == .left
                ) {
                    viewModel.switchSide(to: .left)
                }

                // Switch button
                VStack(spacing: NapletSpacing.sm) {
                    Button {
                        let newSide: BreastSide = viewModel.currentSide == .left ? .right : .left
                        viewModel.switchSide(to: newSide)
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 24))
                            .foregroundColor(NapletColors.primaryPurple)
                            .frame(width: 50, height: 50)
                            .background(NapletColors.primaryPurple.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Text("feeding.switch".localized)
                        .font(NapletTypography.caption())
                        .foregroundColor(NapletColors.textMuted)
                }

                // Right side
                BreastSideTimerLarge(
                    side: .right,
                    time: viewModel.rightTimeFormatted,
                    isActive: viewModel.currentSide == .right
                ) {
                    viewModel.switchSide(to: .right)
                }
            }
            .padding(.horizontal, NapletSpacing.md)

            // Current side indicator
            HStack {
                Circle()
                    .fill(NapletColors.success)
                    .frame(width: 8, height: 8)

                Text("feeding.currentSide".localized(with: viewModel.currentSide.displayName))
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textSecondary)
            }
        }
    }
}

// MARK: - Breast Side Timer Large
struct BreastSideTimerLarge: View {
    let side: BreastSide
    let time: String
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: NapletSpacing.sm) {
                // Side letter
                Text(side.shortName)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(isActive ? NapletColors.primaryPurple : NapletColors.textMuted)

                // Timer
                Text(time)
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .foregroundColor(isActive ? NapletColors.textPrimary : NapletColors.textSecondary)

                // Side name
                Text(side.displayName)
                    .font(NapletTypography.caption())
                    .foregroundColor(NapletColors.textMuted)
            }
            .frame(width: 120, height: 140)
            .background(isActive ? NapletColors.primaryPurple.opacity(0.1) : NapletColors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isActive ? NapletColors.primaryPurple : Color.clear, lineWidth: 3)
            )
            .shadow(
                color: isActive ? NapletColors.primaryPurple.opacity(0.3) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
    }
}

// MARK: - Preview
#Preview("Start Sheet") {
    BreastFeedingStartSheet(viewModel: FeedingViewModel(baby: Baby.preview))
}
