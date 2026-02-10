import SwiftUI

// MARK: - Sleep Tracking View
struct SleepTrackingView: View {
    @StateObject private var viewModel = SleepTrackingViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showEndSleepSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: NapletSpacing.xl) {
                // Header
                headerSection

                // Timer Display
                timerSection

                // Status (sleep type selector)
                statusSection

                // Location picker (antes de começar o sono)
                if !viewModel.isTracking {
                    SleepLocationPicker(selectedLocation: $viewModel.sleepLocation)

                    SleepStartMoodPicker(selectedMood: $viewModel.sleepStartMood)
                }

                // Actions
                actionsSection
                    .padding(.top, NapletSpacing.lg)
            }
            .padding(NapletSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NapletColors.background)
        .sheet(isPresented: $showEndSleepSheet) {
            EndSleepSheet(viewModel: viewModel) {
                dismiss()
            }
            .presentationBackground(NapletColors.background)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                NapletIcon("xmark", size: .medium, color: NapletColors.textSecondary)
            }

            Spacer()

            Text(viewModel.isTracking ? "sleep.tracking".localized : "sleep.startTracking".localized)
                .font(NapletTypography.headline())
                .foregroundColor(NapletColors.textPrimary)

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 24, height: 24)
        }
    }

    // MARK: - Timer Section
    private var timerSection: some View {
        VStack(spacing: NapletSpacing.md) {
            // Sleep icon with animation
            ZStack {
                Circle()
                    .fill(
                        viewModel.isTracking
                            ? NapletColors.sleepActive.opacity(0.1)
                            : NapletColors.backgroundSecondary
                    )
                    .frame(width: 120, height: 120)

                if viewModel.isTracking {
                    NapletAnimatedIcon(
                        "moon.zzz.fill",
                        size: .xLarge,
                        color: NapletColors.sleepActive,
                        animation: .pulse
                    )
                } else {
                    NapletIcon(
                        "moon.fill",
                        size: .xLarge,
                        color: NapletColors.textMuted
                    )
                }
            }

            // Timer
            Text(viewModel.elapsedTimeFormatted)
                .font(NapletTypography.numberDisplay(size: 56))
                .foregroundColor(NapletColors.textPrimary)
                .monospacedDigit()

            // Start time
            if viewModel.isTracking, let startTime = viewModel.startTime {
                Text("sleep.startedAt".localized(with: startTime.timeString))
                    .font(NapletTypography.subheadline())
                    .foregroundColor(NapletColors.textSecondary)
            }
        }
    }

    // MARK: - Status Section
    private var statusSection: some View {
        VStack(spacing: NapletSpacing.md) {
            // Sleep type selector
            HStack(spacing: NapletSpacing.sm) {
                ForEach(SleepRecord.SleepType.allCases, id: \.self) { type in
                    sleepTypeButton(type)
                }
            }
        }
    }

    private func sleepTypeButton(_ type: SleepRecord.SleepType) -> some View {
        Button {
            viewModel.selectedType = type
        } label: {
            HStack(spacing: NapletSpacing.xs) {
                Image(systemName: type.icon)
                Text(type.displayName)
            }
            .font(NapletTypography.subheadline(weight: .medium))
            .foregroundColor(
                viewModel.selectedType == type
                    ? .white
                    : NapletColors.textSecondary
            )
            .padding(.horizontal, NapletSpacing.md)
            .padding(.vertical, NapletSpacing.sm)
            .background(
                viewModel.selectedType == type
                    ? type.color
                    : NapletColors.backgroundSecondary
            )
            .cornerRadius(NapletSpacing.radiusMedium)
        }
        .disabled(viewModel.isTracking)
    }

    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: NapletSpacing.md) {
            if viewModel.isTracking {
                // End sleep button
                NapletButton(
                    "sleep.endSleep".localized,
                    style: .primary,
                    size: .large,
                    icon: "sun.max.fill",
                    isFullWidth: true
                ) {
                    showEndSleepSheet = true
                }

                // Cancel button
                NapletButton(
                    L10n.Common.cancel.localized,
                    style: .ghost,
                    size: .medium,
                    isFullWidth: true
                ) {
                    viewModel.cancelTracking()
                    dismiss()
                }
            } else {
                // Start sleep button
                NapletButton(
                    "sleep.startTracking".localized,
                    style: .primary,
                    size: .large,
                    icon: "moon.zzz.fill",
                    isFullWidth: true
                ) {
                    viewModel.startTracking()
                }
            }
        }
    }
}

// MARK: - End Sleep Sheet

struct EndSleepSheet: View {
    @ObservedObject var viewModel: SleepTrackingViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNotesFocused: Bool
    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: NapletSpacing.lg) {
                        // Duration summary
                        VStack(spacing: NapletSpacing.sm) {
                            Text(viewModel.elapsedTimeFormatted)
                                .font(NapletTypography.numberDisplay(size: 48))
                                .foregroundColor(NapletColors.textPrimary)

                            Text("sleep_duration_label".localized)
                                .font(NapletTypography.subheadline())
                                .foregroundColor(NapletColors.textSecondary)
                        }
                        .padding(.top, NapletSpacing.lg)

                        // Wake type picker
                        WakeTypePicker(selectedType: $viewModel.wakeType)

                        // Wake mood picker
                        WakeMoodPicker(selectedMood: $viewModel.wakeMood)

                        // Quality picker
                        qualityPicker

                        // Notes
                        notesSection
                            .id("notesSection")

                        // Save button
                        NapletButton(
                            "common.save".localized,
                            style: .primary,
                            size: .large,
                            isFullWidth: true
                        ) {
                            isNotesFocused = false
                            viewModel.stopTracking()
                            dismiss()
                            onComplete()
                        }
                        .padding(.top, NapletSpacing.md)
                        .id("saveButton")
                        
                        // Extra padding for keyboard
                        Color.clear
                            .frame(height: 50)
                    }
                    .padding(NapletSpacing.lg)
                }
                .onChange(of: isNotesFocused) { _, focused in
                    if focused {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo("saveButton", anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(NapletColors.background.ignoresSafeArea())
            .navigationTitle("sleep.endSleep".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                
                // Toolbar para fechar teclado
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        isNotesFocused = false
                    } label: {
                        Text("common.done".localized)
                            .fontWeight(.semibold)
                            .foregroundColor(NapletColors.primaryPurple)
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var qualityPicker: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundColor(NapletColors.primaryPurple)

                Text("sleepQuality.title".localized)
                    .font(.headline)
                    .foregroundColor(NapletColors.textPrimary)

                Spacer()

                Text("common.optional".localized)
                    .font(.caption)
                    .foregroundColor(NapletColors.textSecondary)
            }

            HStack(spacing: 12) {
                ForEach(SleepRecord.SleepQuality.allCases, id: \.self) { quality in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedQuality = viewModel.selectedQuality == quality ? nil : quality
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: quality.icon)
                                .font(.system(size: 24))

                            Text(quality.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.selectedQuality == quality
                                    ? quality.color.opacity(0.2)
                                    : NapletColors.backgroundSecondary)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.selectedQuality == quality ? quality.color : Color.clear, lineWidth: 2)
                        )
                        .foregroundColor(viewModel.selectedQuality == quality ? quality.color : NapletColors.textSecondary)
                    }
                    .buttonStyle(SleepScaleButtonStyle())
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
        )
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "note.text")
                    .foregroundColor(NapletColors.primaryPurple)

                Text("sleepQuality.notes".localized)
                    .font(.headline)
                    .foregroundColor(NapletColors.textPrimary)

                Spacer()

                Text("common.optional".localized)
                    .font(.caption)
                    .foregroundColor(NapletColors.textSecondary)
            }

            TextField("sleepQuality.notesPlaceholder".localized, text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(NapletColors.backgroundSecondary)
                )
                .focused($isNotesFocused)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
        )
    }
}

// MARK: - Preview
#Preview {
    SleepTrackingView()
}
