import Foundation
import SwiftUI

// MARK: - Bath ViewModel
@MainActor
class BathViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedBathType: BathType = .bathtub
    @Published var selectedMood: BathMood = .neutral
    @Published var startTime: Date = Date()
    @Published var durationMinutes: Int = 10
    @Published var notes: String = ""

    @Published var todayRecords: [BathRecord] = []
    @Published var statistics: BathStatistics = .empty

    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?
    @Published var showSuccess = false

    // MARK: - Dependencies
    private let repository = BathRepository.shared
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
            Logger.error("Failed to load bath data: \(error)")
        }

        isLoading = false
    }

    // MARK: - Save Bath
    func saveBath() async -> Bool {
        isSaving = true
        error = nil

        do {
            let record = try await repository.addRecord(
                babyId: baby.id,
                startTime: startTime,
                durationMinutes: durationMinutes,
                bathType: selectedBathType,
                mood: selectedMood,
                notes: notes.isEmpty ? nil : notes
            )

            // Update local state
            todayRecords.insert(record, at: 0)
            statistics = try await repository.getTodayStatistics(babyId: baby.id)

            // Reset form
            resetForm()

            showSuccess = true
            isSaving = false

            Logger.info("Bath saved successfully")
            return true
        } catch {
            self.error = error.localizedDescription
            Logger.error("Failed to save bath: \(error)")
            isSaving = false
            return false
        }
    }

    // MARK: - Delete Record
    func deleteRecord(_ record: BathRecord) async {
        do {
            try await repository.deleteRecord(recordId: record.id)
            todayRecords.removeAll { $0.id == record.id }
            statistics = try await repository.getTodayStatistics(babyId: baby.id)
            Logger.info("Bath record deleted")
        } catch {
            self.error = error.localizedDescription
            Logger.error("Failed to delete bath record: \(error)")
        }
    }

    // MARK: - Time Adjustments
    func adjustTime(by seconds: TimeInterval) {
        let newTime = startTime.addingTimeInterval(seconds)
        // Don't allow future times
        if newTime <= Date() {
            startTime = newTime
        }
    }

    func addOneMinute() {
        adjustTime(by: 60)
    }

    func subtractOneMinute() {
        adjustTime(by: -60)
    }

    // MARK: - Duration Adjustments
    func adjustDuration(by minutes: Int) {
        let newDuration = durationMinutes + minutes
        if newDuration >= 1 && newDuration <= 60 {
            durationMinutes = newDuration
        }
    }

    func setDuration(_ minutes: Int) {
        if minutes >= 1 && minutes <= 60 {
            durationMinutes = minutes
        }
    }

    // MARK: - Reset Form
    func resetForm() {
        selectedBathType = .bathtub
        selectedMood = .neutral
        startTime = Date()
        durationMinutes = 10
        notes = ""
    }

    // MARK: - Formatted Time
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }

    // MARK: - Last Bath Info
    var lastBathInfo: String? {
        guard let last = statistics.lastBath else { return nil }
        return "\(last.bathType.displayName) - \(last.timeAgo)"
    }
}
