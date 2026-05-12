import Foundation
import UserNotifications   // preparado para uso futuro

// MARK: - Wake Window Notification Manager
//
// STATUS ATUAL: STUB DOCUMENTADO. As 3 funções públicas existem mas não
// agendam/cancelam nada além de logar a chamada — útil para confirmar que
// o ViewModel está acionando os hooks nos momentos certos durante o
// desenvolvimento futuro.
//
// IMPLEMENTAÇÃO REAL planejada para sprint dedicada de notificações
// (junto com permissions request, push tokens, deep linking, etc).
//
// API consumida por DashboardViewModel:
//   1. shared (singleton)
//   2. rescheduleIfNeeded(baby:lastWakeTime:isSleeping:)  — DashboardViewModel:200
//   3. cancelNapReminder(babyId:)                          — DashboardViewModel:328
//   4. scheduleNapReminder(baby:lastWakeTime:)             — DashboardViewModel:375
//
// TODO Sprint Notificações:
//   • Solicitar permissão (UNUserNotificationCenter.current().requestAuthorization)
//   • Calcular Date de disparo via WakeWindowCalculator.timeUntilOverdue(...)
//   • Agendar UNNotificationRequest com identifier `wake-window-nap-reminder.{babyId}`
//   • Cancelar via removePendingNotificationRequests(withIdentifiers:)
//   • Atualizar quando dados do bebê mudam (rescheduleIfNeeded combina cancel + schedule)
//   • Localizar textos das notificações em PT/EN/ES
//   • Tratar app em background, foreground e terminated states
//   • Testar em device físico (simulador não é confiável para UNNotification)

final class WakeWindowNotificationManager {

    // MARK: - Singleton

    static let shared = WakeWindowNotificationManager()
    private init() {}

    // MARK: - Identifiers (preparados para o futuro)

    /// Prefixo do identifier para notificações de wake window.
    /// Identifier final é único por bebê para permitir cancelamento específico.
    private static let napReminderIdentifierPrefix = "wake-window-nap-reminder"

    /// Identifier estável para a notificação de nap reminder de um bebê.
    static func napReminderIdentifier(for babyId: UUID) -> String {
        "\(napReminderIdentifierPrefix).\(babyId.uuidString)"
    }

    // MARK: - Public API (stub)

    /// Reagenda a notificação de wake window quando dados relevantes mudam.
    /// Chamado pelo DashboardViewModel ao recarregar dados se o bebê está acordado.
    ///
    /// TODO Sprint Notificações: cancelar notificação existente + agendar nova
    /// usando `WakeWindowCalculator.timeUntilOverdue(lastWakeTime:ageInMonths:isSleeping:)`
    /// como base para o `timeInterval` do `UNTimeIntervalNotificationTrigger`.
    func rescheduleIfNeeded(baby: Baby, lastWakeTime: Date?, isSleeping: Bool) {
        Logger.info("[WakeWindowNotification] rescheduleIfNeeded(baby: \(baby.id), lastWakeTime: \(String(describing: lastWakeTime)), isSleeping: \(isSleeping)) — stub, noop")
        // TODO Sprint Notificações: implementar agendamento real.
    }

    /// Cancela a notificação pendente para o bebê especificado.
    /// Chamado quando o bebê começa a dormir (não precisa mais do reminder).
    ///
    /// TODO Sprint Notificações:
    ///   UNUserNotificationCenter.current().removePendingNotificationRequests(
    ///       withIdentifiers: [Self.napReminderIdentifier(for: babyId)]
    ///   )
    func cancelNapReminder(babyId: UUID) {
        Logger.info("[WakeWindowNotification] cancelNapReminder(babyId: \(babyId)) — stub, noop")
        // TODO Sprint Notificações: implementar cancelamento real.
    }

    /// Agenda notificação de aviso pré-overdue para o bebê.
    /// Chamado quando o bebê acorda (sai do estado de sleep).
    ///
    /// TODO Sprint Notificações:
    ///   1. Calcular `timeUntil = WakeWindowCalculator.timeUntilOverdue(...)`
    ///   2. Subtrair buffer pré-aviso (ex: 30 min) para alertar antes do overdue
    ///   3. Criar `UNNotificationRequest` com `UNTimeIntervalNotificationTrigger`
    ///   4. Submeter via `UNUserNotificationCenter.current().add(...)`
    func scheduleNapReminder(baby: Baby, lastWakeTime: Date) {
        Logger.info("[WakeWindowNotification] scheduleNapReminder(baby: \(baby.id), lastWakeTime: \(lastWakeTime)) — stub, noop")
        // TODO Sprint Notificações: implementar agendamento real.
    }
}
