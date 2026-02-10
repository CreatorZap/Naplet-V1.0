import SwiftUI

// MARK: - Feeding View
struct FeedingView: View {
    @StateObject private var viewModel: FeedingViewModel
    @Environment(\.dismiss) private var dismiss

    init(baby: Baby) {
        _viewModel = StateObject(wrappedValue: FeedingViewModel(baby: baby))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.todayRecords.isEmpty && viewModel.activeRecord == nil {
                VStack {
                    // Drag Indicator
                    Capsule()
                        .fill(NapletColors.textMuted.opacity(0.3))
                        .frame(width: 36, height: 5)
                        .padding(.top, NapletSpacing.sm)

                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: NapletColors.primaryPurple))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: NapletSpacing.lg) {
                        // Drag Indicator
                        Capsule()
                            .fill(NapletColors.textMuted.opacity(0.3))
                            .frame(width: 36, height: 5)
                            .padding(.top, NapletSpacing.sm)

                        // Title
                        Text("feeding.title".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(NapletColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, NapletSpacing.lg)

                        // Active Session or Type Selector
                        if viewModel.activeRecord != nil {
                            activeSessionCard
                        } else {
                            feedingTypeSelector
                        }

                        // Today's Statistics
                        statisticsCard

                        // Today's History
                        if !viewModel.todayRecords.isEmpty {
                            todayHistorySection
                        } else {
                            emptyState
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.top, NapletSpacing.sm)
                }
            }
        }
        .background(NapletColors.background)
        .alert("common.error".localized, isPresented: $viewModel.showError) {
            Button("common.ok".localized, role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "error.generic".localized)
        }
        .alert("common.success".localized, isPresented: $viewModel.showSuccess) {
            Button("common.ok".localized) {}
        } message: {
            Text(viewModel.successMessage ?? "feeding.saved".localized)
        }
        .sheet(isPresented: $viewModel.showFeedingSheet) {
            feedingSheetContent
        }
        .task {
            await viewModel.loadData()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }

    // MARK: - Feeding Type Selector
    private var feedingTypeSelector: some View {
        VStack(spacing: NapletSpacing.md) {
            Text("feeding.selectType".localized)
                .font(NapletTypography.headline())
                .foregroundColor(NapletColors.textPrimary)

            HStack(spacing: NapletSpacing.md) {
                ForEach(FeedingType.allCases, id: \.self) { type in
                    FeedingTypeButton(
                        type: type,
                        isSelected: viewModel.selectedFeedingType == type
                    ) {
                        viewModel.selectedFeedingType = type
                        viewModel.showFeedingSheet = true
                    }
                }
            }

            // Last feeding info
            if viewModel.statistics.lastFeeding != nil {
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text("feeding.lastFeeding".localized(with: viewModel.statistics.lastFeedingTimeAgo ?? ""))
                        .font(NapletTypography.caption())
                }
                .foregroundColor(NapletColors.textMuted)
                .padding(.top, NapletSpacing.sm)
            }
        }
        .padding(NapletSpacing.lg)
    }

    // MARK: - Active Session Card
    private var activeSessionCard: some View {
        NapletCard {
            VStack(spacing: NapletSpacing.lg) {
                // Type indicator
                HStack {
                    Image(systemName: viewModel.activeRecord?.type.icon ?? "circle")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.activeRecord?.type.color ?? NapletColors.primaryPurple)

                    Text(viewModel.activeRecord?.type.displayName ?? "")
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)

                    Spacer()

                    // Pulsing indicator
                    Circle()
                        .fill(NapletColors.success)
                        .frame(width: 12, height: 12)
                        .modifier(PulsingAnimation())
                }

                if viewModel.activeRecord?.type == .breast {
                    breastFeedingTimer
                } else if viewModel.activeRecord?.type == .bottle {
                    bottleFeedingTimer
                }

                // Stop Button
                Button {
                    Task {
                        await viewModel.stopFeeding()
                    }
                } label: {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("feeding.stop".localized)
                    }
                    .font(NapletTypography.body(weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, NapletSpacing.md)
                    .background(NapletColors.error)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, NapletSpacing.lg)
    }

    // MARK: - Breast Feeding Timer
    private var breastFeedingTimer: some View {
        VStack(spacing: NapletSpacing.md) {
            // Total time
            Text(viewModel.totalBreastTimeFormatted)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(NapletColors.textPrimary)

            // Side timers
            HStack(spacing: NapletSpacing.xl) {
                // Left side
                BreastSideTimer(
                    side: .left,
                    time: viewModel.leftTimeFormatted,
                    isActive: viewModel.currentSide == .left,
                    isSuggested: viewModel.suggestedSide == .left
                ) {
                    viewModel.switchSide(to: .left)
                }

                // Divider
                Rectangle()
                    .fill(NapletColors.cardBackground)
                    .frame(width: 2, height: 80)

                // Right side
                BreastSideTimer(
                    side: .right,
                    time: viewModel.rightTimeFormatted,
                    isActive: viewModel.currentSide == .right,
                    isSuggested: viewModel.suggestedSide == .right
                ) {
                    viewModel.switchSide(to: .right)
                }
            }
        }
    }

    // MARK: - Bottle Feeding Timer
    private var bottleFeedingTimer: some View {
        VStack(spacing: NapletSpacing.md) {
            // Total time
            Text(viewModel.totalTimeFormatted)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(NapletColors.textPrimary)

            // Amount selector
            VStack(spacing: NapletSpacing.sm) {
                Text("feeding.amount".localized)
                    .font(NapletTypography.caption())
                    .foregroundColor(NapletColors.textMuted)

                HStack(spacing: NapletSpacing.md) {
                    Button {
                        if viewModel.bottleAmount > 10 {
                            viewModel.bottleAmount -= 10
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(NapletColors.primaryPurple)
                    }

                    Text("\(Int(viewModel.bottleAmount)) ml")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(NapletColors.textPrimary)
                        .frame(width: 100)

                    Button {
                        viewModel.bottleAmount += 10
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(NapletColors.primaryPurple)
                    }
                }

                // Type selector
                Picker("", selection: $viewModel.bottleType) {
                    ForEach(BottleContentType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.top, NapletSpacing.sm)
            }
        }
    }

    // MARK: - Statistics Card
    private var statisticsCard: some View {
        NapletCard {
            VStack(spacing: NapletSpacing.md) {
                HStack {
                    Text("feeding.todayStats".localized)
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)
                    Spacer()
                }

                HStack(spacing: NapletSpacing.lg) {
                    StatItem(
                        icon: "figure.and.child.holdinghands",
                        value: "\(viewModel.statistics.breastFeedingCount)",
                        label: "feeding.stats.breast".localized,
                        color: NapletColors.primaryPurple
                    )

                    StatItem(
                        icon: "waterbottle",
                        value: "\(Int(viewModel.statistics.bottleTotalMl)) ml",
                        label: "feeding.stats.bottle".localized,
                        color: NapletColors.info
                    )

                    StatItem(
                        icon: "fork.knife",
                        value: "\(viewModel.statistics.solidFeedingCount)",
                        label: "feeding.stats.solid".localized,
                        color: NapletColors.warning
                    )
                }
            }
        }
        .padding(.horizontal, NapletSpacing.lg)
    }

    // MARK: - Today History Section
    private var todayHistorySection: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            Text("feeding.todayHistory".localized)
                .font(NapletTypography.caption(weight: .semibold))
                .foregroundColor(NapletColors.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, NapletSpacing.lg)

            VStack(spacing: NapletSpacing.sm) {
                ForEach(viewModel.todayRecords) { record in
                    FeedingHistoryRow(record: record) {
                        Task {
                            await viewModel.deleteRecord(record)
                        }
                    }
                }
            }
            .padding(.horizontal, NapletSpacing.lg)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: NapletSpacing.md) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 48))
                .foregroundColor(NapletColors.textMuted)

            Text("feeding.empty.title".localized)
                .font(NapletTypography.headline())
                .foregroundColor(NapletColors.textPrimary)

            Text("feeding.empty.subtitle".localized)
                .font(NapletTypography.body())
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(NapletSpacing.xl)
    }

    // MARK: - Feeding Sheet Content
    @ViewBuilder
    private var feedingSheetContent: some View {
        switch viewModel.selectedFeedingType {
        case .breast:
            BreastFeedingStartSheet(viewModel: viewModel)
        case .bottle:
            BottleFeedingSheet(viewModel: viewModel)
        case .solid:
            SolidFeedingSheet(viewModel: viewModel)
        case .pumping:
            PumpingSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Feeding Type Button
struct FeedingTypeButton: View {
    let type: FeedingType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: NapletSpacing.sm) {
                Image(systemName: type.icon)
                    .font(.system(size: 28))
                    .foregroundColor(type.color)
                    .frame(width: 60, height: 60)
                    .background(type.color.opacity(0.1))
                    .clipShape(Circle())

                Text(type.displayName)
                    .font(NapletTypography.caption(weight: .medium))
                    .foregroundColor(NapletColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NapletSpacing.md)
            .background(NapletColors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Breast Side Timer
struct BreastSideTimer: View {
    let side: BreastSide
    let time: String
    let isActive: Bool
    let isSuggested: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: NapletSpacing.sm) {
                // Side indicator
                Text(side.shortName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isActive ? NapletColors.primaryPurple : NapletColors.textMuted)

                // Time
                Text(time)
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .foregroundColor(isActive ? NapletColors.textPrimary : NapletColors.textSecondary)

                // Suggested badge
                if isSuggested && !isActive {
                    Text("feeding.suggested".localized)
                        .font(NapletTypography.caption())
                        .foregroundColor(NapletColors.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(NapletColors.success.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .frame(width: 100, height: 100)
            .background(isActive ? NapletColors.primaryPurple.opacity(0.1) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? NapletColors.primaryPurple : NapletColors.cardBackground, lineWidth: 2)
            )
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(NapletTypography.body(weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)

            Text(label)
                .font(NapletTypography.caption())
                .foregroundColor(NapletColors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Feeding History Row
struct FeedingHistoryRow: View {
    let record: FeedingRecord
    let onDelete: () -> Void

    @State private var showDeleteAlert = false

    var body: some View {
        NapletCard {
            HStack(spacing: NapletSpacing.md) {
                // Type icon
                Image(systemName: record.type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(record.type.color)
                    .frame(width: 40, height: 40)
                    .background(record.type.color.opacity(0.1))
                    .clipShape(Circle())

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.type.displayName)
                        .font(NapletTypography.body(weight: .medium))
                        .foregroundColor(NapletColors.textPrimary)

                    Text(formatRecordDetails(record))
                        .font(NapletTypography.caption())
                        .foregroundColor(NapletColors.textSecondary)
                }

                Spacer()

                // Time
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatTime(record.startTime))
                        .font(NapletTypography.body(weight: .medium))
                        .foregroundColor(NapletColors.textPrimary)

                    if record.endTime == nil {
                        Text("feeding.active".localized)
                            .font(NapletTypography.caption())
                            .foregroundColor(NapletColors.success)
                    }
                }

                // Delete button
                if record.endTime != nil {
                    Button {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(NapletColors.error.opacity(0.7))
                    }
                }
            }
        }
        .alert("feeding.delete.title".localized, isPresented: $showDeleteAlert) {
            Button("common.cancel".localized, role: .cancel) {}
            Button("common.delete".localized, role: .destructive) {
                onDelete()
            }
        } message: {
            Text("feeding.delete.confirm".localized)
        }
    }

    private func formatRecordDetails(_ record: FeedingRecord) -> String {
        switch record.type {
        case .breast:
            let sides = [
                record.durationLeftSeconds.map { "E: \(formatDuration($0))" },
                record.durationRightSeconds.map { "D: \(formatDuration($0))" }
            ].compactMap { $0 }.joined(separator: " | ")
            return sides.isEmpty ? record.durationFormatted : sides

        case .bottle:
            var details: [String] = []
            if let amount = record.bottleAmountMl {
                details.append("\(Int(amount)) ml")
            }
            if let type = record.bottleType {
                details.append(type.displayName)
            }
            return details.joined(separator: " - ")

        case .solid:
            return record.notes ?? "feeding.solid.recorded".localized

        case .pumping:
            if let total = record.pumpingTotalMl {
                return "\(total) ml"
            }
            let sides = [
                record.pumpingLeftMl.map { "E: \($0) ml" },
                record.pumpingRightMl.map { "D: \($0) ml" }
            ].compactMap { $0 }.joined(separator: " | ")
            return sides.isEmpty ? "---" : sides
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Pulsing Animation Modifier
struct PulsingAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .opacity(isPulsing ? 0.6 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Preview
#Preview {
    FeedingView(baby: Baby.preview)
}
