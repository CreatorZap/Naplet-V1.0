import SwiftUI
import UIKit

// MARK: - Haptic Manager
/// Gerenciador centralizado de haptic feedback no padrão Apple
final class HapticManager {
    static let shared = HapticManager()

    private init() {}

    // MARK: - Impact Feedback

    /// Feedback leve - para transições de tela e seleções sutis
    func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Feedback médio - para seleções importantes
    func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Feedback pesado - para ações significativas
    func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Feedback soft - para toques sutis
    func softImpact() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Feedback rigid - para confirmações
    func rigidImpact() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Notification Feedback

    /// Feedback de sucesso - para conclusão de tarefas
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// Feedback de aviso - para alertas
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    /// Feedback de erro - para falhas
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback

    /// Feedback de seleção - para toques em opções
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

// MARK: - Haptic Style Enum
enum HapticStyle {
    case light
    case medium
    case heavy
    case soft
    case rigid
    case selection
    case success
    case warning
    case error
}

// MARK: - View Extension
extension View {
    /// Adiciona haptic feedback ao toque
    func hapticOnTap(_ style: HapticStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                triggerHaptic(style)
            }
        )
    }

    /// Adiciona haptic feedback quando um valor muda
    func hapticOnChange<V: Equatable>(of value: V, style: HapticStyle = .selection) -> some View {
        self.onChange(of: value) { _, _ in
            triggerHaptic(style)
        }
    }

    private func triggerHaptic(_ style: HapticStyle) {
        switch style {
        case .light:
            HapticManager.shared.lightImpact()
        case .medium:
            HapticManager.shared.mediumImpact()
        case .heavy:
            HapticManager.shared.heavyImpact()
        case .soft:
            HapticManager.shared.softImpact()
        case .rigid:
            HapticManager.shared.rigidImpact()
        case .selection:
            HapticManager.shared.selection()
        case .success:
            HapticManager.shared.success()
        case .warning:
            HapticManager.shared.warning()
        case .error:
            HapticManager.shared.error()
        }
    }
}
