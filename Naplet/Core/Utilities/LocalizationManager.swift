import Foundation
import SwiftUI
import Combine

// MARK: - Language Enum
enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case portugueseBR = "pt-BR"
    case english = "en"
    case spanish = "es"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "language.system".localized
        case .portugueseBR: return "Português (Brasil)"
        case .english: return "English"
        case .spanish: return "Español"
        }
    }

    var flag: String {
        switch self {
        case .system: return "🌐"
        case .portugueseBR: return "🇧🇷"
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        }
    }

    // Código usado para buscar o bundle
    var languageCode: String {
        switch self {
        case .system: return LocalizationManager.getSystemLanguageCodeStatic()
        case .portugueseBR: return "pt-BR"
        case .english: return "en"
        case .spanish: return "es"
        }
    }
}

// MARK: - Localization Manager
/// Thread-safe localization manager that supports real-time language switching
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    // Thread-safe bundle storage
    private let lock = NSLock()
    private var _currentBundle: Bundle = .main

    // Armazenamento persistente
    private let languageKey = "app_selected_language"

    // Published para atualizar UI (MainActor)
    @MainActor @Published var refreshID = UUID()

    // Thread-safe bundle access
    private var currentBundle: Bundle {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _currentBundle
        }
        set {
            lock.lock()
            _currentBundle = newValue
            lock.unlock()
        }
    }

    var selectedLanguage: AppLanguage {
        get {
            let stored = UserDefaults.standard.string(forKey: languageKey) ?? "system"
            return AppLanguage(rawValue: stored) ?? .system
        }
        set {
            #if DEBUG
            print("[LocalizationManager] Setting language from \(selectedLanguage.rawValue) to \(newValue.rawValue)")
            #endif

            // 1. Salvar preferência
            UserDefaults.standard.set(newValue.rawValue, forKey: languageKey)
            UserDefaults.standard.synchronize() // Força sincronização

            // 2. Atualizar bundle ANTES de notificar as views
            updateBundle()

            #if DEBUG
            print("[LocalizationManager] Bundle updated, now triggering UI refresh")
            #endif

            // 3. Forçar atualização de TODAS as views no MainActor
            DispatchQueue.main.async {
                #if DEBUG
                print("[LocalizationManager] Triggering UI refresh with new refreshID")
                #endif
                self.refreshID = UUID()
                self.objectWillChange.send()
                
                // 4. Notificar observers adicionais
                NotificationCenter.default.post(name: NSNotification.Name("LanguageDidChange"), object: nil)
            }
        }
    }

    private init() {
        #if DEBUG
        print("[LocalizationManager] INIT - Checking available bundles:")
        for code in ["en", "pt-BR", "es"] {
            if let path = Bundle.main.path(forResource: code, ofType: "lproj") {
                print("[LocalizationManager] Found bundle: \(code) at \(path)")
            } else {
                print("[LocalizationManager] NOT FOUND: \(code).lproj")
            }
        }
        print("[LocalizationManager] Selected language from UserDefaults: \(UserDefaults.standard.string(forKey: languageKey) ?? "nil")")
        #endif

        updateBundle()
    }

    // MARK: - Bundle Management

    private func updateBundle() {
        let languageCode = resolveLanguageCode()

        #if DEBUG
        print("[LocalizationManager] updateBundle() called")
        print("[LocalizationManager] languageCode: \(languageCode)")
        print("[LocalizationManager] selectedLanguage: \(selectedLanguage.rawValue)")
        #endif

        // Tentar encontrar o bundle para o idioma
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            currentBundle = bundle
            #if DEBUG
            print("[LocalizationManager] Bundle loaded successfully: \(path)")
            #endif
        }
        // Fallback: tentar código base (pt-BR -> pt)
        else if let baseCode = languageCode.split(separator: "-").first,
                let path = Bundle.main.path(forResource: String(baseCode), ofType: "lproj"),
                let bundle = Bundle(path: path) {
            currentBundle = bundle
            #if DEBUG
            print("[LocalizationManager] Fallback to base code: \(baseCode), path: \(path)")
            #endif
        }
        // Fallback final: PT-BR
        else if let path = Bundle.main.path(forResource: "pt-BR", ofType: "lproj"),
                let bundle = Bundle(path: path) {
            currentBundle = bundle
            #if DEBUG
            print("[LocalizationManager] Fallback to PT-BR: \(path)")
            #endif
        }
        // Último recurso: main bundle
        else {
            currentBundle = .main
            #if DEBUG
            print("[LocalizationManager] Using main bundle as last resort")
            #endif
        }
    }

    private func resolveLanguageCode() -> String {
        if selectedLanguage == .system {
            return Self.getSystemLanguageCodeStatic()
        }
        return selectedLanguage.languageCode
    }

    /// Static version for use in AppLanguage enum
    static func getSystemLanguageCodeStatic() -> String {
        // Pegar idioma preferido do sistema
        let preferredLanguage = Locale.preferredLanguages.first ?? "pt-BR"

        // Mapear para idiomas suportados pelo app
        if preferredLanguage.hasPrefix("pt") {
            return "pt-BR"
        } else if preferredLanguage.hasPrefix("es") {
            return "es"
        } else {
            return "en" // Fallback para inglês
        }
    }

    func getSystemLanguageCode() -> String {
        Self.getSystemLanguageCodeStatic()
    }

    // MARK: - Localized String (Thread-safe)

    func localizedString(_ key: String) -> String {
        let result = currentBundle.localizedString(forKey: key, value: key, table: nil)
        #if DEBUG
        if key == "settings.title" || key == "common.done" || key == "settings.profile" || key == "tabs.home" {
            print("[LocalizationManager] localizedString(\(key)) = '\(result)'")
            print("[LocalizationManager] currentBundle: \(currentBundle.bundlePath)")
            print("[LocalizationManager] selectedLanguage: \(selectedLanguage.rawValue)")
        }
        #endif
        return result
    }

    func localizedString(_ key: String, arguments: CVarArg...) -> String {
        let format = currentBundle.localizedString(forKey: key, value: key, table: nil)
        return String(format: format, arguments: arguments)
    }

    func localizedString(_ key: String, withArray arguments: [CVarArg]) -> String {
        let format = currentBundle.localizedString(forKey: key, value: key, table: nil)
        return String(format: format, arguments: arguments)
    }

    // MARK: - Current Language Info

    var currentLanguageDisplay: String {
        if selectedLanguage == .system {
            let systemCode = Self.getSystemLanguageCodeStatic()
            switch systemCode {
            case "pt-BR": return "Português"
            case "es": return "Español"
            default: return "English"
            }
        }
        return selectedLanguage.displayName
    }

    var currentLanguageFlag: String {
        if selectedLanguage == .system {
            let systemCode = Self.getSystemLanguageCodeStatic()
            switch systemCode {
            case "pt-BR": return "🇧🇷"
            case "es": return "🇪🇸"
            default: return "🇺🇸"
            }
        }
        return selectedLanguage.flag
    }
}

// MARK: - View Modifier para Forçar Atualização
struct LocalizationRefresh: ViewModifier {
    @ObservedObject var manager = LocalizationManager.shared

    func body(content: Content) -> some View {
        content
            .id(manager.refreshID) // Força rebuild quando muda
            .environmentObject(manager)
    }
}

extension View {
    func withLocalization() -> some View {
        modifier(LocalizationRefresh())
    }
}
