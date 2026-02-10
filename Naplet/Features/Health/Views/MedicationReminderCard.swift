import SwiftUI

// MARK: - Medication Reminder Card
/// Card que mostra o próximo medicamento a ser dado
struct MedicationReminderCard: View {
    let schedule: MedicationSchedule
    let babyName: String
    let onGiven: () -> Void
    let onSnooze: (SnoozeDuration) -> Void
    let onSkip: () -> Void
    let onTap: () -> Void

    @State private var showSnoozeOptions = false

    var body: some View {
        VStack(spacing: 0) {
            // Main Card Content
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        ZStack {
                            Circle()
                                .fill(urgencyColor.opacity(0.2))
                                .frame(width: 44, height: 44)

                            Image(systemName: "pills.fill")
                                .font(.title3)
                                .foregroundColor(urgencyColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(schedule.medicationName)
                                .font(.headline)
                                .foregroundColor(NapletColors.textPrimary)

                            if let dose = schedule.dose {
                                Text(dose)
                                    .font(.subheadline)
                                    .foregroundColor(NapletColors.textSecondary)
                            }
                        }

                        Spacer()

                        // Time Badge
                        VStack(alignment: .trailing, spacing: 2) {
                            if let nextTime = schedule.nextReminder {
                                Text(formatTime(nextTime))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(urgencyColor)

                                if let timeUntil = schedule.timeUntilNextReminder {
                                    Text(timeUntil)
                                        .font(.caption)
                                        .foregroundColor(NapletColors.textMuted)
                                }
                            }
                        }
                    }

                    // Status indicators
                    HStack(spacing: 12) {
                        // Frequency
                        Label(schedule.frequencyDescription, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(NapletColors.textMuted)

                        // Stock warning
                        if schedule.isLowStock {
                            Label(
                                String(format: "medication.stock.low".localized, schedule.dosesRemaining ?? 0),
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            .font(.caption)
                            .foregroundColor(NapletColors.warning)
                        }
                    }
                }
                .padding(16)
                .background(NapletColors.cardBackground)
            }
            .buttonStyle(.plain)

            // Action Buttons
            HStack(spacing: 0) {
                // Given Button
                Button(action: onGiven) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("medication.action.given".localized)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(NapletColors.success)
                }

                // Snooze Button
                Button {
                    showSnoozeOptions.toggle()
                } label: {
                    HStack {
                        Image(systemName: "clock.badge.exclamationmark")
                        Text("medication.action.snooze".localized)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(NapletColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(NapletColors.backgroundTertiary)
                }

                // Skip Button
                Button(action: onSkip) {
                    HStack {
                        Image(systemName: "forward.fill")
                        Text("medication.action.skip".localized)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(NapletColors.warning)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(NapletColors.backgroundTertiary)
                }
            }

            // Snooze Options (expandable)
            if showSnoozeOptions {
                VStack(spacing: 0) {
                    Divider()
                        .background(NapletColors.background)

                    HStack(spacing: 0) {
                        ForEach(SnoozeDuration.allCases) { duration in
                            Button {
                                onSnooze(duration)
                                showSnoozeOptions = false
                            } label: {
                                Text(duration.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(NapletColors.primaryBlue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }

                            if duration != SnoozeDuration.allCases.last {
                                Divider()
                                    .background(NapletColors.background)
                            }
                        }
                    }
                    .background(NapletColors.cardBackground)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(urgencyBorderColor, lineWidth: isUrgent ? 2 : 0)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .animation(.spring(response: 0.3), value: showSnoozeOptions)
    }

    // MARK: - Computed Properties

    private var isUrgent: Bool {
        guard let next = schedule.nextReminder else { return false }
        let minutesUntil = next.timeIntervalSinceNow / 60
        return minutesUntil <= 15 && minutesUntil > 0
    }

    private var isPastDue: Bool {
        guard let next = schedule.nextReminder else { return false }
        return next.timeIntervalSinceNow < 0
    }

    private var urgencyColor: Color {
        if isPastDue {
            return NapletColors.error
        } else if isUrgent {
            return NapletColors.warning
        }
        return NapletColors.primaryCyan
    }

    private var urgencyBorderColor: Color {
        if isPastDue {
            return NapletColors.error
        } else if isUrgent {
            return NapletColors.warning
        }
        return .clear
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Compact Medication Card
/// Versão compacta do card para lista
struct CompactMedicationCard: View {
    let schedule: MedicationSchedule
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(schedule.medicationName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(NapletColors.textPrimary)

                    if let dose = schedule.dose {
                        Text(dose)
                            .font(.caption)
                            .foregroundColor(NapletColors.textMuted)
                    }
                }

                Spacer()

                // Status
                VStack(alignment: .trailing, spacing: 2) {
                    if schedule.isPaused {
                        Label("medication.paused".localized, systemImage: "pause.circle.fill")
                            .font(.caption)
                            .foregroundColor(NapletColors.textMuted)
                    } else if let timeUntil = schedule.timeUntilNextReminder {
                        Text(timeUntil)
                            .font(.caption)
                            .foregroundColor(statusColor)
                    }

                    if schedule.isLowStock {
                        Text("\(schedule.dosesRemaining ?? 0) " + "medication.doses".localized)
                            .font(.caption2)
                            .foregroundColor(NapletColors.warning)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(NapletColors.textMuted)
            }
            .padding(12)
            .background(NapletColors.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var statusColor: Color {
        if schedule.isPaused {
            return NapletColors.textMuted
        } else if schedule.isLowStock {
            return NapletColors.warning
        }
        return NapletColors.primaryCyan
    }

    private var statusIcon: String {
        if schedule.isPaused {
            return "pause.circle.fill"
        } else if schedule.isLowStock {
            return "exclamationmark.triangle.fill"
        }
        return "pills.fill"
    }
}

// MARK: - Empty State
struct MedicationEmptyState: View {
    let onAddTap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(NapletColors.primaryCyan.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "pills")
                    .font(.system(size: 36))
                    .foregroundColor(NapletColors.primaryCyan.opacity(0.5))
            }

            Text("medication.empty.title".localized)
                .font(.headline)
                .foregroundColor(NapletColors.textPrimary)

            Text("medication.empty.description".localized)
                .font(.subheadline)
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: onAddTap) {
                Label("medication.schedule.add".localized, systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(NapletColors.primaryCyan)
                    .cornerRadius(24)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(NapletColors.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Preview
#if DEBUG
#Preview("Reminder Card") {
    VStack(spacing: 20) {
        MedicationReminderCard(
            schedule: MedicationSchedule(
                babyId: UUID(),
                medicationName: "Paracetamol",
                dose: "5ml",
                frequency: .every6Hours,
                reminderTimes: ["08:00", "14:00", "20:00"],
                dosesRemaining: 3,
                lowStockAlert: 5
            ),
            babyName: "Sofia",
            onGiven: {},
            onSnooze: { _ in },
            onSkip: {},
            onTap: {}
        )

        CompactMedicationCard(
            schedule: MedicationSchedule(
                babyId: UUID(),
                medicationName: "Vitamina D",
                dose: "2 gotas",
                frequency: .onceDaily,
                reminderTimes: ["09:00"]
            ),
            onTap: {}
        )

        MedicationEmptyState(onAddTap: {})
    }
    .padding()
    .background(NapletColors.background)
}
#endif
