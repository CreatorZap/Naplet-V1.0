import Foundation
import Supabase

// MARK: - Vaccination Repository Protocol
protocol VaccinationRepositoryProtocol {
    func fetchVaccines() async throws -> [Vaccine]
    func fetchBabyVaccinations(babyId: UUID) async throws -> [BabyVaccination]
    func fetchVaccinationsWithDetails(babyId: UUID) async throws -> [VaccinationWithDetails]
    func createVaccination(_ vaccination: BabyVaccination) async throws -> BabyVaccination
    func updateVaccination(_ vaccination: BabyVaccination) async throws -> BabyVaccination
    func markAsCompleted(vaccinationId: UUID, applicationDate: Date, batchNumber: String?, location: String?, notes: String?) async throws -> BabyVaccination
    func markAsPending(vaccinationId: UUID) async throws -> BabyVaccination
    func initializeVaccinationsForBaby(babyId: UUID) async throws
}

// MARK: - Vaccination Repository
@MainActor
class VaccinationRepository: ObservableObject, VaccinationRepositoryProtocol {
    static let shared = VaccinationRepository()

    // MARK: - Published Properties
    @Published var vaccines: [Vaccine] = []
    @Published var babyVaccinations: [BabyVaccination] = []
    @Published var vaccinationsWithDetails: [VaccinationWithDetails] = []

    // MARK: - Private Properties
    private let vaccinesTable = "vaccines"
    private let vaccinationsTable = "baby_vaccinations"
    private let supabase = SupabaseService.shared

    private init() {}

    // MARK: - Fetch All Vaccines
    func fetchVaccines() async throws -> [Vaccine] {
        Logger.info("Fetching vaccines from Supabase...")
        do {
            let response: [Vaccine] = try await supabase.client
                .from(vaccinesTable)
                .select()
                .order("age_months", ascending: true)
                .order("dose_number", ascending: true)
                .execute()
                .value

            self.vaccines = response
            Logger.info("✅ Fetched \(response.count) vaccines successfully")
            return response
        } catch {
            Logger.error("❌ Failed to fetch vaccines: \(error)")
            throw error
        }
    }

    // MARK: - Fetch Baby Vaccinations
    func fetchBabyVaccinations(babyId: UUID) async throws -> [BabyVaccination] {
        Logger.info("Fetching baby vaccinations for baby \(babyId)...")

        do {
            let response: [BabyVaccination] = try await supabase.client
                .from(vaccinationsTable)
                .select()
                .eq("baby_id", value: babyId.uuidString)
                .execute()
                .value

            self.babyVaccinations = response

            Logger.info("Fetched \(response.count) vaccinations for baby \(babyId)")
            return response
        } catch {
            Logger.error("Failed to fetch baby vaccinations: \(error)")
            throw error
        }
    }

    // MARK: - Fetch Vaccinations With Details
    func fetchVaccinationsWithDetails(babyId: UUID) async throws -> [VaccinationWithDetails] {
        // Fetch vaccines if not already loaded
        if vaccines.isEmpty {
            _ = try await fetchVaccines()
        }

        // Fetch baby vaccinations
        let vaccinations = try await fetchBabyVaccinations(babyId: babyId)

        // Create vaccine lookup dictionary
        let vaccineDict = Dictionary(uniqueKeysWithValues: vaccines.map { ($0.id, $0) })

        // Combine vaccinations with vaccine details
        let details = vaccinations.compactMap { vaccination -> VaccinationWithDetails? in
            guard let vaccine = vaccineDict[vaccination.vaccineId] else { return nil }
            return VaccinationWithDetails(
                id: vaccination.id,
                vaccination: vaccination,
                vaccine: vaccine
            )
        }

        // Sort by age and dose number
        let sortedDetails = details.sorted { lhs, rhs in
            if lhs.vaccine.ageMonths != rhs.vaccine.ageMonths {
                return lhs.vaccine.ageMonths < rhs.vaccine.ageMonths
            }
            return lhs.vaccine.doseNumber < rhs.vaccine.doseNumber
        }

        self.vaccinationsWithDetails = sortedDetails
        Logger.info("Created \(sortedDetails.count) vaccination details for baby \(babyId)")
        return sortedDetails
    }

    // MARK: - Create Vaccination
    func createVaccination(_ vaccination: BabyVaccination) async throws -> BabyVaccination {
        guard let userId = supabase.currentUserId else {
            throw VaccinationRepositoryError.notAuthenticated
        }

        let insertDTO = BabyVaccinationInsert(from: vaccination, userId: userId)

        let response: BabyVaccination = try await supabase.client
            .from(vaccinationsTable)
            .insert(insertDTO)
            .select()
            .single()
            .execute()
            .value

        self.babyVaccinations.append(response)
        Logger.info("Created vaccination: \(response.id)")
        return response
    }

    // MARK: - Update Vaccination
    func updateVaccination(_ vaccination: BabyVaccination) async throws -> BabyVaccination {
        // Format dates as "YYYY-MM-DD" strings for Supabase date columns
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        var updateData: [String: AnyEncodable] = [
            "status": AnyEncodable(vaccination.status.rawValue),
            "batch_number": AnyEncodable(vaccination.batchNumber),
            "location": AnyEncodable(vaccination.location),
            "health_professional": AnyEncodable(vaccination.healthProfessional),
            "reactions": AnyEncodable(vaccination.reactions),
            "notes": AnyEncodable(vaccination.notes)
        ]

        // Format dates if they exist
        if let appDate = vaccination.applicationDate {
            updateData["application_date"] = AnyEncodable(dateFormatter.string(from: appDate))
        }
        if let schedDate = vaccination.scheduledDate {
            updateData["scheduled_date"] = AnyEncodable(dateFormatter.string(from: schedDate))
        }

        let response: BabyVaccination = try await supabase.client
            .from(vaccinationsTable)
            .update(updateData)
            .eq("id", value: vaccination.id.uuidString)
            .select()
            .single()
            .execute()
            .value

        // Update local cache
        if let index = babyVaccinations.firstIndex(where: { $0.id == vaccination.id }) {
            babyVaccinations[index] = response
        }

        Logger.info("Updated vaccination: \(response.id)")
        return response
    }

    // MARK: - Mark As Completed
    func markAsCompleted(
        vaccinationId: UUID,
        applicationDate: Date,
        batchNumber: String? = nil,
        location: String? = nil,
        notes: String? = nil
    ) async throws -> BabyVaccination {
        Logger.info("markAsCompleted called for vaccination: \(vaccinationId)")

        // Format date as "YYYY-MM-DD" string for Supabase date column
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let applicationDateString = dateFormatter.string(from: applicationDate)

        // Use correct DB column names
        let updateData: [String: AnyEncodable] = [
            "status": AnyEncodable(VaccinationStatus.completed.rawValue),
            "application_date": AnyEncodable(applicationDateString),
            "batch_number": AnyEncodable(batchNumber),
            "location": AnyEncodable(location),
            "notes": AnyEncodable(notes)
        ]

        do {
            let response: BabyVaccination = try await supabase.client
                .from(vaccinationsTable)
                .update(updateData)
                .eq("id", value: vaccinationId.uuidString)
                .select()
                .single()
                .execute()
                .value

            // Update local cache
            if let index = babyVaccinations.firstIndex(where: { $0.id == vaccinationId }) {
                babyVaccinations[index] = response
            }

            Logger.info("Marked vaccination as completed: \(vaccinationId)")
            return response
        } catch {
            Logger.error("Failed to mark as completed: \(error)")
            throw error
        }
    }

    // MARK: - Mark As Pending
    func markAsPending(vaccinationId: UUID) async throws -> BabyVaccination {
        // Use correct DB column names
        let updateData: [String: AnyEncodable] = [
            "status": AnyEncodable(VaccinationStatus.pending.rawValue),
            "application_date": AnyEncodable(nil as Date?),
            "batch_number": AnyEncodable(nil as String?),
            "location": AnyEncodable(nil as String?),
            "health_professional": AnyEncodable(nil as String?),
            "reactions": AnyEncodable(nil as String?),
            "notes": AnyEncodable(nil as String?)
        ]

        let response: BabyVaccination = try await supabase.client
            .from(vaccinationsTable)
            .update(updateData)
            .eq("id", value: vaccinationId.uuidString)
            .select()
            .single()
            .execute()
            .value

        // Update local cache
        if let index = babyVaccinations.firstIndex(where: { $0.id == vaccinationId }) {
            babyVaccinations[index] = response
        }

        Logger.info("Marked vaccination as pending: \(vaccinationId)")
        return response
    }

    // MARK: - Initialize Vaccinations For Baby
    /// Creates vaccination records for all vaccines when a baby is created
    func initializeVaccinationsForBaby(babyId: UUID) async throws {
        Logger.info("🔄 initializeVaccinationsForBaby called for baby: \(babyId)")

        guard let userId = supabase.currentUserId else {
            Logger.error("❌ User not authenticated")
            throw VaccinationRepositoryError.notAuthenticated
        }

        // Fetch all vaccines
        let allVaccines = try await fetchVaccines()
        Logger.info("📋 Found \(allVaccines.count) vaccines to initialize")

        if allVaccines.isEmpty {
            Logger.warning("⚠️ No vaccines found in database!")
            return
        }

        // Create vaccination records for each vaccine
        var insertData: [[String: AnyEncodable]] = []

        for vaccine in allVaccines {
            insertData.append([
                "baby_id": AnyEncodable(babyId.uuidString),
                "vaccine_id": AnyEncodable(vaccine.id.uuidString),
                "status": AnyEncodable(VaccinationStatus.pending.rawValue),
                "recorded_by": AnyEncodable(userId.uuidString)
            ])
        }

        // Batch insert
        do {
            try await supabase.client
                .from(vaccinationsTable)
                .insert(insertData)
                .execute()

            Logger.info("✅ Initialized \(allVaccines.count) vaccinations for baby \(babyId)")
        } catch {
            Logger.error("❌ Failed to initialize vaccinations: \(error)")
            throw error
        }
    }

    // MARK: - Get Progress
    func getProgress(babyId: UUID, babyBirthDate: Date) async throws -> VaccinationProgress {
        let details = try await fetchVaccinationsWithDetails(babyId: babyId)

        let completed = details.filter { $0.vaccination.status == .completed }.count
        let overdue = details.filter { $0.isOverdue(babyBirthDate: babyBirthDate) }.count
        let pending = details.filter { $0.vaccination.status == .pending && !$0.isOverdue(babyBirthDate: babyBirthDate) }.count

        return VaccinationProgress(
            total: details.count,
            completed: completed,
            pending: pending,
            overdue: overdue
        )
    }

    // MARK: - Get Upcoming Vaccinations
    func getUpcomingVaccinations(babyId: UUID, babyBirthDate: Date, limit: Int = 3) async throws -> [VaccinationWithDetails] {
        let details = try await fetchVaccinationsWithDetails(babyId: babyId)

        return details
            .filter { $0.vaccination.status == .pending }
            .filter { $0.isInRecommendedWindow(babyBirthDate: babyBirthDate) || !$0.isOverdue(babyBirthDate: babyBirthDate) }
            .sorted { $0.vaccine.ageMonths < $1.vaccine.ageMonths }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Get Overdue Vaccinations
    func getOverdueVaccinations(babyId: UUID, babyBirthDate: Date) async throws -> [VaccinationWithDetails] {
        let details = try await fetchVaccinationsWithDetails(babyId: babyId)

        return details
            .filter { $0.isOverdue(babyBirthDate: babyBirthDate) }
            .sorted { $0.vaccine.ageMonths < $1.vaccine.ageMonths }
    }

    // MARK: - Group By Age
    func groupVaccinationsByAge(_ vaccinations: [VaccinationWithDetails]) -> [(VaccineAgeGroup, [VaccinationWithDetails])] {
        let grouped = Dictionary(grouping: vaccinations) { vaccination in
            VaccineAgeGroup.from(months: vaccination.vaccine.ageMonths)
        }

        return VaccineAgeGroup.allCases.compactMap { ageGroup in
            guard let vaccinations = grouped[ageGroup], !vaccinations.isEmpty else { return nil }
            return (ageGroup, vaccinations)
        }
    }
}

// MARK: - Vaccination Repository Error
enum VaccinationRepositoryError: LocalizedError {
    case notAuthenticated
    case vaccinationNotFound
    case vaccineNotFound
    case invalidData
    case alreadyInitialized

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .vaccinationNotFound:
            return "Vaccination record not found"
        case .vaccineNotFound:
            return "Vaccine not found"
        case .invalidData:
            return "Invalid vaccination data"
        case .alreadyInitialized:
            return "Vaccinations already initialized for this baby"
        }
    }
}
