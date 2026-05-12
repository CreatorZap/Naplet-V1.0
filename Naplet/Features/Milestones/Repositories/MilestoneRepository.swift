import Foundation
import Supabase

// MARK: - Milestone Repository
@MainActor
class MilestoneRepository: ObservableObject {
    static let shared = MilestoneRepository()

    @Published var achievedMilestones: [BabyMilestone] = []

    private let tableName = "baby_milestones"
    private let supabase = SupabaseService.shared

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    private init() {}

    // MARK: - Fetch Achieved Milestones
    func fetchAchievedMilestones(babyId: UUID) async throws -> [BabyMilestone] {
        let response: [BabyMilestone] = try await supabase.client
            .from(tableName)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .order("achieved_date", ascending: false)
            .execute()
            .value

        self.achievedMilestones = response

        Logger.info("Fetched \(response.count) milestones for baby \(babyId)")
        return response
    }

    // MARK: - Mark Milestone as Achieved
    func markAchieved(
        babyId: UUID,
        milestoneKey: String,
        achievedAt: Date = Date(),
        notes: String? = nil
    ) async throws -> BabyMilestone {
        guard let userId = supabase.currentUserId else {
            throw MilestoneRepositoryError.notAuthenticated
        }

        let dateString = Self.dateFormatter.string(from: achievedAt)

        let insertDTO = BabyMilestoneInsert(
            babyId: babyId,
            milestoneKey: milestoneKey,
            achievedDate: dateString,
            notes: notes?.isEmpty == true ? nil : notes,
            userId: userId
        )

        let response: BabyMilestone = try await supabase.client
            .from(tableName)
            .insert(insertDTO)
            .select()
            .single()
            .execute()
            .value

        self.achievedMilestones.insert(response, at: 0)

        Logger.info("Marked milestone achieved: \(milestoneKey) for baby \(babyId)")
        return response
    }

    // MARK: - Remove Achievement
    func removeAchievement(recordId: UUID) async throws {
        try await supabase.client
            .from(tableName)
            .delete()
            .eq("id", value: recordId.uuidString)
            .execute()

        self.achievedMilestones.removeAll { $0.id == recordId }

        Logger.info("Removed milestone record: \(recordId)")
    }

    // MARK: - Check if Milestone is Achieved
    func isAchieved(milestoneKey: String) -> Bool {
        achievedMilestones.contains { $0.milestoneKey == milestoneKey }
    }

    // MARK: - Get Achievement Record
    func achievementRecord(for milestoneKey: String) -> BabyMilestone? {
        achievedMilestones.first { $0.milestoneKey == milestoneKey }
    }

    // MARK: - Get Achievement Count
    var achievedCount: Int {
        achievedMilestones.count
    }

    // MARK: - Get Progress
    func progress(for category: MilestoneCategory) -> Double {
        let categoryMilestones = MilestoneDefinition.milestones(for: category)
        guard categoryMilestones.count > 0 else { return 0 }

        let achievedKeys = Set(achievedMilestones.map { $0.milestoneKey })
        let achievedInCategory = categoryMilestones.filter { achievedKeys.contains($0.id) }.count

        return Double(achievedInCategory) / Double(categoryMilestones.count)
    }

    func overallProgress() -> Double {
        let total = MilestoneDefinition.allMilestones.count
        guard total > 0 else { return 0 }
        return Double(achievedCount) / Double(total)
    }
}

// MARK: - Milestone Repository Error
enum MilestoneRepositoryError: LocalizedError {
    case notAuthenticated
    case milestoneNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .milestoneNotFound:
            return "Milestone not found"
        }
    }
}
