import Foundation

// MARK: - Referral Code
struct ReferralCode: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let code: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case code
        case createdAt = "created_at"
    }

    /// URL completa para compartilhar
    var shareURL: URL {
        URL(string: "https://naplet.app/r/\(code)") ?? URL(string: "https://naplet.app")!
    }
}

// MARK: - Referral
struct Referral: Codable, Identifiable {
    let id: UUID
    let referrerId: UUID
    let referredId: UUID
    let referralCode: String
    let status: ReferralStatus
    let convertedAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case referrerId = "referrer_id"
        case referredId = "referred_id"
        case referralCode = "referral_code"
        case status
        case convertedAt = "converted_at"
        case createdAt = "created_at"
    }
}

// MARK: - Referral Status
enum ReferralStatus: String, Codable {
    case pending
    case converted
    case expired
}

// MARK: - Referral Stats
struct ReferralStats {
    let totalReferrals: Int
    let isAmbassador: Bool
    let ambassadorSince: Date?
    let referralCode: String

    var referralsUntilAmbassador: Int {
        max(0, 5 - totalReferrals)
    }

    var progress: Double {
        min(1.0, Double(totalReferrals) / 5.0)
    }

    static let empty = ReferralStats(
        totalReferrals: 0,
        isAmbassador: false,
        ambassadorSince: nil,
        referralCode: ""
    )
}

// MARK: - Profile Stats (for decoding from Supabase)
struct ProfileReferralStats: Decodable {
    let totalReferrals: Int
    let isAmbassador: Bool
    let ambassadorSince: Date?

    enum CodingKeys: String, CodingKey {
        case totalReferrals = "total_referrals"
        case isAmbassador = "is_ambassador"
        case ambassadorSince = "ambassador_since"
    }
}
