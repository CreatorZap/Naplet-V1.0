import SwiftUI

// MARK: - Vaccination Dashboard View
struct VaccinationDashboardView: View {
    @StateObject private var viewModel: VaccinationDashboardViewModel
    @State private var selectedVaccination: VaccinationWithDetails?
    @State private var showCompletionSheet = false

    let baby: Baby

    init(baby: Baby) {
        self.baby = baby
        _viewModel = StateObject(wrappedValue: VaccinationDashboardViewModel(baby: baby))
    }

    var body: some View {
        ZStack {
            NapletColors.background.ignoresSafeArea()

            if viewModel.isLoading && viewModel.vaccinationsWithDetails.isEmpty {
                loadingView
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Progress Card
                        progressCard

                        // Overdue Alert
                        if !viewModel.overdueVaccinations.isEmpty {
                            overdueAlertCard
                        }

                        // Upcoming Vaccinations
                        if !viewModel.upcomingVaccinations.isEmpty {
                            upcomingSection
                        }

                        // Filter
                        filterPicker

                        // Search
                        searchBar

                        // Vaccinations List
                        vaccinationsList
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle("vaccination.dashboard.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
        .alert("common.error".localized, isPresented: $viewModel.showError) {
            Button("common.ok".localized, role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(item: $selectedVaccination) { vaccination in
            VaccinationDetailView(
                vaccination: vaccination,
                baby: baby,
                onComplete: { date, batch, location, notes in
                    Task { @MainActor in
                        await viewModel.markAsCompleted(
                            vaccination: vaccination,
                            applicationDate: date,
                            batchNumber: batch,
                            location: location,
                            notes: notes
                        )
                        selectedVaccination = nil
                    }
                },
                onMarkPending: {
                    Task { @MainActor in
                        await viewModel.markAsPending(vaccination: vaccination)
                        selectedVaccination = nil
                    }
                }
            )
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Skeleton do Progress Card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(NapletColors.backgroundTertiary)
                                .frame(width: 180, height: 20)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(NapletColors.backgroundTertiary)
                                .frame(width: 120, height: 14)
                        }
                        Spacer()
                        Circle()
                            .fill(NapletColors.backgroundTertiary)
                            .frame(width: 60, height: 60)
                    }

                    HStack(spacing: 20) {
                        ForEach(0..<3, id: \.self) { _ in
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(NapletColors.backgroundTertiary)
                                    .frame(width: 30, height: 24)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(NapletColors.backgroundTertiary)
                                    .frame(width: 60, height: 12)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(NapletColors.cardBackground)
                )

                // Skeleton das vacinas
                ForEach(0..<4, id: \.self) { _ in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(NapletColors.backgroundTertiary)
                            .frame(width: 44, height: 44)

                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(NapletColors.backgroundTertiary)
                                .frame(width: 160, height: 16)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(NapletColors.backgroundTertiary)
                                .frame(width: 100, height: 12)
                        }

                        Spacer()

                        RoundedRectangle(cornerRadius: 4)
                            .fill(NapletColors.backgroundTertiary)
                            .frame(width: 50, height: 14)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(NapletColors.cardBackground)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .shimmer()
    }

    // MARK: - Progress Card
    private var progressCard: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("vaccination.progress.title".localized)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(NapletColors.textPrimary)

                    Text(String(format: "vaccination.progress.subtitle".localized, baby.name))
                        .font(.system(size: 14))
                        .foregroundColor(NapletColors.textSecondary)
                }

                Spacer()

                // Percentage Circle - More refined
                ZStack {
                    Circle()
                        .stroke(NapletColors.backgroundTertiary.opacity(0.5), lineWidth: 6)
                        .frame(width: 64, height: 64)

                    Circle()
                        .trim(from: 0, to: viewModel.progress.completedPercentage / 100)
                        .stroke(
                            LinearGradient(
                                colors: viewModel.isUpToDate ? 
                                    [NapletColors.success, NapletColors.success.opacity(0.7)] : 
                                    [NapletColors.warning, NapletColors.warning.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: viewModel.progress.completedPercentage)

                    Text(viewModel.progressPercentageText)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(NapletColors.textPrimary)
                }
            }

            // Stats Row - Clean minimal design
            HStack(spacing: 0) {
                statItem(
                    value: viewModel.progress.completed,
                    label: "vaccination.stats.completed".localized,
                    color: NapletColors.success
                )

                Rectangle()
                    .fill(NapletColors.backgroundTertiary.opacity(0.5))
                    .frame(width: 1, height: 36)

                statItem(
                    value: viewModel.progress.pending,
                    label: "vaccination.stats.pending".localized,
                    color: NapletColors.primaryBlue
                )

                Rectangle()
                    .fill(NapletColors.backgroundTertiary.opacity(0.5))
                    .frame(width: 1, height: 36)

                statItem(
                    value: viewModel.progress.overdue,
                    label: "vaccination.stats.overdue".localized,
                    color: NapletColors.error
                )
            }
            .padding(.vertical, 12)
            .background(NapletColors.backgroundTertiary.opacity(0.3))
            .cornerRadius(12)

            // Status Badge - Subtle and elegant
            HStack(spacing: 8) {
                Image(systemName: viewModel.isUpToDate ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .medium))
                Text(viewModel.isUpToDate ? "vaccination.status.upToDate".localized : "vaccination.status.needsAttention".localized)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(viewModel.isUpToDate ? NapletColors.success : NapletColors.warning)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background((viewModel.isUpToDate ? NapletColors.success : NapletColors.warning).opacity(0.12))
            .cornerRadius(20)
        }
        .padding(20)
        .background(NapletColors.cardBackground)
        .cornerRadius(20)
    }

    private func statItem(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(NapletColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Overdue Alert Card
    private var overdueAlertCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(NapletColors.error.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(NapletColors.error)
                }
                
                Text("vaccination.overdue.title".localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(NapletColors.error)
                Spacer()
            }

            Text(String(format: "vaccination.overdue.message".localized, viewModel.overdueVaccinations.count))
                .font(.system(size: 13))
                .foregroundColor(NapletColors.textSecondary)

            VStack(spacing: 8) {
                ForEach(viewModel.overdueVaccinations.prefix(3)) { vaccination in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(NapletColors.error)
                            .frame(width: 6, height: 6)
                        Text(vaccination.vaccine.localizedName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(NapletColors.textPrimary)
                        Text(vaccination.vaccine.doseText)
                            .font(.system(size: 12))
                            .foregroundColor(NapletColors.textMuted)
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(NapletColors.error.opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(NapletColors.error.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Upcoming Section
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("vaccination.upcoming.title".localized)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)

            ForEach(viewModel.upcomingVaccinations) { vaccination in
                upcomingVaccinationCard(vaccination)
            }
        }
    }

    private func upcomingVaccinationCard(_ vaccination: VaccinationWithDetails) -> some View {
        Button {
            selectedVaccination = vaccination
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [NapletColors.primaryCyan.opacity(0.2), NapletColors.primaryCyan.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                    Image(systemName: "syringe.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(NapletColors.primaryCyan)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(vaccination.vaccine.localizedName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(NapletColors.textPrimary)
                        .lineLimit(1)
                    Text(vaccination.vaccine.doseText)
                        .font(.system(size: 12))
                        .foregroundColor(NapletColors.textSecondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Text(vaccination.vaccine.recommendedAgeText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(NapletColors.primaryCyan)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(NapletColors.textMuted.opacity(0.6))
                }
            }
            .padding(14)
            .background(NapletColors.cardBackground)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filter Picker
    private var filterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(VaccinationFilter.allCases) { filter in
                    FilterChip(
                        title: filter.displayName,
                        icon: filter.icon,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedFilter = filter
                        }
                    }
                }
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(NapletColors.textMuted)
            TextField("vaccination.search.placeholder".localized, text: $viewModel.searchText)
                .font(.system(size: 15))
                .foregroundColor(NapletColors.textPrimary)
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(NapletColors.textMuted)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(NapletColors.backgroundTertiary.opacity(0.6))
        .cornerRadius(12)
    }

    // MARK: - Vaccinations List
    private var vaccinationsList: some View {
        LazyVStack(spacing: 24) {
            ForEach(viewModel.groupedVaccinations, id: \.0) { group, vaccinations in
                VStack(alignment: .leading, spacing: 14) {
                    // Age Group Header - Clean and minimal
                    HStack(alignment: .center) {
                        Text(group.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(NapletColors.textPrimary)
                        
                        Spacer()
                        
                        // Progress indicator
                        let completed = vaccinations.filter { $0.vaccination.status == .completed }.count
                        HStack(spacing: 4) {
                            Text("\(completed)")
                                .foregroundColor(NapletColors.success)
                            Text("/")
                                .foregroundColor(NapletColors.textMuted)
                            Text("\(vaccinations.count)")
                                .foregroundColor(NapletColors.textSecondary)
                        }
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                    }
                    .padding(.bottom, 2)

                    // Vaccination Cards
                    VStack(spacing: 10) {
                        ForEach(vaccinations) { vaccination in
                            VaccinationCard(
                                vaccination: vaccination,
                                babyBirthDate: baby.birthDate
                            ) {
                                selectedVaccination = vaccination
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? NapletColors.primaryCyan.opacity(0.15) : NapletColors.backgroundTertiary.opacity(0.6))
            .foregroundColor(isSelected ? NapletColors.primaryCyan : NapletColors.textSecondary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? NapletColors.primaryCyan.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Vaccination Card
struct VaccinationCard: View {
    let vaccination: VaccinationWithDetails
    let babyBirthDate: Date
    let onTap: () -> Void

    private var isOverdue: Bool {
        vaccination.isOverdue(babyBirthDate: babyBirthDate)
    }

    private var statusColor: Color {
        if vaccination.vaccination.status == .completed {
            return NapletColors.success
        } else if isOverdue {
            return NapletColors.error
        }
        return NapletColors.primaryBlue
    }
    
    private var statusIcon: String {
        switch vaccination.vaccination.status {
        case .completed:
            return "checkmark.circle.fill"
        case .pending:
            return isOverdue ? "clock.badge.exclamationmark.fill" : "circle"
        case .overdue:
            return "clock.badge.exclamationmark.fill"
        case .skipped:
            return "xmark.circle"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Status Icon - Clean minimal
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: statusIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(statusColor)
                }

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(vaccination.vaccine.localizedName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(NapletColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(vaccination.vaccine.doseText)
                            .font(.system(size: 12))
                            .foregroundColor(NapletColors.textSecondary)

                        if vaccination.vaccination.status == .completed,
                           let date = vaccination.vaccination.applicationDate {
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(NapletColors.textMuted)
                            Text(formatDate(date))
                                .font(.system(size: 12))
                                .foregroundColor(NapletColors.success)
                        }
                    }
                }

                Spacer()

                // Category Badge - Subtle
                Text(vaccination.vaccine.category.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(vaccination.vaccine.category.color.opacity(0.12))
                    .foregroundColor(vaccination.vaccine.category.color)
                    .cornerRadius(6)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(NapletColors.textMuted.opacity(0.5))
            }
            .padding(14)
            .background(NapletColors.cardBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isOverdue ? NapletColors.error.opacity(0.25) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    NavigationStack {
        VaccinationDashboardView(baby: Baby.preview)
    }
}
#endif
