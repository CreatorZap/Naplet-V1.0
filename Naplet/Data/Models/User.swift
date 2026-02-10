import Foundation

// MARK: - Profile Model (corresponds to Supabase profiles table)
/// Perfil do usuário que extende auth.users do Supabase
struct Profile: Identifiable, Codable, Equatable {
    let id: UUID
    var email: String?
    var displayName: String?
    var avatarUrl: String?
    var subscriptionStatus: SubscriptionStatus
    var subscriptionExpiresAt: Date?
    var timezone: String
    var locale: String
    var notificationToken: String?
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Subscription Status
    enum SubscriptionStatus: String, Codable {
        case free = "free"
        case premium = "premium"
        case trial = "trial"

        var displayName: String {
            switch self {
            case .free: return "subscription.tier.free".localized
            case .premium: return "subscription.tier.premium".localized
            case .trial: return "subscription.tier.trial".localized
            }
        }

        var isPaid: Bool {
            self == .premium
        }

        var maxBabies: Int {
            switch self {
            case .free: return 1
            case .trial: return 2
            case .premium: return 5
            }
        }

        var hasCloudSync: Bool {
            self != .free
        }

        var hasExport: Bool {
            self != .free
        }

        var hasDetailedStats: Bool {
            self != .free
        }

        var hasWidgets: Bool {
            true
        }

        var hasMultiCaregiver: Bool {
            self != .free
        }
    }

    // MARK: - Computed Properties

    var firstName: String? {
        displayName?.components(separatedBy: " ").first
    }

    var initial: String {
        if let name = displayName, !name.isEmpty {
            return String(name.prefix(1)).uppercased()
        }
        if let email = email, !email.isEmpty {
            return String(email.prefix(1)).uppercased()
        }
        return "?"
    }

    var isPremium: Bool {
        subscriptionStatus.isPaid
    }

    var isSubscriptionActive: Bool {
        guard subscriptionStatus.isPaid else { return false }
        if let expiresAt = subscriptionExpiresAt {
            return expiresAt > Date()
        }
        return true
    }

    var isTrial: Bool {
        subscriptionStatus == .trial
    }

    var trialDaysRemaining: Int? {
        guard isTrial, let expiresAt = subscriptionExpiresAt else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0
        return max(0, days)
    }

    // MARK: - Init
    init(
        id: UUID,
        email: String? = nil,
        displayName: String? = nil,
        avatarUrl: String? = nil,
        subscriptionStatus: SubscriptionStatus = .free,
        subscriptionExpiresAt: Date? = nil,
        timezone: String = TimeZone.current.identifier,
        locale: String = Locale.current.identifier,
        notificationToken: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.subscriptionStatus = subscriptionStatus
        self.subscriptionExpiresAt = subscriptionExpiresAt
        self.timezone = timezone
        self.locale = locale
        self.notificationToken = notificationToken
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Coding Keys (snake_case para Supabase)
extension Profile {
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case subscriptionStatus = "subscription_status"
        case subscriptionExpiresAt = "subscription_expires_at"
        case timezone
        case locale
        case notificationToken = "notification_token"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Profile Insert DTO (para criar perfil)
/// Estrutura para INSERT no Supabase (sem campos auto-gerados)
struct ProfileInsert: Codable {
    let id: UUID
    let email: String?
    let displayName: String?
    let avatarUrl: String?
    let timezone: String
    let locale: String

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case timezone
        case locale
    }

    init(from profile: Profile) {
        self.id = profile.id
        self.email = profile.email
        self.displayName = profile.displayName
        self.avatarUrl = profile.avatarUrl
        self.timezone = profile.timezone
        self.locale = profile.locale
    }
}

// MARK: - Profile Update DTO (para atualizar perfil)
/// Estrutura para UPDATE no Supabase (apenas campos editáveis)
struct ProfileUpdate: Codable {
    var displayName: String?
    var avatarUrl: String?
    var timezone: String?
    var locale: String?
    var notificationToken: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case timezone
        case locale
        case notificationToken = "notification_token"
    }
}

// MARK: - Auth State
enum AuthState: Equatable {
    case unknown
    case unauthenticated
    case authenticated(Profile)

    var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }

    var user: Profile? {
        if case .authenticated(let profile) = self {
            return profile
        }
        return nil
    }

    var userId: UUID? {
        user?.id
    }
}

// MARK: - Legacy AppUser (para compatibilidade)
/// Mantido para compatibilidade com código existente
/// Use `Profile` para novos desenvolvimentos
typealias AppUser = Profile

// MARK: - Mock Data
extension Profile {
    static let preview = Profile(
        id: UUID(),
        email: "ana@example.com",
        displayName: "Ana Silva",
        subscriptionStatus: .premium
    )

    static let freePreview = Profile(
        id: UUID(),
        email: "joao@example.com",
        displayName: "João Santos",
        subscriptionStatus: .free
    )

    static let trialPreview = Profile(
        id: UUID(),
        email: "maria@example.com",
        displayName: "Maria Santos",
        subscriptionStatus: .trial,
        subscriptionExpiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date())
    )
}
