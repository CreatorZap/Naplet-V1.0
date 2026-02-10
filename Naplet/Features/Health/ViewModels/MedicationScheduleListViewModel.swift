import Foundation
import SwiftUI

// MARK: - Medication Schedule List ViewModel
@MainActor
class MedicationScheduleListViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var activeSchedules: [MedicationSchedule] = []
    @Published var nextMedication: MedicationSchedule?
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var showError: Bool = false

    // MARK: - Private Properties
    private let baby: Baby
    private let repository = MedicationScheduleRepository.shared
    private let notificationService = NotificationService.shared

    // MARK: - Init
    init(baby: Baby) {
        self.baby = baby
    }

    // MARK: - Load Data
    func loadSchedules() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let schedules = try await repository.fetchActiveSchedules(babyId: baby.id)
            activeSchedules = schedules.filter { $0.canReceiveReminders }

            // Encontra o próximo medicamento
            updateNextMedication()

            Logger.info("Loaded \(activeSchedules.count) active medication schedules")
        } catch {
            Logger.error("Failed to load medication schedules: \(error)")
            self.error = "medication.error.load".localized
            showError = true
        }
    }

    // MARK: - Update Next Medication
    private func updateNextMedication() {
        var closest: MedicationSchedule?
        var closestTime: Date?

        for schedule in activeSchedules {
            if let nextTime = schedule.nextReminder {
                if closestTime == nil || nextTime < closestTime! {
                    closest = schedule
                    closestTime = nextTime
                }
            }
        }

        nextMedication = closest
    }

    // MARK: - Actions

    /// Marca medicamento como dado
    func markAsGiven(_ schedule: MedicationSchedule) async {
        guard let scheduledTime = schedule.nextReminder else { return }

        do {
            let log = try await repository.logMedicationGiven(
                scheduleId: schedule.id,
                babyId: baby.id,
                scheduledTime: scheduledTime,
                doseGiven: schedule.dose
            )

            // Atualiza lista
            await loadSchedules()

            // Cancela notificações pendentes deste horário
            await notificationService.cancelMedicationReminders(scheduleId: schedule.id)

            // Reagenda para o próximo horário
            await notificationService.scheduleMedicationReminders(
                schedule: schedule,
                babyName: baby.name
            )

            // Verifica estoque baixo
            if schedule.isLowStock {
                await notificationService.scheduleLowStockReminder(
                    schedule: schedule,
                    babyName: baby.name
                )
            }

            Logger.info("Marked medication as given: \(schedule.medicationName)")

            // Feedback tátil
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

        } catch {
            Logger.error("Failed to mark medication as given: \(error)")
            self.error = "medication.error.log".localized
            showError = true
        }
    }

    /// Adia medicamento (snooze)
    func snooze(_ schedule: MedicationSchedule, duration: SnoozeDuration) async {
        guard let scheduledTime = schedule.nextReminder else { return }

        do {
            let log = try await repository.logMedicationSnoozed(
                scheduleId: schedule.id,
                babyId: baby.id,
                scheduledTime: scheduledTime,
                snoozeDuration: duration
            )

            // Agenda nova notificação para o tempo de snooze
            let snoozeDate = Calendar.current.date(
                byAdding: .minute,
                value: duration.minutes,
                to: Date()
            ) ?? Date()

            await notificationService.scheduleSingleMedicationReminder(
                schedule: schedule,
                babyName: baby.name,
                at: snoozeDate,
                isSnoozed: true
            )

            Logger.info("Snoozed medication for \(duration.minutes) minutes: \(schedule.medicationName)")

            // Feedback tátil
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

        } catch {
            Logger.error("Failed to snooze medication: \(error)")
            self.error = "medication.error.snooze".localized
            showError = true
        }
    }

    /// Pula medicamento
    func skip(_ schedule: MedicationSchedule) async {
        guard let scheduledTime = schedule.nextReminder else { return }

        do {
            let log = try await repository.logMedicationSkipped(
                scheduleId: schedule.id,
                babyId: baby.id,
                scheduledTime: scheduledTime,
                notes: "Skipped by user"
            )

            // Atualiza lista
            await loadSchedules()

            Logger.info("Skipped medication: \(schedule.medicationName)")

            // Feedback tátil
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

        } catch {
            Logger.error("Failed to skip medication: \(error)")
            self.error = "medication.error.skip".localized
            showError = true
        }
    }

    /// Pausa um schedule
    func pause(_ schedule: MedicationSchedule) async {
        do {
            try await repository.pauseSchedule(id: schedule.id)

            // Cancela notificações
            await notificationService.cancelMedicationReminders(scheduleId: schedule.id)

            // Atualiza lista
            await loadSchedules()

            Logger.info("Paused medication schedule: \(schedule.medicationName)")

        } catch {
            Logger.error("Failed to pause medication: \(error)")
            self.error = "medication.error.pause".localized
            showError = true
        }
    }

    /// Retoma um schedule
    func resume(_ schedule: MedicationSchedule) async {
        do {
            try await repository.resumeSchedule(id: schedule.id)

            // Reagenda notificações
            await notificationService.scheduleMedicationReminders(
                schedule: schedule,
                babyName: baby.name
            )

            // Atualiza lista
            await loadSchedules()

            Logger.info("Resumed medication schedule: \(schedule.medicationName)")

        } catch {
            Logger.error("Failed to resume medication: \(error)")
            self.error = "medication.error.resume".localized
            showError = true
        }
    }

    /// Deleta um schedule
    func delete(_ schedule: MedicationSchedule) async {
        do {
            // Cancela notificações primeiro
            await notificationService.cancelMedicationReminders(scheduleId: schedule.id)

            try await repository.deleteSchedule(id: schedule.id)

            // Atualiza lista
            await loadSchedules()

            Logger.info("Deleted medication schedule: \(schedule.medicationName)")

        } catch {
            Logger.error("Failed to delete medication: \(error)")
            self.error = "medication.error.delete".localized
            showError = true
        }
    }

    /// Atualiza estoque
    func updateStock(_ schedule: MedicationSchedule, newAmount: Int) async {
        do {
            try await repository.updateDosesRemaining(id: schedule.id, doses: newAmount)

            // Atualiza lista
            await loadSchedules()

            // Verifica se precisa notificar estoque baixo
            if newAmount <= schedule.lowStockAlert {
                await notificationService.scheduleLowStockReminder(
                    schedule: schedule,
                    babyName: baby.name
                )
            }

            Logger.info("Updated stock for \(schedule.medicationName): \(newAmount)")

        } catch {
            Logger.error("Failed to update stock: \(error)")
            self.error = "medication.error.stock".localized
            showError = true
        }
    }
}
