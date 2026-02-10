import SwiftUI

// MARK: - Naplet Typography
/// Sistema de tipografia do Naplet
struct NapletTypography {

    // MARK: - Font Sizes
    static let largeTitle: CGFloat = 34
    static let title1: CGFloat = 28
    static let title2: CGFloat = 22
    static let title3: CGFloat = 20
    static let headline: CGFloat = 17
    static let body: CGFloat = 17
    static let callout: CGFloat = 16
    static let subheadline: CGFloat = 15
    static let footnote: CGFloat = 13
    static let caption: CGFloat = 12

    // MARK: - Font Weights
    enum Weight {
        case regular
        case medium
        case semibold
        case bold

        var fontWeight: Font.Weight {
            switch self {
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            }
        }
    }

    // MARK: - Font Styles

    /// Large Title - 34pt Bold
    static func largeTitle(weight: Weight = .bold) -> Font {
        .system(size: Self.largeTitle, weight: weight.fontWeight, design: .default)
    }

    /// Title 1 - 28pt Bold
    static func title1(weight: Weight = .bold) -> Font {
        .system(size: Self.title1, weight: weight.fontWeight, design: .default)
    }

    /// Title 2 - 22pt Semibold
    static func title2(weight: Weight = .semibold) -> Font {
        .system(size: Self.title2, weight: weight.fontWeight, design: .default)
    }

    /// Title 3 - 20pt Semibold
    static func title3(weight: Weight = .semibold) -> Font {
        .system(size: Self.title3, weight: weight.fontWeight, design: .default)
    }

    /// Headline - 17pt Semibold
    static func headline(weight: Weight = .semibold) -> Font {
        .system(size: Self.headline, weight: weight.fontWeight, design: .default)
    }

    /// Body - 17pt Regular
    static func body(weight: Weight = .regular) -> Font {
        .system(size: Self.body, weight: weight.fontWeight, design: .default)
    }

    /// Callout - 16pt Regular
    static func callout(weight: Weight = .regular) -> Font {
        .system(size: Self.callout, weight: weight.fontWeight, design: .default)
    }

    /// Subheadline - 15pt Regular
    static func subheadline(weight: Weight = .regular) -> Font {
        .system(size: Self.subheadline, weight: weight.fontWeight, design: .default)
    }

    /// Footnote - 13pt Regular
    static func footnote(weight: Weight = .regular) -> Font {
        .system(size: Self.footnote, weight: weight.fontWeight, design: .default)
    }

    /// Caption - 12pt Regular
    static func caption(weight: Weight = .regular) -> Font {
        .system(size: Self.caption, weight: weight.fontWeight, design: .default)
    }

    // MARK: - Rounded Fonts (para números grandes como countdown)

    /// Large Number Display - SF Pro Rounded
    static func numberDisplay(size: CGFloat = 64, weight: Weight = .bold) -> Font {
        .system(size: size, weight: weight.fontWeight, design: .rounded)
    }

    /// Timer Display - SF Pro Rounded
    static func timerDisplay(weight: Weight = .semibold) -> Font {
        .system(size: 48, weight: weight.fontWeight, design: .rounded)
    }

    /// Stats Number - SF Pro Rounded
    static func statsNumber(weight: Weight = .bold) -> Font {
        .system(size: 32, weight: weight.fontWeight, design: .rounded)
    }
}

// MARK: - View Modifier for Typography
struct NapletTextStyle: ViewModifier {
    let font: Font
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color)
    }
}

extension View {
    /// Aplica estilo de texto do Naplet
    func napletTextStyle(font: Font, color: Color = NapletColors.textPrimary) -> some View {
        modifier(NapletTextStyle(font: font, color: color))
    }
}
