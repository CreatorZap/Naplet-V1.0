import Foundation
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    // Chamado quando notificação é recebida com app em foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Mostrar mesmo com app aberto
        completionHandler([.banner, .sound, .badge])
    }

    // Chamado quando usuário interage com a notificação
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let categoryIdentifier = response.notification.request.content.categoryIdentifier

        Logger.info("Notification action: \(actionIdentifier), category: \(categoryIdentifier)")

        switch actionIdentifier {
        case "START_NAP":
            // Postar notificação para iniciar soneca
            NotificationCenter.default.post(name: NSNotification.Name("StartNapFromNotification"), object: nil)

        case "SNOOZE_15":
            // Reagendar para 15 minutos
            Task {
                await snoozeNotification(originalRequest: response.notification.request, minutes: 15)
            }

        case "DISMISS", UNNotificationDismissActionIdentifier:
            // Apenas limpar badge
            Task { @MainActor in
                NotificationService.shared.clearBadge()
            }

        default:
            // Ação padrão (abrir app)
            NotificationCenter.default.post(name: NSNotification.Name("OpenAppFromNotification"), object: nil)
        }

        completionHandler()
    }

    private func snoozeNotification(originalRequest: UNNotificationRequest, minutes: Int) async {
        guard let content = originalRequest.content.mutableCopy() as? UNMutableNotificationContent else {
            Logger.error("Failed to copy notification content for snooze")
            return
        }
        content.title = "Reminder: " + content.title

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(
            identifier: originalRequest.identifier + "-snoozed",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            Logger.info("Notification snoozed for \(minutes) minutes")
        } catch {
            Logger.error("Failed to snooze notification: \(error)")
        }
    }
}
