import Foundation

// MARK: - SupabaseService Support Extension
extension SupabaseService {

    // MARK: - FAQ Methods

    /// Fetch all active FAQ items from Supabase
    func fetchFAQItems() async throws -> [FAQItem] {
        // Check if in mock mode
        if AppEnvironment.current.useMockData {
            return LocalFAQData.items
        }

        let response: [FAQItem] = try await client
            .from("faq_items")
            .select()
            .eq("is_active", value: true)
            .order("order_index")
            .execute()
            .value

        return response
    }

    // MARK: - Support Ticket Methods

    /// Create a new support ticket
    func createSupportTicket(_ ticket: SupportTicket) async throws {
        // Check if in mock mode
        if AppEnvironment.current.useMockData {
            Logger.info("Mock mode: Support ticket would be created - \(ticket.subject)")
            return
        }

        try await client
            .from("support_tickets")
            .insert(ticket)
            .execute()

        Logger.info("Support ticket created successfully")
    }

    /// Fetch user's support tickets
    func fetchUserTickets() async throws -> [SupportTicket] {
        guard let userId = currentUserId else {
            throw SupabaseSupportError.notAuthenticated
        }

        // Check if in mock mode
        if AppEnvironment.current.useMockData {
            return []
        }

        let response: [SupportTicket] = try await client
            .from("support_tickets")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    // MARK: - Helper Methods

    /// Get current user ID
    func getCurrentUserId() async throws -> UUID? {
        return currentUserId
    }

    /// Get current user email
    func getCurrentUserEmail() async throws -> String? {
        return currentUser?.email
    }
}

// MARK: - Support Errors
enum SupabaseSupportError: Error, LocalizedError {
    case notAuthenticated
    case fetchFailed
    case createFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .fetchFailed:
            return "Failed to fetch data"
        case .createFailed:
            return "Failed to create ticket"
        }
    }
}
