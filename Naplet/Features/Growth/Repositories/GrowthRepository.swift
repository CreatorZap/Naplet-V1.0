import Foundation
import Supabase

// MARK: - Growth Repository
@MainActor
class GrowthRepository: ObservableObject {
    static let shared = GrowthRepository()

    @Published var records: [GrowthRecord] = []

    private let tableName = "growth_records"
    private let supabase = SupabaseService.shared

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    private init() {}

    // MARK: - Fetch All Records
    func fetchRecords(babyId: UUID) async throws -> [GrowthRecord] {
        let response: [GrowthRecord] = try await supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .order("record_date", ascending: true)
            .execute()
            .value

        self.records = response

        Logger.info("Fetched \(response.count) growth records for baby \(babyId)")
        return response
    }

    // MARK: - Add Record
    func addRecord(
        babyId: UUID,
        recordDate: Date,
        weightKg: Decimal?,
        heightCm: Decimal?,
        headCircumferenceCm: Decimal?,
        notes: String? = nil
    ) async throws -> GrowthRecord {
        guard let userId = supabase.currentUserId else {
            throw GrowthRepositoryError.notAuthenticated
        }

        let dateString = Self.dateFormatter.string(from: recordDate)

        let insertDTO = GrowthRecordInsert(
            babyId: babyId,
            userId: userId,
            recordDate: dateString,
            weightKg: weightKg,
            heightCm: heightCm,
            headCircumferenceCm: headCircumferenceCm,
            notes: notes?.isEmpty == true ? nil : notes
        )

        let response: GrowthRecord = try await supabase.client
            .from(tableName)
            .insert(insertDTO)
            .select()
            .single()
            .execute()
            .value

        // Insert in sorted order
        if let index = self.records.firstIndex(where: { $0.recordDateValue > response.recordDateValue }) {
            self.records.insert(response, at: index)
        } else {
            self.records.append(response)
        }

        Logger.info("Added growth record: \(response.id) on \(dateString)")
        return response
    }

    // MARK: - Update Record
    func updateRecord(
        recordId: UUID,
        weightKg: Decimal?,
        heightCm: Decimal?,
        headCircumferenceCm: Decimal?,
        notes: String?
    ) async throws {
        struct UpdateDTO: Codable {
            let weightKg: Decimal?
            let heightCm: Decimal?
            let headCircumferenceCm: Decimal?
            let notes: String?

            enum CodingKeys: String, CodingKey {
                case weightKg = "weight_kg"
                case heightCm = "height_cm"
                case headCircumferenceCm = "head_circumference_cm"
                case notes
            }
        }

        let dto = UpdateDTO(
            weightKg: weightKg,
            heightCm: heightCm,
            headCircumferenceCm: headCircumferenceCm,
            notes: notes?.isEmpty == true ? nil : notes
        )

        try await supabase.client
            .from(tableName)
            .update(dto)
            .eq("id", value: recordId.uuidString)
            .execute()

        if let index = self.records.firstIndex(where: { $0.id == recordId }) {
            var updated = self.records[index]
            updated.weightKg = weightKg
            updated.heightCm = heightCm
            updated.headCircumferenceCm = headCircumferenceCm
            updated.notes = notes
            self.records[index] = updated
        }

        Logger.info("Updated growth record: \(recordId)")
    }

    // MARK: - Delete Record
    func deleteRecord(recordId: UUID) async throws {
        try await supabase.client
            .from(tableName)
            .delete()
            .eq("id", value: recordId.uuidString)
            .execute()

        self.records.removeAll { $0.id == recordId }

        Logger.info("Deleted growth record: \(recordId)")
    }

    // MARK: - Get Latest Record
    func latestRecord(babyId: UUID) async throws -> GrowthRecord? {
        let response: [GrowthRecord] = try await supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .order("record_date", ascending: false)
            .limit(1)
            .execute()
            .value

        return response.first
    }
}

// MARK: - Growth Repository Error
enum GrowthRepositoryError: LocalizedError {
    case notAuthenticated
    case recordNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .recordNotFound:
            return "Growth record not found"
        }
    }
}
