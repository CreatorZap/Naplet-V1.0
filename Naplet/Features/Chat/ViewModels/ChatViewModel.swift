import Foundation
import SwiftUI

// MARK: - Chat ViewModel
@MainActor
class ChatViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentConversation: ChatConversation?

    // MARK: - Context
    private var baby: Baby?
    private var sleepRecords: [SleepRecord] = []

    // MARK: - History Manager
    private let historyManager = ChatHistoryManager.shared

    // MARK: - Free Tier Tracking
    @AppStorage("aiChatCount") private var chatCount: Int = 0
    @AppStorage("aiChatResetDate") private var chatResetDateString: String = ""

    private var chatResetDate: Date? {
        get {
            guard !chatResetDateString.isEmpty else { return nil }
            return ISO8601DateFormatter().date(from: chatResetDateString)
        }
        set {
            if let date = newValue {
                chatResetDateString = ISO8601DateFormatter().string(from: date)
            } else {
                chatResetDateString = ""
            }
        }
    }

    var remainingFreeChats: Int {
        checkAndResetMonthlyLimit()
        return max(0, AppConfig.Limits.freeAIChatPerMonth - chatCount)
    }

    var hasReachedLimit: Bool {
        remainingFreeChats <= 0
    }

    // MARK: - Init
    init() {}

    // MARK: - Setup
    func setup(baby: Baby, sleepRecords: [SleepRecord]) {
        self.baby = baby
        self.sleepRecords = sleepRecords

        // Start new conversation if none loaded
        if currentConversation == nil {
            startNewConversation()
        }
    }

    // MARK: - Start New Conversation
    func startNewConversation() {
        guard let baby = baby else { return }

        currentConversation = historyManager.createConversation(
            babyId: baby.id,
            babyName: baby.name
        )

        messages = []
        addWelcomeMessage()

        // Save welcome message
        saveCurrentConversation()
    }

    // MARK: - Load Existing Conversation
    func loadConversation(_ conversation: ChatConversation) {
        currentConversation = conversation
        messages = conversation.messages

        // If empty, add welcome message
        if messages.isEmpty {
            addWelcomeMessage()
            saveCurrentConversation()
        }
    }

    // MARK: - Welcome Message
    private func addWelcomeMessage() {
        let welcome = ChatMessage(
            role: .assistant,
            content: "chat.welcome.message".localized
        )
        messages.append(welcome)
    }

    // MARK: - Save Current Conversation
    private func saveCurrentConversation() {
        guard var conversation = currentConversation else { return }
        conversation.messages = messages
        historyManager.updateConversation(conversation)
        currentConversation = conversation
    }

    // MARK: - Send Message
    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        guard let baby = baby else {
            errorMessage = "chat.error.noBaby".localized
            return
        }

        // Check free tier limit (skip for premium users)
        checkAndResetMonthlyLimit()
        let isPremium = SubscriptionManager.shared.hasUnlimitedChat
        if hasReachedLimit && !isPremium {
            errorMessage = "chat.error.limitReached".localized(with: AppConfig.Limits.freeAIChatPerMonth)
            return
        }

        // Add user message
        let userMessage = ChatMessage(
            role: .user,
            content: text
        )
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        errorMessage = nil

        do {
            let context = BabyContext.from(baby: baby, sleepRecords: sleepRecords)

            // Prepare history (last 10 messages)
            let history = messages.suffix(10).compactMap { msg -> OpenAIService.Message? in
                guard msg.role != .system else { return nil }
                return OpenAIService.Message(
                    role: msg.role.rawValue,
                    content: msg.content
                )
            }

            // Remove the last user message from history (it's sent separately)
            let historyWithoutLast = Array(history.dropLast())

            let response = try await OpenAIService.shared.sendMessage(
                userMessage: text,
                babyContext: context,
                conversationHistory: historyWithoutLast
            )

            let assistantMessage = ChatMessage(
                role: .assistant,
                content: response
            )
            messages.append(assistantMessage)

            // Increment chat count
            chatCount += 1

            // Save conversation
            saveCurrentConversation()

        } catch let error as OpenAIService.OpenAIError {
            Logger.error("Chat error: \(error)")

            switch error {
            case .notConfigured:
                errorMessage = "chat.error.notConfigured".localized
            case .rateLimited:
                errorMessage = "chat.error.rateLimited".localized
            case .unauthorized:
                errorMessage = "chat.error.unauthorized".localized
            default:
                errorMessage = "chat.error.generic".localized
            }

            // Remove the user message if we couldn't get a response
            if messages.last?.role == .user {
                messages.removeLast()
            }

        } catch {
            Logger.error("Chat error: \(error)")
            errorMessage = "chat.error.connection".localized

            if messages.last?.role == .user {
                messages.removeLast()
            }
        }

        isLoading = false
    }

    // MARK: - Clear Chat (starts new conversation)
    func clearChat() {
        startNewConversation()
    }

    // MARK: - Monthly Limit Reset
    private func checkAndResetMonthlyLimit() {
        let calendar = Calendar.current

        guard let resetDate = chatResetDate else {
            chatResetDate = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))
            return
        }

        let now = Date()
        if !calendar.isDate(resetDate, equalTo: now, toGranularity: .month) {
            chatCount = 0
            chatResetDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now))
        }
    }

    // MARK: - Suggested Questions
    var suggestedQuestions: [String] {
        guard let baby = baby else { return [] }

        var questions: [String] = []

        if baby.isNewborn {
            questions.append("chat.suggestion.routine".localized)
            questions.append("chat.suggestion.hoursPerDay".localized)
        } else if baby.isInfant {
            questions.append("chat.suggestion.improveNaps".localized)
            questions.append("chat.suggestion.nightWaking".localized)
        } else {
            questions.append("chat.suggestion.napTransition".localized)
            questions.append("chat.suggestion.bedtime".localized)
        }

        questions.append("chat.suggestion.sleepCues".localized)
        questions.append("chat.suggestion.wakeWindow".localized)

        return questions
    }
}
