import Foundation
import Supabase

// MARK: - Sleep Repository
@MainActor
class SleepRepository: ObservableObject {
    private let supabase = SupabaseService.shared
    private let tableName = "sleep_records"
    private let wakingsTable = "night_wakings"

    @Published var sleepRecords: [SleepRecord] = []
    @Published var activeSleep: SleepRecord?
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Start Sleep
    func startSleep(babyId: UUID, type: SleepRecord.SleepType) async throws -> SleepRecord {
        guard let userId = supabase.currentUserId else {
            throw SleepRepositoryError.notAuthenticated
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        let newRecord = SleepRecordInsertDTO(
            babyId: babyId,
            type: type,
            startTime: Date(),
            recordedBy: userId
        )

        let response: SleepRecord = try await supabase.client
            .from(tableName)
            .insert(newRecord)
            .select()
            .single()
            .execute()
            .value

        activeSleep = response
        sleepRecords.insert(response, at: 0)

        // Salvar ID do sono ativo localmente (para recuperação offline)
        UserDefaults.standard.set(response.id.uuidString, forKey: "activeSleepId")
        UserDefaults.standard.set(response.startTime.timeIntervalSince1970, forKey: "activeSleepStartTime")

        Logger.info("Sleep started: \(type.displayName)")
        return response
    }

    // MARK: - Stop Sleep
    func stopSleep(quality: SleepRecord.SleepQuality? = nil, notes: String? = nil) async throws -> SleepRecord? {
        guard let sleep = activeSleep else {
            Logger.warning("No active sleep to stop")
            return nil
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        let endTimeNow = Date()
        let update = SleepRecordUpdateDTO(
            endTime: endTimeNow,
            quality: quality,
            notes: notes
        )

        let response: SleepRecord = try await supabase.client
            .from(tableName)
            .update(update)
            .eq("id", value: sleep.id.uuidString)
            .select()
            .single()
            .execute()
            .value

        // Atualizar lista local
        if let index = sleepRecords.firstIndex(where: { $0.id == sleep.id }) {
            sleepRecords[index] = response
        }

        activeSleep = nil

        // Limpar dados locais
        UserDefaults.standard.removeObject(forKey: "activeSleepId")
        UserDefaults.standard.removeObject(forKey: "activeSleepStartTime")

        Logger.info("Sleep stopped. Duration: \(response.durationFormatted)")
        return response
    }

    // MARK: - Fetch Today's Records
    func fetchTodaysRecords(for babyId: UUID) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let response: [SleepRecord] = try await supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .gte("start_time", value: startOfDay.ISO8601Format())
            .order("start_time", ascending: false)
            .execute()
            .value

        sleepRecords = response

        // Verificar se há sono ativo
        activeSleep = response.first(where: { $0.isActive })

        Logger.info("Fetched \(response.count) sleep records for today")
    }

    // MARK: - Fetch Records for Date Range
    func fetchRecords(for babyId: UUID, from startDate: Date, to endDate: Date) async throws -> [SleepRecord] {
        isLoading = true
        defer { isLoading = false }

        let response: [SleepRecord] = try await supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .gte("start_time", value: startDate.ISO8601Format())
            .lte("start_time", value: endDate.ISO8601Format())
            .order("start_time", ascending: false)
            .execute()
            .value

        return response
    }

    // MARK: - Fetch Last 7 Days
    func fetchLastWeekRecords(for babyId: UUID) async throws -> [SleepRecord] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        return try await fetchRecords(for: babyId, from: startDate, to: endDate)
    }

    // MARK: - Fetch Last 30 Days
    func fetchLastMonthRecords(for babyId: UUID) async throws -> [SleepRecord] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        return try await fetchRecords(for: babyId, from: startDate, to: endDate)
    }

    // MARK: - Get Daily Stats via RPC
    func getDailyStats(for babyId: UUID, date: Date = Date()) async throws -> SleepStatistics {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let dateString = dateFormatter.string(from: date)

        let response: [DailyStatsResponse] = try await supabase.client
            .rpc("get_daily_stats", params: [
                "p_baby_id": babyId.uuidString,
                "p_date": dateString
            ])
            .execute()
            .value

        if let stats = response.first {
            return stats.toStatistics(for: date)
        }

        // Return empty stats if no data
        return SleepStatistics(
            totalSleepMinutes: 0,
            nightSleepMinutes: 0,
            napMinutes: 0,
            numberOfNaps: 0,
            averageNapDuration: 0,
            averageQuality: nil,
            date: date
        )
    }

    // MARK: - Get Active Sleep via RPC
    func getActiveSleep(for babyId: UUID) async throws -> SleepRecord? {
        let response: [SleepRecord] = try await supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .is("end_time", value: nil)
            .order("start_time", ascending: false)
            .limit(1)
            .execute()
            .value

        activeSleep = response.first
        return activeSleep
    }

    // MARK: - Update Record
    func updateRecord(_ record: SleepRecord) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let update = SleepRecordUpdateDTO(
            endTime: record.endTime,
            quality: record.quality,
            notes: record.notes
        )

        try await supabase.client
            .from(tableName)
            .update(update)
            .eq("id", value: record.id.uuidString)
            .execute()

        if let index = sleepRecords.firstIndex(where: { $0.id == record.id }) {
            sleepRecords[index] = record
        }

        Logger.info("Sleep record updated")
    }

    // MARK: - Delete Record
    func deleteRecord(_ record: SleepRecord) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        try await supabase.client
            .from(tableName)
            .delete()
            .eq("id", value: record.id.uuidString)
            .execute()

        sleepRecords.removeAll { $0.id == record.id }

        if activeSleep?.id == record.id {
            activeSleep = nil
            UserDefaults.standard.removeObject(forKey: "activeSleepId")
            UserDefaults.standard.removeObject(forKey: "activeSleepStartTime")
        }

        Logger.info("Sleep record deleted")
    }

    // MARK: - Night Wakings

    func addNightWaking(to record: SleepRecord, reason: NightWaking.WakingReason? = nil) async throws -> NightWaking {
        let waking = NightWakingInsertDTO(
            sleepRecordId: record.id,
            startTime: Date(),
            reason: reason
        )

        let response: NightWaking = try await supabase.client
            .from(wakingsTable)
            .insert(waking)
            .select()
            .single()
            .execute()
            .value

        // Update local record
        if let index = sleepRecords.firstIndex(where: { $0.id == record.id }) {
            sleepRecords[index].nightWakings.append(response)
        }

        Logger.info("Night waking added")
        return response
    }

    func endNightWaking(_ waking: NightWaking) async throws {
        let update = NightWakingUpdateDTO(
            endTime: Date()
        )

        try await supabase.client
            .from(wakingsTable)
            .update(update)
            .eq("id", value: waking.id.uuidString)
            .execute()

        // Update local record
        for i in sleepRecords.indices {
            if let j = sleepRecords[i].nightWakings.firstIndex(where: { $0.id == waking.id }) {
                sleepRecords[i].nightWakings[j].endTime = Date()
                break
            }
        }

        Logger.info("Night waking ended")
    }

    func fetchNightWakings(for record: SleepRecord) async throws -> [NightWaking] {
        let response: [NightWaking] = try await supabase.client
            .from(wakingsTable)
            .select()
            .eq("sleep_record_id", value: record.id.uuidString)
            .order("start_time", ascending: true)
            .execute()
            .value

        return response
    }

    // MARK: - Statistics Helpers

    func getTotalSleepToday(for babyId: UUID) -> TimeInterval {
        let todaysRecords = sleepRecords.filter { $0.isToday && !$0.isActive }
        return todaysRecords.reduce(0) { $0 + ($1.duration ?? 0) }
    }

    func getNapsCountToday() -> Int {
        sleepRecords.filter { $0.isToday && $0.type == .nap && !$0.isActive }.count
    }

    func getLastSleep() -> SleepRecord? {
        sleepRecords.first(where: { !$0.isActive })
    }

    func getAverageNapDuration() -> TimeInterval? {
        let naps = sleepRecords.filter { $0.type == .nap && !$0.isActive }
        guard !naps.isEmpty else { return nil }
        let totalDuration = naps.compactMap { $0.duration }.reduce(0, +)
        return totalDuration / Double(naps.count)
    }
}

// MARK: - Errors
enum SleepRepositoryError: LocalizedError {
    case notAuthenticated
    case noActiveSleep
    case recordNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Usuário não autenticado"
        case .noActiveSleep:
            return "Não há sono ativo"
        case .recordNotFound:
            return "Registro de sono não encontrado"
        }
    }
}

// MARK: - Insert/Update DTOs (specific for repository operations)

struct SleepRecordInsertDTO: Encodable {
    let babyId: UUID
    let type: SleepRecord.SleepType
    let startTime: Date
    let recordedBy: UUID

    enum CodingKeys: String, CodingKey {
        case babyId = "baby_id"
        case type
        case startTime = "start_time"
        case recordedBy = "recorded_by"
    }
}

struct SleepRecordUpdateDTO: Encodable {
    let endTime: Date?
    let quality: SleepRecord.SleepQuality?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case endTime = "end_time"
        case quality
        case notes
    }
}

struct NightWakingInsertDTO: Encodable {
    let sleepRecordId: UUID
    let startTime: Date
    let reason: NightWaking.WakingReason?

    enum CodingKeys: String, CodingKey {
        case sleepRecordId = "sleep_record_id"
        case startTime = "start_time"
        case reason
    }
}

struct NightWakingUpdateDTO: Encodable {
    let endTime: Date?

    enum CodingKeys: String, CodingKey {
        case endTime = "end_time"
    }
}

// MARK: - Mock Repository (for testing/preview)
final class MockSleepRepository {
    var records: [SleepRecord] = []

    func fetchSleepRecords(for babyId: UUID, from: Date?, to: Date?) async throws -> [SleepRecord] {
        var filtered = records.filter { $0.babyId == babyId }

        if let fromDate = from {
            filtered = filtered.filter { $0.startTime >= fromDate }
        }

        if let toDate = to {
            filtered = filtered.filter { $0.startTime <= toDate }
        }

        return filtered.sorted { $0.startTime > $1.startTime }
    }

    func fetchActiveSleep(for babyId: UUID) async throws -> SleepRecord? {
        return records.first { $0.babyId == babyId && $0.isActive }
    }

    func fetchLastSleep(for babyId: UUID) async throws -> SleepRecord? {
        return records
            .filter { $0.babyId == babyId && !$0.isActive }
            .sorted { ($0.endTime ?? Date.distantPast) > ($1.endTime ?? Date.distantPast) }
            .first
    }

    func createSleepRecord(_ record: SleepRecord) async throws -> SleepRecord {
        records.append(record)
        return record
    }

    func updateSleepRecord(_ record: SleepRecord) async throws -> SleepRecord {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        }
        return record
    }

    func deleteSleepRecord(id: UUID) async throws {
        records.removeAll { $0.id == id }
    }
}
