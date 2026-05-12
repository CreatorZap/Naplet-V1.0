import Foundation
import Supabase

// MARK: - Baby Repository
@MainActor
class BabyRepository: ObservableObject {
    private let supabase = SupabaseService.shared
    private let tableName = "babies"

    @Published var babies: [Baby] = []
    @Published var currentBaby: Baby?
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Create Baby
    func createBaby(name: String, birthDate: Date, gender: Baby.Gender?) async throws -> Baby {
        guard let userId = supabase.currentUserId else {
            throw BabyRepositoryError.notAuthenticated
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        let newBaby = BabyInsertDTO(
            name: name,
            birthDate: birthDate,
            gender: gender,
            ownerId: userId
        )

        let response: Baby = try await supabase.client
            .from(tableName)
            .insert(newBaby)
            .select()
            .single()
            .execute()
            .value

        babies.append(response)
        currentBaby = response

        // Save current baby ID locally
        UserDefaults.standard.set(response.id.uuidString, forKey: "currentBabyId")

        Logger.info("Baby created: \(response.name)")
        return response
    }

    // MARK: - Fetch User's Babies (including shared via caregiver)
    func fetchBabies() async throws {
        guard let userId = supabase.currentUserId else {
            throw BabyRepositoryError.notAuthenticated
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        // Fetch babies owned by user
        let ownedBabies: [Baby] = try await supabase.client
            .from(tableName)
            .select()
            .eq("owner_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        // Fetch babies shared via caregiver relationship
        let sharedBabies: [Baby] = try await supabase.client
            .from(tableName)
            .select("*, caregivers!inner(*)")
            .eq("caregivers.user_id", value: userId.uuidString)
            .not("owner_id", operator: .eq, value: userId.uuidString)
            .execute()
            .value

        // Combine and deduplicate
        var allBabies = ownedBabies
        for baby in sharedBabies {
            if !allBabies.contains(where: { $0.id == baby.id }) {
                allBabies.append(baby)
            }
        }

        babies = allBabies

        // Load current baby
        loadCurrentBaby()

        Logger.info("Fetched \(babies.count) babies (owned: \(ownedBabies.count), shared: \(sharedBabies.count))")
    }

    // MARK: - Fetch Single Baby
    func fetchBaby(id: UUID) async throws -> Baby? {
        isLoading = true
        defer { isLoading = false }

        let response: [Baby] = try await supabase.client
            .from(tableName)
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    // MARK: - Update Baby
    func updateBaby(_ baby: Baby) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let update = BabyUpdateDTO(
            name: baby.name,
            birthDate: baby.birthDate,
            gender: baby.gender,
            photoUrl: baby.photoURL
        )

        try await supabase.client
            .from(tableName)
            .update(update)
            .eq("id", value: baby.id.uuidString)
            .execute()

        // Update local list
        if let index = babies.firstIndex(where: { $0.id == baby.id }) {
            babies[index] = baby
        }

        if currentBaby?.id == baby.id {
            currentBaby = baby
        }

        Logger.info("Baby updated: \(baby.name)")
    }

    // MARK: - Delete Baby
    func deleteBaby(_ baby: Baby) async throws {
        guard let userId = supabase.currentUserId else {
            throw BabyRepositoryError.notAuthenticated
        }

        // Only owner can delete
        guard baby.ownerId == userId else {
            throw BabyRepositoryError.notOwner
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        try await supabase.client
            .from(tableName)
            .delete()
            .eq("id", value: baby.id.uuidString)
            .execute()

        babies.removeAll { $0.id == baby.id }

        if currentBaby?.id == baby.id {
            currentBaby = babies.first
            if let newCurrent = currentBaby {
                UserDefaults.standard.set(newCurrent.id.uuidString, forKey: "currentBabyId")
            } else {
                UserDefaults.standard.removeObject(forKey: "currentBabyId")
            }
        }

        Logger.info("Baby deleted: \(baby.name)")
    }

    // MARK: - Select Current Baby
    func selectBaby(_ baby: Baby) {
        currentBaby = baby
        UserDefaults.standard.set(baby.id.uuidString, forKey: "currentBabyId")
        Logger.info("Selected baby: \(baby.name)")
    }

    // MARK: - Check if user can edit baby
    func canEdit(_ baby: Baby) -> Bool {
        guard let userId = supabase.currentUserId else { return false }
        return baby.ownerId == userId
    }

    // MARK: - Update Sleep Preferences
    func updateSleepPreferences(babyId: UUID, preferences: BabySleepPreferences) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let update = SleepPreferencesUpdateDTO(sleepPreferences: preferences)

        try await supabase.client
            .from(tableName)
            .update(update)
            .eq("id", value: babyId.uuidString)
            .execute()

        // Update local list
        if let index = babies.firstIndex(where: { $0.id == babyId }) {
            babies[index].sleepPreferences = preferences
        }

        if currentBaby?.id == babyId {
            currentBaby?.sleepPreferences = preferences
        }

        Logger.info("Sleep preferences updated for baby: \(babyId)")
    }

    // MARK: - Private Helpers

    private func loadCurrentBaby() {
        if let currentBabyId = UserDefaults.standard.string(forKey: "currentBabyId"),
           let uuid = UUID(uuidString: currentBabyId),
           let baby = babies.first(where: { $0.id == uuid }) {
            currentBaby = baby
        } else if let firstBaby = babies.first {
            currentBaby = firstBaby
            UserDefaults.standard.set(firstBaby.id.uuidString, forKey: "currentBabyId")
        }
    }
}

// MARK: - Errors
enum BabyRepositoryError: LocalizedError {
    case notAuthenticated
    case babyNotFound
    case createFailed
    case notOwner

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Usuário não autenticado"
        case .babyNotFound:
            return "Bebê não encontrado"
        case .createFailed:
            return "Erro ao criar bebê"
        case .notOwner:
            return "Apenas o responsável pode realizar esta ação"
        }
    }
}

// MARK: - Insert/Update DTOs (specific for repository operations)
struct BabyInsertDTO: Encodable {
    let name: String
    let birthDate: Date
    let gender: Baby.Gender?
    let ownerId: UUID

    enum CodingKeys: String, CodingKey {
        case name
        case birthDate = "birth_date"
        case gender
        case ownerId = "owner_id"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(birthDate, forKey: .birthDate)
        try container.encodeIfPresent(gender?.rawValue, forKey: .gender)
        try container.encode(ownerId, forKey: .ownerId)
    }
}

struct BabyUpdateDTO: Encodable {
    let name: String
    let birthDate: Date
    let gender: Baby.Gender?
    let photoUrl: String?

    enum CodingKeys: String, CodingKey {
        case name
        case birthDate = "birth_date"
        case gender
        case photoUrl = "photo_url"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(birthDate, forKey: .birthDate)
        try container.encodeIfPresent(gender?.rawValue, forKey: .gender)
        try container.encodeIfPresent(photoUrl, forKey: .photoUrl)
    }
}

struct SleepPreferencesUpdateDTO: Encodable {
    let sleepPreferences: BabySleepPreferences

    enum CodingKeys: String, CodingKey {
        case sleepPreferences = "sleep_preferences"
    }
}

// MARK: - Mock Repository (for testing/preview)
#if DEBUG
final class MockBabyRepository {
    var babies: [Baby] = Baby.previewList

    func fetchBabies(for userId: UUID) async throws -> [Baby] {
        return babies
    }

    func fetchBaby(id: UUID) async throws -> Baby? {
        return babies.first { $0.id == id }
    }

    func createBaby(_ baby: Baby) async throws -> Baby {
        babies.append(baby)
        return baby
    }

    func updateBaby(_ baby: Baby) async throws -> Baby {
        if let index = babies.firstIndex(where: { $0.id == baby.id }) {
            babies[index] = baby
        }
        return baby
    }

    func deleteBaby(id: UUID) async throws {
        babies.removeAll { $0.id == id }
    }
}
#endif
