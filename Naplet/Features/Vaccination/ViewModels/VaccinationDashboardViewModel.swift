import Foundation
import SwiftUI

// MARK: - Vaccination Dashboard ViewModel
@MainActor
class VaccinationDashboardViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var vaccinationsWithDetails: [VaccinationWithDetails] = []
    @Published var progress: VaccinationProgress = VaccinationProgress(total: 0, completed: 0, pending: 0, overdue: 0)
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?

    // Filter & Sort
    @Published var selectedFilter: VaccinationFilter = .all
    @Published var searchText = ""

    // MARK: - Private Properties
    private let baby: Baby
    private let repository = VaccinationRepository.shared

    // MARK: - Computed Properties

    /// Vaccinations filtered and sorted
    var filteredVaccinations: [VaccinationWithDetails] {
        var result = vaccinationsWithDetails

        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .pending:
            result = result.filter { $0.vaccination.status == .pending && !$0.isOverdue(babyBirthDate: baby.birthDate) }
        case .completed:
            result = result.filter { $0.vaccination.status == .completed }
        case .overdue:
            result = result.filter { $0.isOverdue(babyBirthDate: baby.birthDate) }
        }

        // Apply search
        if !searchText.isEmpty {
            let search = searchText.lowercased()
            result = result.filter {
                $0.vaccine.name.lowercased().contains(search) ||
                ($0.vaccine.nameEn?.lowercased().contains(search) ?? false) ||
                ($0.vaccine.description?.lowercased().contains(search) ?? false) ||
                ($0.vaccine.protectionInfo?.lowercased().contains(search) ?? false)
            }
        }

        return result
    }

    /// Vaccinations grouped by age
    var groupedVaccinations: [(VaccineAgeGroup, [VaccinationWithDetails])] {
        repository.groupVaccinationsByAge(filteredVaccinations)
    }

    /// Overdue vaccinations
    var overdueVaccinations: [VaccinationWithDetails] {
        vaccinationsWithDetails.filter { $0.isOverdue(babyBirthDate: baby.birthDate) }
    }

    /// Upcoming vaccinations (in recommended window)
    var upcomingVaccinations: [VaccinationWithDetails] {
        vaccinationsWithDetails
            .filter { $0.vaccination.status == .pending && !$0.isOverdue(babyBirthDate: baby.birthDate) }
            .filter { $0.isInRecommendedWindow(babyBirthDate: baby.birthDate) }
            .prefix(3)
            .map { $0 }
    }

    /// Next vaccination to apply
    var nextVaccination: VaccinationWithDetails? {
        vaccinationsWithDetails
            .filter { $0.vaccination.status == .pending }
            .sorted { $0.vaccine.ageMonths < $1.vaccine.ageMonths }
            .first
    }

    /// Baby's age in months
    var babyAgeMonths: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.month], from: baby.birthDate, to: Date()).month ?? 0
    }

    /// Progress percentage formatted
    var progressPercentageText: String {
        String(format: "%.0f%%", progress.completedPercentage)
    }

    /// Is vaccination up to date
    var isUpToDate: Bool {
        progress.isUpToDate
    }

    // MARK: - Init
    init(baby: Baby) {
        self.baby = baby
    }

    // MARK: - Load Data
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch vaccinations with details
            vaccinationsWithDetails = try await repository.fetchVaccinationsWithDetails(babyId: baby.id)

            // If no vaccinations exist for this baby, initialize them
            if vaccinationsWithDetails.isEmpty {
                Logger.info("No vaccinations found for \(baby.name), initializing...")
                try await repository.initializeVaccinationsForBaby(babyId: baby.id)
                // Fetch again after initialization
                vaccinationsWithDetails = try await repository.fetchVaccinationsWithDetails(babyId: baby.id)
            }

            // Calculate progress
            progress = try await repository.getProgress(babyId: baby.id, babyBirthDate: baby.birthDate)

            Logger.info("Loaded \(vaccinationsWithDetails.count) vaccinations for \(baby.name)")
        } catch {
            Logger.error("Failed to load vaccinations: \(error)")
            errorMessage = "vaccination.error.load".localized
            showError = true
        }
    }

    // MARK: - Mark As Completed
    func markAsCompleted(
        vaccination: VaccinationWithDetails,
        applicationDate: Date,
        batchNumber: String? = nil,
        location: String? = nil,
        notes: String? = nil
    ) async {
        Logger.info("ViewModel.markAsCompleted called for: \(vaccination.vaccine.name)")

        do {
            let updated = try await repository.markAsCompleted(
                vaccinationId: vaccination.id,
                applicationDate: applicationDate,
                batchNumber: batchNumber,
                location: location,
                notes: notes
            )

            // Update local state
            if let index = vaccinationsWithDetails.firstIndex(where: { $0.id == vaccination.id }) {
                vaccinationsWithDetails[index] = VaccinationWithDetails(
                    id: updated.id,
                    vaccination: updated,
                    vaccine: vaccination.vaccine
                )
            }

            // Update progress
            progress = try await repository.getProgress(babyId: baby.id, babyBirthDate: baby.birthDate)

            Logger.info("Marked vaccination as completed: \(vaccination.vaccine.name)")
        } catch {
            Logger.error("Failed to mark vaccination as completed: \(error)")
            errorMessage = "vaccination.error.update".localized
            showError = true
        }
    }

    // MARK: - Mark As Pending
    func markAsPending(vaccination: VaccinationWithDetails) async {
        do {
            let updated = try await repository.markAsPending(vaccinationId: vaccination.id)

            // Update local state
            if let index = vaccinationsWithDetails.firstIndex(where: { $0.id == vaccination.id }) {
                vaccinationsWithDetails[index] = VaccinationWithDetails(
                    id: updated.id,
                    vaccination: updated,
                    vaccine: vaccination.vaccine
                )
            }

            // Update progress
            progress = try await repository.getProgress(babyId: baby.id, babyBirthDate: baby.birthDate)

            Logger.info("Marked vaccination as pending: \(vaccination.vaccine.name)")
        } catch {
            Logger.error("Failed to mark vaccination as pending: \(error)")
            errorMessage = "vaccination.error.update".localized
            showError = true
        }
    }

    // MARK: - Refresh
    func refresh() async {
        await loadData()
    }
}

// MARK: - Vaccination Filter
enum VaccinationFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case pending = "pending"
    case completed = "completed"
    case overdue = "overdue"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "vaccination.filter.all".localized
        case .pending: return "vaccination.filter.pending".localized
        case .completed: return "vaccination.filter.completed".localized
        case .overdue: return "vaccination.filter.overdue".localized
        }
    }

    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .pending: return "clock"
        case .completed: return "checkmark.circle"
        case .overdue: return "exclamationmark.triangle"
        }
    }
}
