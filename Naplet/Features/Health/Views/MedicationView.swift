import SwiftUI

// MARK: - Medication Tab
enum MedicationTab: String, CaseIterable {
    case record = "record"
    case schedule = "schedule"

    var title: String {
        switch self {
        case .record: return "medication.tab.record".localized
        case .schedule: return "medication.tab.schedule".localized
        }
    }

    var icon: String {
        switch self {
        case .record: return "plus.circle.fill"
        case .schedule: return "clock.badge.checkmark.fill"
        }
    }
}

// MARK: - Medication View
struct MedicationView: View {
    @StateObject private var viewModel: HealthViewModel
    @StateObject private var scheduleListViewModel: MedicationScheduleListViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: MedicationTab = .record
    @State private var showScheduleSheet = false
    @State private var editingSchedule: MedicationSchedule?

    let baby: Baby

    init(baby: Baby) {
        self.baby = baby
        _viewModel = StateObject(wrappedValue: HealthViewModel(baby: baby))
        _scheduleListViewModel = StateObject(wrappedValue: MedicationScheduleListViewModel(baby: baby))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Drag Indicator
                Capsule()
                    .fill(NapletColors.textMuted.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, NapletSpacing.sm)
                    .padding(.bottom, NapletSpacing.md)

                // Tab Picker
                tabPicker

                // Content based on selected tab
                if selectedTab == .record {
                    recordTabContent
                } else {
                    scheduleTabContent
                }
            }
        }
        .background(NapletColors.background)
        .task {
            await viewModel.loadMedications()
            await scheduleListViewModel.loadSchedules()
        }
        .alert("common.success".localized, isPresented: $viewModel.showSuccess) {
            Button("common.ok".localized) {
                dismiss()
            }
        } message: {
            Text("health.medication.saved".localized)
        }
        .sheet(isPresented: $showScheduleSheet) {
            MedicationScheduleView(baby: baby, editingSchedule: editingSchedule)
                .onDisappear {
                    editingSchedule = nil
                    Task {
                        await scheduleListViewModel.loadSchedules()
                    }
                }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }

    // MARK: - Tab Picker
    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(MedicationTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14))
                        Text(tab.title)
                            .font(NapletTypography.caption(weight: .semibold))
                    }
                    .foregroundColor(selectedTab == tab ? .white : NapletColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selectedTab == tab
                            ? NapletColors.primaryCyan
                            : Color.clear
                    )
                    .cornerRadius(10)
                }
            }
        }
        .padding(4)
        .background(NapletColors.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal, NapletSpacing.lg)
        .padding(.bottom, NapletSpacing.md)
    }

    // MARK: - Record Tab Content
    private var recordTabContent: some View {
        ZStack {
            ScrollView {
                VStack(spacing: NapletSpacing.xl) {
                    // Header
                    headerSection

                    // Time selector
                    timeSection

                    // Medication name
                    medicationNameSection

                    // Dose
                    doseSection

                    // Notes
                    notesSection

                    // Today's records
                    if !viewModel.todayMedications.isEmpty {
                        todayRecordsSection
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, NapletSpacing.lg)
            }

            // Save button
            VStack {
                Spacer()
                saveButton
            }
        }
    }

    // MARK: - Schedule Tab Content
    private var scheduleTabContent: some View {
        ZStack {
            ScrollView {
                VStack(spacing: NapletSpacing.lg) {
                    // Next medication card
                    if let nextMed = scheduleListViewModel.nextMedication {
                        nextMedicationSection(nextMed)
                    }

                    // Active schedules
                    if !scheduleListViewModel.activeSchedules.isEmpty {
                        activeSchedulesSection
                    } else {
                        MedicationEmptyState {
                            showScheduleSheet = true
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, NapletSpacing.lg)
                .padding(.top, NapletSpacing.md)
            }

            // Add button
            VStack {
                Spacer()
                addScheduleButton
            }
        }
    }

    // MARK: - Next Medication Section
    private func nextMedicationSection(_ schedule: MedicationSchedule) -> some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            Text("medication.next".localized)
                .font(NapletTypography.caption(weight: .semibold))
                .foregroundColor(NapletColors.textSecondary)

            MedicationReminderCard(
                schedule: schedule,
                babyName: baby.name,
                onGiven: {
                    Task {
                        await scheduleListViewModel.markAsGiven(schedule)
                    }
                },
                onSnooze: { duration in
                    Task {
                        await scheduleListViewModel.snooze(schedule, duration: duration)
                    }
                },
                onSkip: {
                    Task {
                        await scheduleListViewModel.skip(schedule)
                    }
                },
                onTap: {
                    editingSchedule = schedule
                    showScheduleSheet = true
                }
            )
        }
    }

    // MARK: - Active Schedules Section
    private var activeSchedulesSection: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            HStack {
                Text("medication.active".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)

                Spacer()

                Text("\(scheduleListViewModel.activeSchedules.count)")
                    .font(NapletTypography.caption())
                    .foregroundColor(NapletColors.textMuted)
            }

            VStack(spacing: NapletSpacing.sm) {
                ForEach(scheduleListViewModel.activeSchedules) { schedule in
                    CompactMedicationCard(schedule: schedule) {
                        editingSchedule = schedule
                        showScheduleSheet = true
                    }
                }
            }
        }
    }

    // MARK: - Add Schedule Button
    private var addScheduleButton: some View {
        Button {
            editingSchedule = nil
            showScheduleSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("medication.schedule.add".localized)
            }
            .font(NapletTypography.body(weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NapletSpacing.md)
            .background(NapletColors.primaryCyan)
            .cornerRadius(16)
        }
        .padding(.horizontal, NapletSpacing.lg)
        .padding(.bottom, NapletSpacing.xl)
        .background(
            LinearGradient(
                colors: [NapletColors.background.opacity(0), NapletColors.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .allowsHitTesting(false)
        )
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: NapletSpacing.sm) {
            ZStack {
                Circle()
                    .fill(NapletColors.primaryCyan.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "pills.fill")
                    .font(.system(size: 48))
                    .foregroundColor(NapletColors.primaryCyan)
            }

            Text("health.medication.record".localized)
                .font(NapletTypography.title2())
                .foregroundColor(NapletColors.textPrimary)

            if let lastInfo = viewModel.lastMedicationInfo {
                Text("health.last".localized + ": " + lastInfo)
                    .font(NapletTypography.caption())
                    .foregroundColor(NapletColors.textSecondary)
            }
        }
        .padding(.top, NapletSpacing.md)
    }

    // MARK: - Time Section
    private var timeSection: some View {
        NapletCard {
            VStack(spacing: NapletSpacing.md) {
                Text("health.time".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: NapletSpacing.xl) {
                    Button {
                        viewModel.adjustMedicationTime(by: -60)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(NapletColors.primaryPurple)
                            Text("-1 min")
                                .font(NapletTypography.caption())
                                .foregroundColor(NapletColors.textSecondary)
                        }
                    }

                    Text(viewModel.formattedMedicationTime)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(NapletColors.textPrimary)
                        .frame(minWidth: 140)

                    Button {
                        viewModel.adjustMedicationTime(by: 60)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(NapletColors.primaryPurple)
                            Text("+1 min")
                                .font(NapletTypography.caption())
                                .foregroundColor(NapletColors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Medication Name Section
    private var medicationNameSection: some View {
        NapletCard {
            VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                HStack {
                    Text("health.medication.name".localized)
                        .font(NapletTypography.caption(weight: .semibold))
                        .foregroundColor(NapletColors.textSecondary)

                    Text("*")
                        .foregroundColor(NapletColors.error)
                }

                TextField("health.medication.namePlaceholder".localized, text: $viewModel.medicationName)
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textPrimary)
                    .padding(NapletSpacing.md)
                    .background(NapletColors.background)
                    .cornerRadius(8)

                // Quick medication suggestions
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: NapletSpacing.sm) {
                        ForEach(medicationSuggestions, id: \.self) { med in
                            MedicationSuggestionChip(name: med) {
                                viewModel.medicationName = med
                            }
                        }
                    }
                }
            }
        }
    }

    private var medicationSuggestions: [String] {
        [
            "health.med.paracetamol".localized,
            "health.med.ibuprofen".localized,
            "health.med.vitamin".localized,
            "health.med.antibiotic".localized,
            "health.med.drops".localized
        ]
    }

    // MARK: - Dose Section
    private var doseSection: some View {
        NapletCard {
            VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                HStack {
                    Text("health.medication.dose".localized)
                        .font(NapletTypography.caption(weight: .semibold))
                        .foregroundColor(NapletColors.textSecondary)

                    Text("(\("common.optional".localized))")
                        .font(NapletTypography.caption())
                        .foregroundColor(NapletColors.textMuted)
                }

                TextField("health.medication.dosePlaceholder".localized, text: $viewModel.medicationDose)
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textPrimary)
                    .padding(NapletSpacing.md)
                    .background(NapletColors.background)
                    .cornerRadius(8)

                // Quick dose suggestions
                HStack(spacing: NapletSpacing.sm) {
                    ForEach(["2.5ml", "5ml", "1 gota", "2 gotas", "1 comp"], id: \.self) { dose in
                        DoseSuggestionChip(dose: dose) {
                            viewModel.medicationDose = dose
                        }
                    }
                }
            }
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        NapletCard {
            VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                Text("health.notes".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)

                TextField("health.notesPlaceholder".localized, text: $viewModel.medicationNotes, axis: .vertical)
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textPrimary)
                    .lineLimit(2...4)
                    .padding(NapletSpacing.md)
                    .background(NapletColors.background)
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - Today's Records Section
    private var todayRecordsSection: some View {
        NapletCard {
            VStack(alignment: .leading, spacing: NapletSpacing.md) {
                Text("health.today".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)

                ForEach(viewModel.todayMedications.prefix(5)) { record in
                    HStack {
                        Image(systemName: "pills.fill")
                            .font(.system(size: 14))
                            .foregroundColor(NapletColors.primaryCyan)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.medicationName ?? "-")
                                .font(NapletTypography.body(weight: .semibold))
                                .foregroundColor(NapletColors.textPrimary)

                            if let dose = record.medicationDose {
                                Text(dose)
                                    .font(NapletTypography.caption())
                                    .foregroundColor(NapletColors.textMuted)
                            }
                        }

                        Spacer()

                        Text(record.formattedTime)
                            .font(NapletTypography.caption())
                            .foregroundColor(NapletColors.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            Task {
                await viewModel.saveMedication()
            }
        } label: {
            HStack {
                if viewModel.isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("health.save".localized)
                }
            }
            .font(NapletTypography.body(weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NapletSpacing.md)
            .background(viewModel.medicationName.isEmpty ? NapletColors.textMuted : NapletColors.primaryCyan)
            .cornerRadius(16)
        }
        .disabled(viewModel.isSaving || viewModel.medicationName.isEmpty)
        .padding(.horizontal, NapletSpacing.lg)
        .padding(.bottom, NapletSpacing.xl)
        .background(
            LinearGradient(
                colors: [NapletColors.background.opacity(0), NapletColors.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .allowsHitTesting(false)
        )
    }
}

// MARK: - Medication Suggestion Chip
struct MedicationSuggestionChip: View {
    let name: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(name)
                .font(NapletTypography.caption(weight: .medium))
                .foregroundColor(NapletColors.primaryCyan)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(NapletColors.primaryCyan.opacity(0.1))
                .cornerRadius(16)
        }
    }
}

// MARK: - Dose Suggestion Chip
struct DoseSuggestionChip: View {
    let dose: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(dose)
                .font(NapletTypography.caption(weight: .medium))
                .foregroundColor(NapletColors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(NapletColors.cardBackground)
                .cornerRadius(8)
        }
    }
}

// MARK: - Preview
#Preview {
    MedicationView(baby: Baby.preview)
}
