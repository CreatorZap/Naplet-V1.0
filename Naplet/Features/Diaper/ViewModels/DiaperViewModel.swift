import Foundation
import SwiftUI

// MARK: - Diaper ViewModel
@MainActor
class DiaperViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedContent: DiaperContent = .wet
    @Published var changedAt: Date = Date()
    @Published var weightGrams: String = ""
    @Published var notes: String = ""

    @Published var todayRecords: [DiaperRecord] = []
    @Published var statistics: DiaperStatistics = .empty

    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?
    @Published var showSuccess = false

    // MARK: - Dependencies
    private let repository = DiaperRepository.shared
    private let baby: Baby

    // MARK: - Init
    init(baby: Baby) {
        self.baby = baby
    }

    // MARK: - Load Data
    func loadData() async {
        isLoading = true
        error = nil

        do {
            async let recordsTask = repository.fetchTodayRecords(babyId: baby.id)
            async let statsTask = repository.getTodayStatistics(babyId: baby.id)

            let (records, stats) = try await (recordsTask, statsTask)

            self.todayRecords = records
            self.statistics = stats
        } catch {
            self.error = error.localizedDescription
            Logger.error("Failed to load diaper data: \(error)")
        }

        isLoading = false
    }

    // MARK: - Save Diaper Change
    func saveDiaperChange() async -> Bool {
        isSaving = true
        error = nil

        do {
            let weight = Int(weightGrams)

            let record = try await repository.addRecord(
                babyId: baby.id,
                content: selectedContent,
                changedAt: changedAt,
                weightGrams: weight,
                notes: notes.isEmpty ? nil : notes
            )

            // Update local state
            todayRecords.insert(record, at: 0)
            statistics = try await repository.getTodayStatistics(babyId: baby.id)

            // Reset form
            resetForm()

            showSuccess = true
            isSaving = false

            Logger.info("Diaper change saved successfully")
            return true
        } catch {
            self.error = error.localizedDescription
            Logger.error("Failed to save diaper change: \(error)")
            isSaving = false
            return false
        }
    }

    // MARK: - Delete Record
    func deleteRecord(_ record: DiaperRecord) async {
        do {
            try await repository.deleteRecord(recordId: record.id)
            todayRecords.removeAll { $0.id == record.id }
            statistics = try await repository.getTodayStatistics(babyId: baby.id)
            Logger.info("Diaper record deleted")
        } catch {
            self.error = error.localizedDescription
            Logger.error("Failed to delete diaper record: \(error)")
        }
    }

    // MARK: - Time Adjustments
    func adjustTime(by seconds: TimeInterval) {
        changedAt = changedAt.addingTimeInterval(seconds)
    }

    func addOneMinute() {
        adjustTime(by: 60)
    }

    func subtractOneMinute() {
        adjustTime(by: -60)
    }

    // MARK: - Reset Form
    func resetForm() {
        selectedContent = .wet
        changedAt = Date()
        weightGrams = ""
        notes = ""
    }

    // MARK: - Formatted Time
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: changedAt)
    }

    // MARK: - Last Change Info
    var lastChangeInfo: String? {
        guard let last = statistics.lastChange else { return nil }
        return "\(last.content.displayName) - \(last.timeAgo)"
    }
}
