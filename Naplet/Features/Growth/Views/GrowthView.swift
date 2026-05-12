import SwiftUI
import Charts

// MARK: - Growth View
struct GrowthView: View {
    @StateObject private var viewModel: GrowthViewModel
    @Environment(\.dismiss) private var dismiss

    init(babyId: UUID, birthDate: Date) {
        _viewModel = StateObject(wrappedValue: GrowthViewModel(babyId: babyId, birthDate: birthDate))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: NapletSpacing.lg) {
                // Latest measurements summary
                latestMeasurements

                // Chart type selector
                chartTypeSelector

                // Growth chart
                growthChart

                // Unit toggle
                unitToggle

                // Records list
                recordsList
            }
            .padding(.vertical, NapletSpacing.md)
        }
        .background(NapletColors.background.ignoresSafeArea())
        .navigationTitle("growth.title".localized)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.prepareAddRecord()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(NapletColors.primaryPurple)
                }
            }
        }
        .task {
            await viewModel.loadRecords()
        }
        .sheet(isPresented: $viewModel.showingAddSheet) {
            AddGrowthRecordView(viewModel: viewModel)
        }
    }

    // MARK: - Latest Measurements

    private var latestMeasurements: some View {
        HStack(spacing: NapletSpacing.sm) {
            measurementCard(
                icon: "scalemass.fill",
                title: "growth.weight".localized,
                value: viewModel.latestWeight,
                color: NapletColors.primaryPurple
            )

            measurementCard(
                icon: "ruler.fill",
                title: "growth.height".localized,
                value: viewModel.latestHeight,
                color: NapletColors.primaryBlue
            )

            measurementCard(
                icon: "circle.dashed",
                title: "growth.head".localized,
                value: viewModel.latestHeadCircumference,
                color: NapletColors.primaryPink
            )
        }
        .padding(.horizontal, NapletSpacing.lg)
    }

    private func measurementCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: NapletSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(NapletColors.textMuted)

            Text(value)
                .font(.system(size: NapletTypography.subheadline, weight: .bold, design: .rounded))
                .foregroundColor(NapletColors.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(NapletSpacing.md)
        .background(NapletColors.backgroundSecondary)
        .cornerRadius(NapletSpacing.radiusMedium)
    }

    // MARK: - Chart Type Selector

    private var chartTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NapletSpacing.sm) {
                ForEach(GrowthChartType.allCases, id: \.rawValue) { type in
                    Button {
                        withAnimation { viewModel.selectedChartType = type }
                    } label: {
                        HStack(spacing: NapletSpacing.xs) {
                            Image(systemName: type.iconName)
                                .font(.system(size: 12))
                            Text(type.titleKey.localized)
                                .font(.system(size: NapletTypography.caption, weight: .medium))
                        }
                        .padding(.horizontal, NapletSpacing.md)
                        .padding(.vertical, NapletSpacing.sm)
                        .background(viewModel.selectedChartType == type ? NapletColors.primaryPurple : NapletColors.backgroundTertiary)
                        .foregroundColor(viewModel.selectedChartType == type ? .white : NapletColors.textSecondary)
                        .cornerRadius(NapletSpacing.radiusFull)
                    }
                }
            }
            .padding(.horizontal, NapletSpacing.lg)
        }
    }

    // MARK: - Growth Chart

    private var growthChart: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            let dataPoints = viewModel.chartDataPoints(for: viewModel.selectedChartType)

            if dataPoints.count >= 2 {
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("growth.chart.age".localized, point.ageInDays),
                        y: .value(viewModel.selectedChartType.titleKey.localized, point.value)
                    )
                    .foregroundStyle(chartColor)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("growth.chart.age".localized, point.ageInDays),
                        y: .value(viewModel.selectedChartType.titleKey.localized, point.value)
                    )
                    .foregroundStyle(chartColor)
                    .symbolSize(40)

                    AreaMark(
                        x: .value("growth.chart.age".localized, point.ageInDays),
                        y: .value(viewModel.selectedChartType.titleKey.localized, point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [chartColor.opacity(0.3), chartColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxisLabel("growth.chart.age_days".localized)
                .chartYAxisLabel(viewModel.chartUnitLabel)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                            .foregroundStyle(NapletColors.textMuted.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(NapletColors.textMuted)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                            .foregroundStyle(NapletColors.textMuted.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(NapletColors.textMuted)
                    }
                }
                .frame(height: 220)
                .padding(NapletSpacing.md)
            } else if dataPoints.count == 1 {
                // Single data point — show value
                VStack(spacing: NapletSpacing.sm) {
                    Image(systemName: viewModel.selectedChartType.iconName)
                        .font(.system(size: 32))
                        .foregroundColor(chartColor)

                    Text(String(format: "%.1f %@", dataPoints[0].value, viewModel.chartUnitLabel))
                        .font(.system(size: NapletTypography.title2, weight: .bold, design: .rounded))
                        .foregroundColor(NapletColors.textPrimary)

                    Text("growth.chart.need_more".localized)
                        .font(.system(size: NapletTypography.caption))
                        .foregroundColor(NapletColors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                // No data
                VStack(spacing: NapletSpacing.md) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(NapletColors.textMuted)

                    Text("growth.chart.empty".localized)
                        .font(.system(size: NapletTypography.subheadline))
                        .foregroundColor(NapletColors.textMuted)

                    Button {
                        viewModel.prepareAddRecord()
                    } label: {
                        Text("growth.add_first".localized)
                            .font(.system(size: NapletTypography.subheadline, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, NapletSpacing.lg)
                            .padding(.vertical, NapletSpacing.sm)
                            .background(NapletColors.primaryPurple)
                            .cornerRadius(NapletSpacing.radiusFull)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            }
        }
        .background(NapletColors.backgroundSecondary)
        .cornerRadius(20)
        .padding(.horizontal, NapletSpacing.lg)
    }

    private var chartColor: Color {
        switch viewModel.selectedChartType {
        case .weight: return NapletColors.primaryPurple
        case .height: return NapletColors.primaryBlue
        case .headCircumference: return NapletColors.primaryPink
        }
    }

    // MARK: - Unit Toggle

    private var unitToggle: some View {
        HStack {
            Spacer()
            Button {
                withAnimation { viewModel.toggleUnit() }
            } label: {
                HStack(spacing: NapletSpacing.xs) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 12))
                    Text(viewModel.unit == .metric ? "growth.unit.imperial".localized : "growth.unit.metric".localized)
                        .font(.system(size: NapletTypography.caption, weight: .medium))
                }
                .padding(.horizontal, NapletSpacing.md)
                .padding(.vertical, NapletSpacing.xs)
                .background(NapletColors.backgroundTertiary)
                .foregroundColor(NapletColors.textSecondary)
                .cornerRadius(NapletSpacing.radiusFull)
            }
        }
        .padding(.horizontal, NapletSpacing.lg)
    }

    // MARK: - Records List

    private var recordsList: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            Text("growth.history".localized)
                .font(.system(size: NapletTypography.headline, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)
                .padding(.horizontal, NapletSpacing.lg)

            if viewModel.isLoading {
                ProgressView()
                    .tint(NapletColors.primaryPurple)
                    .frame(maxWidth: .infinity)
                    .padding(NapletSpacing.xl)
            } else if viewModel.records.isEmpty {
                Text("growth.no_records".localized)
                    .font(.system(size: NapletTypography.subheadline))
                    .foregroundColor(NapletColors.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(NapletSpacing.xl)
            } else {
                LazyVStack(spacing: NapletSpacing.sm) {
                    ForEach(viewModel.sortedRecordsDescending) { record in
                        recordRow(record)
                    }
                }
                .padding(.horizontal, NapletSpacing.lg)
            }
        }
    }

    private func recordRow(_ record: GrowthRecord) -> some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.formatDate(record.recordDateValue))
                        .font(.system(size: NapletTypography.subheadline, weight: .semibold))
                        .foregroundColor(NapletColors.textPrimary)

                    Text(viewModel.ageAtRecord(record))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(NapletColors.textMuted)
                }

                Spacer()
            }

            HStack(spacing: NapletSpacing.md) {
                if record.weightKg != nil {
                    measurementPill(
                        icon: "scalemass.fill",
                        value: viewModel.formatValue(record, type: .weight),
                        color: NapletColors.primaryPurple
                    )
                }

                if record.heightCm != nil {
                    measurementPill(
                        icon: "ruler.fill",
                        value: viewModel.formatValue(record, type: .height),
                        color: NapletColors.primaryBlue
                    )
                }

                if record.headCircumferenceCm != nil {
                    measurementPill(
                        icon: "circle.dashed",
                        value: viewModel.formatValue(record, type: .headCircumference),
                        color: NapletColors.primaryPink
                    )
                }
            }

            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: NapletTypography.caption))
                    .foregroundColor(NapletColors.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(NapletSpacing.md)
        .background(NapletColors.backgroundSecondary)
        .cornerRadius(NapletSpacing.radiusMedium)
        .contextMenu {
            Button(role: .destructive) {
                Task {
                    await viewModel.deleteRecord(record)
                }
            } label: {
                Label("growth.delete".localized, systemImage: "trash")
            }
        }
    }

    private func measurementPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(NapletColors.textPrimary)
        }
        .padding(.horizontal, NapletSpacing.sm)
        .padding(.vertical, NapletSpacing.xs)
        .background(color.opacity(0.1))
        .cornerRadius(NapletSpacing.radiusSmall)
    }
}
