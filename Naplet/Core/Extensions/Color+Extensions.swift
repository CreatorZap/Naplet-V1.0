import SwiftUI

// MARK: - Color Extensions
extension Color {

    // MARK: - Opacity Variants

    /// Retorna a cor com opacidade de 10%
    var opacity10: Color {
        self.opacity(0.1)
    }

    /// Retorna a cor com opacidade de 20%
    var opacity20: Color {
        self.opacity(0.2)
    }

    /// Retorna a cor com opacidade de 30%
    var opacity30: Color {
        self.opacity(0.3)
    }

    /// Retorna a cor com opacidade de 50%
    var opacity50: Color {
        self.opacity(0.5)
    }

    /// Retorna a cor com opacidade de 70%
    var opacity70: Color {
        self.opacity(0.7)
    }

    // MARK: - Color Manipulation

    /// Clareia a cor
    func lighter(by percentage: CGFloat = 0.2) -> Color {
        return self.adjust(by: abs(percentage))
    }

    /// Escurece a cor
    func darker(by percentage: CGFloat = 0.2) -> Color {
        return self.adjust(by: -1 * abs(percentage))
    }

    private func adjust(by percentage: CGFloat) -> Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return Color(
            red: min(red + percentage, 1.0),
            green: min(green + percentage, 1.0),
            blue: min(blue + percentage, 1.0),
            opacity: Double(alpha)
        )
    }

    // MARK: - Hex Conversion

    /// Converte a cor para hex string
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }

    // MARK: - UIColor Conversion

    /// Converte para UIColor
    var uiColor: UIColor {
        UIColor(self)
    }

    // MARK: - Gradient Helpers

    /// Cria um gradiente vertical com a cor
    func verticalGradient(to endColor: Color) -> LinearGradient {
        LinearGradient(
            colors: [self, endColor],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Cria um gradiente horizontal com a cor
    func horizontalGradient(to endColor: Color) -> LinearGradient {
        LinearGradient(
            colors: [self, endColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Cria um gradiente diagonal com a cor
    func diagonalGradient(to endColor: Color) -> LinearGradient {
        LinearGradient(
            colors: [self, endColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Cria um gradiente radial com a cor
    func radialGradient(to endColor: Color) -> RadialGradient {
        RadialGradient(
            colors: [self, endColor],
            center: .center,
            startRadius: 0,
            endRadius: 200
        )
    }

    // MARK: - Contrast Color

    /// Retorna branco ou preto dependendo do contraste necessário
    var contrastColor: Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0

        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: nil)

        // Fórmula de luminância relativa
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue

        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Gradient Extensions
extension LinearGradient {

    /// Gradiente transparente para cor (útil para overlays)
    static func fadeIn(to color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(0), color],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Gradiente cor para transparente
    static func fadeOut(from color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - ShapeStyle Convenience
extension ShapeStyle where Self == LinearGradient {

    /// Atalho para gradiente primário do Naplet
    static var napletPrimary: LinearGradient {
        NapletColors.gradientPrimary
    }

    /// Atalho para gradiente secundário do Naplet
    static var napletSecondary: LinearGradient {
        NapletColors.gradientSecondary
    }

    /// Atalho para gradiente de sleep
    static var napletSleep: LinearGradient {
        NapletColors.gradientSleep
    }
}
