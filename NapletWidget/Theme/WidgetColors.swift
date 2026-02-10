import SwiftUI
import WidgetKit

// MARK: - Widget Colors
/// Cores do Design System Naplet para Widgets
enum WidgetColors {

    // MARK: - Background Colors
    /// Fundo principal escuro
    static let background = Color(hex: "#0D0B1E")
    /// Cards e superfícies
    static let backgroundSecondary = Color(hex: "#1A1730")
    /// Elementos elevados
    static let backgroundTertiary = Color(hex: "#252142")
    /// Cards com gradiente sutil
    static let backgroundCard = Color(hex: "#1E1B33")

    // MARK: - Accent Colors
    /// Roxo principal
    static let primaryPurple = Color(hex: "#8B5CF6")
    /// Rosa accent
    static let primaryPink = Color(hex: "#EC4899")
    /// Azul accent
    static let primaryBlue = Color(hex: "#3B82F6")
    /// Cyan accent
    static let primaryCyan = Color(hex: "#06B6D4")

    // MARK: - Gradients
    /// Gradiente primário roxo → rosa
    static let gradientPrimary = LinearGradient(
        colors: [primaryPurple, primaryPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gradiente para sono ativo
    static let gradientSleep = LinearGradient(
        colors: [Color(hex: "#6D28D9"), Color(hex: "#8B5CF6")],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Gradiente para acordado
    static let gradientAwake = LinearGradient(
        colors: [Color(hex: "#1A1730"), Color(hex: "#0D0B1E")],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Gradiente para cards
    static let gradientCard = LinearGradient(
        colors: [backgroundSecondary, background],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Text Colors
    /// Texto primário - branco
    static let textPrimary = Color.white
    /// Texto secundário
    static let textSecondary = Color(hex: "#A1A1AA")
    /// Texto muted/desabilitado
    static let textMuted = Color(hex: "#71717A")

    // MARK: - Status Colors
    /// Sucesso - verde
    static let success = Color(hex: "#22C55E")
    /// Alerta - amarelo/laranja
    static let warning = Color(hex: "#F59E0B")
    /// Erro - vermelho
    static let error = Color(hex: "#EF4444")
    /// Info - azul
    static let info = Color(hex: "#3B82F6")

    // MARK: - Sleep-Specific Colors
    /// Sono ativo - roxo
    static let sleepActive = Color(hex: "#8B5CF6")
    /// Soneca - roxo claro
    static let napColor = Color(hex: "#A78BFA")
    /// Acordado - amarelo dourado
    static let awakeColor = Color(hex: "#FCD34D")
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
