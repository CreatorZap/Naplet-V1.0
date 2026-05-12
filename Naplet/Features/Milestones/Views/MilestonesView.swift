import SwiftUI

// MARK: - Milestones View
struct MilestonesView: View {
    @StateObject private var viewModel: MilestonesViewModel
    @Environment(\.dismiss) private var dismiss

    init(babyId: UUID, ageInMonths: Int) {
        _viewModel = StateObject(wrappedValue: MilestonesViewModel(babyId: babyId, ageInMonths: ageInMonths))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: NapletSpacing.lg) {
                // Progress header
                progressHeader

                // Category filter chips
                categoryFilter

                // Milestone list
                milestoneList
            }
            .padding(.vertical, NapletSpacing.md)
        }
        .background(NapletColors.background.ignoresSafeArea())
        .navigationTitle("milestones.title".localized)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadMilestones()
        }
        .sheet(isPresented: $viewModel.showingAchieveSheet) {
            achieveSheet
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: NapletSpacing.md) {
            // Overall progress ring
            ZStack {
                Circle()
                    .stroke(NapletColors.backgroundTertiary, lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: viewModel.overallProgress)
                    .stroke(
                        LinearGradient(
                            colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(viewModel.achievedCount)")
                        .font(.system(size: NapletTypography.title2, weight: .bold, design: .rounded))
                        .foregroundColor(NapletColors.textPrimary)
                    Text("/\(viewModel.totalCount)")
                        .font(.system(size: NapletTypography.caption, weight: .medium))
                        .foregroundColor(NapletColors.textMuted)
                }
            }

            Text("milestones.progress".localized)
                .font(.system(size: NapletTypography.subheadline, weight: .medium))
                .foregroundColor(NapletColors.textSecondary)

            // Category progress bars
            VStack(spacing: NapletSpacing.sm) {
                ForEach(MilestoneCategory.allCases, id: \.rawValue) { category in
                    categoryProgressRow(category)
                }
            }
            .padding(.horizontal, NapletSpacing.lg)
        }
        .padding(NapletSpacing.lg)
        .background(NapletColors.backgroundSecondary)
        .cornerRadius(20)
        .padding(.horizontal, NapletSpacing.lg)
    }

    private func categoryProgressRow(_ category: MilestoneCategory) -> some View {
        HStack(spacing: NapletSpacing.sm) {
            Image(systemName: category.iconName)
                .font(.system(size: 14))
                .foregroundColor(NapletColors.primaryPurple)
                .frame(width: 20)

            Text(category.nameKey.localized)
                .font(.system(size: NapletTypography.caption, weight: .medium))
                .foregroundColor(NapletColors.textSecondary)
                .frame(width: 80, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(NapletColors.backgroundTertiary)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(NapletColors.primaryPurple)
                        .frame(width: max(geometry.size.width * viewModel.categoryProgress(for: category), 0), height: 6)
                }
            }
            .frame(height: 6)

            Text("\(viewModel.categoryAchievedCount(for: category))/\(viewModel.categoryTotalCount(for: category))")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(NapletColors.textMuted)
                .frame(width: 30, alignment: .trailing)
        }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NapletSpacing.sm) {
                // All category chip
                filterChip(
                    title: "milestones.filter.all".localized,
                    icon: "square.grid.2x2.fill",
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.selectedCategory = nil
                }

                ForEach(MilestoneCategory.allCases, id: \.rawValue) { category in
                    filterChip(
                        title: category.nameKey.localized,
                        icon: category.iconName,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, NapletSpacing.lg)
        }
    }

    private func filterChip(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: NapletSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: NapletTypography.caption, weight: .medium))
            }
            .padding(.horizontal, NapletSpacing.md)
            .padding(.vertical, NapletSpacing.sm)
            .background(isSelected ? NapletColors.primaryPurple : NapletColors.backgroundTertiary)
            .foregroundColor(isSelected ? .white : NapletColors.textSecondary)
            .cornerRadius(NapletSpacing.radiusFull)
        }
    }

    // MARK: - Milestone List

    private var milestoneList: some View {
        LazyVStack(spacing: NapletSpacing.sm) {
            if viewModel.isLoading {
                ProgressView()
                    .tint(NapletColors.primaryPurple)
                    .padding(NapletSpacing.xl)
            } else {
                ForEach(viewModel.filteredMilestones) { milestone in
                    milestoneRow(milestone)
                }
            }
        }
        .padding(.horizontal, NapletSpacing.lg)
    }

    private func milestoneRow(_ milestone: MilestoneDefinition) -> some View {
        let status = viewModel.status(for: milestone)
        let isAchieved = status == .achieved

        return Button {
            if isAchieved {
                // Show options (remove)
            } else {
                viewModel.prepareMilestoneAchieve(milestone)
            }
        } label: {
            HStack(spacing: NapletSpacing.md) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(statusColor(status).opacity(0.15))
                        .frame(width: 44, height: 44)

                    if isAchieved {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(NapletColors.success)
                    } else {
                        Image(systemName: milestone.iconName)
                            .font(.system(size: 18))
                            .foregroundColor(statusColor(status))
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(milestone.name)
                        .font(.system(size: NapletTypography.subheadline, weight: .semibold))
                        .foregroundColor(isAchieved ? NapletColors.textSecondary : NapletColors.textPrimary)
                        .strikethrough(isAchieved)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(milestone.description)
                        .font(.system(size: NapletTypography.caption))
                        .foregroundColor(NapletColors.textMuted)
                        .fixedSize(horizontal: false, vertical: true)

                    if isAchieved, let record = viewModel.achievementRecord(for: milestone.id) {
                        Text(String(format: "milestones.achieved_on".localized, formatDate(record.achievedDateValue ?? Date())))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(NapletColors.success.opacity(0.8))
                    } else {
                        Text(String(format: "milestones.expected_age".localized, "\(milestone.expectedAgeMonths)"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(statusColor(status).opacity(0.8))
                    }
                }

                Spacer(minLength: NapletSpacing.sm)

                // Action indicator
                if !isAchieved {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(NapletColors.primaryPurple.opacity(0.6))
                }
            }
            .padding(NapletSpacing.md)
            .background(NapletColors.backgroundSecondary)
            .cornerRadius(NapletSpacing.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: NapletSpacing.radiusMedium)
                    .stroke(
                        isAchieved ? NapletColors.success.opacity(0.2) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .contextMenu {
            if isAchieved {
                Button(role: .destructive) {
                    Task {
                        await viewModel.removeAchievement(for: milestone.id)
                    }
                } label: {
                    Label("milestones.remove".localized, systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Achieve Sheet

    private var achieveSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NapletSpacing.lg) {
                    if let milestone = viewModel.selectedMilestone {
                        // Milestone info
                        VStack(spacing: NapletSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(NapletColors.primaryPurple.opacity(0.15))
                                    .frame(width: 64, height: 64)

                                Image(systemName: milestone.iconName)
                                    .font(.system(size: 28))
                                    .foregroundColor(NapletColors.primaryPurple)
                            }

                            Text(milestone.name)
                                .font(.system(size: NapletTypography.title3, weight: .bold))
                                .foregroundColor(NapletColors.textPrimary)
                                .multilineTextAlignment(.center)

                            Text(milestone.description)
                                .font(.system(size: NapletTypography.subheadline))
                                .foregroundColor(NapletColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, NapletSpacing.lg)
                    }

                    // Date picker
                    VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                        Text("milestones.achieve_date".localized)
                            .font(.system(size: NapletTypography.subheadline, weight: .semibold))
                            .foregroundColor(NapletColors.textPrimary)

                        DatePicker(
                            "",
                            selection: $viewModel.achieveDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .tint(NapletColors.primaryPurple)
                    }
                    .padding(NapletSpacing.md)
                    .background(NapletColors.backgroundSecondary)
                    .cornerRadius(NapletSpacing.radiusMedium)

                    // Notes
                    VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                        Text("milestones.notes".localized)
                            .font(.system(size: NapletTypography.subheadline, weight: .semibold))
                            .foregroundColor(NapletColors.textPrimary)

                        TextField("milestones.notes_placeholder".localized, text: $viewModel.achieveNotes, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(NapletSpacing.md)
                            .background(NapletColors.backgroundTertiary)
                            .cornerRadius(NapletSpacing.radiusSmall)
                            .foregroundColor(NapletColors.textPrimary)
                    }
                    .padding(NapletSpacing.md)
                    .background(NapletColors.backgroundSecondary)
                    .cornerRadius(NapletSpacing.radiusMedium)

                    // Error message
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

                    // Save button
                    Button {
                        Task {
                            await viewModel.markAchieved()
                        }
                    } label: {
                        HStack {
                            if viewModel.isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("milestones.mark_achieved".localized)
                                    .font(.system(size: NapletTypography.body, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: NapletSpacing.buttonHeightLarge)
                        .background(NapletColors.primaryPurple)
                        .foregroundColor(.white)
                        .cornerRadius(NapletSpacing.radiusMedium)
                    }
                    .disabled(viewModel.isSaving)
                }
                .padding(.horizontal, NapletSpacing.lg)
            }
            .background(NapletColors.background.ignoresSafeArea())
            .navigationTitle("milestones.achieve_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("milestones.cancel".localized) {
                        viewModel.showingAchieveSheet = false
                    }
                    .foregroundColor(NapletColors.primaryPurple)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Helpers

    private func statusColor(_ status: MilestoneStatus) -> Color {
        switch status {
        case .achieved:
            return NapletColors.success
        case .expected:
            return NapletColors.warning
        case .upcoming:
            return NapletColors.primaryPurple
        case .late:
            return NapletColors.primaryPink
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
