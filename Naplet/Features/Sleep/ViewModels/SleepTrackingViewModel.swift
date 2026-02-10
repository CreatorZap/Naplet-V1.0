import Foundation
import SwiftUI
import Combine

// MARK: - Sleep Tracking ViewModel
@MainActor
class SleepTrackingViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var isTracking: Bool = false
    @Published var startTime: Date?
    @Published var elapsedTime: TimeInterval = 0
    @Published var selectedType: SleepRecord.SleepType = .nap
    @Published var selectedQuality: SleepRecord.SleepQuality?
    @Published var notes: String = ""

    // MARK: - Novos Campos de Localização e Humor
    @Published var sleepLocation: SleepLocation?
    @Published var sleepStartMood: SleepStartMood?
    @Published var wakeType: WakeType?
    @Published var wakeMood: WakeMood?

    // MARK: - Private Properties
    private var timer: Timer?
    private var currentRecord: SleepRecord?

    // MARK: - Computed Properties

    var elapsedTimeFormatted: String {
        elapsedTime.timerFormat
    }

    var canStart: Bool {
        !isTracking
    }

    var canStop: Bool {
        isTracking && elapsedTime > 60 // Minimum 1 minute
    }

    // MARK: - Initialization

    init() {
        // Check if there's an ongoing sleep session
        checkOngoingSession()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Methods

    func startTracking() {
        guard !isTracking else { return }

        startTime = Date()
        isTracking = true
        elapsedTime = 0

        // Create new record
        // TODO: Get actual baby ID and user ID
        currentRecord = SleepRecord(
            babyId: UUID(),
            type: selectedType,
            startTime: startTime!,
            sleepLocation: sleepLocation,
            sleepStartMood: sleepStartMood,
            recordedBy: UUID()
        )

        // Start timer
        startTimer()

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    func stopTracking() {
        guard isTracking else { return }

        // Stop timer
        timer?.invalidate()
        timer = nil

        // Update record
        if var record = currentRecord {
            record.finish(quality: selectedQuality)
            if !notes.isEmpty {
                record.notes = notes
            }
            // Adicionar campos de despertar
            record.wakeType = wakeType
            record.wakeMood = wakeMood
            // Atualizar localização se mudou
            if sleepLocation != nil {
                record.sleepLocation = sleepLocation
            }
            // TODO: Save to database
            saveRecord(record)
        }

        // Reset state
        resetState()

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    func cancelTracking() {
        guard isTracking else { return }

        // Stop timer
        timer?.invalidate()
        timer = nil

        // Don't save the record
        currentRecord = nil

        // Reset state
        resetState()
    }

    // MARK: - Private Methods

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateElapsedTime()
            }
        }
    }

    private func updateElapsedTime() {
        guard let start = startTime else { return }
        elapsedTime = Date().timeIntervalSince(start)
    }

    private func resetState() {
        isTracking = false
        startTime = nil
        elapsedTime = 0
        currentRecord = nil
        selectedQuality = nil
        notes = ""
        sleepLocation = nil
        sleepStartMood = nil
        wakeType = nil
        wakeMood = nil
    }

    private func checkOngoingSession() {
        // TODO: Check if there's an ongoing session in database
    }

    private func saveRecord(_ record: SleepRecord) {
        // TODO: Save to Supabase
        #if DEBUG
        print("Saving record: \(record)")
        #endif
    }
}
