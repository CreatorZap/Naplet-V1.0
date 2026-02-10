import SwiftUI

// MARK: - Sleep Schedule Settings View
struct SleepScheduleSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SleepScheduleSettingsViewModel

    let baby: Baby
    let onSave: (BabySleepPreferences) -> Void

    init(baby: Baby, onSave: @escaping (BabySleepPreferences) -> Void) {
        self.baby = baby
        self.onSave = onSave
        _viewModel = StateObject(wrappedValue: SleepScheduleSettingsViewModel(baby: baby))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NapletColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: NapletSpacing.lg) {
                        // Header informativo
                        infoCard

                        // Horario de acordar
                        wakeTimeSection

                        // Horario de dormir
                        bedtimeSection

                        // Duracao de soneca
                        napDurationSection

                        // Janela de sono
                        wakeWindowSection

                        // Dados aprendidos
                        if viewModel.hasLearnedData {
                            learnedDataCard
                        }

                        // Botao reset
                        resetButton
                    }
                    .padding(NapletSpacing.md)
                }
            }
            .navigationTitle("sleepSchedule.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(NapletColors.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) {
                        onSave(viewModel.getPreferences())
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(NapletColors.primaryPurple)
                }
            }
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        HStack(spacing: NapletSpacing.sm) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 20))
                .foregroundColor(NapletColors.warning)

            VStack(alignment: .leading, spacing: 4) {
                Text("sleepSchedule.info.title".localized)
                    .font(.system(size: NapletTypography.subheadline, weight: .semibold))
                    .foregroundColor(NapletColors.textPrimary)

                Text("sleepSchedule.info.description".localized)
                    .font(.system(size: NapletTypography.caption))
                    .foregroundColor(NapletColors.textSecondary)
            }

            Spacer()
        }
        .padding(NapletSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(NapletColors.warning.opacity(0.1))
        )
    }

    // MARK: - Wake Time Section

    private var wakeTimeSection: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            sectionHeader(
                icon: "sun.max.fill",
                title: "sleepSchedule.wakeTime.title".localized,
                color: NapletColors.warning
            )

            VStack(spacing: NapletSpacing.sm) {
                Toggle(isOn: $viewModel.useCustomWakeTime) {
                    Text("sleepSchedule.useCustom".localized)
                        .font(.system(size: NapletTypography.body))
                        .foregroundColor(NapletColors.textPrimary)
                }
                .tint(NapletColors.primaryPurple)

                if viewModel.useCustomWakeTime {
                    DatePicker(
                        "sleepSchedule.wakeTime.label".localized,
                        selection: $viewModel.customWakeTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 100)
                } else {
                    defaultValueLabel(
                        "sleepSchedule.default".localized(with: viewModel.defaultWakeTimeFormatted)
                    )
                }
            }
            .padding(NapletSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(NapletColors.cardBackground)
            )
        }
    }

    // MARK: - Bedtime Section

    private var bedtimeSection: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            sectionHeader(
                icon: "moon.zzz.fill",
                title: "sleepSchedule.bedtime.title".localized,
                color: NapletColors.primaryPink
            )

            VStack(spacing: NapletSpacing.sm) {
                Toggle(isOn: $viewModel.useCustomBedtime) {
                    Text("sleepSchedule.useCustom".localized)
                        .font(.system(size: NapletTypography.body))
                        .foregroundColor(NapletColors.textPrimary)
                }
                .tint(NapletColors.primaryPurple)

                if viewModel.useCustomBedtime {
                    DatePicker(
                        "sleepSchedule.bedtime.label".localized,
                        selection: $viewModel.customBedtime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 100)
                } else {
                    defaultValueLabel(
                        "sleepSchedule.default".localized(with: viewModel.defaultBedtimeFormatted)
                    )
                }
            }
            .padding(NapletSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(NapletColors.cardBackground)
            )
        }
    }

    // MARK: - Nap Duration Section

    private var napDurationSection: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            sectionHeader(
                icon: "moon.fill",
                title: "sleepSchedule.napDuration.title".localized,
                color: NapletColors.primaryPurple
            )

            VStack(spacing: NapletSpacing.sm) {
                Toggle(isOn: $viewModel.useCustomNapDuration) {
                    Text("sleepSchedule.useCustom".localized)
                        .font(.system(size: NapletTypography.body))
                        .foregroundColor(NapletColors.textPrimary)
                }
                .tint(NapletColors.primaryPurple)

                if viewModel.useCustomNapDuration {
                    Stepper(
                        value: $viewModel.customNapDuration,
                        in: 15...180,
                        step: 15
                    ) {
                        Text("\(viewModel.customNapDuration) min")
                            .font(.system(size: NapletTypography.title3, weight: .semibold))
                            .foregroundColor(NapletColors.textPrimary)
                    }
                } else {
                    defaultValueLabel(
                        "sleepSchedule.default".localized(with: "60 min")
                    )
                }
            }
            .padding(NapletSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(NapletColors.cardBackground)
            )
        }
    }

    // MARK: - Wake Window Section

    private var wakeWindowSection: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            sectionHeader(
                icon: "clock.fill",
                title: "sleepSchedule.wakeWindow.title".localized,
                color: NapletColors.primaryCyan
            )

            VStack(spacing: NapletSpacing.sm) {
                Toggle(isOn: $viewModel.useCustomWakeWindow) {
                    Text("sleepSchedule.useCustom".localized)
                        .font(.system(size: NapletTypography.body))
                        .foregroundColor(NapletColors.textPrimary)
                }
                .tint(NapletColors.primaryPurple)

                if viewModel.useCustomWakeWindow {
                    Stepper(
                        value: $viewModel.customWakeWindow,
                        in: 30...360,
                        step: 15
                    ) {
                        Text("\(viewModel.customWakeWindow) min")
                            .font(.system(size: NapletTypography.title3, weight: .semibold))
                            .foregroundColor(NapletColors.textPrimary)
                    }
                } else {
                    defaultValueLabel(
                        "sleepSchedule.default".localized(with: viewModel.defaultWakeWindowFormatted)
                    )
                }
            }
            .padding(NapletSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(NapletColors.cardBackground)
            )
        }
    }

    // MARK: - Learned Data Card

    private var learnedDataCard: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            sectionHeader(
                icon: "brain.head.profile",
                title: "sleepSchedule.learned.title".localized,
                color: NapletColors.success
            )

            VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                Text("sleepSchedule.learned.description".localized(with: viewModel.daysOfData))
                    .font(.system(size: NapletTypography.caption))
                    .foregroundColor(NapletColors.textSecondary)

                if let wakeTime = viewModel.learnedWakeTime {
                    learnedValueRow(
                        icon: "sun.max.fill",
                        label: "sleepSchedule.wakeTime.title".localized,
                        value: wakeTime
                    )
                }

                if let bedtime = viewModel.learnedBedtime {
                    learnedValueRow(
                        icon: "moon.zzz.fill",
                        label: "sleepSchedule.bedtime.title".localized,
                        value: bedtime
                    )
                }

                if let napDuration = viewModel.learnedNapDuration {
                    learnedValueRow(
                        icon: "moon.fill",
                        label: "sleepSchedule.napDuration.title".localized,
                        value: "\(napDuration) min"
                    )
                }

                if let wakeWindow = viewModel.learnedWakeWindow {
                    learnedValueRow(
                        icon: "clock.fill",
                        label: "sleepSchedule.wakeWindow.title".localized,
                        value: "\(wakeWindow) min"
                    )
                }
            }
            .padding(NapletSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(NapletColors.success.opacity(0.1))
            )
        }
    }

    // MARK: - Reset Button

    private var resetButton: some View {
        Button {
            viewModel.resetToDefaults()
        } label: {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text("sleepSchedule.reset".localized)
            }
            .font(.system(size: NapletTypography.body))
            .foregroundColor(NapletColors.error)
        }
        .padding(.top, NapletSpacing.md)
    }

    // MARK: - Helper Views

    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: NapletSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: NapletTypography.headline, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)
        }
    }

    private func defaultValueLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: NapletTypography.subheadline))
            .foregroundColor(NapletColors.textMuted)
            .padding(.vertical, NapletSpacing.sm)
    }

    private func learnedValueRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(NapletColors.textMuted)
                .frame(width: 20)

            Text(label)
                .font(.system(size: NapletTypography.caption))
                .foregroundColor(NapletColors.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: NapletTypography.subheadline, weight: .medium))
                .foregroundColor(NapletColors.success)
        }
    }
}
