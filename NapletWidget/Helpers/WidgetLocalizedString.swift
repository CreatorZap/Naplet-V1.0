import Foundation
import SwiftUI

// MARK: - Widget Strings
/// Strings localizadas para o Widget com fallback hardcoded
/// Isso garante que o texto sempre apareça corretamente, mesmo se
/// os arquivos .strings não estiverem configurados no Xcode
enum WidgetStrings {
    // MARK: - Status
    static var awake: String {
        localized("widget.awake", fallback: "Acordado")
    }

    static var sleeping: String {
        localized("widget.sleeping", fallback: "Dormindo")
    }

    static func sleepingFor(_ duration: String) -> String {
        String(format: localized("widget.sleepingFor", fallback: "Dormindo há %@"), duration)
    }

    static var napping: String {
        localized("widget.napping", fallback: "Cochilando")
    }

    // MARK: - Statistics
    static var sleepToday: String {
        localized("widget.sleepToday", fallback: "Sono hoje")
    }

    static var naps: String {
        localized("dashboard.stats.naps", fallback: "Sonecas")
    }

    static var totalSleep: String {
        localized("dashboard.stats.totalSleep", fallback: "Total")
    }

    static var nightSleep: String {
        localized("dashboard.stats.nightSleep", fallback: "Noturno")
    }

    // MARK: - Quick Actions
    static var sleep: String {
        localized("widget.quickAction.sleep", fallback: "Dormir")
    }

    static var wakeUp: String {
        localized("widget.quickAction.wakeUp", fallback: "Acordar")
    }

    // MARK: - Widget Configuration
    static var sleepStatusName: String {
        localized("widget.sleepStatus.name", fallback: "Sono do Bebê")
    }

    static var sleepStatusDescription: String {
        localized("widget.sleepStatus.description", fallback: "Acompanhe o sono do seu bebê")
    }

    static var quickActionTitle: String {
        localized("widget.quickAction.title", fallback: "Ações Rápidas")
    }

    static var quickActionDescription: String {
        localized("widget.quickAction.description", fallback: "Registre atividades rapidamente")
    }

    // MARK: - Helper
    private static func localized(_ key: String, fallback: String) -> String {
        let bundle = Bundle.main
        let value = bundle.localizedString(forKey: key, value: fallback, table: nil)

        // Se retornou a própria chave, usa o fallback
        if value == key {
            return fallback
        }
        return value
    }
}

// MARK: - Legacy Extension (para compatibilidade)
extension String {
    /// Retorna a string localizada para uso no Widget
    /// Mantido para compatibilidade, mas prefira usar WidgetStrings
    var widgetLocalized: String {
        let bundle = Bundle.main
        let value = bundle.localizedString(forKey: self, value: self, table: nil)
        return value
    }
}
