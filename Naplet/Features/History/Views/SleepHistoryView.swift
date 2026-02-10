import SwiftUI
import Charts

struct SleepHistoryView: View {
    @StateObject private var viewModel = SleepHistoryViewModel()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var selectedPeriod: HistoryTimePeriod = .week
    @State private var selectedTab: StatisticsTab = .summary
    @State private var showReport = false

    enum HistoryTimePeriod: CaseIterable {
        case week
        case twoWeeks
        case month

        var days: Int {
            switch self {
            case .week: return 7
            case .twoWeeks: return 14
            case .month: return 30
            }
        }
        
        var displayName: String {
            switch self {
            case .week: return L10n.History.Period.week.localized
            case .twoWeeks: return L10n.History.Period.twoWeeks.localized
            case .month: return L10n.History.Period.month.localized
            }
        }
    }
    
    enum StatisticsTab: String, CaseIterable {
        case summary
        case naps
        case wakeTime
        case nightSleep
        
        var displayName: String {
            switch self {
            case .summary: return "statistics.tab.summary".localized
            case .naps: return "statistics.tab.naps".localized
            case .wakeTime: return "statistics.tab.wakeTime".localized
            case .nightSleep: return "statistics.tab.nightSleep".localized
            }
        }
        
        var icon: String {
            switch self {
            case .summary: return "chart.bar.fill"
            case .naps: return "sun.max.fill"
            case .wakeTime: return "sunrise.fill"
            case .nightSleep: return "moon.stars.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NapletColors.background
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.sleepData.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: NapletColors.primaryPurple))
                } else {
                    ScrollView {
                        VStack(spacing: NapletSpacing.lg) {
                            // Header com título e subtítulo
                            headerSection
                            
                            // Period Selector
                            periodSelector

                            // Tabs de filtro
                            tabSelector
                            
                            // Conteúdo baseado na tab selecionada
                            tabContent
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.top, NapletSpacing.md)
                    }
                }
            }
            .navigationTitle("statistics.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showReport = true
                    } label: {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(NapletColors.primaryPurple)
                    }
                }
            }
            .sheet(isPresented: $showReport) {
                if let baby = viewModel.currentBaby {
                    ReportView(baby: baby)
                        .presentationBackground(NapletColors.background)
                }
            }
            .id(localizationManager.refreshID)
        }
        .task {
            await viewModel.loadData(days: selectedPeriod.days)
        }
        .onChange(of: selectedPeriod) { _, newValue in
            Task {
                await viewModel.loadData(days: newValue.days)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: NapletSpacing.xs) {
            Text("statistics.subtitle".localized)
                .font(.system(size: NapletTypography.subheadline))
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, NapletSpacing.lg)
    }

    // MARK: - Period Selector
    private var periodSelector: some View {
        NapletCard {
            HStack {
                // Data range display
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.dateRangeFormatted)
                        .font(.system(size: NapletTypography.body, weight: .medium))
                        .foregroundColor(NapletColors.textPrimary)
                }
                
                Spacer()
                
                // Period pills
                HStack(spacing: NapletSpacing.xs) {
                    ForEach(HistoryTimePeriod.allCases, id: \.self) { period in
                        Button(action: { 
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedPeriod = period 
                            }
                        }) {
                            Text(period.displayName)
                                .font(.system(size: NapletTypography.caption, weight: .medium))
                                .foregroundColor(selectedPeriod == period ? .white : NapletColors.textSecondary)
                                .padding(.horizontal, NapletSpacing.sm)
                                .padding(.vertical, NapletSpacing.xs)
                                .background(selectedPeriod == period ? NapletColors.primaryPurple : Color.clear)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, NapletSpacing.lg)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NapletSpacing.sm) {
                ForEach(StatisticsTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12))
                            Text(tab.displayName)
                                .font(.system(size: NapletTypography.subheadline, weight: .medium))
                        }
                        .foregroundColor(selectedTab == tab ? .white : NapletColors.textSecondary)
                        .padding(.horizontal, NapletSpacing.md)
                        .padding(.vertical, NapletSpacing.sm)
                        .background(
                            selectedTab == tab 
                                ? NapletColors.primaryPurple 
                                : NapletColors.backgroundSecondary
                        )
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, NapletSpacing.lg)
        }
    }
    
    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .summary:
            summaryTabContent
        case .naps:
            napsTabContent
        case .wakeTime:
            wakeTimeTabContent
        case .nightSleep:
            nightSleepTabContent
        }
    }
    
    // MARK: - Summary Tab
    private var summaryTabContent: some View {
        VStack(spacing: NapletSpacing.lg) {
            // Gráfico de sono total
            totalSleepChart
            
            // Distribuição do sono (Gráfico de rosca)
            sleepDistributionChart
            
            // Summary Cards
            summaryCards
            
            // Daily Breakdown
            dailyBreakdown
        }
    }
    
    // MARK: - Naps Tab
    private var napsTabContent: some View {
        VStack(spacing: NapletSpacing.lg) {
            // Gráfico de sonecas
            napsChart
            
            // Cards de sonecas
            napsStatsCards
        }
    }
    
    // MARK: - Wake Time Tab
    private var wakeTimeTabContent: some View {
        VStack(spacing: NapletSpacing.lg) {
            // Gráfico de hora de acordar
            wakeTimeChart
            
            // Stats
            wakeTimeStatsCards
        }
    }
    
    // MARK: - Night Sleep Tab
    private var nightSleepTabContent: some View {
        VStack(spacing: NapletSpacing.lg) {
            // Gráfico de hora de dormir
            bedtimeChart
            
            // Stats
            nightSleepStatsCards
        }
    }
    
    // MARK: - Total Sleep Chart
    private var totalSleepChart: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.md) {
            Text("statistics.totalSleep".localized)
                .font(.system(size: NapletTypography.headline, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)
                .padding(.horizontal, NapletSpacing.lg)

            NapletCard {
                if viewModel.sleepData.isEmpty {
                    emptyChartPlaceholder
                } else {
                    VStack(spacing: NapletSpacing.md) {
                        Chart {
                            ForEach(viewModel.sleepData) { data in
                                BarMark(
                                    x: .value("Date", data.date, unit: .day),
                                    y: .value("Hours", data.totalHours)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .cornerRadius(4)
                            }
                            
                            // Linha de média
                            RuleMark(y: .value("Average", viewModel.averageSleepHours))
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                .foregroundStyle(NapletColors.primaryPurple.opacity(0.7))
                                .annotation(position: .top, alignment: .trailing) {
                                    Text("statistics.average".localized + ": \(viewModel.averageSleepFormatted)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(NapletColors.primaryPurple)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(NapletColors.backgroundSecondary)
                                        .cornerRadius(4)
                                }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                AxisValueLabel {
                                    if let date = value.as(Date.self) {
                                        VStack(spacing: 2) {
                                            Text(date, format: .dateTime.weekday(.abbreviated))
                                                .font(.system(size: 10))
                                            Text(date, format: .dateTime.day())
                                                .font(.system(size: 8))
                                        }
                                        .foregroundStyle(NapletColors.textSecondary)
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine()
                                    .foregroundStyle(NapletColors.backgroundTertiary)
                                AxisValueLabel()
                                    .foregroundStyle(NapletColors.textSecondary)
                            }
                        }
                        .frame(height: 200)
                    }
                }
            }
            .padding(.horizontal, NapletSpacing.lg)
        }
    }
    
    // MARK: - Sleep Distribution Chart (Donut)
    private var sleepDistributionChart: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.md) {
            Text("statistics.distribution".localized)
                .font(.system(size: NapletTypography.headline, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)
                .padding(.horizontal, NapletSpacing.lg)

            NapletCard {
                HStack(spacing: NapletSpacing.xl) {
                    // Donut Chart
                    ZStack {
                        Circle()
                            .stroke(NapletColors.backgroundTertiary, lineWidth: 20)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: viewModel.nightSleepPercentage)
                            .stroke(
                                LinearGradient(
                                    colors: [NapletColors.primaryPurple, NapletColors.primaryBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 2) {
                            Text("\(Int(viewModel.nightSleepPercentage * 100))%")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(NapletColors.textPrimary)
                            Text("common.total".localized)
                                .font(.system(size: 12))
                                .foregroundColor(NapletColors.textSecondary)
                        }
                    }
                    
                    // Legend
                    VStack(alignment: .leading, spacing: NapletSpacing.md) {
                        HStack(spacing: NapletSpacing.sm) {
                            Circle()
                                .fill(NapletColors.primaryPurple)
                                .frame(width: 12, height: 12)
                            Text("statistics.nightPeriod".localized)
                                .font(.system(size: NapletTypography.subheadline))
                                .foregroundColor(NapletColors.textPrimary)
                            Spacer()
                            Text("\(Int(viewModel.nightSleepPercentage * 100))%")
                                .font(.system(size: NapletTypography.subheadline, weight: .semibold))
                                .foregroundColor(NapletColors.textPrimary)
                        }
                        
                        HStack(spacing: NapletSpacing.sm) {
                            Circle()
                                .fill(NapletColors.backgroundTertiary)
                                .frame(width: 12, height: 12)
                            Text("statistics.dayPeriod".localized)
                                .font(.system(size: NapletTypography.subheadline))
                                .foregroundColor(NapletColors.textPrimary)
                            Spacer()
                            Text("\(Int((1 - viewModel.nightSleepPercentage) * 100))%")
                                .font(.system(size: NapletTypography.subheadline, weight: .semibold))
                                .foregroundColor(NapletColors.textPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, NapletSpacing.md)
            }
            .padding(.horizontal, NapletSpacing.lg)
        }
    }
    
    // MARK: - Wake Time Chart
    private var wakeTimeChart: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.md) {
            Text("statistics.wakeTime".localized)
                .font(.system(size: NapletTypography.headline, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)
                .padding(.horizontal, NapletSpacing.lg)

            NapletCard {
                if viewModel.wakeTimeData.isEmpty {
                    emptyChartPlaceholder
                } else {
                    VStack(spacing: NapletSpacing.md) {
                        Chart {
                            ForEach(viewModel.wakeTimeData) { data in
                                PointMark(
                                    x: .value("Date", data.date, unit: .day),
                                    y: .value("Time", data.timeValue)
                                )
                                .foregroundStyle(NapletColors.warning)
                                .symbolSize(60)
                                
                                LineMark(
                                    x: .value("Date", data.date, unit: .day),
                                    y: .value("Time", data.timeValue)
                                )
                                .foregroundStyle(NapletColors.warning.opacity(0.5))
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            }
                            
                            // Linha de média
                            RuleMark(y: .value("Average", viewModel.averageWakeTime))
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                .foregroundStyle(NapletColors.warning.opacity(0.7))
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                AxisValueLabel {
                                    if let date = value.as(Date.self) {
                                        VStack(spacing: 2) {
                                            Text(date, format: .dateTime.weekday(.abbreviated))
                                                .font(.system(size: 10))
                                            Text(date, format: .dateTime.day())
                                                .font(.system(size: 8))
                                        }
                                        .foregroundStyle(NapletColors.textSecondary)
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                    .foregroundStyle(NapletColors.backgroundTertiary)
                                AxisValueLabel {
                                    if let timeValue = value.as(Double.self) {
                                        Text(formatTimeValue(timeValue))
                                            .font(.system(size: 10))
                                            .foregroundStyle(NapletColors.textSecondary)
                                    }
                                }
                            }
                        }
                        .frame(height: 200)
                        
                        // Média
                        HStack {
                            Spacer()
                            Text("statistics.average".localized + ": ")
                                .font(.system(size: NapletTypography.subheadline))
                                .foregroundColor(NapletColors.textSecondary)
                            Text(viewModel.averageWakeTimeFormatted)
                                .font(.system(size: NapletTypography.subheadline, weight: .bold))
                                .foregroundColor(NapletColors.warning)
                        }
                    }
                }
            }
            .padding(.horizontal, NapletSpacing.lg)
        }
    }
    
    // MARK: - Bedtime Chart
    private var bedtimeChart: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.md) {
            Text("statistics.bedtime".localized)
                .font(.system(size: NapletTypography.headline, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)
                .padding(.horizontal, NapletSpacing.lg)

            NapletCard {
                if viewModel.bedtimeData.isEmpty {
                    emptyChartPlaceholder
                } else {
                    VStack(spacing: NapletSpacing.md) {
                        Chart {
                            ForEach(viewModel.bedtimeData) { data in
                                PointMark(
                                    x: .value("Date", data.date, unit: .day),
                                    y: .value("Time", data.timeValue)
                                )
                                .foregroundStyle(NapletColors.primaryPink)
                                .symbolSize(60)
                                
                                LineMark(
                                    x: .value("Date", data.date, unit: .day),
                                    y: .value("Time", data.timeValue)
                                )
                                .foregroundStyle(NapletColors.primaryPink.opacity(0.5))
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            }
                            
                            // Linha de média
                            RuleMark(y: .value("Average", viewModel.averageBedtime))
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                .foregroundStyle(NapletColors.primaryPink.opacity(0.7))
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                AxisValueLabel {
                                    if let date = value.as(Date.self) {
                                        VStack(spacing: 2) {
                                            Text(date, format: .dateTime.weekday(.abbreviated))
                                                .font(.system(size: 10))
                                            Text(date, format: .dateTime.day())
                                                .font(.system(size: 8))
                                        }
                                        .foregroundStyle(NapletColors.textSecondary)
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                    .foregroundStyle(NapletColors.backgroundTertiary)
                                AxisValueLabel {
                                    if let timeValue = value.as(Double.self) {
                                        Text(formatTimeValue(timeValue))
                                            .font(.system(size: 10))
                                            .foregroundStyle(NapletColors.textSecondary)
                                    }
                                }
                            }
                        }
                        .frame(height: 200)
                        
                        // Média
                        HStack {
                            Spacer()
                            Text("statistics.average".localized + ": ")
                                .font(.system(size: NapletTypography.subheadline))
                                .foregroundColor(NapletColors.textSecondary)
                            Text(viewModel.averageBedtimeFormatted)
                                .font(.system(size: NapletTypography.subheadline, weight: .bold))
                                .foregroundColor(NapletColors.primaryPink)
                        }
                    }
                }
            }
            .padding(.horizontal, NapletSpacing.lg)
        }
    }
    
    // MARK: - Naps Chart
    private var napsChart: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.md) {
            Text("statistics.napsPerDay".localized)
                .font(.system(size: NapletTypography.headline, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)
                .padding(.horizontal, NapletSpacing.lg)

            NapletCard {
                if viewModel.napsData.isEmpty {
                    emptyChartPlaceholder
                } else {
                    VStack(spacing: NapletSpacing.md) {
                        Chart {
                            ForEach(viewModel.napsData) { data in
                                BarMark(
                                    x: .value("Date", data.date, unit: .day),
                                    y: .value("Count", data.count)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [NapletColors.warning, NapletColors.warning.opacity(0.6)],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .cornerRadius(4)
                            }
                            
                            // Linha de média
                            RuleMark(y: .value("Average", viewModel.averageNapsPerDay))
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                .foregroundStyle(NapletColors.warning.opacity(0.7))
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                AxisValueLabel {
                                    if let date = value.as(Date.self) {
                                        VStack(spacing: 2) {
                                            Text(date, format: .dateTime.weekday(.abbreviated))
                                                .font(.system(size: 10))
                                            Text(date, format: .dateTime.day())
                                                .font(.system(size: 8))
                                        }
                                        .foregroundStyle(NapletColors.textSecondary)
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine()
                                    .foregroundStyle(NapletColors.backgroundTertiary)
                                AxisValueLabel()
                                    .foregroundStyle(NapletColors.textSecondary)
                            }
                        }
                        .frame(height: 200)
                        
                        // Média
                        HStack {
                            Spacer()
                            Text("statistics.average".localized + ": ")
                                .font(.system(size: NapletTypography.subheadline))
                                .foregroundColor(NapletColors.textSecondary)
                            Text(String(format: "%.1f", viewModel.averageNapsPerDay))
                                .font(.system(size: NapletTypography.subheadline, weight: .bold))
                                .foregroundColor(NapletColors.warning)
                        }
                    }
                }
            }
            .padding(.horizontal, NapletSpacing.lg)
        }
    }

    // MARK: - Summary Cards
    private var summaryCards: some View {
        VStack(spacing: NapletSpacing.md) {
            HStack(spacing: NapletSpacing.md) {
                SummaryCard(
                    title: "history.avgDailySleep".localized,
                    value: viewModel.averageSleepFormatted,
                    icon: "moon.fill",
                    color: NapletColors.primaryPurple
                )

                SummaryCard(
                    title: "history.avgNapsPerDay".localized,
                    value: String(format: "%.1f", viewModel.averageNapsPerDay),
                    icon: "zzz",
                    color: NapletColors.primaryPink
                )
            }

            HStack(spacing: NapletSpacing.md) {
                SummaryCard(
                    title: "history.bestDay".localized,
                    value: viewModel.bestDaySleepFormatted,
                    icon: "star.fill",
                    color: NapletColors.success
                )

                SummaryCard(
                    title: "history.totalRecords".localized,
                    value: "\(viewModel.totalRecords)",
                    icon: "list.bullet",
                    color: NapletColors.primaryBlue
                )
            }
        }
        .padding(.horizontal, NapletSpacing.lg)
    }
    
    // MARK: - Naps Stats Cards
    private var napsStatsCards: some View {
        VStack(spacing: NapletSpacing.md) {
            HStack(spacing: NapletSpacing.md) {
                SummaryCard(
                    title: "statistics.avgNapDuration".localized,
                    value: viewModel.averageNapDurationFormatted,
                    icon: "clock.fill",
                    color: NapletColors.warning
                )

                SummaryCard(
                    title: "statistics.totalNaps".localized,
                    value: "\(viewModel.totalNaps)",
                    icon: "sun.max.fill",
                    color: NapletColors.warning
                )
            }
        }
        .padding(.horizontal, NapletSpacing.lg)
    }
    
    // MARK: - Wake Time Stats Cards
    private var wakeTimeStatsCards: some View {
        VStack(spacing: NapletSpacing.md) {
            HStack(spacing: NapletSpacing.md) {
                SummaryCard(
                    title: "statistics.earliestWake".localized,
                    value: viewModel.earliestWakeTimeFormatted,
                    icon: "sunrise.fill",
                    color: NapletColors.warning
                )

                SummaryCard(
                    title: "statistics.latestWake".localized,
                    value: viewModel.latestWakeTimeFormatted,
                    icon: "sun.max.fill",
                    color: NapletColors.warning
                )
            }
        }
        .padding(.horizontal, NapletSpacing.lg)
    }
    
    // MARK: - Night Sleep Stats Cards
    private var nightSleepStatsCards: some View {
        VStack(spacing: NapletSpacing.md) {
            HStack(spacing: NapletSpacing.md) {
                SummaryCard(
                    title: "statistics.avgNightSleep".localized,
                    value: viewModel.averageNightSleepFormatted,
                    icon: "moon.stars.fill",
                    color: NapletColors.primaryPurple
                )

                SummaryCard(
                    title: "statistics.avgBedtime".localized,
                    value: viewModel.averageBedtimeFormatted,
                    icon: "bed.double.fill",
                    color: NapletColors.primaryPink
                )
            }
        }
        .padding(.horizontal, NapletSpacing.lg)
    }

    // MARK: - Daily Breakdown
    private var dailyBreakdown: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.md) {
            Text(L10n.History.dailyBreakdown.localized)
                .font(.system(size: NapletTypography.headline, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)
                .padding(.horizontal, NapletSpacing.lg)

            if viewModel.dailyRecords.isEmpty {
                NapletCard {
                    Text("history.noRecordsToDisplay".localized)
                        .font(.system(size: NapletTypography.body))
                        .foregroundColor(NapletColors.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, NapletSpacing.lg)
                }
                .padding(.horizontal, NapletSpacing.lg)
            } else {
                VStack(spacing: NapletSpacing.sm) {
                    ForEach(viewModel.dailyRecords.prefix(10)) { dayRecord in
                        DailyRecordCard(record: dayRecord)
                    }
                }
                .padding(.horizontal, NapletSpacing.lg)
            }
        }
    }
    
    // MARK: - Empty Chart Placeholder
    private var emptyChartPlaceholder: some View {
        VStack(spacing: NapletSpacing.md) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(NapletColors.textMuted)
            
            Text(L10n.History.noRecords.localized)
                .font(.system(size: NapletTypography.body))
                .foregroundColor(NapletColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NapletSpacing.xl)
    }
    
    // MARK: - Helper Functions
    private func formatTimeValue(_ value: Double) -> String {
        let hours = Int(value)
        let minutes = Int((value - Double(hours)) * 60)
        return String(format: "%02d:%02d", hours, minutes)
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        NapletCard {
            VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)

                    Text(title)
                        .font(.system(size: NapletTypography.caption))
                        .foregroundColor(NapletColors.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Text(value)
                    .font(.system(size: NapletTypography.title2, weight: .bold))
                    .foregroundColor(NapletColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Daily Record Card
struct DailyRecordCard: View {
    let record: DailySleepRecord

    var body: some View {
        NapletCard {
            VStack(spacing: NapletSpacing.sm) {
                HStack {
                    Text(record.dateFormatted)
                        .font(.system(size: NapletTypography.subheadline, weight: .semibold))
                        .foregroundColor(NapletColors.textPrimary)

                    Spacer()

                    Text(record.totalSleepFormatted)
                        .font(.system(size: NapletTypography.subheadline, weight: .bold))
                        .foregroundColor(NapletColors.primaryPurple)
                }

                HStack(spacing: NapletSpacing.lg) {
                    Label("\(record.napCount) \("history.naps".localized)", systemImage: "sun.max.fill")
                        .font(.system(size: NapletTypography.caption))
                        .foregroundColor(NapletColors.textSecondary)

                    if record.nightSleepHours > 0 {
                        Label(String(format: "%.1fh \("history.night".localized)", record.nightSleepHours), systemImage: "moon.stars.fill")
                            .font(.system(size: NapletTypography.caption))
                            .foregroundColor(NapletColors.textSecondary)
                    }

                    Spacer()
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(NapletColors.backgroundTertiary)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * record.progressPercentage, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
    }
}

#Preview {
    SleepHistoryView()
}
