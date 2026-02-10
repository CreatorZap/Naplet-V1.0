import SwiftUI

// MARK: - Naplet Spacing System
/// Sistema de espaçamento consistente do Naplet
struct NapletSpacing {

    // MARK: - Base Spacing Values
    /// Extra Small - 4pt
    static let xs: CGFloat = 4
    /// Small - 8pt
    static let sm: CGFloat = 8
    /// Medium - 16pt
    static let md: CGFloat = 16
    /// Large - 24pt
    static let lg: CGFloat = 24
    /// Extra Large - 32pt
    static let xl: CGFloat = 32
    /// Extra Extra Large - 48pt
    static let xxl: CGFloat = 48

    // MARK: - Component Specific Spacing

    /// Padding interno de cards
    static let cardPadding: CGFloat = md
    /// Espaçamento entre itens de lista
    static let listItemSpacing: CGFloat = sm
    /// Padding horizontal de tela
    static let screenHorizontalPadding: CGFloat = md
    /// Padding vertical de tela
    static let screenVerticalPadding: CGFloat = lg
    /// Espaçamento entre seções
    static let sectionSpacing: CGFloat = xl

    // MARK: - Corner Radius
    /// Pequeno - 8pt (botões pequenos, tags)
    static let radiusSmall: CGFloat = 8
    /// Médio - 12pt (cards, inputs)
    static let radiusMedium: CGFloat = 12
    /// Grande - 16pt (cards grandes, modais)
    static let radiusLarge: CGFloat = 16
    /// Extra grande - 24pt (elementos especiais)
    static let radiusXLarge: CGFloat = 24
    /// Circular
    static let radiusFull: CGFloat = 9999

    // MARK: - Icon Sizes
    /// Ícone pequeno - 16pt
    static let iconSmall: CGFloat = 16
    /// Ícone médio - 24pt
    static let iconMedium: CGFloat = 24
    /// Ícone grande - 32pt
    static let iconLarge: CGFloat = 32
    /// Ícone extra grande - 48pt
    static let iconXLarge: CGFloat = 48

    // MARK: - Button Heights
    /// Botão pequeno - 36pt
    static let buttonHeightSmall: CGFloat = 36
    /// Botão médio - 44pt
    static let buttonHeightMedium: CGFloat = 44
    /// Botão grande - 56pt
    static let buttonHeightLarge: CGFloat = 56
}

// MARK: - Padding Extension
extension View {
    /// Aplica padding horizontal padrão de tela
    func screenPadding() -> some View {
        self.padding(.horizontal, NapletSpacing.screenHorizontalPadding)
    }

    /// Aplica padding de card
    func cardPadding() -> some View {
        self.padding(NapletSpacing.cardPadding)
    }

    /// Aplica padding de seção
    func sectionPadding() -> some View {
        self.padding(.vertical, NapletSpacing.sectionSpacing)
    }
}
