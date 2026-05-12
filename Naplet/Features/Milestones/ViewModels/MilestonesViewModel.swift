import Foundation
import SwiftUI

// MARK: - Milestones ViewModel
@MainActor
class MilestonesViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var selectedCategory: MilestoneCategory? = nil
    @Published var isLoading = false
    @Published var loadError: String? = nil
    @Published var showingAchieveSheet = false
    @Published var selectedMilestone: MilestoneDefinition? = nil
    @Published var achieveDate: Date = Date()
    @Published var achieveNotes: String = ""
    @Published var isSaving = false
    @Published var saveError: String? = nil

    // MARK: - Dependencies
    private let repository = MilestoneRepository.shared
    private let babyId: UUID
    private let ageInMonths: Int

    // MARK: - Init
    init(babyId: UUID, ageInMonths: Int) {
        self.babyId = babyId
        self.ageInMonths = ageInMonths
    }

    // MARK: - Computed Properties

    var filteredMilestones: [MilestoneDefinition] {
        if let category = selectedCategory {
            return MilestoneDefinition.milestones(for: category)
        }
        return MilestoneDefinition.allMilestones
    }

    var achievedKeys: Set<String> {
        Set(repository.achievedMilestones.map { $0.milestoneKey })
    }

    var overallProgress: Double {
        repository.overallProgress()
    }

    var achievedCount: Int {
        repository.achievedCount
    }

    var totalCount: Int {
        MilestoneDefinition.allMilestones.count
    }

    // MARK: - Milestone Status

    func status(for milestone: MilestoneDefinition) -> MilestoneStatus {
        if achievedKeys.contains(milestone.id) {
            return .achieved
        }

        if ageInMonths < milestone.expectedAgeMonths - 2 {
            return .upcoming
        } else if ageInMonths > milestone.expectedAgeMonths + 3 {
            return .late
        } else {
            return .expected
        }
    }

    func achievementRecord(for milestoneKey: String) -> BabyMilestone? {
        repository.achievementRecord(for: milestoneKey)
    }

    func categoryProgress(for category: MilestoneCategory) -> Double {
        repository.progress(for: category)
    }

    func categoryAchievedCount(for category: MilestoneCategory) -> Int {
        let categoryMilestones = MilestoneDefinition.milestones(for: category)
        return categoryMilestones.filter { achievedKeys.contains($0.id) }.count
    }

    func categoryTotalCount(for category: MilestoneCategory) -> Int {
        MilestoneDefinition.milestones(for: category).count
    }

    // MARK: - Actions

    func loadMilestones() async {
        isLoading = true
        loadError = nil

        do {
            _ = try await repository.fetchAchievedMilestones(babyId: babyId)
        } catch {
            loadError = error.localizedDescription
            #if DEBUG
            print("Error loading milestones: \(error)")
            #endif
        }

        isLoading = false
    }

    func prepareMilestoneAchieve(_ milestone: MilestoneDefinition) {
        selectedMilestone = milestone
        achieveDate = Date()
        achieveNotes = ""
        showingAchieveSheet = true
    }

    func markAchieved() async {
        guard let milestone = selectedMilestone else { return }

        isSaving = true
        saveError = nil

        do {
            _ = try await repository.markAchieved(
                babyId: babyId,
                milestoneKey: milestone.id,
                achievedAt: achieveDate,
                notes: achieveNotes.isEmpty ? nil : achieveNotes
            )
            showingAchieveSheet = false
            selectedMilestone = nil
        } catch {
            saveError = error.localizedDescription
            Logger.error("Error marking milestone '\(milestone.id)': \(error)")
            #if DEBUG
            print("Error marking milestone: \(error)")
            #endif
        }

        isSaving = false
    }

    func removeAchievement(for milestoneKey: String) async {
        guard let record = repository.achievementRecord(for: milestoneKey) else { return }

        do {
            try await repository.removeAchievement(recordId: record.id)
        } catch {
            loadError = error.localizedDescription
            #if DEBUG
            print("Error removing milestone: \(error)")
            #endif
        }
    }
}
