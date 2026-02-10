import Foundation

// MARK: - Chat Message Model
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date

    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    var isUser: Bool { role == .user }

    init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - Chat Conversation (for history)
struct ChatConversation: Identifiable, Codable {
    let id: UUID
    let babyId: UUID
    let babyName: String
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date

    /// Título da conversa baseado na primeira pergunta do usuário
    var title: String {
        if let firstUserMessage = messages.first(where: { $0.role == .user }) {
            let text = firstUserMessage.content
            if text.count > 50 {
                return String(text.prefix(50)) + "..."
            }
            return text
        }
        return "chat.history.newConversation".localized
    }

    /// Preview da última mensagem
    var lastMessagePreview: String {
        if let lastMessage = messages.last {
            let text = lastMessage.content
            if text.count > 80 {
                return String(text.prefix(80)) + "..."
            }
            return text
        }
        return ""
    }

    /// Número de mensagens do usuário
    var userMessageCount: Int {
        messages.filter { $0.role == .user }.count
    }

    init(
        id: UUID = UUID(),
        babyId: UUID,
        babyName: String,
        messages: [ChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.babyId = babyId
        self.babyName = babyName
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Chat History Manager
@MainActor
class ChatHistoryManager: ObservableObject {
    static let shared = ChatHistoryManager()

    @Published var conversations: [ChatConversation] = []

    private let storageKey = "chat_conversations"
    private let maxConversations = 50

    private init() {
        loadConversations()
    }

    // MARK: - Load Conversations
    func loadConversations() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([ChatConversation].self, from: data) else {
            conversations = []
            return
        }
        conversations = decoded.sorted { $0.updatedAt > $1.updatedAt }
    }

    // MARK: - Save Conversations
    private func saveConversations() {
        guard let encoded = try? JSONEncoder().encode(conversations) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }

    // MARK: - Create New Conversation
    func createConversation(babyId: UUID, babyName: String) -> ChatConversation {
        let conversation = ChatConversation(
            babyId: babyId,
            babyName: babyName
        )
        conversations.insert(conversation, at: 0)

        // Limit stored conversations
        if conversations.count > maxConversations {
            conversations = Array(conversations.prefix(maxConversations))
        }

        saveConversations()
        return conversation
    }

    // MARK: - Update Conversation
    func updateConversation(_ conversation: ChatConversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            var updated = conversation
            updated.updatedAt = Date()
            conversations[index] = updated

            // Move to top
            conversations.sort { $0.updatedAt > $1.updatedAt }
            saveConversations()
        }
    }

    // MARK: - Delete Conversation
    func deleteConversation(_ conversation: ChatConversation) {
        conversations.removeAll { $0.id == conversation.id }
        saveConversations()
    }

    // MARK: - Delete All Conversations
    func deleteAllConversations() {
        conversations.removeAll()
        saveConversations()
    }

    // MARK: - Get Conversations for Baby
    func getConversations(for babyId: UUID) -> [ChatConversation] {
        conversations.filter { $0.babyId == babyId }
    }
}
