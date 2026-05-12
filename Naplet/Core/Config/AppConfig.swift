import Foundation

// MARK: - App Configuration
// ============================================
// CONFIGURAÇÃO DO NAPLET
// ============================================
// 
// INSTRUÇÕES PARA CONFIGURAR O SUPABASE:
//
// 1. Acesse https://app.supabase.com
// 2. Crie um novo projeto ou selecione um existente
// 3. Vá em Settings → API
// 4. Copie a "Project URL" para supabaseURL
// 5. Copie a "anon public" key para supabaseAnonKey
//
// IMPORTANTE: Nunca commite keys reais no git!
// Use variáveis de ambiente em produção.
//
// ============================================

enum AppConfig {

    // MARK: - Supabase Configuration
    // ============================================
    // Substitua pelos valores do seu projeto Supabase
    // ============================================
    
    /// URL do projeto Supabase
    /// Formato: https://[PROJECT_REF].supabase.co
    /// Encontre em: Supabase Dashboard → Settings → API → Project URL
    static let supabaseURL = "https://exwqjrdlanlqcthwjflt.supabase.co"
    
    /// Chave anônima do Supabase (anon/public key)
    /// Esta chave pode ser exposta no cliente - é segura
    /// Encontre em: Supabase Dashboard → Settings → API → anon public
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4d3FqcmRsYW5scWN0aHdqZmx0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg2OTQxMDYsImV4cCI6MjA4NDI3MDEwNn0.MJbSI1qEdf4y3cO-Aszg-ixpkB8mRVPXGBrxdBuUjVE"
    
    // MARK: - RevenueCat Configuration
    // ============================================
    // Para assinaturas/compras in-app
    // https://www.revenuecat.com/docs/getting-started
    // ============================================

    /// Chave API do RevenueCat (iOS)
    /// Encontre em: RevenueCat Dashboard → API Keys
    /// ⚠️ IMPORTANTE: Substituir por chave de PRODUÇÃO antes do lançamento
    /// Obter em: https://app.revenuecat.com → Project Settings → API Keys
    /// A chave de produção NÃO deve ter prefixo "test_"
    static let revenueCatAPIKey = "appl_ZmzpzrfPorQGHpEwFEdkpkkJtvq"

    // MARK: - OpenAI Configuration
    // ============================================
    // O cliente NÃO carrega chave de API. Toda chamada à OpenAI passa pela
    // Edge Function `openai-proxy` no Supabase, autenticada via JWT do usuário.
    // A chave OpenAI vive como secret no Supabase, nunca no binário do app.
    // Endpoint: https://exwqjrdlanlqcthwjflt.supabase.co/functions/v1/openai-proxy
    // ============================================
    enum OpenAI {
        /// Modelo OpenAI usado nas chamadas via proxy.
        static let model = "gpt-4o-mini"
    }
    
    // MARK: - Google Sign In Configuration
    // ============================================
    // Para login com Google
    // https://console.cloud.google.com/apis/credentials
    // ============================================
    enum Google {
        /// iOS Client ID do Google Cloud Console
        /// Encontre em: Google Cloud Console → APIs & Services → Credentials → OAuth 2.0 Client IDs
        static let iOSClientID = "634768547715-p7qj7h3qk02mq9fmts5srmd4fv9qr851.apps.googleusercontent.com"
        
        /// Web Client ID do Google Cloud Console (usado pelo Supabase)
        /// Encontre em: Google Cloud Console → APIs & Services → Credentials → OAuth 2.0 Client IDs
        static let webClientID = "634768547715-debo80knf2eien9hmkk5cd3l5h7hk6hb.apps.googleusercontent.com"
        
        /// URL Scheme para callback do Google Sign In
        /// Formato invertido do iOS Client ID
        static let urlScheme = "com.googleusercontent.apps.634768547715-p7qj7h3qk02mq9fmts5srmd4fv9qr851"
    }

    // MARK: - App Info
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static var fullVersion: String {
        "\(appVersion) (\(buildNumber))"
    }

    // MARK: - Feature Flags
    // ============================================
    // TOGGLE PARA ATIVAR/DESATIVAR FUNCIONALIDADES
    // ============================================
    enum Features {
        /// Habilita chat com IA para dicas de sono
        static let enableAIChat = true
        
        /// Habilita app companion para Apple Watch
        static let enableAppleWatch = false
        
        /// Habilita sons de ninar
        static let enableSounds = false
        
        /// Habilita exportação para PDF
        static let enablePDFExport = true
        
        /// Habilita widgets para Home Screen
        static let enableWidgets = true
        
        /// Habilita múltiplos cuidadores por bebê
        static let enableMultiCaregiver = true
        
        // ============================================
        // ⚠️ TOGGLE MOCK MODE
        // ============================================
        // true  = Usa dados simulados (para desenvolvimento)
        // false = Usa Supabase real (para produção)
        //
        // MUDE PARA FALSE QUANDO:
        // 1. Configurar supabaseURL e supabaseAnonKey acima
        // 2. Executar o schema SQL no Supabase Dashboard
        // 3. Quiser testar com dados reais
        // ============================================
        static let useMockData = false
    }

    // MARK: - Limits
    enum Limits {
        /// Máximo de bebês por conta (gratuito)
        static let maxBabiesPerAccountFree = 1
        
        /// Máximo de bebês por conta (premium)
        static let maxBabiesPerAccount = 5
        
        /// Máximo de cuidadores por bebê
        static let maxCaregiversPerBaby = 5
        
        /// Dias de histórico na versão gratuita
        static let freeHistoryDays = 7
        
        /// Consultas AI gratuitas por mês
        static let freeAIChatPerMonth = 5
        
        /// Dias de expiração do convite
        static let inviteExpirationDays = 7
    }

    // MARK: - API Configuration
    enum API {
        /// Timeout para requisições (segundos)
        static let timeout: TimeInterval = 30
        
        /// Número de tentativas em caso de falha
        static let retryAttempts = 3
        
        /// Intervalo entre tentativas (segundos)
        static let retryDelay: TimeInterval = 1
    }

    // MARK: - Subscription
    enum Subscription {
        /// ID do entitlement no RevenueCat
        /// ⚠️ Deve corresponder exatamente ao ID no RevenueCat Dashboard
        static let premiumEntitlement = "Naplet Pro"

        /// Product ID - assinatura mensal (regular)
        static let monthlyProductId = "naplet_premium_monthly"

        /// Product ID - assinatura anual (regular)
        static let yearlyProductId = "naplet_premium_annual"

        /// Product ID - assinatura anual Founders (promocional)
        static let foundersAnnualProductId = "naplet_founders_annual"

        /// Offering ID - padrão
        static let defaultOfferingId = "default"

        /// Offering ID - founders (ativo nos primeiros 3 meses)
        static let foundersOfferingId = "founders"

        /// Duração do trial (dias)
        static let trialDays = 7

        /// Data de fim do período Founders
        /// ⚠️ AJUSTAR CONFORME DATA DE LANÇAMENTO
        /// Formato: 3 meses após o lançamento
        static let foundersEndDate: Date = {
            // Extensão de 3 meses (de 22-Abr-2026 → 22-Jul-2026) decidida em
            // 12-Mai-2026 após constatar que o prazo original expirou sem
            // campanha de marketing. Janela usada para rodar testes do paywall
            // (Bloco 1.3 do Sprint 1) antes de travar pricing regular.
            var components = DateComponents()
            components.year = 2026
            components.month = 7
            components.day = 22
            components.hour = 23
            components.minute = 59
            components.second = 59
            return Calendar.current.date(from: components) ?? Date()
        }()

        /// Verifica se ainda está no período Founders
        static var isFoundersPeriod: Bool {
            Date() < foundersEndDate
        }

        /// Dias restantes do período Founders
        static var foundersDaysRemaining: Int {
            Calendar.current.dateComponents([.day], from: Date(), to: foundersEndDate).day ?? 0
        }
    }
    
    // MARK: - Notification Settings
    enum Notifications {
        /// Tempo antes do wake window terminar para alertar (minutos)
        static let wakeWindowAlertMinutes = 15
        
        /// Horário padrão para lembrete noturno (HH:mm)
        static let defaultBedtimeReminder = "19:30"
    }
    
    // MARK: - Analytics
    enum Analytics {
        /// Habilita analytics em debug
        static let enableInDebug = false

        /// Habilita crash reports
        static let enableCrashReports = true
    }

    // MARK: - Developer Access
    // ============================================
    // Desenvolvedores com acesso premium gratuito
    // ============================================
    enum Developer {
        /// Emails de desenvolvedores com acesso premium
        static let emails: Set<String> = [
            "contato@edysouza.com.br"
        ]

        /// Verifica se o email é de um desenvolvedor
        static func isDeveloper(email: String?) -> Bool {
            guard let email = email?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) else {
                return false
            }
            return emails.contains(email)
        }
    }
}

// MARK: - Configuration Validation
extension AppConfig {
    /// Verifica se a configuração do Supabase está válida
    static var isSupabaseConfigured: Bool {
        !supabaseURL.contains("YOUR_PROJECT")
            && !supabaseAnonKey.contains("YOUR_KEY")
            && supabaseURL.hasPrefix("https://")
            && supabaseURL.contains(".supabase.co")
    }
    
    /// Verifica se deve usar dados mock
    static var shouldUseMockData: Bool {
        Features.useMockData || !isSupabaseConfigured
    }
    
    /// Log de configuração (para debug)
    static func logConfiguration() {
        Logger.info("=== App Configuration ===")
        Logger.info("Version: \(fullVersion)")
        Logger.info("Supabase Configured: \(isSupabaseConfigured)")
        Logger.info("Mock Mode: \(shouldUseMockData)")
        Logger.info("Environment: \(AppEnvironment.current.name)")
        Logger.info("=========================")
    }
}
