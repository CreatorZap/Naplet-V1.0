import Foundation

// MARK: - Baby Context for AI
struct BabyContext {
    let babyName: String
    let ageDescription: String
    let recommendedWakeWindow: Int
    let recommendedNaps: String
    let recommendedSleepHours: String
    let todayTotalSleep: Int
    let todayNaps: Int
    let lastSleepDescription: String

    static func from(baby: Baby, sleepRecords: [SleepRecord]) -> BabyContext {
        let todayRecords = sleepRecords.filter { Calendar.current.isDateInToday($0.startTime) }
        let completedRecords = todayRecords.filter { $0.endTime != nil }
        let totalMinutes = completedRecords.compactMap { $0.durationMinutes }.reduce(0, +)
        let naps = completedRecords.filter { $0.type == .nap }
        let lastSleep = sleepRecords.first

        let wakeRange = baby.recommendedWakeWindowMinutes
        let napRange = baby.recommendedNapsPerDay
        let sleepRange = baby.recommendedSleepHours

        return BabyContext(
            babyName: baby.name,
            ageDescription: baby.ageDescription,
            recommendedWakeWindow: (wakeRange.lowerBound + wakeRange.upperBound) / 2,
            recommendedNaps: "\(napRange.lowerBound)-\(napRange.upperBound)",
            recommendedSleepHours: String(format: "%.0f-%.0f", sleepRange.lowerBound, sleepRange.upperBound),
            todayTotalSleep: totalMinutes,
            todayNaps: naps.count,
            lastSleepDescription: lastSleep.map {
                "\($0.type.displayName) de \($0.durationFormatted)"
            } ?? "Nenhum registro"
        )
    }
}

// MARK: - OpenAI Service
actor OpenAIService {
    static let shared = OpenAIService()

    private let baseURL = "https://api.openai.com/v1/chat/completions"

    private var model: String {
        AppConfig.OpenAI.model
    }

    private var apiKey: String {
        AppConfig.OpenAI.apiKey
    }

    /// Verifica se o serviço está configurado
    nonisolated var isConfigured: Bool {
        AppConfig.OpenAI.isConfigured
    }

    private init() {}

    // MARK: - Request/Response Types
    struct Message: Codable {
        let role: String
        let content: String
    }

    struct ChatRequest: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double
        let maxTokens: Int

        enum CodingKeys: String, CodingKey {
            case model, messages, temperature
            case maxTokens = "max_tokens"
        }
    }

    struct ChatResponse: Codable {
        struct Choice: Codable {
            struct Message: Codable {
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]
    }

    // MARK: - Send Message
    func sendMessage(
        userMessage: String,
        babyContext: BabyContext,
        conversationHistory: [Message]
    ) async throws -> String {

        // Check if API key is configured
        guard AppConfig.OpenAI.isConfigured else {
            throw OpenAIError.notConfigured
        }

        let systemPrompt = buildSystemPrompt(babyContext: babyContext)

        var messages: [Message] = [
            Message(role: "system", content: systemPrompt)
        ]
        messages.append(contentsOf: conversationHistory)
        messages.append(Message(role: "user", content: userMessage))

        let request = ChatRequest(
            model: model,
            messages: messages,
            temperature: 0.7,
            maxTokens: 500
        )

        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = AppConfig.API.timeout

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.noResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            Logger.error("OpenAI API Error (\(httpResponse.statusCode)): \(errorBody)")

            if httpResponse.statusCode == 401 {
                throw OpenAIError.unauthorized
            } else if httpResponse.statusCode == 429 {
                throw OpenAIError.rateLimited
            } else {
                throw OpenAIError.apiError(errorBody)
            }
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)

        guard let content = chatResponse.choices.first?.message.content else {
            throw OpenAIError.noResponse
        }

        return content
    }

    // MARK: - Errors
    enum OpenAIError: Error, LocalizedError {
        case notConfigured
        case invalidURL
        case apiError(String)
        case noResponse
        case unauthorized
        case rateLimited

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "API OpenAI não configurada. Adicione sua chave em AppConfig."
            case .invalidURL:
                return "URL inválida"
            case .apiError(let message):
                return "Erro da API: \(message)"
            case .noResponse:
                return "Sem resposta do servidor"
            case .unauthorized:
                return "Chave API inválida"
            case .rateLimited:
                return "chat.error.rateLimited".localized
            }
        }
    }
    
    // MARK: - Build System Prompt (Localized)
    private func buildSystemPrompt(babyContext: BabyContext) -> String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        
        let babyInfo = """
        Baby: \(babyContext.babyName), \(babyContext.ageDescription). Ideal wake window: \(babyContext.recommendedWakeWindow) min. Recommended naps: \(babyContext.recommendedNaps)/day. Ideal total sleep: \(babyContext.recommendedSleepHours)h.
        Today: \(babyContext.todayTotalSleep) min of sleep, \(babyContext.todayNaps) naps. Last sleep: \(babyContext.lastSleepDescription).
        """
        
        let formatRules = """
        FORMATTING (very important):
        - DO NOT use markdown (no **bold**, *italic*, ### headings)
        - DO NOT use numbered lists or bullets (1. 2. 3. or - - -)
        - DO NOT use excessive emojis (max 1 per response, only if natural)
        - Write in flowing paragraphs, like a normal text message
        - Maximum 2-3 short paragraphs
        """
        
        switch languageCode {
        case "pt":
            return """
            Você é uma consultora de sono infantil experiente conversando com pais pelo chat. Seu nome é Naplet AI.
            
            \(babyInfo)
            
            COMO RESPONDER:
            - Converse naturalmente, como uma amiga especialista falaria pelo WhatsApp
            - Seja direta e prática, sem enrolação
            - Use português brasileiro coloquial (mas não informal demais)
            - Personalize usando o nome do bebê quando fizer sentido
            
            \(formatRules)
            
            CONTEÚDO:
            - Dê dicas práticas baseadas na idade do bebê
            - Se não souber algo específico, sugira consultar o pediatra
            - Seja acolhedora mas objetiva
            """
            
        case "es":
            return """
            Eres una consultora de sueño infantil experimentada conversando con padres por chat. Tu nombre es Naplet AI.
            
            \(babyInfo)
            
            CÓMO RESPONDER:
            - Conversa naturalmente, como una amiga especialista hablaría por WhatsApp
            - Sé directa y práctica, sin rodeos
            - Usa español coloquial (pero no demasiado informal)
            - Personaliza usando el nombre del bebé cuando tenga sentido
            
            \(formatRules)
            
            CONTENIDO:
            - Da consejos prácticos basados en la edad del bebé
            - Si no sabes algo específico, sugiere consultar al pediatra
            - Sé acogedora pero objetiva
            """
            
        default: // English
            return """
            You are an experienced infant sleep consultant chatting with parents. Your name is Naplet AI.
            
            \(babyInfo)
            
            HOW TO RESPOND:
            - Chat naturally, like a friendly expert would on WhatsApp
            - Be direct and practical, no fluff
            - Use casual English (but not too informal)
            - Personalize using the baby's name when it makes sense
            
            \(formatRules)
            
            CONTENT:
            - Give practical tips based on the baby's age
            - If you don't know something specific, suggest consulting the pediatrician
            - Be warm but objective
            """
        }
    }
}
