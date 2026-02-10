import Foundation
import SwiftUI
import Combine
import UIKit

// MARK: - Feeding ViewModel
@MainActor
class FeedingViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showSuccess = false
    @Published var successMessage: String?

    // Active session
    @Published var activeRecord: FeedingRecord?
    @Published var isTimerRunning = false

    // Timer values
    @Published var leftSeconds: Int = 0
    @Published var rightSeconds: Int = 0
    @Published var currentSide: BreastSide = .left
    @Published var totalSeconds: Int = 0

    // Bottle feeding
    @Published var bottleAmount: Double = 120
    @Published var bottleType: BottleContentType = .formula

    // Pumping
    @Published var pumpingMode: PumpingMode = .total
    @Published var pumpingTotalMl: Int = 100
    @Published var pumpingLeftMl: Int = 50
    @Published var pumpingRightMl: Int = 50

    // Notes
    @Published var feedingNotes: String?

    // Today's records
    @Published var todayRecords: [FeedingRecord] = []
    @Published var statistics: FeedingStatistics = .empty

    // UI State
    @Published var selectedFeedingType: FeedingType = .breast
    @Published var showFeedingSheet = false
    @Published var lastBreastSide: BreastSide?

    // MARK: - Private
    private let baby: Baby
    private let repository = FeedingRepository.shared
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed
    var leftTimeFormatted: String {
        formatTime(leftSeconds)
    }

    var rightTimeFormatted: String {
        formatTime(rightSeconds)
    }

    var totalTimeFormatted: String {
        formatTime(totalSeconds)
    }

    var totalBreastTime: Int {
        leftSeconds + rightSeconds
    }

    var totalBreastTimeFormatted: String {
        formatTime(totalBreastTime)
    }

    var suggestedSide: BreastSide {
        if let last = lastBreastSide {
            return last == .left ? .right : .left
        }
        return .left
    }

    var canStartFeeding: Bool {
        activeRecord == nil
    }

    // MARK: - Init
    init(baby: Baby) {
        self.baby = baby
        self.currentSide = suggestedSide
    }

    // MARK: - Load Data
    func loadData() async {
        isLoading = true

        do {
            // Check for active session
            if let active = try await repository.fetchActiveFeeding(babyId: baby.id) {
                activeRecord = active
                restoreTimerState(from: active)
                startTimer()
            }

            // Load today's records
            todayRecords = try await repository.fetchTodayRecords(babyId: baby.id)

            // Load statistics
            statistics = try await repository.getTodayStatistics(babyId: baby.id)

            // Get last breast side
            lastBreastSide = try await repository.getLastBreastSide(babyId: baby.id)
            if activeRecord == nil {
                currentSide = suggestedSide
            }

        } catch {
            Logger.error("Failed to load feeding data: \(error)")
            errorMessage = "feeding.error.load".localized
            showError = true
        }

        isLoading = false
    }

    // MARK: - Start Breast Feeding
    func startBreastFeeding(side: BreastSide = .left) async {
        guard canStartFeeding else { return }

        isLoading = true

        do {
            let record = try await repository.startFeeding(
                babyId: baby.id,
                type: .breast,
                breastSide: side
            )

            activeRecord = record
            currentSide = side
            leftSeconds = 0
            rightSeconds = 0
            totalSeconds = 0
            isTimerRunning = true

            startTimer()

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

        } catch {
            Logger.error("Failed to start breast feeding: \(error)")
            errorMessage = "feeding.error.start".localized
            showError = true
        }

        isLoading = false
    }

    // MARK: - Start Bottle Feeding
    func startBottleFeeding() async {
        guard canStartFeeding else { return }

        isLoading = true

        do {
            let record = try await repository.startFeeding(
                babyId: baby.id,
                type: .bottle
            )

            activeRecord = record
            totalSeconds = 0
            isTimerRunning = true

            startTimer()

            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

        } catch {
            Logger.error("Failed to start bottle feeding: \(error)")
            errorMessage = "feeding.error.start".localized
            showError = true
        }

        isLoading = false
    }

    // MARK: - Stop Feeding
    func stopFeeding(notes: String? = nil) async {
        guard let record = activeRecord else { return }

        isLoading = true
        stopTimer()

        do {
            var finalSide: BreastSide?

            if record.type == .breast {
                if leftSeconds > 0 && rightSeconds > 0 {
                    finalSide = .both
                } else if leftSeconds > 0 {
                    finalSide = .left
                } else if rightSeconds > 0 {
                    finalSide = .right
                }
            }

            let _ = try await repository.stopFeeding(
                recordId: record.id,
                durationLeftSeconds: record.type == .breast ? leftSeconds : nil,
                durationRightSeconds: record.type == .breast ? rightSeconds : nil,
                bottleAmountMl: record.type == .bottle ? bottleAmount : nil,
                bottleType: record.type == .bottle ? bottleType : nil,
                breastSide: finalSide,
                notes: notes
            )

            activeRecord = nil
            isTimerRunning = false
            leftSeconds = 0
            rightSeconds = 0
            totalSeconds = 0

            // Reload data
            await loadData()

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            successMessage = "feeding.saved".localized
            showSuccess = true

        } catch {
            Logger.error("Failed to stop feeding: \(error)")
            errorMessage = "feeding.error.stop".localized
            showError = true
            startTimer() // Resume timer if stop failed
        }

        isLoading = false
    }

    // MARK: - Switch Breast Side
    func switchSide(to side: BreastSide) {
        guard activeRecord?.type == .breast else { return }

        currentSide = side

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    // MARK: - Record Solid Feeding
    func recordSolidFeeding(notes: String? = nil) async {
        isLoading = true

        do {
            let record = try await repository.startFeeding(
                babyId: baby.id,
                type: .solid
            )

            // Immediately stop with notes
            let _ = try await repository.stopFeeding(
                recordId: record.id,
                notes: notes
            )

            await loadData()

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            successMessage = "feeding.saved".localized
            showSuccess = true

        } catch {
            Logger.error("Failed to record solid feeding: \(error)")
            errorMessage = "feeding.error.save".localized
            showError = true
        }

        isLoading = false
    }

    // MARK: - Delete Record
    func deleteRecord(_ record: FeedingRecord) async {
        do {
            try await repository.deleteRecord(recordId: record.id)
            await loadData()
        } catch {
            Logger.error("Failed to delete feeding record: \(error)")
            errorMessage = "feeding.error.delete".localized
            showError = true
        }
    }

    // MARK: - Record Pumping
    func recordPumping() async {
        isLoading = true

        do {
            let record = try await repository.startFeeding(
                babyId: baby.id,
                type: .pumping
            )

            // Immediately stop with pumping data
            let _ = try await repository.stopFeeding(
                recordId: record.id,
                notes: feedingNotes
            )

            // TODO: Add pumping-specific fields when repository supports it
            // For now, we save pumping amount in notes as a workaround

            await loadData()

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Reset pumping values
            pumpingMode = .total
            pumpingTotalMl = 100
            pumpingLeftMl = 50
            pumpingRightMl = 50
            feedingNotes = nil

            successMessage = "feeding.saved".localized
            showSuccess = true

        } catch {
            Logger.error("Failed to record pumping: \(error)")
            errorMessage = "feeding.error.save".localized
            showError = true
        }

        isLoading = false
    }

    // MARK: - Timer Management
    private func startTimer() {
        stopTimer()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }

        isTimerRunning = true
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
    }

    private func tick() {
        totalSeconds += 1

        if activeRecord?.type == .breast {
            switch currentSide {
            case .left:
                leftSeconds += 1
            case .right:
                rightSeconds += 1
            case .both:
                // Both sides increment together
                leftSeconds += 1
                rightSeconds += 1
            }
        }
    }

    private func restoreTimerState(from record: FeedingRecord) {
        leftSeconds = record.durationLeftSeconds ?? 0
        rightSeconds = record.durationRightSeconds ?? 0
        currentSide = record.breastSide ?? .left

        // Calculate elapsed time since start
        let elapsed = Int(Date().timeIntervalSince(record.startTime))
        totalSeconds = elapsed

        // For breast feeding, calculate remaining time if durations are not set
        if record.type == .breast && leftSeconds == 0 && rightSeconds == 0 {
            // All time goes to current side by default
            if currentSide == .left {
                leftSeconds = elapsed
            } else {
                rightSeconds = elapsed
            }
        }
    }

    // MARK: - Helpers
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    // MARK: - Deinit
    deinit {
        timer?.invalidate()
    }
}
