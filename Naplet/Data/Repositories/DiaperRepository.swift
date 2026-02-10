import Foundation
import Supabase

// MARK: - Diaper Repository
@MainActor
class DiaperRepository: ObservableObject {
    static let shared = DiaperRepository()

    @Published var todayRecords: [DiaperRecord] = []

    private let tableName = "diaper_records"
    private let supabase = SupabaseService.shared

    private init() {}

    // MARK: - Add Diaper Record
    func addRecord(
        babyId: UUID,
        content: DiaperContent,
        changedAt: Date = Date(),
        weightGrams: Int? = nil,
        notes: String? = nil
    ) async throws -> DiaperRecord {
        guard let userId = supabase.currentUserId else {
            throw DiaperRepositoryError.notAuthenticated
        }

        let insertDTO = DiaperRecordInsert(
            babyId: babyId,
            changedAt: changedAt,
            content: content,
            weightGrams: weightGrams,
            notes: notes?.isEmpty == true ? nil : notes,
            recordedBy: userId
        )

        let response: DiaperRecord = try await supabase.client
            .from(tableName)
            .insert(insertDTO)
            .select()
            .single()
            .execute()
            .value

        self.todayRecords.insert(response, at: 0)

        Logger.info("Added diaper record: \(response.id) - \(content.rawValue)")
        return response
    }

    // MARK: - Fetch Today's Records
    func fetchTodayRecords(babyId: UUID) async throws -> [DiaperRecord] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let formatter = ISO8601DateFormatter()

        let response: [DiaperRecord] = try await supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .gte("changed_at", value: formatter.string(from: startOfDay))
            .order("changed_at", ascending: false)
            .execute()
            .value

        self.todayRecords = response

        return response
    }

    // MARK: - Fetch Records by Date Range
    func fetchRecords(
        babyId: UUID,
        startDate: Date,
        endDate: Date
    ) async throws -> [DiaperRecord] {
        let formatter = ISO8601DateFormatter()

        let response: [DiaperRecord] = try await supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .gte("changed_at", value: formatter.string(from: startDate))
            .lte("changed_at", value: formatter.string(from: endDate))
            .order("changed_at", ascending: false)
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

        self.todayRecords.removeAll { $0.id == recordId }

        Logger.info("Deleted diaper record: \(recordId)")
    }

    // MARK: - Get Last Diaper Change
    func getLastChange(babyId: UUID) async throws -> DiaperRecord? {
        let response: [DiaperRecord] = try await supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .order("changed_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    // MARK: - Get Today's Statistics
    func getTodayStatistics(babyId: UUID) async throws -> DiaperStatistics {
        let records = try await fetchTodayRecords(babyId: babyId)

        let wetCount = records.filter { $0.content == .wet }.count
        let dirtyCount = records.filter { $0.content == .dirty }.count
        let mixedCount = records.filter { $0.content == .mixed }.count
        let dryCount = records.filter { $0.content == .dry }.count

        return DiaperStatistics(
            wetCount: wetCount,
            dirtyCount: dirtyCount,
            mixedCount: mixedCount,
            dryCount: dryCount,
            lastChange: records.first
        )
    }
}

// MARK: - Diaper Repository Error
enum DiaperRepositoryError: LocalizedError {
    case notAuthenticated
    case recordNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .recordNotFound:
            return "Diaper record not found"
        }
    }
}
