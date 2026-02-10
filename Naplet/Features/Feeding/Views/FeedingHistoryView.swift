import SwiftUI

// MARK: - Feeding History View
struct FeedingHistoryView: View {
    let baby: Baby
    @StateObject private var viewModel: FeedingHistoryViewModel

    @Environment(\.dismiss) private var dismiss

    init(baby: Baby) {
        self.baby = baby
        _viewModel = StateObject(wrappedValue: FeedingHistoryViewModel(baby: baby))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NapletColors.background
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: NapletColors.primaryPurple))
                } else if viewModel.groupedRecords.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: NapletSpacing.lg) {
                            // Period Selector
                            periodSelector

                            // Summary Card
                            summaryCard

                            // Records by Day
                            ForEach(viewModel.groupedRecords, id: \.date) { group in
                                daySection(group)
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.top, NapletSpacing.md)
                    }
                }
            }
            .navigationTitle("feeding.history.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.close".localized) {
                        dismiss()
                    }
                    .foregroundColor(NapletColors.primaryPurple)
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Period Selector
    private var periodSelector: some View {
        Picker("", selection: $viewModel.selectedPeriod) {
            ForEach(FeedingHistoryPeriod.allCases, id: \.self) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, NapletSpacing.lg)
        .onChange(of: viewModel.selectedPeriod) { _, _ in
            Task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Summary Card
    private var summaryCard: some View {
        NapletCard {
            VStack(spacing: NapletSpacing.md) {
                HStack {
                    Text("feeding.history.summary".localized)
                        .font(NapletTypography.headline())
                        .foregroundColor(NapletColors.textPrimary)
                    Spacer()
                }

                HStack(spacing: NapletSpacing.lg) {
                    SummaryStatItem(
                        value: "\(viewModel.summary.totalFeedings)",
                        label: "feeding.history.total".localized,
                        icon: "fork.knife.circle",
                        color: NapletColors.primaryPurple
                    )

                    SummaryStatItem(
                        value: "\(viewModel.summary.breastCount)",
                        label: "feeding.stats.breast".localized,
                        icon: "figure.and.child.holdinghands",
                        color: NapletColors.primaryPurple
                    )

                    SummaryStatItem(
                        value: "\(Int(viewModel.summary.bottleTotalMl)) ml",
                        label: "feeding.stats.bottle".localized,
                        icon: "waterbottle",
                        color: NapletColors.info
                    )

                    SummaryStatItem(
                        value: "\(viewModel.summary.solidCount)",
                        label: "feeding.stats.solid".localized,
                        icon: "fork.knife",
                        color: NapletColors.warning
                    )
                }

                // Average per day
                if viewModel.summary.averagePerDay > 0 {
                    Divider()

                    HStack {
                        Image(systemName: "chart.bar")
                            .foregroundColor(NapletColors.textMuted)

                        Text("feeding.history.avgPerDay".localized(with: String(format: "%.1f", viewModel.summary.averagePerDay)))
                            .font(NapletTypography.caption())
                            .foregroundColor(NapletColors.textSecondary)

                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, NapletSpacing.lg)
    }

    // MARK: - Day Section
    private func daySection(_ group: FeedingDayGroup) -> some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            // Day header
            HStack {
                Text(formatDayHeader(group.date))
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)
                    .textCase(.uppercase)

                Spacer()

                Text("\(group.records.count) " + "feeding.history.feeds".localized)
                    .font(NapletTypography.caption())
                    .foregroundColor(NapletColors.textMuted)
            }
            .padding(.horizontal, NapletSpacing.lg)

            // Records
            VStack(spacing: NapletSpacing.sm) {
                ForEach(group.records) { record in
                    FeedingHistoryDetailRow(record: record)
                }
            }
            .padding(.horizontal, NapletSpacing.lg)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: NapletSpacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(NapletColors.textMuted)

            Text("feeding.history.empty".localized)
                .font(NapletTypography.headline())
                .foregroundColor(NapletColors.textPrimary)

            Text("feeding.history.emptySubtitle".localized)
                .font(NapletTypography.body())
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(NapletSpacing.xl)
    }

    // MARK: - Helpers
    private func formatDayHeader(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "time.today".localized
        } else if calendar.isDateInYesterday(date) {
            return "time.yesterday".localized
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, d MMM"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Summary Stat Item
struct SummaryStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(value)
                .font(NapletTypography.body(weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(NapletColors.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Feeding History Detail Row
struct FeedingHistoryDetailRow: View {
    let record: FeedingRecord

    var body: some View {
        NapletCard {
            HStack(spacing: NapletSpacing.md) {
                // Type icon
                Image(systemName: record.type.icon)
                    .font(.system(size: 18))
                    .foregroundColor(record.type.color)
                    .frame(width: 36, height: 36)
                    .background(record.type.color.opacity(0.1))
                    .clipShape(Circle())

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.type.displayName)
                        .font(NapletTypography.body(weight: .medium))
                        .foregroundColor(NapletColors.textPrimary)

                    Text(detailText)
                        .font(NapletTypography.caption())
                        .foregroundColor(NapletColors.textSecondary)
                }

                Spacer()

                // Time
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatTime(record.startTime))
                        .font(NapletTypography.body())
                        .foregroundColor(NapletColors.textPrimary)

                    if record.endTime != nil {
                        Text(record.durationFormatted)
                            .font(NapletTypography.caption())
                            .foregroundColor(NapletColors.textMuted)
                    }
                }
            }
        }
    }

    private var detailText: String {
        switch record.type {
        case .breast:
            var parts: [String] = []
            if let left = record.durationLeftSeconds, left > 0 {
                parts.append("E: \(formatSeconds(left))")
            }
            if let right = record.durationRightSeconds, right > 0 {
                parts.append("D: \(formatSeconds(right))")
            }
            return parts.isEmpty ? "---" : parts.joined(separator: " | ")

        case .bottle:
            var parts: [String] = []
            if let amount = record.bottleAmountMl {
                parts.append("\(Int(amount)) ml")
            }
            if let type = record.bottleType {
                parts.append(type.displayName)
            }
            return parts.isEmpty ? "---" : parts.joined(separator: " - ")

        case .solid:
            return record.notes ?? "feeding.solid.recorded".localized

        case .pumping:
            var parts: [String] = []
            if let total = record.pumpingTotalMl {
                parts.append("\(total) ml total")
            } else {
                if let left = record.pumpingLeftMl, left > 0 {
                    parts.append("E: \(left) ml")
                }
                if let right = record.pumpingRightMl, right > 0 {
                    parts.append("D: \(right) ml")
                }
            }
            return parts.isEmpty ? "---" : parts.joined(separator: " | ")
        }
    }

    private func formatSeconds(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Feeding History ViewModel
@MainActor
class FeedingHistoryViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var selectedPeriod: FeedingHistoryPeriod = .week
    @Published var groupedRecords: [FeedingDayGroup] = []
    @Published var summary: FeedingHistorySummary = .empty

    private let baby: Baby
    private let repository = FeedingRepository.shared

    init(baby: Baby) {
        self.baby = baby
    }

    func loadData() async {
        isLoading = true

        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: endDate) ?? endDate

        do {
            let records = try await repository.fetchRecords(
                babyId: baby.id,
                startDate: startDate,
                endDate: endDate
            )

            // Group by day
            let grouped = Dictionary(grouping: records) { record in
                calendar.startOfDay(for: record.startTime)
            }

            groupedRecords = grouped.map { date, records in
                FeedingDayGroup(date: date, records: records.sorted { $0.startTime > $1.startTime })
            }.sorted { $0.date > $1.date }

            // Calculate summary
            let completedRecords = records.filter { $0.endTime != nil }
            let breastRecords = completedRecords.filter { $0.type == .breast }
            let bottleRecords = completedRecords.filter { $0.type == .bottle }
            let solidRecords = completedRecords.filter { $0.type == .solid }

            let totalBottleMl = bottleRecords.reduce(0.0) { $0 + ($1.bottleAmountMl ?? 0) }
            let daysCount = max(1, grouped.keys.count)

            summary = FeedingHistorySummary(
                totalFeedings: completedRecords.count,
                breastCount: breastRecords.count,
                bottleTotalMl: totalBottleMl,
                solidCount: solidRecords.count,
                averagePerDay: Double(completedRecords.count) / Double(daysCount)
            )

        } catch {
            Logger.error("Failed to load feeding history: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Supporting Types
enum FeedingHistoryPeriod: String, CaseIterable {
    case week
    case twoWeeks
    case month

    var displayName: String {
        switch self {
        case .week: return "history.period.week".localized
        case .twoWeeks: return "history.period.twoWeeks".localized
        case .month: return "history.period.month".localized
        }
    }

    var days: Int {
        switch self {
        case .week: return 7
        case .twoWeeks: return 14
        case .month: return 30
        }
    }
}

struct FeedingDayGroup {
    let date: Date
    let records: [FeedingRecord]
}

struct FeedingHistorySummary {
    let totalFeedings: Int
    let breastCount: Int
    let bottleTotalMl: Double
    let solidCount: Int
    let averagePerDay: Double

    static var empty: FeedingHistorySummary {
        FeedingHistorySummary(
            totalFeedings: 0,
            breastCount: 0,
            bottleTotalMl: 0,
            solidCount: 0,
            averagePerDay: 0
        )
    }
}

// MARK: - Preview
#Preview {
    FeedingHistoryView(baby: Baby.preview)
}
