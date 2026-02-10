import Foundation
import SwiftUI

// MARK: - Medication Schedule ViewModel
@MainActor
class MedicationScheduleViewModel: ObservableObject {

    // MARK: - Published Properties

    // Medication Info
    @Published var medicationName: String = ""
    @Published var dose: String = ""
    @Published var notes: String = ""

    // Frequency
    @Published var frequency: MedicationFrequency = .every8Hours
    @Published var reminderTimes: [String] = ["08:00", "14:00", "22:00"]

    // Duration
    @Published var durationType: DurationType = .continuous
    @Published var durationDays: Int = 7
    @Published var endDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    // Stock
    @Published var trackStock: Bool = false
    @Published var dosesRemaining: Int = 30
    @Published var lowStockAlert: Int = 5
    @Published var dosesPerTake: Double = 1.0

    // State
    @Published var isSaving: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var didSave: Bool = false

    // MARK: - Private Properties
    private let baby: Baby
    private let editingSchedule: MedicationSchedule?
    private let repository = MedicationScheduleRepository.shared
    private let notificationService = NotificationService.shared

    // MARK: - Suggestions
    let medicationSuggestions = [
        "Paracetamol",
        "Ibuprofeno",
        "Amoxicilina",
        "Dipirona",
        "Vitamina D",
        "Vitamina C",
        "Probiótico",
        "Antialérgico"
    ]

    let doseSuggestions = [
        "2.5ml",
        "5ml",
        "7.5ml",
        "10ml",
        "1 gota",
        "2 gotas",
        "5 gotas",
        "1 comp",
        "1/2 comp"
    ]

    // MARK: - Computed Properties
    var canSave: Bool {
        !medicationName.trimmingCharacters(in: .whitespaces).isEmpty &&
        (frequency == .asNeeded || !reminderTimes.isEmpty)
    }

    // MARK: - Init
    init(baby: Baby, editingSchedule: MedicationSchedule? = nil) {
        self.baby = baby
        self.editingSchedule = editingSchedule

        if let schedule = editingSchedule {
            loadSchedule(schedule)
        }
    }

    // MARK: - Load Existing Schedule
    private func loadSchedule(_ schedule: MedicationSchedule) {
        medicationName = schedule.medicationName
        dose = schedule.dose ?? ""
        notes = schedule.notes ?? ""
        frequency = schedule.frequency
        reminderTimes = schedule.reminderTimes
        durationType = schedule.durationType
        durationDays = schedule.durationDays ?? 7
        endDate = schedule.endDate ?? Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        trackStock = schedule.dosesRemaining != nil
        dosesRemaining = schedule.dosesRemaining ?? 30
        lowStockAlert = schedule.lowStockAlert
        dosesPerTake = schedule.dosesPerTake
    }

    // MARK: - Frequency Selection
    func selectFrequency(_ freq: MedicationFrequency) {
        frequency = freq

        // Atualiza horários sugeridos
        if freq != .custom && freq != .asNeeded {
            reminderTimes = freq.suggestedTimes
        } else if freq == .asNeeded {
            reminderTimes = []
        }
    }

    // MARK: - Time Management
    func addTimeSlot() {
        let newTime = "12:00"
        reminderTimes.append(newTime)
        reminderTimes.sort()
    }

    func removeTimeSlot(at index: Int) {
        guard reminderTimes.count > 1 else { return }
        reminderTimes.remove(at: index)
    }

    func updateTime(at index: Int, to date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        reminderTimes[index] = formatter.string(from: date)
        reminderTimes.sort()
    }

    func timeFromString(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString) ?? Date()
    }

    // MARK: - Save
    func save() async {
        guard canSave else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            // Calcula end date baseado no tipo de duração
            var calculatedEndDate: Date?
            switch durationType {
            case .continuous:
                calculatedEndDate = nil
            case .days:
                calculatedEndDate = Calendar.current.date(byAdding: .day, value: durationDays, to: Date())
            case .untilDate:
                calculatedEndDate = endDate
            }

            let schedule = MedicationSchedule(
                id: editingSchedule?.id ?? UUID(),
                babyId: baby.id,
                medicationName: medicationName.trimmingCharacters(in: .whitespaces),
                dose: dose.isEmpty ? nil : dose.trimmingCharacters(in: .whitespaces),
                notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
                frequency: frequency,
                reminderTimes: reminderTimes,
                startDate: editingSchedule?.startDate ?? Date(),
                endDate: calculatedEndDate,
                durationType: durationType,
                durationDays: durationType == .days ? durationDays : nil,
                dosesRemaining: trackStock ? dosesRemaining : nil,
                dosesPerTake: dosesPerTake,
                lowStockAlert: lowStockAlert,
                isActive: true,
                isPaused: false,
                pausedUntil: nil,
                createdBy: editingSchedule?.createdBy,
                createdAt: editingSchedule?.createdAt ?? Date(),
                updatedAt: Date()
            )

            let savedSchedule: MedicationSchedule

            if editingSchedule != nil {
                savedSchedule = try await repository.updateSchedule(schedule)
            } else {
                savedSchedule = try await repository.createSchedule(schedule)
            }

            // Agenda notificações
            if frequency != .asNeeded {
                await notificationService.scheduleMedicationReminders(
                    schedule: savedSchedule,
                    babyName: baby.name
                )
            }

            // Verifica estoque baixo
            if trackStock && dosesRemaining <= lowStockAlert {
                await notificationService.scheduleLowStockReminder(
                    schedule: savedSchedule,
                    babyName: baby.name
                )
            }

            Logger.info("Saved medication schedule: \(savedSchedule.medicationName)")
            didSave = true

        } catch {
            Logger.error("Failed to save medication schedule: \(error)")
            errorMessage = "medication.error.save".localized
            showError = true
        }
    }
}
