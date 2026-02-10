import Foundation
import Supabase

// MARK: - Feeding Repository
@MainActor
class FeedingRepository: ObservableObject {
    static let shared = FeedingRepository()

    @Published var activeFeeding: FeedingRecord?
    @Published var todayRecords: [FeedingRecord] = []

    private let tableName = "feeding_records"
    private let supabase = SupabaseService.shared

    private init() {}

    // MARK: - Start Feeding
    func startFeeding(
        babyId: UUID,
        type: FeedingType,
        breastSide: BreastSide? = nil
    ) async throws -> FeedingRecord {
        let record = FeedingRecord(
            babyId: babyId,
            type: type,
            startTime: Date(),
            breastSide: breastSide
        )

        let response: FeedingRecord = try await supabase.client
            .from(tableName)
            .insert(record)
            .select()
            .single()
            .execute()
            .value

        self.activeFeeding = response

        Logger.info("Started feeding session: \(response.id)")
        return response
    }

    // MARK: - Stop Feeding
    func stopFeeding(
        recordId: UUID,
        durationLeftSeconds: Int? = nil,
        durationRightSeconds: Int? = nil,
        bottleAmountMl: Double? = nil,
        bottleType: BottleContentType? = nil,
        breastSide: BreastSide? = nil,
        notes: String? = nil
    ) async throws -> FeedingRecord {
        var updateData: [String: AnyJSON] = [
            "end_time": .string(ISO8601DateFormatter().string(from: Date())),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]

        if let left = durationLeftSeconds {
            updateData["duration_left_seconds"] = .integer(left)
        }
        if let right = durationRightSeconds {
            updateData["duration_right_seconds"] = .integer(right)
        }
        if let amount = bottleAmountMl {
            updateData["bottle_amount_ml"] = .double(amount)
        }
        if let type = bottleType {
            updateData["bottle_type"] = .string(type.rawValue)
        }
        if let side = breastSide {
            updateData["breast_side"] = .string(side.rawValue)
        }
        if let notes = notes {
            updateData["notes"] = .string(notes)
        }

        let response: FeedingRecord = try await supabase.client
            .from(tableName)
            .update(updateData)
            .eq("id", value: recordId.uuidString)
            .select()
            .single()
            .execute()
            .value

        self.activeFeeding = nil

        Logger.info("Stopped feeding session: \(recordId)")
        return response
    }

    // MARK: - Update Breast Duration
    func updateBreastDuration(
        recordId: UUID,
        leftSeconds: Int,
        rightSeconds: Int,
        currentSide: BreastSide
    ) async throws {
        let updateData: [String: AnyJSON] = [
            "duration_left_seconds": .integer(leftSeconds),
            "duration_right_seconds": .integer(rightSeconds),
            "breast_side": .string(currentSide.rawValue),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]

        try await supabase.client
            .from(tableName)
            .update(updateData)
            .eq("id", value: recordId.uuidString)
            .execute()

        Logger.debug("Updated breast duration for \(recordId)")
    }

    // MARK: - Fetch Active Feeding
    func fetchActiveFeeding(babyId: UUID) async throws -> FeedingRecord? {
        let response: [FeedingRecord] = try await supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .is("end_time", value: nil)
            .order("start_time", ascending: false)
            .limit(1)
            .execute()
            .value

        let active = response.first
        self.activeFeeding = active

        return active
    }

    // MARK: - Fetch Today's Records
    func fetchTodayRecords(babyId: UUID) async throws -> [FeedingRecord] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let formatter = ISO8601DateFormatter()

        let response: [FeedingRecord] = try await supabase.client
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
    ) async throws -> [FeedingRecord] {
        let formatter = ISO8601DateFormatter()

        let response: [FeedingRecord] = try await supabase.client
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
        if self.activeFeeding?.id == recordId {
            self.activeFeeding = nil
        }

        Logger.info("Deleted feeding record: \(recordId)")
    }

    // MARK: - Get Last Feeding
    func getLastFeeding(babyId: UUID) async throws -> FeedingRecord? {
        let response: [FeedingRecord] = try await supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .not("end_time", operator: .is, value: "null")
            .order("end_time", ascending: false)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    // MARK: - Get Last Breast Side Used
    func getLastBreastSide(babyId: UUID) async throws -> BreastSide? {
        let response: [FeedingRecord] = try await supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .eq("type", value: FeedingType.breast.rawValue)
            .not("breast_side", operator: .is, value: "null")
            .order("end_time", ascending: false)
            .limit(1)
            .execute()
            .value

        return response.first?.breastSide
    }

    // MARK: - Get Today's Statistics
    func getTodayStatistics(babyId: UUID) async throws -> FeedingStatistics {
        let records = try await fetchTodayRecords(babyId: babyId)

        let breastRecords = records.filter { $0.type == .breast && $0.endTime != nil }
        let bottleRecords = records.filter { $0.type == .bottle && $0.endTime != nil }
        let solidRecords = records.filter { $0.type == .solid && $0.endTime != nil }

        let totalBreastMinutes = breastRecords.reduce(0) { sum, record in
            sum + (record.durationLeftSeconds ?? 0) + (record.durationRightSeconds ?? 0)
        } / 60

        let totalBottleMl = bottleRecords.reduce(0.0) { sum, record in
            sum + (record.bottleAmountMl ?? 0)
        }

        return FeedingStatistics(
            breastFeedingCount: breastRecords.count,
            breastFeedingMinutes: totalBreastMinutes,
            bottleFeedingCount: bottleRecords.count,
            bottleTotalMl: totalBottleMl,
            solidFeedingCount: solidRecords.count,
            lastFeeding: records.first { $0.endTime != nil }
        )
    }

    // MARK: - Save Local (Fallback)
    func saveLocally(_ record: FeedingRecord) {
        var records = loadLocalRecords()
        records.append(record)

        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: "localFeedingRecords")
        }
    }

    func loadLocalRecords() -> [FeedingRecord] {
        guard let data = UserDefaults.standard.data(forKey: "localFeedingRecords"),
              let records = try? JSONDecoder().decode([FeedingRecord].self, from: data) else {
            return []
        }
        return records
    }
}

// MARK: - Feeding Statistics
struct FeedingStatistics {
    let breastFeedingCount: Int
    let breastFeedingMinutes: Int
    let bottleFeedingCount: Int
    let bottleTotalMl: Double
    let solidFeedingCount: Int
    let lastFeeding: FeedingRecord?

    var totalFeedingCount: Int {
        breastFeedingCount + bottleFeedingCount + solidFeedingCount
    }

    var lastFeedingTimeAgo: String? {
        guard let lastFeeding = lastFeeding,
              let endTime = lastFeeding.endTime else { return nil }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: endTime, relativeTo: Date())
    }

    static var empty: FeedingStatistics {
        FeedingStatistics(
            breastFeedingCount: 0,
            breastFeedingMinutes: 0,
            bottleFeedingCount: 0,
            bottleTotalMl: 0,
            solidFeedingCount: 0,
            lastFeeding: nil
        )
    }
}
