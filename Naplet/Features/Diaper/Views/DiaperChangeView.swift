import SwiftUI

// MARK: - Diaper Change View
struct DiaperChangeView: View {
    @StateObject private var viewModel: DiaperViewModel
    @Environment(\.dismiss) private var dismiss

    init(baby: Baby) {
        _viewModel = StateObject(wrappedValue: DiaperViewModel(baby: baby))
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

                    // Content type selector
                    contentTypeSection

                    // Optional weight
                    weightSection

                    // Notes
                    notesSection

                    // Today's summary
                    if viewModel.statistics.totalCount > 0 {
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
            Text("diaper.saved".localized)
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
                    .fill(NapletColors.primaryPurple.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "humidity.fill")
                    .font(.system(size: 48))
                    .foregroundColor(NapletColors.primaryPurple)
            }

            Text("diaper.change".localized)
                .font(NapletTypography.title2())
                .foregroundColor(NapletColors.textPrimary)

            if let lastInfo = viewModel.lastChangeInfo {
                Text("diaper.last".localized + ": " + lastInfo)
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
                Text("diaper.time".localized)
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
                                .foregroundColor(NapletColors.primaryPurple)
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

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: viewModel.changedAt)
    }

    // MARK: - Content Type Section
    private var contentTypeSection: some View {
        NapletCard {
            VStack(spacing: NapletSpacing.md) {
                Text("diaper.content".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: NapletSpacing.md) {
                    ForEach(DiaperContent.allCases, id: \.self) { content in
                        DiaperContentButton(
                            content: content,
                            isSelected: viewModel.selectedContent == content
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.selectedContent = content
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Weight Section
    private var weightSection: some View {
        NapletCard {
            VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                HStack {
                    Text("diaper.weight".localized)
                        .font(NapletTypography.caption(weight: .semibold))
                        .foregroundColor(NapletColors.textSecondary)

                    Text("(\("common.optional".localized))")
                        .font(NapletTypography.caption())
                        .foregroundColor(NapletColors.textMuted)
                }

                HStack {
                    TextField("0", text: $viewModel.weightGrams)
                        .keyboardType(.numberPad)
                        .font(NapletTypography.title2())
                        .foregroundColor(NapletColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .frame(width: 100)
                        .padding(.vertical, NapletSpacing.sm)
                        .background(NapletColors.background)
                        .cornerRadius(8)

                    Text("g")
                        .font(NapletTypography.body())
                        .foregroundColor(NapletColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        NapletCard {
            VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                Text("diaper.notes".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)

                TextField("diaper.notesPlaceholder".localized, text: $viewModel.notes, axis: .vertical)
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
                Text("diaper.today".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: NapletSpacing.lg) {
                    DiaperStatItem(
                        icon: "drop.fill",
                        count: viewModel.statistics.wetCount,
                        label: "diaper.wet".localized,
                        color: NapletColors.info
                    )

                    DiaperStatItem(
                        icon: "leaf.fill",
                        count: viewModel.statistics.dirtyCount,
                        label: "diaper.dirty".localized,
                        color: NapletColors.warning
                    )

                    DiaperStatItem(
                        icon: "drop.triangle.fill",
                        count: viewModel.statistics.mixedCount,
                        label: "diaper.mixed".localized,
                        color: NapletColors.primaryPurple
                    )
                }
            }
        }
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            Task {
                await viewModel.saveDiaperChange()
            }
        } label: {
            HStack {
                if viewModel.isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("diaper.save".localized)
                }
            }
            .font(NapletTypography.body(weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NapletSpacing.md)
            .background(viewModel.selectedContent.color)
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

// MARK: - Diaper Content Button
struct DiaperContentButton: View {
    let content: DiaperContent
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: NapletSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(isSelected ? content.color : NapletColors.cardBackground)
                        .frame(width: 56, height: 56)

                    Image(systemName: content.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : content.color)
                }

                Text(content.displayName)
                    .font(NapletTypography.caption(weight: .medium))
                    .foregroundColor(isSelected ? NapletColors.textPrimary : NapletColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NapletSpacing.md)
            .background(isSelected ? content.color.opacity(0.15) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? content.color : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Diaper Stat Item
struct DiaperStatItem: View {
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
    DiaperChangeView(baby: Baby.preview)
}
