import Foundation
import SwiftUI

// MARK: - Health ViewModel
@MainActor
class HealthViewModel: ObservableObject {
    // MARK: - Temperature Properties
    @Published var temperature: Double = 37.0
    @Published var temperatureRecordedAt: Date = Date()
    @Published var temperatureNotes: String = ""

    // MARK: - Medication Properties
    @Published var medicationName: String = ""
    @Published var medicationDose: String = ""
    @Published var medicationRecordedAt: Date = Date()
    @Published var medicationNotes: String = ""

    // MARK: - Records
    @Published var todayTemperatures: [HealthRecord] = []
    @Published var todayMedications: [HealthRecord] = []

    // MARK: - State
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?
    @Published var showSuccess = false

    // MARK: - Dependencies
    private let repository = HealthRepository.shared
    private let baby: Baby

    // MARK: - Init
    init(baby: Baby) {
        self.baby = baby
    }

    // MARK: - Load Data
    func loadTemperatures() async {
        isLoading = true
        error = nil

        do {
            todayTemperatures = try await repository.fetchTodayRecords(babyId: baby.id, type: .temperature)
        } catch {
            self.error = error.localizedDescription
            Logger.error("Failed to load temperatures: \(error)")
        }

        isLoading = false
    }

    func loadMedications() async {
        isLoading = true
        error = nil

        do {
            todayMedications = try await repository.fetchTodayRecords(babyId: baby.id, type: .medication)
        } catch {
            self.error = error.localizedDescription
            Logger.error("Failed to load medications: \(error)")
        }

        isLoading = false
    }

    // MARK: - Save Temperature
    func saveTemperature() async -> Bool {
        isSaving = true
        error = nil

        do {
            let record = try await repository.addTemperature(
                babyId: baby.id,
                celsius: temperature,
                recordedAt: temperatureRecordedAt,
                notes: temperatureNotes.isEmpty ? nil : temperatureNotes
            )

            todayTemperatures.insert(record, at: 0)
            resetTemperatureForm()

            showSuccess = true
            isSaving = false

            Logger.info("Temperature saved: \(temperature)°C")
            return true
        } catch {
            self.error = error.localizedDescription
            Logger.error("Failed to save temperature: \(error)")
            isSaving = false
            return false
        }
    }

    // MARK: - Save Medication
    func saveMedication() async -> Bool {
        guard !medicationName.isEmpty else {
            error = "health.medication.nameRequired".localized
            return false
        }

        isSaving = true
        error = nil

        do {
            let record = try await repository.addMedication(
                babyId: baby.id,
                name: medicationName,
                dose: medicationDose.isEmpty ? nil : medicationDose,
                recordedAt: medicationRecordedAt,
                notes: medicationNotes.isEmpty ? nil : medicationNotes
            )

            todayMedications.insert(record, at: 0)
            resetMedicationForm()

            showSuccess = true
            isSaving = false

            Logger.info("Medication saved: \(medicationName)")
            return true
        } catch {
            self.error = error.localizedDescription
            Logger.error("Failed to save medication: \(error)")
            isSaving = false
            return false
        }
    }

    // MARK: - Delete Record
    func deleteRecord(_ record: HealthRecord) async {
        do {
            try await repository.deleteRecord(recordId: record.id)

            if record.type == .temperature {
                todayTemperatures.removeAll { $0.id == record.id }
            } else {
                todayMedications.removeAll { $0.id == record.id }
            }

            Logger.info("Health record deleted")
        } catch {
            self.error = error.localizedDescription
            Logger.error("Failed to delete health record: \(error)")
        }
    }

    // MARK: - Time Adjustments
    func adjustTemperatureTime(by seconds: TimeInterval) {
        temperatureRecordedAt = temperatureRecordedAt.addingTimeInterval(seconds)
    }

    func adjustMedicationTime(by seconds: TimeInterval) {
        medicationRecordedAt = medicationRecordedAt.addingTimeInterval(seconds)
    }

    // MARK: - Reset Forms
    func resetTemperatureForm() {
        temperature = 37.0
        temperatureRecordedAt = Date()
        temperatureNotes = ""
    }

    func resetMedicationForm() {
        medicationName = ""
        medicationDose = ""
        medicationRecordedAt = Date()
        medicationNotes = ""
    }

    // MARK: - Computed Properties
    var temperatureStatus: TemperatureStatus {
        TemperatureStatus.from(celsius: temperature)
    }

    var formattedTemperatureTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: temperatureRecordedAt)
    }

    var formattedMedicationTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: medicationRecordedAt)
    }

    var lastTemperatureInfo: String? {
        guard let last = todayTemperatures.first,
              let temp = last.formattedTemperature else { return nil }
        return "\(temp) - \(last.timeAgo)"
    }

    var lastMedicationInfo: String? {
        guard let last = todayMedications.first,
              let name = last.medicationName else { return nil }
        return "\(name) - \(last.timeAgo)"
    }
}
