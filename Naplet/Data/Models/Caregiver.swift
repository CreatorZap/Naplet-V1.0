import Foundation
import SwiftUI

// MARK: - Caregiver Model
/// Representa a relação entre um usuário e um bebê (muitos-para-muitos)
struct Caregiver: Identifiable, Codable, Equatable {
    let id: UUID
    let babyId: UUID
    let userId: UUID
    var role: CaregiverRole
    var displayName: String?
    var invitedBy: UUID?
    var acceptedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Caregiver Role
    enum CaregiverRole: String, Codable, CaseIterable {
        case owner = "owner"
        case parent = "parent"
        case grandparent = "grandparent"
        case nanny = "nanny"
        case other = "other"

        var displayName: String {
            switch self {
            case .owner: return "caregivers.role.owner".localized
            case .parent: return "caregivers.role.parent".localized
            case .grandparent: return "caregivers.role.grandparent".localized
            case .nanny: return "caregivers.role.nanny".localized
            case .other: return "caregivers.role.other".localized
            }
        }

        var icon: String {
            switch self {
            case .owner: return "star.fill"
            case .parent: return "person.fill"
            case .grandparent: return "person.2.fill"
            case .nanny: return "heart.fill"
            case .other: return "person.crop.circle"
            }
        }

        var color: Color {
            switch self {
            case .owner: return NapletColors.warning
            case .parent: return NapletColors.primaryPurple
            case .grandparent: return NapletColors.primaryBlue
            case .nanny: return NapletColors.primaryPink
            case .other: return NapletColors.textSecondary
            }
        }

        var canEdit: Bool {
            true // Todos podem editar registros de sono
        }

        var canDelete: Bool {
            self == .owner
        }

        var canInvite: Bool {
            self == .owner || self == .parent
        }

        var canRemoveCaregivers: Bool {
            self == .owner
        }
    }

    // MARK: - Computed Properties

    var isPending: Bool {
        acceptedAt == nil
    }

    var isOwner: Bool {
        role == .owner
    }

    var isAccepted: Bool {
        acceptedAt != nil
    }

    // MARK: - Init
    init(
        id: UUID = UUID(),
        babyId: UUID,
        userId: UUID,
        role: CaregiverRole = .parent,
        displayName: String? = nil,
        invitedBy: UUID? = nil,
        acceptedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.babyId = babyId
        self.userId = userId
        self.role = role
        self.displayName = displayName
        self.invitedBy = invitedBy
        self.acceptedAt = acceptedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Coding Keys (snake_case para Supabase)
extension Caregiver {
    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case userId = "user_id"
        case role
        case displayName = "display_name"
        case invitedBy = "invited_by"
        case acceptedAt = "accepted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Invite Model
/// Convite para se tornar cuidador de um bebê
struct Invite: Identifiable, Codable, Equatable {
    let id: UUID
    let babyId: UUID
    let invitedBy: UUID
    let inviteCode: String
    var email: String?
    var role: Caregiver.CaregiverRole
    var status: InviteStatus
    var acceptedBy: UUID?
    var expiresAt: Date
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Invite Status
    enum InviteStatus: String, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case expired = "expired"
        case cancelled = "cancelled"

        var displayName: String {
            switch self {
            case .pending: return "invite.status.pending".localized
            case .accepted: return "invite.status.accepted".localized
            case .expired: return "invite.status.expired".localized
            case .cancelled: return "invite.status.cancelled".localized
            }
        }

        var icon: String {
            switch self {
            case .pending: return "clock.fill"
            case .accepted: return "checkmark.circle.fill"
            case .expired: return "xmark.circle.fill"
            case .cancelled: return "minus.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .pending: return NapletColors.warning
            case .accepted: return NapletColors.success
            case .expired: return NapletColors.textMuted
            case .cancelled: return NapletColors.error
            }
        }
    }

    // MARK: - Computed Properties

    var isValid: Bool {
        status == .pending && expiresAt > Date()
    }

    var isExpired: Bool {
        expiresAt <= Date()
    }

    // MARK: - Init
    init(
        id: UUID = UUID(),
        babyId: UUID,
        invitedBy: UUID,
        inviteCode: String,
        email: String? = nil,
        role: Caregiver.CaregiverRole = .other,
        status: InviteStatus = .pending,
        acceptedBy: UUID? = nil,
        expiresAt: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.babyId = babyId
        self.invitedBy = invitedBy
        self.inviteCode = inviteCode
        self.email = email
        self.role = role
        self.status = status
        self.acceptedBy = acceptedBy
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Invite Coding Keys
extension Invite {
    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case invitedBy = "invited_by"
        case inviteCode = "invite_code"
        case email
        case role
        case status
        case acceptedBy = "accepted_by"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Mock Data
extension Caregiver {
    static let preview = Caregiver(
        babyId: Baby.preview.id,
        userId: UUID(),
        role: .owner,
        displayName: "Ana Silva",
        acceptedAt: Date()
    )

    static let previewList: [Caregiver] = [
        Caregiver(babyId: Baby.preview.id, userId: UUID(), role: .owner, displayName: "Ana Silva", acceptedAt: Date()),
        Caregiver(babyId: Baby.preview.id, userId: UUID(), role: .parent, displayName: "Pedro Silva", acceptedAt: Date()),
        Caregiver(babyId: Baby.preview.id, userId: UUID(), role: .grandparent, displayName: "Maria Santos")
    ]
}

extension Invite {
    static let preview = Invite(
        babyId: Baby.preview.id,
        invitedBy: UUID(),
        inviteCode: "ABC12345",
        email: "convidado@example.com",
        role: .grandparent
    )
}
