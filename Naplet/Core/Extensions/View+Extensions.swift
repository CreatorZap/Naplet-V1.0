import SwiftUI

// MARK: - View Extensions
extension View {

    // MARK: - Conditional Modifiers

    /// Aplica um modificador condicionalmente
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Aplica um modificador condicionalmente com else
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }

    // MARK: - Hide/Show

    /// Esconde a view condicionalmente
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }

    // MARK: - Frame Helpers

    /// Define frame quadrado
    func frame(square size: CGFloat) -> some View {
        self.frame(width: size, height: size)
    }

    /// Expande para preencher todo o espaço disponível
    func fillMaxSize(alignment: Alignment = .center) -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }

    /// Expande horizontalmente
    func fillMaxWidth(alignment: Alignment = .center) -> some View {
        self.frame(maxWidth: .infinity, alignment: alignment)
    }

    /// Expande verticalmente
    func fillMaxHeight(alignment: Alignment = .center) -> some View {
        self.frame(maxHeight: .infinity, alignment: alignment)
    }

    // MARK: - Corner Radius with Specific Corners

    /// Aplica corner radius em cantos específicos
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }

    // MARK: - Shadows

    /// Aplica sombra suave padrão do Naplet
    func napletShadow() -> some View {
        self.shadow(
            color: Color.black.opacity(0.15),
            radius: 10,
            x: 0,
            y: 4
        )
    }

    /// Aplica sombra colorida (glow effect)
    func glowShadow(color: Color = NapletColors.primaryPurple, radius: CGFloat = 15) -> some View {
        self.shadow(color: color.opacity(0.4), radius: radius, x: 0, y: 5)
    }

    // MARK: - Haptic Feedback

    /// Adiciona haptic feedback ao tap
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                let impact = UIImpactFeedbackGenerator(style: style)
                impact.impactOccurred()
            }
        )
    }

    // MARK: - Loading Overlay

    /// Adiciona overlay de loading
    func loading(_ isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.4)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    }
                }
            }
        )
    }

    // MARK: - Keyboard

    /// Dismiss keyboard on tap
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }

    // MARK: - Safe Area

    /// Lê a safe area insets
    func readSafeArea(_ action: @escaping (EdgeInsets) -> Void) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: SafeAreaInsetsKey.self,
                    value: geometry.safeAreaInsets
                )
            }
        )
        .onPreferenceChange(SafeAreaInsetsKey.self, perform: action)
    }

    // MARK: - Debug

    /// Adiciona borda colorida para debug de layout
    func debugBorder(_ color: Color = .red, width: CGFloat = 1) -> some View {
        #if DEBUG
        return self.border(color, width: width)
        #else
        return self
        #endif
    }
}

// MARK: - Helper Shapes
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preference Keys
struct SafeAreaInsetsKey: PreferenceKey {
    static var defaultValue: EdgeInsets = .init()

    static func reduce(value: inout EdgeInsets, nextValue: () -> EdgeInsets) {
        value = nextValue()
    }
}

// MARK: - Animation Extensions
extension View {
    /// Animação de fade in
    func fadeIn(delay: Double = 0) -> some View {
        self.modifier(FadeInModifier(delay: delay))
    }

    /// Animação de slide up
    func slideUp(delay: Double = 0) -> some View {
        self.modifier(SlideUpModifier(delay: delay))
    }
}

struct FadeInModifier: ViewModifier {
    let delay: Double
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                    opacity = 1
                }
            }
    }
}

struct SlideUpModifier: ViewModifier {
    let delay: Double
    @State private var offset: CGFloat = 20
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}
