import Foundation

// MARK: - App Environment
// ============================================
// AMBIENTES DE EXECUÇÃO DO NAPLET
// ============================================
//
// development - Debug, logs verbose, mock data opcional
// staging     - Testes com backend real, analytics habilitado
// production  - App Store, sem logs, analytics completo
//
// ============================================

enum AppEnvironment: String {
    case development = "development"
    case staging = "staging"
    case production = "production"

    // MARK: - Current Environment
    // ============================================
    // Determinado automaticamente via build flags
    // Configure em Build Settings → Swift Compiler - Custom Flags
    // DEBUG = -DDEBUG
    // STAGING = -DSTAGING
    // ============================================

    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }

    // MARK: - Properties

    var name: String {
        rawValue.capitalized
    }
    
    var displayName: String {
        switch self {
        case .development: return "Development"
        case .staging: return "Staging"
        case .production: return "Production"
        }
    }

    // MARK: - Supabase Configuration
    
    /// URL do Supabase (sem trailing slash)
    var supabaseURL: String {
        // Sempre usa a mesma URL - diferentes ambientes usam diferentes projetos Supabase
        // Ou configure diferentes URLs para staging/production aqui
        return AppConfig.supabaseURL
    }

    /// Chave anônima do Supabase
    var supabaseKey: String {
        return AppConfig.supabaseAnonKey
    }
    
    /// Verifica se Supabase está configurado
    var isSupabaseConfigured: Bool {
        AppConfig.isSupabaseConfigured
    }

    // MARK: - Feature Flags por Ambiente

    var isDebug: Bool {
        self == .development
    }

    var analyticsEnabled: Bool {
        self != .development || AppConfig.Analytics.enableInDebug
    }
    
    var crashReportsEnabled: Bool {
        AppConfig.Analytics.enableCrashReports
    }

    // MARK: - Mock Data
    // ============================================
    // ⚠️ CONTROLE DE MOCK DATA
    // ============================================
    // 
    // Mock é ativado SE:
    // 1. Features.useMockData = true em AppConfig.swift
    // 2. OU Supabase não está configurado corretamente
    //
    // Para usar Supabase real:
    // 1. Configure supabaseURL e supabaseAnonKey em AppConfig.swift
    // 2. Execute o SQL schema no Supabase Dashboard
    // 3. Mude Features.useMockData para false
    //
    // ============================================
    
    var useMockData: Bool {
        return AppConfig.shouldUseMockData
    }

    // MARK: - Logging
    
    var logLevel: LogLevel {
        switch self {
        case .development: return .debug
        case .staging: return .info
        case .production: return .error
        }
    }
    
    var verboseLogging: Bool {
        self == .development
    }

    // MARK: - Base URLs

    var apiBaseURL: String {
        switch self {
        case .development:
            return AppConfig.supabaseURL
        case .staging:
            // Configure URL de staging se tiver um projeto Supabase separado
            return "https://staging-api.naplet.app"
        case .production:
            return "https://api.naplet.app"
        }
    }
    
    var websiteURL: String {
        switch self {
        case .development, .staging:
            return "https://staging.naplet.app"
        case .production:
            return "https://naplet.app"
        }
    }
    
    var supportEmail: String {
        "suporte@naplet.app"
    }
    
    var privacyPolicyURL: URL? {
        URL(string: "\(websiteURL)/privacy")
    }
    
    var termsOfServiceURL: URL? {
        URL(string: "\(websiteURL)/terms")
    }
}

// MARK: - Log Level
enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var prefix: String {
        switch self {
        case .debug: return "🔍 DEBUG"
        case .info: return "ℹ️ INFO"
        case .warning: return "⚠️ WARNING"
        case .error: return "❌ ERROR"
        }
    }
    
    var shouldLog: Bool {
        self >= AppEnvironment.current.logLevel
    }
}

// MARK: - Environment Info
extension AppEnvironment {
    /// Retorna informações de debug sobre o ambiente
    var debugInfo: [String: Any] {
        [
            "environment": name,
            "isDebug": isDebug,
            "useMockData": useMockData,
            "supabaseConfigured": isSupabaseConfigured,
            "analyticsEnabled": analyticsEnabled,
            "logLevel": logLevel.prefix,
            "appVersion": AppConfig.fullVersion
        ]
    }
    
    /// Log do estado atual do ambiente
    func logEnvironmentInfo() {
        Logger.info("=== Environment Info ===")
        for (key, value) in debugInfo {
            Logger.debug("\(key): \(value)")
        }
        Logger.info("========================")
    }
}
