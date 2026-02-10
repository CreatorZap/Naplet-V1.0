import Foundation
import Supabase

// MARK: - Health Repository
@MainActor
class HealthRepository: ObservableObject {
    static let shared = HealthRepository()

    @Published var todayTemperatures: [HealthRecord] = []
    @Published var todayMedications: [HealthRecord] = []

    private let tableName = "health_records"
    private let supabase = SupabaseService.shared

    private init() {}

    // MARK: - Add Temperature Record
    func addTemperature(
        babyId: UUID,
        celsius: Double,
        recordedAt: Date = Date(),
        notes: String? = nil
    ) async throws -> HealthRecord {
        guard let userId = supabase.currentUserId else {
            throw HealthRepositoryError.notAuthenticated
        }

        let insertDTO = HealthRecordInsert(
            babyId: babyId,
            type: .temperature,
            recordedAt: recordedAt,
            temperatureCelsius: celsius,
            notes: notes?.isEmpty == true ? nil : notes,
            recordedBy: userId
        )

        let response: HealthRecord = try await supabase.client
            .from(tableName)
            .insert(insertDTO)
            .select()
            .single()
            .execute()
            .value

        self.todayTemperatures.insert(response, at: 0)

        Logger.info("Added temperature record: \(response.id) - \(celsius)°C")
        return response
    }

    // MARK: - Add Medication Record
    func addMedication(
        babyId: UUID,
        name: String,
        dose: String? = nil,
        recordedAt: Date = Date(),
        notes: String? = nil
    ) async throws -> HealthRecord {
        guard let userId = supabase.currentUserId else {
            throw HealthRepositoryError.notAuthenticated
        }

        let insertDTO = HealthRecordInsert(
            babyId: babyId,
            type: .medication,
            recordedAt: recordedAt,
            medicationName: name,
            medicationDose: dose?.isEmpty == true ? nil : dose,
            notes: notes?.isEmpty == true ? nil : notes,
            recordedBy: userId
        )

        let response: HealthRecord = try await supabase.client
            .from(tableName)
            .insert(insertDTO)
            .select()
            .single()
            .execute()
            .value

        self.todayMedications.insert(response, at: 0)

        Logger.info("Added medication record: \(response.id) - \(name)")
        return response
    }

    // MARK: - Fetch Today's Records
    func fetchTodayRecords(babyId: UUID, type: HealthRecordType? = nil) async throws -> [HealthRecord] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let formatter = ISO8601DateFormatter()

        var query = supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .gte("recorded_at", value: formatter.string(from: startOfDay))

        if let type = type {
            query = query.eq("type", value: type.rawValue)
        }

        let response: [HealthRecord] = try await query
            .order("recorded_at", ascending: false)
            .execute()
            .value

        if type == .temperature {
            self.todayTemperatures = response
        } else if type == .medication {
            self.todayMedications = response
        }

        return response
    }

    // MARK: - Fetch Records by Date Range
    func fetchRecords(
        babyId: UUID,
        startDate: Date,
        endDate: Date,
        type: HealthRecordType? = nil
    ) async throws -> [HealthRecord] {
        let formatter = ISO8601DateFormatter()

        var query = supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .gte("recorded_at", value: formatter.string(from: startDate))
            .lte("recorded_at", value: formatter.string(from: endDate))

        if let type = type {
            query = query.eq("type", value: type.rawValue)
        }

        let response: [HealthRecord] = try await query
            .order("recorded_at", ascending: false)
            .execute()
            .value

        return response
    }

    // MARK: - Delete Record
    func deleteRecord(recordId: UUID) async throws {
        try await supabase.client
            .from(tableName)
            .delete()
            .eq("id", value: recordId.uuidString)
            .execute()

        self.todayTemperatures.removeAll { $0.id == recordId }
        self.todayMedications.removeAll { $0.id == recordId }

        Logger.info("Deleted health record: \(recordId)")
    }

    // MARK: - Get Last Temperature
    func getLastTemperature(babyId: UUID) async throws -> HealthRecord? {
        let response: [HealthRecord] = try await supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .eq("type", value: HealthRecordType.temperature.rawValue)
            .order("recorded_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    // MARK: - Get Last Medication
    func getLastMedication(babyId: UUID) async throws -> HealthRecord? {
        let response: [HealthRecord] = try await supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .eq("type", value: HealthRecordType.medication.rawValue)
            .order("recorded_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return response.first
    }
}

// MARK: - Health Repository Error
enum HealthRepositoryError: LocalizedError {
    case notAuthenticated
    case recordNotFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .recordNotFound:
            return "Health record not found"
        case .invalidData:
            return "Invalid health record data"
        }
    }
}
