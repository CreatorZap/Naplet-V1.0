import SwiftUI

// MARK: - Sleep Start Mood Picker

struct SleepStartMoodPicker: View {
    @Binding var selectedMood: SleepStartMood?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "moon.zzz.fill")
                    .foregroundColor(NapletColors.primaryPurple)

                Text("how_fell_asleep".localized)
                    .font(.headline)
                    .foregroundColor(NapletColors.textPrimary)

                Spacer()

                Text("common.optional".localized)
                    .font(.caption)
                    .foregroundColor(NapletColors.textSecondary)
            }

            HStack(spacing: 12) {
                ForEach(SleepStartMood.allCases) { mood in
                    SleepMoodButton(
                        icon: mood.icon,
                        title: mood.displayName,
                        color: mood.color,
                        isSelected: selectedMood == mood
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedMood = selectedMood == mood ? nil : mood
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
        )
    }
}

// MARK: - Wake Type Picker

struct WakeTypePicker: View {
    @Binding var selectedType: WakeType?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "sunrise.fill")
                    .foregroundColor(NapletColors.primaryPurple)

                Text("how_woke_up".localized)
                    .font(.headline)
                    .foregroundColor(NapletColors.textPrimary)

                Spacer()

                Text("common.optional".localized)
                    .font(.caption)
                    .foregroundColor(NapletColors.textSecondary)
            }

            HStack(spacing: 12) {
                ForEach(WakeType.allCases) { type in
                    SleepMoodButton(
                        icon: type.icon,
                        title: type.displayName,
                        color: type.color,
                        isSelected: selectedType == type
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedType = selectedType == type ? nil : type
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
        )
    }
}

// MARK: - Wake Mood Picker

struct WakeMoodPicker: View {
    @Binding var selectedMood: WakeMood?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "face.smiling.fill")
                    .foregroundColor(NapletColors.primaryPurple)

                Text("mood_when_woke".localized)
                    .font(.headline)
                    .foregroundColor(NapletColors.textPrimary)

                Spacer()

                Text("common.optional".localized)
                    .font(.caption)
                    .foregroundColor(NapletColors.textSecondary)
            }

            HStack(spacing: 12) {
                ForEach(WakeMood.allCases) { mood in
                    SleepMoodButton(
                        icon: mood.icon,
                        title: mood.displayName,
                        color: mood.color,
                        isSelected: selectedMood == mood
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedMood = selectedMood == mood ? nil : mood
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
        )
    }
}

// MARK: - Reusable Mood Button

struct SleepMoodButton: View {
    let icon: String
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(isSelected ? color : NapletColors.textSecondary)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.2) : NapletColors.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .foregroundColor(isSelected ? color : NapletColors.textSecondary)
        }
        .buttonStyle(SleepScaleButtonStyle())
    }
}

// MARK: - Previews

#Preview("Sleep Start Mood") {
    ZStack {
        NapletColors.background.ignoresSafeArea()
        SleepStartMoodPicker(selectedMood: .constant(.easy))
            .padding()
    }
}

#Preview("Wake Type") {
    ZStack {
        NapletColors.background.ignoresSafeArea()
        WakeTypePicker(selectedType: .constant(.natural))
            .padding()
    }
}

#Preview("Wake Mood") {
    ZStack {
        NapletColors.background.ignoresSafeArea()
        WakeMoodPicker(selectedMood: .constant(.happy))
            .padding()
    }
}
