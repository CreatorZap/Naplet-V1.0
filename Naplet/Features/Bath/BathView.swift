import SwiftUI

// MARK: - Bath View
struct BathView: View {
    @StateObject private var viewModel: BathViewModel
    @Environment(\.dismiss) private var dismiss

    init(baby: Baby) {
        _viewModel = StateObject(wrappedValue: BathViewModel(baby: baby))
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

                    // Header with icon
                    headerSection

                    // Time selector
                    timeSection

                    // Duration selector
                    durationSection

                    // Bath type selector
                    bathTypeSection

                    // Mood selector
                    moodSection

                    // Notes
                    notesSection

                    // Today's summary
                    if viewModel.statistics.totalBathsToday > 0 {
                        todaySummarySection
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, NapletSpacing.lg)
            }

            // Save button overlay
            VStack {
                Spacer()
                saveButton
            }
        }
        .background(NapletColors.background)
        .task {
            await viewModel.loadData()
        }
        .alert("common.success".localized, isPresented: $viewModel.showSuccess) {
            Button("common.ok".localized) {
                dismiss()
            }
        } message: {
            Text("bath.saved".localized)
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
                    .fill(NapletColors.primaryCyan.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "bathtub.fill")
                    .font(.system(size: 48))
                    .foregroundColor(NapletColors.primaryCyan)
            }

            Text("bath.register".localized)
                .font(NapletTypography.title2())
                .foregroundColor(NapletColors.textPrimary)

            if let lastInfo = viewModel.lastBathInfo {
                Text("bath.last".localized + ": " + lastInfo)
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
                Text("bath.time".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: NapletSpacing.xl) {
                    // Minus button
                    Button {
                        viewModel.subtractOneMinute()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(NapletColors.primaryCyan)
                            Text("-1 min")
                                .font(NapletTypography.caption())
                                .foregroundColor(NapletColors.textSecondary)
                        }
                    }

                    // Time display
                    VStack(spacing: 4) {
                        Text(viewModel.formattedTime)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(NapletColors.textPrimary)

                        Text(formattedDate)
                            .font(NapletTypography.caption())
                            .foregroundColor(NapletColors.textMuted)
                    }
                    .frame(minWidth: 140)

                    // Plus button
                    Button {
                        viewModel.addOneMinute()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(NapletColors.primaryCyan)
                            Text("+1 min")
                                .font(NapletTypography.caption())
                                .foregroundColor(NapletColors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: viewModel.startTime)
    }

    // MARK: - Duration Section
    private var durationSection: some View {
        NapletCard {
            VStack(spacing: NapletSpacing.md) {
                Text("bath.duration".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: NapletSpacing.lg) {
                    // Minus button
                    Button {
                        viewModel.adjustDuration(by: -1)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(NapletColors.primaryCyan)
                    }

                    // Duration display
                    HStack(spacing: NapletSpacing.xs) {
                        Text("\(viewModel.durationMinutes)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(NapletColors.textPrimary)
                            .frame(minWidth: 60)

                        Text("min")
                            .font(NapletTypography.body())
                            .foregroundColor(NapletColors.textSecondary)
                    }

                    // Plus button
                    Button {
                        viewModel.adjustDuration(by: 1)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(NapletColors.primaryCyan)
                    }
                }

                // Quick duration buttons
                HStack(spacing: NapletSpacing.sm) {
                    ForEach([5, 10, 15, 20], id: \.self) { minutes in
                        Button {
                            viewModel.setDuration(minutes)
                        } label: {
                            Text("\(minutes)m")
                                .font(NapletTypography.caption(weight: .medium))
                                .foregroundColor(
                                    viewModel.durationMinutes == minutes
                                        ? .white
                                        : NapletColors.textSecondary
                                )
                                .padding(.horizontal, NapletSpacing.md)
                                .padding(.vertical, NapletSpacing.sm)
                                .background(
                                    viewModel.durationMinutes == minutes
                                        ? NapletColors.primaryCyan
                                        : NapletColors.backgroundTertiary
                                )
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Bath Type Section
    private var bathTypeSection: some View {
        NapletCard {
            VStack(spacing: NapletSpacing.md) {
                Text("bath.type".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: NapletSpacing.md) {
                    ForEach(BathType.allCases, id: \.self) { type in
                        BathTypeButton(
                            type: type,
                            isSelected: viewModel.selectedBathType == type
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.selectedBathType = type
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Mood Section
    private var moodSection: some View {
        NapletCard {
            VStack(spacing: NapletSpacing.md) {
                Text("bath.mood".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: NapletSpacing.lg) {
                    ForEach(BathMood.allCases, id: \.self) { mood in
                        BathMoodButton(
                            mood: mood,
                            isSelected: viewModel.selectedMood == mood
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.selectedMood = mood
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
                Text("bath.notes".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)

                TextField("bath.notesPlaceholder".localized, text: $viewModel.notes, axis: .vertical)
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textPrimary)
                    .lineLimit(2...4)
                    .padding(NapletSpacing.md)
                    .background(NapletColors.background)
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - Today's Summary Section
    private var todaySummarySection: some View {
        NapletCard {
            VStack(spacing: NapletSpacing.md) {
                Text("bath.today".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: NapletSpacing.lg) {
                    BathStatItem(
                        icon: "bathtub.fill",
                        count: viewModel.statistics.bathtubCount,
                        label: "bath.type.bathtub".localized,
                        color: NapletColors.primaryCyan
                    )

                    BathStatItem(
                        icon: "shower.fill",
                        count: viewModel.statistics.showerCount,
                        label: "bath.type.shower".localized,
                        color: NapletColors.primaryBlue
                    )

                    BathStatItem(
                        icon: "drop.fill",
                        count: viewModel.statistics.spongeCount,
                        label: "bath.type.sponge".localized,
                        color: NapletColors.info
                    )
                }
            }
        }
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            Task {
                await viewModel.saveBath()
            }
        } label: {
            HStack {
                if viewModel.isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("bath.save".localized)
                }
            }
            .font(NapletTypography.body(weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NapletSpacing.md)
            .background(viewModel.selectedBathType.color)
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

// MARK: - Bath Type Button
struct BathTypeButton: View {
    let type: BathType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: NapletSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(isSelected ? type.color : NapletColors.cardBackground)
                        .frame(width: 56, height: 56)

                    Image(systemName: type.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : type.color)
                }

                Text(type.displayName)
                    .font(NapletTypography.caption(weight: .medium))
                    .foregroundColor(isSelected ? NapletColors.textPrimary : NapletColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NapletSpacing.md)
            .background(isSelected ? type.color.opacity(0.15) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Bath Mood Button
struct BathMoodButton: View {
    let mood: BathMood
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: NapletSpacing.xs) {
                Image(systemName: mood.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(isSelected ? mood.color : NapletColors.textSecondary)

                Text(mood.displayName)
                    .font(NapletTypography.caption(weight: .medium))
                    .foregroundColor(isSelected ? NapletColors.textPrimary : NapletColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NapletSpacing.md)
            .background(isSelected ? mood.color.opacity(0.15) : NapletColors.backgroundTertiary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? mood.color : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Bath Stat Item
struct BathStatItem: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)

                Text("\(count)")
                    .font(NapletTypography.statsNumber())
                    .foregroundColor(NapletColors.textPrimary)
            }

            Text(label)
                .font(NapletTypography.caption())
                .foregroundColor(NapletColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview {
    BathView(baby: Baby.preview)
}
