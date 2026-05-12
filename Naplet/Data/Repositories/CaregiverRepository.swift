import Foundation
import Supabase

// MARK: - Caregiver Repository
@MainActor
class CaregiverRepository: ObservableObject {
    private let supabase = SupabaseService.shared
    private let caregiversTable = "caregivers"
    private let invitesTable = "invites"

    @Published var caregivers: [Caregiver] = []
    @Published var pendingInvites: [Invite] = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Fetch Caregivers for Baby
    func fetchCaregivers(for babyId: UUID) async throws -> [Caregiver] {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let response: [Caregiver] = try await supabase.client
            .from(caregiversTable)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value

        caregivers = response
        Logger.info("Fetched \(response.count) caregivers for baby")
        return response
    }

    // MARK: - Fetch Active Caregivers (accepted only)
    func fetchActiveCaregivers(for babyId: UUID) async throws -> [Caregiver] {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let response: [Caregiver] = try await supabase.client
            .from(caregiversTable)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .not("accepted_at", operator: .is, value: "null")
            .order("created_at", ascending: true)
            .execute()
            .value

        return response
    }

    // MARK: - Check User Role for Baby
    func getUserRole(for babyId: UUID) async throws -> Caregiver.CaregiverRole? {
        guard let userId = supabase.currentUserId else {
            return nil
        }

        // First check caregivers table
        let response: [Caregiver] = try await supabase.client
            .from(caregiversTable)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        if let caregiver = response.first {
            return caregiver.role
        }
        
        // If not in caregivers, check if user is the baby owner
        let babies: [Baby] = try await supabase.client
            .from("babies")
            .select()
            .eq("id", value: babyId.uuidString)
            .eq("owner_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        
        if !babies.isEmpty {
            // User is the owner - auto-create caregiver record
            Logger.info("User is baby owner, auto-creating caregiver record")
            try? await createOwnerCaregiver(babyId: babyId, userId: userId)
            return .owner
        }
        
        return nil
    }
    
    // MARK: - Create Owner as Caregiver
    private func createOwnerCaregiver(babyId: UUID, userId: UUID) async throws {
        let ownerCaregiver = CaregiverInsertDTO(
            babyId: babyId,
            userId: userId,
            role: .owner,
            invitedBy: nil,
            acceptedAt: Date()
        )
        
        try await supabase.client
            .from(caregiversTable)
            .insert(ownerCaregiver)
            .execute()
        
        Logger.info("Owner caregiver record created for baby \(babyId)")
    }

    // MARK: - Create Invite
    func createInvite(
        for babyId: UUID,
        email: String? = nil,
        role: Caregiver.CaregiverRole = .other,
        expiresInDays: Int = 7
    ) async throws -> Invite {
        guard let userId = supabase.currentUserId else {
            throw CaregiverRepositoryError.notAuthenticated
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        // Generate invite code via RPC or locally
        let inviteCode = generateInviteCode()
        let expiresAt = Calendar.current.date(byAdding: .day, value: expiresInDays, to: Date()) ?? Date()

        let newInvite = InviteInsertDTO(
            babyId: babyId,
            invitedBy: userId,
            inviteCode: inviteCode,
            email: email,
            role: role,
            expiresAt: expiresAt
        )

        let response: Invite = try await supabase.client
            .from(invitesTable)
            .insert(newInvite)
            .select()
            .single()
            .execute()
            .value

        pendingInvites.append(response)
        Logger.info("Invite created: \(inviteCode)")
        return response
    }

    // MARK: - Accept Invite (via RPC)
    func acceptInvite(code: String) async throws -> AcceptInviteResponse {
        guard supabase.currentUserId != nil else {
            throw CaregiverRepositoryError.notAuthenticated
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        // Call the accept_invite RPC function
        let response: [AcceptInviteResponse] = try await supabase.client
            .rpc("accept_invite", params: ["p_invite_code": code])
            .execute()
            .value

        guard let result = response.first else {
            throw CaregiverRepositoryError.invalidInvite
        }

        if !result.success {
            throw CaregiverRepositoryError.inviteFailed(result.error ?? "Unknown error")
        }

        Logger.info("Invite accepted for baby: \(result.babyId?.uuidString ?? "unknown")")
        return result
    }

    // MARK: - Accept Invite (manual - fallback if RPC not available)
    func acceptInviteManual(code: String) async throws -> Caregiver {
        guard let userId = supabase.currentUserId else {
            throw CaregiverRepositoryError.notAuthenticated
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        // Find the invite
        let invites: [Invite] = try await supabase.client
            .from(invitesTable)
            .select()
            .eq("invite_code", value: code)
            .eq("status", value: "pending")
            .gt("expires_at", value: Date().ISO8601Format())
            .limit(1)
            .execute()
            .value

        guard let invite = invites.first else {
            throw CaregiverRepositoryError.invalidInvite
        }

        // Check if already a caregiver
        let existingCaregivers: [Caregiver] = try await supabase.client
            .from(caregiversTable)
            .select()
            .eq("baby_id", value: invite.babyId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        if !existingCaregivers.isEmpty {
            throw CaregiverRepositoryError.alreadyCaregiver
        }

        // Create caregiver record
        let newCaregiver = CaregiverInsertDTO(
            babyId: invite.babyId,
            userId: userId,
            role: invite.role,
            invitedBy: invite.invitedBy,
            acceptedAt: Date()
        )

        let caregiver: Caregiver = try await supabase.client
            .from(caregiversTable)
            .insert(newCaregiver)
            .select()
            .single()
            .execute()
            .value

        // Update invite status
        try await supabase.client
            .from(invitesTable)
            .update(InviteUpdateDTO(status: .accepted, acceptedBy: userId))
            .eq("id", value: invite.id.uuidString)
            .execute()

        Logger.info("Caregiver created via invite")
        return caregiver
    }

    // MARK: - Remove Caregiver
    func removeCaregiver(_ caregiver: Caregiver) async throws {
        guard let userId = supabase.currentUserId else {
            throw CaregiverRepositoryError.notAuthenticated
        }

        // Cannot remove owner
        if caregiver.role == .owner {
            throw CaregiverRepositoryError.cannotRemoveOwner
        }

        // Only owner can remove others
        let userRole = try await getUserRole(for: caregiver.babyId)
        if userRole != .owner && caregiver.userId != userId {
            throw CaregiverRepositoryError.notAuthorized
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        try await supabase.client
            .from(caregiversTable)
            .delete()
            .eq("id", value: caregiver.id.uuidString)
            .execute()

        caregivers.removeAll { $0.id == caregiver.id }
        Logger.info("Caregiver removed")
    }

    // MARK: - Update Caregiver Role
    func updateCaregiverRole(_ caregiver: Caregiver, newRole: Caregiver.CaregiverRole) async throws {
        // Cannot change owner role
        if caregiver.role == .owner || newRole == .owner {
            throw CaregiverRepositoryError.cannotChangeOwnerRole
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        let update = CaregiverUpdateDTO(role: newRole)

        try await supabase.client
            .from(caregiversTable)
            .update(update)
            .eq("id", value: caregiver.id.uuidString)
            .execute()

        if let index = caregivers.firstIndex(where: { $0.id == caregiver.id }) {
            caregivers[index].role = newRole
        }

        Logger.info("Caregiver role updated to \(newRole.displayName)")
    }

    // MARK: - Cancel Invite
    func cancelInvite(_ invite: Invite) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let update = InviteUpdateDTO(status: .cancelled, acceptedBy: nil)

        try await supabase.client
            .from(invitesTable)
            .update(update)
            .eq("id", value: invite.id.uuidString)
            .execute()

        pendingInvites.removeAll { $0.id == invite.id }
        Logger.info("Invite cancelled")
    }

    // MARK: - Fetch Pending Invites
    func fetchPendingInvites(for babyId: UUID) async throws -> [Invite] {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let response: [Invite] = try await supabase.client
            .from(invitesTable)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .eq("status", value: "pending")
            .gt("expires_at", value: Date().ISO8601Format())
            .order("created_at", ascending: false)
            .execute()
            .value

        pendingInvites = response
        return response
    }

    // MARK: - Fetch Invites for Current User
    func fetchMyPendingInvites() async throws -> [Invite] {
        guard supabase.currentUserId != nil else {
            throw CaregiverRepositoryError.notAuthenticated
        }

        // Get user email
        let user = try await supabase.client.auth.user()
        guard let email = user.email else {
            return []
        }

        let response: [Invite] = try await supabase.client
            .from(invitesTable)
            .select()
            .eq("email", value: email)
            .eq("status", value: "pending")
            .gt("expires_at", value: Date().ISO8601Format())
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    // MARK: - Helper: Generate Invite Code
    private func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Excludes confusing chars like O, 0, I, 1
        return String((0..<8).map { _ in characters.randomElement() ?? Character("A") })
    }
}

// MARK: - Errors
enum CaregiverRepositoryError: LocalizedError {
    case notAuthenticated
    case notAuthorized
    case invalidInvite
    case alreadyCaregiver
    case cannotRemoveOwner
    case cannotChangeOwnerRole
    case inviteFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Usuário não autenticado"
        case .notAuthorized:
            return "Você não tem permissão para esta ação"
        case .invalidInvite:
            return "Convite inválido ou expirado"
        case .alreadyCaregiver:
            return "Você já é cuidador deste bebê"
        case .cannotRemoveOwner:
            return "Não é possível remover o responsável principal"
        case .cannotChangeOwnerRole:
            return "Não é possível alterar o papel do responsável principal"
        case .inviteFailed(let message):
            return message
        }
    }
}

// MARK: - RPC Response Types
struct AcceptInviteResponse: Codable {
    let success: Bool
    let caregiverId: UUID?
    let babyId: UUID?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case success
        case caregiverId = "caregiver_id"
        case babyId = "baby_id"
        case error
    }
}

// MARK: - Insert/Update DTOs

struct CaregiverInsertDTO: Encodable {
    let babyId: UUID
    let userId: UUID
    let role: Caregiver.CaregiverRole
    let invitedBy: UUID?
    let acceptedAt: Date?

    enum CodingKeys: String, CodingKey {
        case babyId = "baby_id"
        case userId = "user_id"
        case role
        case invitedBy = "invited_by"
        case acceptedAt = "accepted_at"
    }
}

struct CaregiverUpdateDTO: Encodable {
    let role: Caregiver.CaregiverRole?
    let displayName: String?
    let acceptedAt: Date?

    enum CodingKeys: String, CodingKey {
        case role
        case displayName = "display_name"
        case acceptedAt = "accepted_at"
    }

    init(role: Caregiver.CaregiverRole? = nil, displayName: String? = nil, acceptedAt: Date? = nil) {
        self.role = role
        self.displayName = displayName
        self.acceptedAt = acceptedAt
    }
}

struct InviteInsertDTO: Encodable {
    let babyId: UUID
    let invitedBy: UUID
    let inviteCode: String
    let email: String?
    let role: Caregiver.CaregiverRole
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case babyId = "baby_id"
        case invitedBy = "invited_by"
        case inviteCode = "invite_code"
        case email
        case role
        case expiresAt = "expires_at"
    }
}

struct InviteUpdateDTO: Encodable {
    let status: Invite.InviteStatus?
    let acceptedBy: UUID?

    enum CodingKeys: String, CodingKey {
        case status
        case acceptedBy = "accepted_by"
    }
}

// MARK: - Caregiver with Profile (joined query)
struct CaregiverWithProfile: Codable, Identifiable {
    let id: UUID
    let babyId: UUID
    let userId: UUID
    let role: Caregiver.CaregiverRole
    let displayName: String?
    let acceptedAt: Date?
    let createdAt: Date

    // Joined profile data
    let profile: ProfileInfo?

    struct ProfileInfo: Codable {
        let email: String?
        let displayName: String?
        let avatarUrl: String?

        enum CodingKeys: String, CodingKey {
            case email
            case displayName = "display_name"
            case avatarUrl = "avatar_url"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case userId = "user_id"
        case role
        case displayName = "display_name"
        case acceptedAt = "accepted_at"
        case createdAt = "created_at"
        case profile = "profiles"
    }

    var effectiveDisplayName: String {
        displayName ?? profile?.displayName ?? profile?.email ?? "Cuidador"
    }
}

// MARK: - Extension to fetch caregivers with profile
extension CaregiverRepository {
    func fetchCaregiversWithProfiles(for babyId: UUID) async throws -> [CaregiverWithProfile] {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let response: [CaregiverWithProfile] = try await supabase.client
            .from(caregiversTable)
            .select("*, profiles(*)")
            .eq("baby_id", value: babyId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value

        return response
    }
}

// MARK: - Mock Repository
#if DEBUG
final class MockCaregiverRepository {
    var caregivers: [Caregiver] = Caregiver.previewList
    var invites: [Invite] = []

    func fetchCaregivers(for babyId: UUID) async throws -> [Caregiver] {
        return caregivers.filter { $0.babyId == babyId }
    }

    func createInvite(for babyId: UUID, role: Caregiver.CaregiverRole) async throws -> Invite {
        let invite = Invite(
            babyId: babyId,
            invitedBy: UUID(),
            inviteCode: "MOCK1234",
            role: role
        )
        invites.append(invite)
        return invite
    }

    func acceptInvite(code: String) async throws -> Caregiver {
        guard let invite = invites.first(where: { $0.inviteCode == code }) else {
            throw CaregiverRepositoryError.invalidInvite
        }

        let caregiver = Caregiver(
            babyId: invite.babyId,
            userId: UUID(),
            role: invite.role,
            acceptedAt: Date()
        )
        caregivers.append(caregiver)
        return caregiver
    }

    func removeCaregiver(_ caregiver: Caregiver) async throws {
        caregivers.removeAll { $0.id == caregiver.id }
    }
}
#endif
