import Foundation
import Supabase

// MARK: - Bath Repository
@MainActor
class BathRepository: ObservableObject {
    static let shared = BathRepository()

    @Published var todayRecords: [BathRecord] = []

    private let tableName = "bath_records"
    private let supabase = SupabaseService.shared

    private init() {}

    // MARK: - Add Bath Record
    func addRecord(
        babyId: UUID,
        startTime: Date = Date(),
        durationMinutes: Int,
        bathType: BathType,
        mood: BathMood?,
        notes: String? = nil
    ) async throws -> BathRecord {
        guard let userId = supabase.currentUserId else {
            throw BathRepositoryError.notAuthenticated
        }

        let endTime = Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startTime)

        let insertDTO = BathRecordInsert(
            babyId: babyId,
            startTime: startTime,
            endTime: endTime,
            durationMinutes: durationMinutes,
            bathType: bathType,
            mood: mood,
            notes: notes?.isEmpty == true ? nil : notes,
            recordedBy: userId
        )

        let response: BathRecord = try await supabase.client
            .from(tableName)
            .insert(insertDTO)
            .select()
            .single()
            .execute()
            .value

        self.todayRecords.insert(response, at: 0)

        Logger.info("Added bath record: \(response.id) - \(bathType.rawValue)")
        return response
    }

    // MARK: - Fetch Today's Records
    func fetchTodayRecords(babyId: UUID) async throws -> [BathRecord] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let formatter = ISO8601DateFormatter()

        let response: [BathRecord] = try await supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .gte("start_time", value: formatter.string(from: startOfDay))
            .order("start_time", ascending: false)
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
    ) async throws -> [BathRecord] {
        let formatter = ISO8601DateFormatter()

        let response: [BathRecord] = try await supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .gte("start_time", value: formatter.string(from: startDate))
            .lte("start_time", value: formatter.string(from: endDate))
            .order("start_time", ascending: false)
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

        Logger.info("Deleted bath record: \(recordId)")
    }

    // MARK: - Get Last Bath
    func getLastBath(babyId: UUID) async throws -> BathRecord? {
        let response: [BathRecord] = try await supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .order("start_time", ascending: false)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    // MARK: - Get Today's Statistics
    func getTodayStatistics(babyId: UUID) async throws -> BathStatistics {
        let records = try await fetchTodayRecords(babyId: babyId)

        let bathtubCount = records.filter { $0.bathType == .bathtub }.count
        let showerCount = records.filter { $0.bathType == .shower }.count
        let spongeCount = records.filter { $0.bathType == .sponge }.count

        return BathStatistics(
            totalBathsToday: records.count,
            bathtubCount: bathtubCount,
            showerCount: showerCount,
            spongeCount: spongeCount,
            lastBath: records.first
        )
    }
}

// MARK: - Bath Repository Error
enum BathRepositoryError: LocalizedError {
    case notAuthenticated
    case recordNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .recordNotFound:
            return "Bath record not found"
        }
    }
}
