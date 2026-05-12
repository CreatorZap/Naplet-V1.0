import SwiftUI

// MARK: - Add Growth Record View
struct AddGrowthRecordView: View {
    @ObservedObject var viewModel: GrowthViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: GrowthField?

    enum GrowthField {
        case weight, height, head
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NapletSpacing.lg) {
                    // Date picker
                    dateSection

                    // Measurements
                    measurementsSection

                    // Unit info
                    unitInfo

                    // Notes
                    notesSection

                    // Save button
                    saveButton
                }
                .padding(.horizontal, NapletSpacing.lg)
                .padding(.vertical, NapletSpacing.md)
            }
            .background(NapletColors.background.ignoresSafeArea())
            .navigationTitle("growth.add_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("growth.cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(NapletColors.primaryPurple)
                }

                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("growth.done".localized) {
                            focusedField = nil
                        }
                        .foregroundColor(NapletColors.primaryPurple)
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Date Section

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            Text("growth.date".localized)
                .font(.system(size: NapletTypography.subheadline, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)

            DatePicker(
                "",
                selection: $viewModel.addDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .tint(NapletColors.primaryPurple)
            .labelsHidden()
        }
        .padding(NapletSpacing.md)
        .background(NapletColors.backgroundSecondary)
        .cornerRadius(NapletSpacing.radiusMedium)
    }

    // MARK: - Measurements Section

    private var measurementsSection: some View {
        VStack(spacing: NapletSpacing.md) {
            measurementField(
                icon: "scalemass.fill",
                title: "growth.weight".localized,
                placeholder: "0.00",
                unitLabel: viewModel.unit.weightLabel,
                text: $viewModel.addWeightText,
                color: NapletColors.primaryPurple,
                field: .weight
            )

            measurementField(
                icon: "ruler.fill",
                title: "growth.height".localized,
                placeholder: "0.0",
                unitLabel: viewModel.unit.lengthLabel,
                text: $viewModel.addHeightText,
                color: NapletColors.primaryBlue,
                field: .height
            )

            measurementField(
                icon: "circle.dashed",
                title: "growth.head".localized,
                placeholder: "0.0",
                unitLabel: viewModel.unit.lengthLabel,
                text: $viewModel.addHeadText,
                color: NapletColors.primaryPink,
                field: .head
            )
        }
        .padding(NapletSpacing.md)
        .background(NapletColors.backgroundSecondary)
        .cornerRadius(NapletSpacing.radiusMedium)
    }

    private func measurementField(
        icon: String,
        title: String,
        placeholder: String,
        unitLabel: String,
        text: Binding<String>,
        color: Color,
        field: GrowthField
    ) -> some View {
        HStack(spacing: NapletSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: NapletTypography.caption, weight: .medium))
                    .foregroundColor(NapletColors.textMuted)

                HStack(spacing: NapletSpacing.xs) {
                    TextField(placeholder, text: text)
                        .keyboardType(.decimalPad)
                        .font(.system(size: NapletTypography.body, weight: .semibold, design: .rounded))
                        .foregroundColor(NapletColors.textPrimary)
                        .focused($focusedField, equals: field)

                    Text(unitLabel)
                        .font(.system(size: NapletTypography.subheadline, weight: .medium))
                        .foregroundColor(NapletColors.textMuted)
                }
            }
        }
        .padding(NapletSpacing.sm)
    }

    // MARK: - Unit Info

    private var unitInfo: some View {
        Button {
            withAnimation { viewModel.toggleUnit() }
        } label: {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 14))

                Text(viewModel.unit == .metric
                     ? "growth.switch_imperial".localized
                     : "growth.switch_metric".localized)
                    .font(.system(size: NapletTypography.caption, weight: .medium))

                Spacer()

                Text(viewModel.unit == .metric ? "kg / cm" : "lb / in")
                    .font(.system(size: NapletTypography.caption, weight: .semibold))
                    .foregroundColor(NapletColors.primaryPurple)
            }
            .foregroundColor(NapletColors.textSecondary)
            .padding(NapletSpacing.md)
            .background(NapletColors.backgroundTertiary)
            .cornerRadius(NapletSpacing.radiusSmall)
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            Text("growth.notes".localized)
                .font(.system(size: NapletTypography.subheadline, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)

            TextField("growth.notes_placeholder".localized, text: $viewModel.addNotes, axis: .vertical)
                .lineLimit(3...5)
                .padding(NapletSpacing.md)
                .background(NapletColors.backgroundTertiary)
                .cornerRadius(NapletSpacing.radiusSmall)
                .foregroundColor(NapletColors.textPrimary)
        }
        .padding(NapletSpacing.md)
        .background(NapletColors.backgroundSecondary)
        .cornerRadius(NapletSpacing.radiusMedium)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        let hasData = !viewModel.addWeightText.isEmpty
            || !viewModel.addHeightText.isEmpty
            || !viewModel.addHeadText.isEmpty

        return VStack(spacing: NapletSpacing.sm) {
            if let saveError = viewModel.saveError {
                HStack(spacing: NapletSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(NapletColors.error)
                    Text(saveError)
                        .font(.system(size: NapletTypography.caption))
                        .foregroundColor(NapletColors.error)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(NapletSpacing.md)
                .background(NapletColors.error.opacity(0.1))
                .cornerRadius(NapletSpacing.radiusSmall)
            }

            Button {
            Task {
                await viewModel.saveRecord()
            }
        } label: {
            HStack {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("growth.save".localized)
                        .font(.system(size: NapletTypography.body, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: NapletSpacing.buttonHeightLarge)
            .background(hasData ? NapletColors.primaryPurple : NapletColors.backgroundTertiary)
            .foregroundColor(hasData ? .white : NapletColors.textMuted)
            .cornerRadius(NapletSpacing.radiusMedium)
        }
        .disabled(viewModel.isSaving || !hasData)
        }
    }
}
