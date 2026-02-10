import SwiftUI

// MARK: - Temperature View
struct TemperatureView: View {
    @StateObject private var viewModel: HealthViewModel
    @Environment(\.dismiss) private var dismiss

    init(baby: Baby) {
        _viewModel = StateObject(wrappedValue: HealthViewModel(baby: baby))
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: NapletSpacing.xl) {
                    // Drag Indicator
                    Capsule()
                        .fill(NapletColors.textMuted.opacity(0.3))
                        .frame(width: 36, height: 5)
                        .padding(.top, NapletSpacing.sm)

                    // Header
                    headerSection

                    // Time selector
                    timeSection

                    // Temperature slider
                    temperatureSection

                    // Notes
                    notesSection

                    // Today's records
                    if !viewModel.todayTemperatures.isEmpty {
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
        .background(NapletColors.background)
        .task {
            await viewModel.loadTemperatures()
        }
        .alert("common.success".localized, isPresented: $viewModel.showSuccess) {
            Button("common.ok".localized) {
                dismiss()
            }
        } message: {
            Text("health.temp.saved".localized)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: NapletSpacing.sm) {
            ZStack {
                Circle()
                    .fill(viewModel.temperatureStatus.color.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "thermometer.medium")
                    .font(.system(size: 48))
                    .foregroundColor(viewModel.temperatureStatus.color)
            }

            Text("health.temperature.record".localized)
                .font(NapletTypography.title2())
                .foregroundColor(NapletColors.textPrimary)

            if let lastInfo = viewModel.lastTemperatureInfo {
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
                        viewModel.adjustTemperatureTime(by: -60)
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

                    Text(viewModel.formattedTemperatureTime)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(NapletColors.textPrimary)
                        .frame(minWidth: 140)

                    Button {
                        viewModel.adjustTemperatureTime(by: 60)
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

    // MARK: - Temperature Section
    private var temperatureSection: some View {
        NapletCard {
            VStack(spacing: NapletSpacing.lg) {
                // Temperature display
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", viewModel.temperature))
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(viewModel.temperatureStatus.color)

                    Text("°C")
                        .font(NapletTypography.title2())
                        .foregroundColor(NapletColors.textSecondary)
                }

                // Status badge
                Text(viewModel.temperatureStatus.displayName)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(viewModel.temperatureStatus.color)
                    .cornerRadius(20)

                // Slider
                VStack(spacing: NapletSpacing.sm) {
                    Slider(
                        value: $viewModel.temperature,
                        in: 35.0...42.0,
                        step: 0.1
                    )
                    .tint(viewModel.temperatureStatus.color)

                    HStack {
                        Text("35.0°C")
                            .font(NapletTypography.caption())
                            .foregroundColor(NapletColors.textMuted)

                        Spacer()

                        Text("42.0°C")
                            .font(NapletTypography.caption())
                            .foregroundColor(NapletColors.textMuted)
                    }
                }

                // Quick temperature buttons
                HStack(spacing: NapletSpacing.sm) {
                    ForEach([36.5, 37.0, 37.5, 38.0, 38.5], id: \.self) { temp in
                        QuickTempButton(
                            temp: temp,
                            isSelected: abs(viewModel.temperature - temp) < 0.1
                        ) {
                            withAnimation {
                                viewModel.temperature = temp
                            }
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

                TextField("health.notesPlaceholder".localized, text: $viewModel.temperatureNotes, axis: .vertical)
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

                ForEach(viewModel.todayTemperatures.prefix(5)) { record in
                    HStack {
                        Circle()
                            .fill(record.temperatureStatus?.color ?? NapletColors.success)
                            .frame(width: 8, height: 8)

                        Text(record.formattedTemperature ?? "-")
                            .font(NapletTypography.body(weight: .semibold))
                            .foregroundColor(NapletColors.textPrimary)

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
                await viewModel.saveTemperature()
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
            .background(viewModel.temperatureStatus.color)
            .cornerRadius(16)
        }
        .disabled(viewModel.isSaving)
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

// MARK: - Quick Temp Button
struct QuickTempButton: View {
    let temp: Double
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(String(format: "%.1f", temp))
                .font(NapletTypography.caption(weight: .medium))
                .foregroundColor(isSelected ? .white : NapletColors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(isSelected ? NapletColors.error : NapletColors.cardBackground)
                .cornerRadius(8)
        }
    }
}

// MARK: - Preview
#Preview {
    TemperatureView(baby: Baby.preview)
}
