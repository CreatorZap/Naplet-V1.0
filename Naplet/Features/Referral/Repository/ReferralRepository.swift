import Foundation

// MARK: - Referral Repository Protocol
protocol ReferralRepositoryProtocol {
    func fetchMyReferralCode() async throws -> ReferralCode?
    func fetchMyReferrals() async throws -> [Referral]
    func fetchReferralStats() async throws -> ReferralStats
    func validateReferralCode(_ code: String) async throws -> Bool
    func processReferral(referredUserId: UUID, code: String) async throws -> Bool
}

// MARK: - Referral Repository
final class ReferralRepository: ReferralRepositoryProtocol {

    private let supabase = SupabaseService.shared

    // MARK: - Fetch My Referral Code

    func fetchMyReferralCode() async throws -> ReferralCode? {
        guard let userId = try? await supabase.client.auth.session.user.id else {
            return nil
        }

        let codes: [ReferralCode] = try await supabase.client
            .from("referral_codes")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return codes.first
    }

    // MARK: - Fetch My Referrals

    func fetchMyReferrals() async throws -> [Referral] {
        guard let userId = try? await supabase.client.auth.session.user.id else {
            return []
        }

        let referrals: [Referral] = try await supabase.client
            .from("referrals")
            .select()
            .eq("referrer_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return referrals
    }

    // MARK: - Fetch Stats

    func fetchReferralStats() async throws -> ReferralStats {
        guard let userId = try? await supabase.client.auth.session.user.id else {
            throw ReferralError.notAuthenticated
        }

        // Buscar código
        let code = try await fetchMyReferralCode()

        // Buscar perfil com stats
        let profiles: [ProfileReferralStats] = try await supabase.client
            .from("profiles")
            .select("total_referrals, is_ambassador, ambassador_since")
            .eq("id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        let profile = profiles.first

        return ReferralStats(
            totalReferrals: profile?.totalReferrals ?? 0,
            isAmbassador: profile?.isAmbassador ?? false,
            ambassadorSince: profile?.ambassadorSince,
            referralCode: code?.code ?? ""
        )
    }

    // MARK: - Validate Code

    func validateReferralCode(_ code: String) async throws -> Bool {
        let codes: [ReferralCode] = try await supabase.client
            .from("referral_codes")
            .select()
            .eq("code", value: code.uppercased())
            .limit(1)
            .execute()
            .value

        return !codes.isEmpty
    }

    // MARK: - Process Referral

    func processReferral(referredUserId: UUID, code: String) async throws -> Bool {
        struct RpcParams: Encodable {
            let p_referred_user_id: String
            let p_referral_code: String
        }

        let params = RpcParams(
            p_referred_user_id: referredUserId.uuidString,
            p_referral_code: code.uppercased()
        )

        _ = try await supabase.client
            .rpc("process_referral_conversion", params: params)
            .execute()

        return true
    }
}

// MARK: - Referral Errors

enum ReferralError: LocalizedError {
    case notAuthenticated
    case invalidCode
    case alreadyReferred
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "referral.error.notAuthenticated".localized
        case .invalidCode:
            return "referral.error.invalidCode".localized
        case .alreadyReferred:
            return "referral.error.alreadyReferred".localized
        case .processingFailed:
            return "referral.error.processingFailed".localized
        }
    }
}
