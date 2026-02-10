import Foundation
import SwiftUI

// MARK: - FAQ Item
struct FAQItem: Codable, Identifiable {
    let id: UUID
    let category: String
    let questionPt: String
    let questionEn: String
    let questionEs: String
    let answerPt: String
    let answerEn: String
    let answerEs: String
    let orderIndex: Int
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, category
        case questionPt = "question_pt"
        case questionEn = "question_en"
        case questionEs = "question_es"
        case answerPt = "answer_pt"
        case answerEn = "answer_en"
        case answerEs = "answer_es"
        case orderIndex = "order_index"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Retorna pergunta no idioma atual
    var localizedQuestion: String {
        let lang = LocalizationManager.shared.selectedLanguage
        switch lang {
        case .english: return questionEn
        case .spanish: return questionEs
        default: return questionPt
        }
    }

    // Retorna resposta no idioma atual
    var localizedAnswer: String {
        let lang = LocalizationManager.shared.selectedLanguage
        switch lang {
        case .english: return answerEn
        case .spanish: return answerEs
        default: return answerPt
        }
    }
}

// MARK: - FAQ Category
enum FAQCategory: String, CaseIterable, Identifiable {
    case general = "general"
    case sleep = "sleep"
    case subscription = "subscription"
    case technical = "technical"
    case account = "account"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .general: return "faq.category.general".localized
        case .sleep: return "faq.category.sleep".localized
        case .subscription: return "faq.category.subscription".localized
        case .technical: return "faq.category.technical".localized
        case .account: return "faq.category.account".localized
        }
    }

    var icon: String {
        switch self {
        case .general: return "info.circle.fill"
        case .sleep: return "moon.fill"
        case .subscription: return "creditcard.fill"
        case .technical: return "gearshape.fill"
        case .account: return "person.fill"
        }
    }

    var color: Color {
        switch self {
        case .general: return .blue
        case .sleep: return NapletColors.primaryPurple
        case .subscription: return .green
        case .technical: return .orange
        case .account: return NapletColors.primaryPink
        }
    }
}

// MARK: - Support Ticket
struct SupportTicket: Codable {
    var id: UUID?
    let userId: UUID?
    let userEmail: String
    let userName: String?
    let category: String
    let subject: String
    let message: String
    let appVersion: String?
    let deviceInfo: String?
    let status: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userEmail = "user_email"
        case userName = "user_name"
        case category, subject, message
        case appVersion = "app_version"
        case deviceInfo = "device_info"
        case status
        case createdAt = "created_at"
    }
}

// MARK: - Ticket Category
enum TicketCategory: String, CaseIterable, Identifiable {
    case bug = "bug"
    case feature = "feature"
    case billing = "billing"
    case question = "question"
    case other = "other"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .bug: return "ticket.category.bug".localized
        case .feature: return "ticket.category.feature".localized
        case .billing: return "ticket.category.billing".localized
        case .question: return "ticket.category.question".localized
        case .other: return "ticket.category.other".localized
        }
    }

    var icon: String {
        switch self {
        case .bug: return "ladybug.fill"
        case .feature: return "lightbulb.fill"
        case .billing: return "creditcard.fill"
        case .question: return "questionmark.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Local FAQ Data (Fallback)
struct LocalFAQData {
    static let items: [FAQItem] = [
        // General
        FAQItem(
            id: UUID(),
            category: "general",
            questionPt: "O que e o Naplet?",
            questionEn: "What is Naplet?",
            questionEs: "Que es Naplet?",
            answerPt: "O Naplet e um aplicativo completo para acompanhar o sono e a rotina do seu bebe. Com ele, voce pode registrar sonecas, alimentacao, fraldas e muito mais. Alem disso, oferecemos um assistente de IA para tirar suas duvidas sobre o sono do bebe.",
            answerEn: "Naplet is a complete app to track your baby's sleep and routine. With it, you can log naps, feedings, diapers and much more. We also offer an AI assistant to answer your questions about baby sleep.",
            answerEs: "Naplet es una aplicacion completa para seguir el sueno y la rutina de tu bebe. Con ella, puedes registrar siestas, alimentacion, panales y mucho mas. Ademas, ofrecemos un asistente de IA para responder tus preguntas sobre el sueno del bebe.",
            orderIndex: 1,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        FAQItem(
            id: UUID(),
            category: "general",
            questionPt: "O Naplet e gratuito?",
            questionEn: "Is Naplet free?",
            questionEs: "Naplet es gratis?",
            answerPt: "O Naplet oferece um plano gratuito com funcionalidades basicas. Para desbloquear recursos avancados como Chat IA ilimitado, relatorios para pediatra e convite de cuidadores, voce pode assinar o Naplet Premium.",
            answerEn: "Naplet offers a free plan with basic features. To unlock advanced features like unlimited AI Chat, pediatrician reports, and caregiver invites, you can subscribe to Naplet Premium.",
            answerEs: "Naplet ofrece un plan gratuito con funcionalidades basicas. Para desbloquear recursos avanzados como Chat IA ilimitado, informes para pediatra e invitacion de cuidadores, puedes suscribirte a Naplet Premium.",
            orderIndex: 2,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        FAQItem(
            id: UUID(),
            category: "general",
            questionPt: "Como convido meu parceiro(a) ou avos?",
            questionEn: "How do I invite my partner or grandparents?",
            questionEs: "Como invito a mi pareja o abuelos?",
            answerPt: "No plano Premium, voce pode convidar cuidadores ilimitados. Va em Configuracoes > Convidar Cuidador e envie o codigo de convite por WhatsApp, SMS ou email.",
            answerEn: "With the Premium plan, you can invite unlimited caregivers. Go to Settings > Invite Caregiver and send the invite code via WhatsApp, SMS or email.",
            answerEs: "Con el plan Premium, puedes invitar cuidadores ilimitados. Ve a Configuracion > Invitar Cuidador y envia el codigo de invitacion por WhatsApp, SMS o email.",
            orderIndex: 3,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        // Sleep
        FAQItem(
            id: UUID(),
            category: "sleep",
            questionPt: "O que e janela de sono?",
            questionEn: "What is a sleep window?",
            questionEs: "Que es una ventana de sueno?",
            answerPt: "A janela de sono e o periodo ideal entre os sonos do bebe. Se voce colocar o bebe para dormir dentro dessa janela, ele tende a dormir mais facilmente e ter um sono mais reparador. O Naplet calcula automaticamente com base na idade do seu bebe.",
            answerEn: "The sleep window is the ideal period between baby's sleeps. If you put the baby to sleep within this window, they tend to fall asleep more easily and have better quality sleep. Naplet automatically calculates it based on your baby's age.",
            answerEs: "La ventana de sueno es el periodo ideal entre los suenos del bebe. Si pones al bebe a dormir dentro de esta ventana, tiende a dormirse mas facilmente y tener un sueno mas reparador.",
            orderIndex: 1,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        FAQItem(
            id: UUID(),
            category: "sleep",
            questionPt: "Como registro uma soneca?",
            questionEn: "How do I log a nap?",
            questionEs: "Como registro una siesta?",
            answerPt: "Na tela inicial, toque em 'Iniciar Sono' quando o bebe comecar a dormir. Quando acordar, toque em 'Parar Sono'. Voce tambem pode adicionar detalhes como onde o bebe dormiu e a qualidade do sono.",
            answerEn: "On the home screen, tap 'Start Sleep' when the baby starts sleeping. When they wake up, tap 'Stop Sleep'. You can also add details like where the baby slept and sleep quality.",
            answerEs: "En la pantalla principal, toca 'Iniciar Sueno' cuando el bebe empiece a dormir. Cuando despierte, toca 'Parar Sueno'.",
            orderIndex: 2,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        // Subscription
        FAQItem(
            id: UUID(),
            category: "subscription",
            questionPt: "Como funciona o periodo de teste?",
            questionEn: "How does the trial period work?",
            questionEs: "Como funciona el periodo de prueba?",
            answerPt: "Voce tem 14 dias para experimentar todos os recursos Premium gratuitamente. Durante esse periodo, voce pode cancelar a qualquer momento sem ser cobrado.",
            answerEn: "You have 14 days to try all Premium features for free. During this period, you can cancel at any time without being charged.",
            answerEs: "Tienes 14 dias para probar todas las funciones Premium gratuitamente. Durante este periodo, puedes cancelar en cualquier momento sin que te cobren.",
            orderIndex: 1,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        FAQItem(
            id: UUID(),
            category: "subscription",
            questionPt: "Como cancelo minha assinatura?",
            questionEn: "How do I cancel my subscription?",
            questionEs: "Como cancelo mi suscripcion?",
            answerPt: "Voce pode cancelar sua assinatura a qualquer momento atraves das Configuracoes do seu iPhone > Apple ID > Assinaturas > Naplet > Cancelar Assinatura.",
            answerEn: "You can cancel your subscription at any time through your iPhone Settings > Apple ID > Subscriptions > Naplet > Cancel Subscription.",
            answerEs: "Puedes cancelar tu suscripcion en cualquier momento a traves de Configuracion de tu iPhone > Apple ID > Suscripciones > Naplet > Cancelar Suscripcion.",
            orderIndex: 2,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        // Technical
        FAQItem(
            id: UUID(),
            category: "technical",
            questionPt: "Os dados do meu bebe estao seguros?",
            questionEn: "Is my baby's data secure?",
            questionEs: "Los datos de mi bebe estan seguros?",
            answerPt: "Sim! Levamos a seguranca muito a serio. Todos os dados sao criptografados e armazenados em servidores seguros. Nunca vendemos ou compartilhamos seus dados com terceiros.",
            answerEn: "Yes! We take security very seriously. All data is encrypted and stored on secure servers. We never sell or share your data with third parties.",
            answerEs: "Si! Nos tomamos la seguridad muy en serio. Todos los datos estan encriptados y almacenados en servidores seguros.",
            orderIndex: 1,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        FAQItem(
            id: UUID(),
            category: "technical",
            questionPt: "O app funciona offline?",
            questionEn: "Does the app work offline?",
            questionEs: "La app funciona sin internet?",
            answerPt: "Voce pode registrar sonos e atividades offline. Quando seu dispositivo se conectar a internet, os dados serao sincronizados automaticamente. O Chat IA requer conexao com a internet.",
            answerEn: "You can log sleeps and activities offline. When your device connects to the internet, the data will be automatically synced. The AI Chat requires an internet connection.",
            answerEs: "Puedes registrar suenos y actividades sin conexion. Cuando tu dispositivo se conecte a internet, los datos se sincronizaran automaticamente.",
            orderIndex: 2,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        // Account
        FAQItem(
            id: UUID(),
            category: "account",
            questionPt: "Como excluo minha conta?",
            questionEn: "How do I delete my account?",
            questionEs: "Como elimino mi cuenta?",
            answerPt: "Voce pode excluir sua conta em Configuracoes > Excluir Conta. Todos os seus dados serao permanentemente removidos de nossos servidores. Esta acao nao pode ser desfeita.",
            answerEn: "You can delete your account in Settings > Delete Account. All your data will be permanently removed from our servers. This action cannot be undone.",
            answerEs: "Puedes eliminar tu cuenta en Configuracion > Eliminar Cuenta. Todos tus datos seran eliminados permanentemente de nuestros servidores.",
            orderIndex: 1,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        FAQItem(
            id: UUID(),
            category: "account",
            questionPt: "Esqueci minha senha, o que faco?",
            questionEn: "I forgot my password, what do I do?",
            questionEs: "Olvide mi contrasena, que hago?",
            answerPt: "Na tela de login, toque em 'Esqueci minha senha' e digite seu email. Voce recebera um link para criar uma nova senha.",
            answerEn: "On the login screen, tap 'Forgot password' and enter your email. You will receive a link to create a new password.",
            answerEs: "En la pantalla de inicio de sesion, toca 'Olvide mi contrasena' e ingresa tu email. Recibiras un enlace para crear una nueva contrasena.",
            orderIndex: 2,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}
