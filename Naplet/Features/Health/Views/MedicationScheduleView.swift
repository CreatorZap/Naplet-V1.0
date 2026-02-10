import SwiftUI

// MARK: - Medication Schedule View
/// Tela para criar/editar agendamentos de medicamentos
struct MedicationScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MedicationScheduleViewModel

    let baby: Baby
    let editingSchedule: MedicationSchedule?

    init(baby: Baby, editingSchedule: MedicationSchedule? = nil) {
        self.baby = baby
        self.editingSchedule = editingSchedule
        _viewModel = StateObject(wrappedValue: MedicationScheduleViewModel(
            baby: baby,
            editingSchedule: editingSchedule
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NapletColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Medication Info
                        medicationInfoSection

                        // Frequency Selection
                        frequencySection

                        // Time Selection
                        if viewModel.frequency != .asNeeded {
                            timeSelectionSection
                        }

                        // Duration
                        durationSection

                        // Stock Control
                        stockControlSection

                        // Notes
                        notesSection

                        // Save Button
                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle(editingSchedule != nil ? "medication.schedule.edit".localized : "medication.schedule.new".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(NapletColors.textSecondary)
                }
            }
            .alert("common.error".localized, isPresented: $viewModel.showError) {
                Button("common.ok".localized, role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(NapletColors.primaryCyan.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "pills.fill")
                    .font(.system(size: 36))
                    .foregroundColor(NapletColors.primaryCyan)
            }

            Text(editingSchedule != nil ? "medication.schedule.editDescription".localized : "medication.schedule.description".localized)
                .font(.subheadline)
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Medication Info Section
    private var medicationInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("medication.info".localized)
                .font(.headline)
                .foregroundColor(NapletColors.textPrimary)

            // Medication Name
            VStack(alignment: .leading, spacing: 8) {
                Text("medication.name".localized)
                    .font(.subheadline)
                    .foregroundColor(NapletColors.textSecondary)

                TextField("medication.namePlaceholder".localized, text: $viewModel.medicationName)
                    .textFieldStyle(NapletTextFieldStyle())

                // Quick suggestions
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.medicationSuggestions, id: \.self) { suggestion in
                            Button {
                                viewModel.medicationName = suggestion
                            } label: {
                                Text(suggestion)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        viewModel.medicationName == suggestion
                                            ? NapletColors.primaryCyan.opacity(0.3)
                                            : NapletColors.backgroundTertiary
                                    )
                                    .foregroundColor(
                                        viewModel.medicationName == suggestion
                                            ? NapletColors.primaryCyan
                                            : NapletColors.textSecondary
                                    )
                                    .cornerRadius(16)
                            }
                        }
                    }
                }
            }

            // Dose
            VStack(alignment: .leading, spacing: 8) {
                Text("medication.dose".localized)
                    .font(.subheadline)
                    .foregroundColor(NapletColors.textSecondary)

                TextField("medication.dosePlaceholder".localized, text: $viewModel.dose)
                    .textFieldStyle(NapletTextFieldStyle())

                // Quick suggestions
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.doseSuggestions, id: \.self) { suggestion in
                            Button {
                                viewModel.dose = suggestion
                            } label: {
                                Text(suggestion)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        viewModel.dose == suggestion
                                            ? NapletColors.primaryCyan.opacity(0.3)
                                            : NapletColors.backgroundTertiary
                                    )
                                    .foregroundColor(
                                        viewModel.dose == suggestion
                                            ? NapletColors.primaryCyan
                                            : NapletColors.textSecondary
                                    )
                                    .cornerRadius(16)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(NapletColors.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Frequency Section
    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("medication.frequency".localized)
                .font(.headline)
                .foregroundColor(NapletColors.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(MedicationFrequency.allCases) { freq in
                    FrequencyButton(
                        frequency: freq,
                        isSelected: viewModel.frequency == freq
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.selectFrequency(freq)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(NapletColors.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Time Selection Section
    private var timeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("medication.times".localized)
                    .font(.headline)
                    .foregroundColor(NapletColors.textPrimary)

                Spacer()

                if viewModel.frequency == .custom {
                    Button {
                        viewModel.addTimeSlot()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(NapletColors.primaryCyan)
                    }
                }
            }

            VStack(spacing: 12) {
                ForEach(Array(viewModel.reminderTimes.enumerated()), id: \.offset) { index, time in
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(NapletColors.primaryCyan)
                            .frame(width: 24)

                        DatePicker(
                            "",
                            selection: Binding(
                                get: { viewModel.timeFromString(time) },
                                set: { viewModel.updateTime(at: index, to: $0) }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .tint(NapletColors.primaryCyan)

                        Spacer()

                        if viewModel.frequency == .custom && viewModel.reminderTimes.count > 1 {
                            Button {
                                viewModel.removeTimeSlot(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(NapletColors.error)
                            }
                        }
                    }
                    .padding(12)
                    .background(NapletColors.backgroundTertiary)
                    .cornerRadius(12)
                }
            }

            if viewModel.frequency != .custom {
                Text("medication.times.autoDescription".localized)
                    .font(.caption)
                    .foregroundColor(NapletColors.textMuted)
            }
        }
        .padding(16)
        .background(NapletColors.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Duration Section
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("medication.duration".localized)
                .font(.headline)
                .foregroundColor(NapletColors.textPrimary)

            // Duration Type Picker
            Picker("", selection: $viewModel.durationType) {
                ForEach(DurationType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)

            // Additional fields based on type
            switch viewModel.durationType {
            case .continuous:
                HStack {
                    Image(systemName: "infinity")
                        .foregroundColor(NapletColors.primaryCyan)
                    Text("medication.duration.continuousDescription".localized)
                        .font(.subheadline)
                        .foregroundColor(NapletColors.textSecondary)
                }
                .padding(12)
                .background(NapletColors.backgroundTertiary)
                .cornerRadius(12)

            case .days:
                HStack {
                    Text("medication.duration.daysLabel".localized)
                        .foregroundColor(NapletColors.textSecondary)

                    Stepper(
                        value: $viewModel.durationDays,
                        in: 1...365
                    ) {
                        Text("\(viewModel.durationDays)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(NapletColors.primaryCyan)
                    }
                }
                .padding(12)
                .background(NapletColors.backgroundTertiary)
                .cornerRadius(12)

            case .untilDate:
                DatePicker(
                    "medication.duration.endDate".localized,
                    selection: $viewModel.endDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .tint(NapletColors.primaryCyan)
                .padding(12)
                .background(NapletColors.backgroundTertiary)
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(NapletColors.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Stock Control Section
    private var stockControlSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("medication.stock".localized)
                    .font(.headline)
                    .foregroundColor(NapletColors.textPrimary)

                Spacer()

                Toggle("", isOn: $viewModel.trackStock)
                    .tint(NapletColors.primaryCyan)
            }

            if viewModel.trackStock {
                VStack(spacing: 12) {
                    // Doses remaining
                    HStack {
                        Text("medication.stock.remaining".localized)
                            .foregroundColor(NapletColors.textSecondary)

                        Spacer()

                        HStack(spacing: 16) {
                            Button {
                                if viewModel.dosesRemaining > 0 {
                                    viewModel.dosesRemaining -= 1
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(NapletColors.primaryPink)
                            }

                            Text("\(viewModel.dosesRemaining)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(NapletColors.textPrimary)
                                .frame(minWidth: 50)

                            Button {
                                viewModel.dosesRemaining += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(NapletColors.primaryCyan)
                            }
                        }
                    }

                    Divider()
                        .background(NapletColors.backgroundTertiary)

                    // Low stock alert
                    HStack {
                        Text("medication.stock.alertAt".localized)
                            .foregroundColor(NapletColors.textSecondary)

                        Spacer()

                        Stepper(
                            value: $viewModel.lowStockAlert,
                            in: 1...50
                        ) {
                            Text("\(viewModel.lowStockAlert)")
                                .foregroundColor(NapletColors.primaryCyan)
                        }
                    }

                    // Doses per take
                    HStack {
                        Text("medication.stock.perTake".localized)
                            .foregroundColor(NapletColors.textSecondary)

                        Spacer()

                        Stepper(
                            value: $viewModel.dosesPerTake,
                            in: 0.5...10,
                            step: 0.5
                        ) {
                            Text(String(format: "%.1f", viewModel.dosesPerTake))
                                .foregroundColor(NapletColors.primaryCyan)
                        }
                    }
                }
                .padding(12)
                .background(NapletColors.backgroundTertiary)
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(NapletColors.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("medication.notes".localized)
                .font(.headline)
                .foregroundColor(NapletColors.textPrimary)

            TextEditor(text: $viewModel.notes)
                .frame(minHeight: 80)
                .padding(12)
                .background(NapletColors.backgroundTertiary)
                .cornerRadius(12)
                .foregroundColor(NapletColors.textPrimary)
        }
        .padding(16)
        .background(NapletColors.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            Task {
                await viewModel.save()
            }
        } label: {
            HStack {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text(editingSchedule != nil ? "common.save".localized : "medication.schedule.create".localized)
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                viewModel.canSave
                    ? NapletColors.primaryCyan
                    : NapletColors.primaryCyan.opacity(0.5)
            )
            .cornerRadius(16)
        }
        .disabled(!viewModel.canSave || viewModel.isSaving)
    }
}

// MARK: - Frequency Button
struct FrequencyButton: View {
    let frequency: MedicationFrequency
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: frequency.icon)
                    .font(.title2)

                Text(frequency.displayName)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected
                    ? NapletColors.primaryCyan.opacity(0.2)
                    : NapletColors.backgroundTertiary
            )
            .foregroundColor(
                isSelected
                    ? NapletColors.primaryCyan
                    : NapletColors.textSecondary
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? NapletColors.primaryCyan : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

// MARK: - Naplet TextField Style
struct NapletTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(NapletColors.backgroundTertiary)
            .cornerRadius(12)
            .foregroundColor(NapletColors.textPrimary)
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    MedicationScheduleView(baby: Baby.preview)
}
#endif
