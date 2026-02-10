import Foundation
import UserNotifications
import UIKit

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []

    private let center = UNUserNotificationCenter.current()

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                isAuthorized = granted
            }
            Logger.info("Notification authorization: \(granted)")
            return granted
        } catch {
            Logger.error("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Schedule Nap Reminder
    func scheduleNapReminder(for baby: Baby, wakeUpTime: Date) async {
        // Calcular próximo horário de soneca baseado no wake window
        let wakeWindow = baby.recommendedWakeWindow
        let napTime = wakeUpTime.addingTimeInterval(wakeWindow)

        // Não agendar se já passou do horário
        guard napTime > Date() else {
            Logger.info("Nap time already passed, not scheduling")
            return
        }

        // Agendar notificação 10 minutos antes
        let reminderTime = napTime.addingTimeInterval(-10 * 60)

        guard reminderTime > Date() else {
            // Se já passou dos 10 min antes, agendar para o horário exato
            await scheduleNotification(
                identifier: "nap-reminder-\(baby.id.uuidString)",
                title: "notification.nap.time.title".localized,
                body: String(format: "notification.nap.time.body".localized, baby.name),
                date: napTime,
                sound: .default
            )
            return
        }

        // Agendar reminder 10 min antes
        await scheduleNotification(
            identifier: "nap-reminder-\(baby.id.uuidString)",
            title: "notification.nap.coming.title".localized,
            body: String(format: "notification.nap.coming.body".localized, baby.name),
            date: reminderTime,
            sound: .default
        )

        // Agendar notificação no horário exato
        await scheduleNotification(
            identifier: "nap-time-\(baby.id.uuidString)",
            title: "notification.nap.time.title".localized,
            body: String(format: "notification.nap.time.body".localized, baby.name),
            date: napTime,
            sound: .default
        )

        Logger.info("Scheduled nap reminder for \(baby.name) at \(napTime)")
    }

    // MARK: - Schedule Wake Reminder
    func scheduleWakeReminder(for baby: Baby, sleepStartTime: Date, maxNapDuration: TimeInterval = 2 * 60 * 60) async {
        let wakeTime = sleepStartTime.addingTimeInterval(maxNapDuration)

        guard wakeTime > Date() else { return }

        await scheduleNotification(
            identifier: "wake-reminder-\(baby.id.uuidString)",
            title: "notification.wake.title".localized,
            body: String(format: "notification.wake.body".localized, baby.name),
            date: wakeTime,
            sound: .default
        )

        Logger.info("Scheduled wake reminder for \(baby.name) at \(wakeTime)")
    }

    // MARK: - Wake Window Alerts (Enhanced)

    /// Agenda notificação para quando o wake window estiver chegando ao fim
    func scheduleWakeWindowAlert(
        babyName: String,
        wakeWindowMinutes: Int,
        lastWakeTime: Date,
        alertBeforeMinutes: Int = 15,
        baby: Baby? = nil
    ) async {
        // Cancela notificações anteriores de wake window
        await cancelWakeWindowNotifications()

        // Calcula quando a janela de sono termina
        let wakeWindowEndTime = lastWakeTime.addingTimeInterval(TimeInterval(wakeWindowMinutes * 60))

        // Verifica se ainda é horário válido para soneca
        if let baby = baby {
            let recommendation = baby.currentSleepRecommendation(at: wakeWindowEndTime)

            switch recommendation {
            case .prepareBedtime, .bedtime, .pastBedtime:
                // É hora de dormir, não de soneca - agendar notificação de bedtime ao invés
                await scheduleBedtimeAlert(babyName: babyName, baby: baby)
                return
            case .tooEarly:
                // Muito cedo (madrugada) - não notificar
                Logger.info("Muito cedo para notificação de wake window")
                return
            case .nap:
                // OK, continuar com notificação de soneca
                break
            }
        }

        // Calcula quando notificar (wake window - tempo de alerta antecipado)
        let notifyAfterMinutes = wakeWindowMinutes - alertBeforeMinutes
        let notifyTime = lastWakeTime.addingTimeInterval(TimeInterval(notifyAfterMinutes * 60))

        // Se o tempo já passou, não agenda
        guard notifyTime > Date() else {
            Logger.info("Wake window já passou, não agendando notificação")
            return
        }

        let timeInterval = notifyTime.timeIntervalSinceNow

        // Notificação 1: Alerta antecipado (hora da soneca chegando)
        let content1 = UNMutableNotificationContent()
        content1.title = "notification.nap.warning.title".localized
        content1.body = String(format: "notification.nap.warning.body".localized, babyName, alertBeforeMinutes)
        content1.sound = .default
        content1.categoryIdentifier = "WAKE_WINDOW_ALERT"
        content1.badge = 1
        content1.userInfo = ["type": "wake_window_warning", "isNap": true]

        let trigger1 = UNTimeIntervalNotificationTrigger(timeInterval: max(timeInterval, 1), repeats: false)

        let request1 = UNNotificationRequest(
            identifier: "wake_window_warning_\(UUID().uuidString)",
            content: content1,
            trigger: trigger1
        )

        do {
            try await center.add(request1)
            Logger.info("Notificação de soneca agendada para \(notifyTime)")
        } catch {
            Logger.error("Erro ao agendar notificação de warning: \(error)")
        }

        // Notificação 2: Hora da soneca (quando atinge o wake window)
        let sleepTimeInterval = wakeWindowEndTime.timeIntervalSinceNow

        if sleepTimeInterval > 0 {
            let content2 = UNMutableNotificationContent()
            content2.title = "notification.nap.now.title".localized
            content2.body = String(format: "notification.nap.now.body".localized, babyName)
            content2.sound = .default
            content2.categoryIdentifier = "WAKE_WINDOW_ALERT"
            content2.badge = 1
            content2.userInfo = ["type": "wake_window_reached", "isNap": true]

            let trigger2 = UNTimeIntervalNotificationTrigger(timeInterval: max(sleepTimeInterval, 1), repeats: false)

            let request2 = UNNotificationRequest(
                identifier: "wake_window_reached_\(UUID().uuidString)",
                content: content2,
                trigger: trigger2
            )

            do {
                try await center.add(request2)
                Logger.info("Notificação 'hora da soneca' agendada para \(wakeWindowEndTime)")
            } catch {
                Logger.error("Erro ao agendar notificação de wake window: \(error)")
            }
        }

        await refreshPendingNotifications()
    }

    // MARK: - Bedtime Alert (Sono Noturno)
    /// Agenda notificação para hora de dormir (sono noturno)
    func scheduleBedtimeAlert(babyName: String, baby: Baby) async {
        // Cancela notificações anteriores de bedtime
        let pendingRequests = await center.pendingNotificationRequests()
        let bedtimeIds = pendingRequests
            .filter { $0.identifier.contains("bedtime_alert") }
            .map { $0.identifier }
        center.removePendingNotificationRequests(withIdentifiers: bedtimeIds)

        let now = Date()
        let calendar = Calendar.current

        // Calcular horário de bedtime para hoje
        var bedtimeComponents = calendar.dateComponents([.year, .month, .day], from: now)
        bedtimeComponents.hour = baby.recommendedBedtime.hour
        bedtimeComponents.minute = baby.recommendedBedtime.minute

        guard let bedtimeToday = calendar.date(from: bedtimeComponents) else { return }

        // Se já passou do bedtime hoje, não agendar
        guard bedtimeToday > now else {
            Logger.info("Já passou do bedtime hoje, não agendando notificação")
            return
        }

        // Notificação 1: 30 minutos antes do bedtime (preparar)
        let prepTime = bedtimeToday.addingTimeInterval(-30 * 60)
        if prepTime > now {
            let content1 = UNMutableNotificationContent()
            content1.title = "notification.bedtime.prepare.title".localized
            content1.body = String(format: "notification.bedtime.prepare.body".localized, babyName, 30)
            content1.sound = .default
            content1.categoryIdentifier = "BEDTIME_ALERT"
            content1.badge = 1
            content1.userInfo = ["type": "bedtime_prepare"]

            let trigger1 = UNTimeIntervalNotificationTrigger(timeInterval: prepTime.timeIntervalSinceNow, repeats: false)

            let request1 = UNNotificationRequest(
                identifier: "bedtime_alert_prepare_\(UUID().uuidString)",
                content: content1,
                trigger: trigger1
            )

            do {
                try await center.add(request1)
                Logger.info("Notificação 'preparar para dormir' agendada para \(prepTime)")
            } catch {
                Logger.error("Erro ao agendar notificação de preparo: \(error)")
            }
        }

        // Notificação 2: Hora de dormir
        let content2 = UNMutableNotificationContent()
        content2.title = "notification.bedtime.now.title".localized
        content2.body = String(format: "notification.bedtime.now.body".localized, babyName)
        content2.sound = .default
        content2.categoryIdentifier = "BEDTIME_ALERT"
        content2.badge = 1
        content2.userInfo = ["type": "bedtime_now"]

        let trigger2 = UNTimeIntervalNotificationTrigger(timeInterval: bedtimeToday.timeIntervalSinceNow, repeats: false)

        let request2 = UNNotificationRequest(
            identifier: "bedtime_alert_now_\(UUID().uuidString)",
            content: content2,
            trigger: trigger2
        )

        do {
            try await center.add(request2)
            Logger.info("Notificação 'hora de dormir' agendada para \(bedtimeToday)")
        } catch {
            Logger.error("Erro ao agendar notificação de bedtime: \(error)")
        }

        await refreshPendingNotifications()
    }

    /// Agenda notificação quando o bebê acordar de uma soneca
    func schedulePostNapAlert(
        babyName: String,
        wakeWindowMinutes: Int,
        wokeUpAt: Date
    ) async {
        await scheduleWakeWindowAlert(
            babyName: babyName,
            wakeWindowMinutes: wakeWindowMinutes,
            lastWakeTime: wokeUpAt,
            alertBeforeMinutes: 15
        )
    }

    // MARK: - Bedtime Reminders

    /// Agenda lembrete diário para rotina de sono noturno
    func scheduleBedtimeReminder(
        babyName: String,
        bedtimeHour: Int,
        bedtimeMinute: Int,
        reminderMinutesBefore: Int = 30
    ) async {
        await cancelBedtimeReminders()

        var dateComponents = DateComponents()
        dateComponents.hour = bedtimeHour
        dateComponents.minute = bedtimeMinute - reminderMinutesBefore

        // Ajusta se minutos ficarem negativos
        if dateComponents.minute! < 0 {
            dateComponents.minute! += 60
            dateComponents.hour! -= 1
            if dateComponents.hour! < 0 {
                dateComponents.hour! = 23
            }
        }

        let content = UNMutableNotificationContent()
        content.title = "notification.bedtime.title".localized
        content.body = String(format: "notification.bedtime.body".localized, reminderMinutesBefore, babyName)
        content.sound = .default
        content.categoryIdentifier = "BEDTIME_REMINDER"
        content.badge = 1

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "bedtime_reminder",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            Logger.info("Lembrete de rotina noturna agendado para \(dateComponents.hour ?? 0):\(dateComponents.minute ?? 0)")
        } catch {
            Logger.error("Erro ao agendar lembrete de bedtime: \(error)")
        }

        await refreshPendingNotifications()
    }

    // MARK: - Cancel Wake Window Notifications
    func cancelWakeWindowNotifications() async {
        let requests = await center.pendingNotificationRequests()
        let wakeWindowIds = requests
            .filter { $0.identifier.contains("wake_window") }
            .map { $0.identifier }

        center.removePendingNotificationRequests(withIdentifiers: wakeWindowIds)
        Logger.info("Canceladas \(wakeWindowIds.count) notificações de wake window")
    }

    func cancelBedtimeReminders() async {
        center.removePendingNotificationRequests(withIdentifiers: ["bedtime_reminder"])
        Logger.info("Lembrete de bedtime cancelado")
    }

    // MARK: - Generic Schedule Notification
    private func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        date: Date,
        sound: UNNotificationSound?
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        content.badge = 1

        // Adicionar categoria para ações
        content.categoryIdentifier = "NAP_REMINDER"

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
            await refreshPendingNotifications()
            Logger.info("Notification scheduled: \(identifier)")
        } catch {
            Logger.error("Failed to schedule notification: \(error)")
        }
    }

    // MARK: - Cancel Notifications
    func cancelNapReminders(for babyId: UUID) {
        let identifiers = [
            "nap-reminder-\(babyId.uuidString)",
            "nap-time-\(babyId.uuidString)",
            "wake-reminder-\(babyId.uuidString)"
        ]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        Logger.info("Cancelled nap reminders for baby \(babyId)")

        Task {
            await refreshPendingNotifications()
        }
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        pendingNotifications = []
        Logger.info("All notifications cancelled")
    }

    // MARK: - Refresh Pending
    func refreshPendingNotifications() async {
        let requests = await center.pendingNotificationRequests()
        await MainActor.run {
            pendingNotifications = requests
        }
    }

    // MARK: - Clear Badge
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                Logger.error("Failed to clear badge: \(error)")
            }
        }
    }

    // MARK: - Setup Notification Categories
    func setupNotificationCategories() {
        // Nap Category
        let startNapAction = UNNotificationAction(
            identifier: "START_NAP",
            title: "notification.action.startNap".localized,
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_15",
            title: "notification.action.remind15".localized,
            options: []
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "notification.action.dismiss".localized,
            options: [.destructive]
        )

        let napCategory = UNNotificationCategory(
            identifier: "NAP_REMINDER",
            actions: [startNapAction, snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        // Medication Category
        let medGivenAction = UNNotificationAction(
            identifier: "MED_GIVEN",
            title: "medication.action.given".localized,
            options: [.foreground]
        )

        let medSnooze15Action = UNNotificationAction(
            identifier: "MED_SNOOZE_15",
            title: "medication.action.snooze15".localized,
            options: []
        )

        let medSnooze30Action = UNNotificationAction(
            identifier: "MED_SNOOZE_30",
            title: "medication.action.snooze30".localized,
            options: []
        )

        let medSkipAction = UNNotificationAction(
            identifier: "MED_SKIP",
            title: "medication.action.skip".localized,
            options: [.destructive]
        )

        let medicationCategory = UNNotificationCategory(
            identifier: "MEDICATION_REMINDER",
            actions: [medGivenAction, medSnooze15Action, medSnooze30Action, medSkipAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([napCategory, medicationCategory])
    }

    // MARK: - Medication Reminders

    /// Agenda lembretes de medicamento para um schedule
    func scheduleMedicationReminders(
        schedule: MedicationSchedule,
        babyName: String
    ) async {
        guard schedule.canReceiveReminders else {
            Logger.info("Schedule não pode receber lembretes: \(schedule.medicationName)")
            return
        }

        // Cancela lembretes antigos deste schedule
        await cancelMedicationReminders(scheduleId: schedule.id)

        let calendar = Calendar.current
        let now = Date()

        for timeString in schedule.reminderTimes {
            guard let time = parseTimeString(timeString) else { continue }

            // Cria data para hoje com o horário especificado
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute

            guard let reminderDate = calendar.date(from: components) else { continue }

            // Se o horário já passou hoje, agenda para amanhã
            let finalDate: Date
            if reminderDate <= now {
                finalDate = calendar.date(byAdding: .day, value: 1, to: reminderDate) ?? reminderDate
            } else {
                finalDate = reminderDate
            }

            // Cria notificação
            let content = UNMutableNotificationContent()
            content.title = "medication.reminder.title".localized
            content.body = String(
                format: "medication.reminder.body".localized,
                schedule.medicationName,
                schedule.dose ?? "",
                babyName
            )
            content.sound = .default
            content.categoryIdentifier = "MEDICATION_REMINDER"
            content.badge = 1

            // UserInfo para identificar o schedule e horário
            content.userInfo = [
                "type": "medication_reminder",
                "schedule_id": schedule.id.uuidString,
                "baby_id": schedule.babyId.uuidString,
                "medication_name": schedule.medicationName,
                "dose": schedule.dose ?? "",
                "scheduled_time": ISO8601DateFormatter().string(from: finalDate)
            ]

            // Trigger diário no mesmo horário
            var triggerComponents = DateComponents()
            triggerComponents.hour = timeComponents.hour
            triggerComponents.minute = timeComponents.minute

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: triggerComponents,
                repeats: true // Repete diariamente
            )

            let identifier = "medication_\(schedule.id.uuidString)_\(timeString.replacingOccurrences(of: ":", with: ""))"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
                Logger.info("Agendado lembrete de \(schedule.medicationName) para \(timeString)")
            } catch {
                Logger.error("Erro ao agendar lembrete de medicamento: \(error)")
            }
        }

        await refreshPendingNotifications()
    }

    /// Agenda lembrete único de medicamento (para snooze ou horário específico)
    func scheduleSingleMedicationReminder(
        schedule: MedicationSchedule,
        babyName: String,
        at date: Date,
        isSnoozed: Bool = false
    ) async {
        let content = UNMutableNotificationContent()

        if isSnoozed {
            content.title = "medication.reminder.snoozed.title".localized
        } else {
            content.title = "medication.reminder.title".localized
        }

        content.body = String(
            format: "medication.reminder.body".localized,
            schedule.medicationName,
            schedule.dose ?? "",
            babyName
        )
        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"
        content.badge = 1
        content.userInfo = [
            "type": isSnoozed ? "medication_snooze" : "medication_reminder",
            "schedule_id": schedule.id.uuidString,
            "baby_id": schedule.babyId.uuidString,
            "medication_name": schedule.medicationName,
            "dose": schedule.dose ?? "",
            "scheduled_time": ISO8601DateFormatter().string(from: date)
        ]

        let timeInterval = date.timeIntervalSinceNow
        guard timeInterval > 0 else {
            Logger.warning("Tentativa de agendar notificação no passado")
            return
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )

        let identifier = "medication_single_\(schedule.id.uuidString)_\(UUID().uuidString.prefix(8))"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            Logger.info("Agendado lembrete único de \(schedule.medicationName) para \(date)")
        } catch {
            Logger.error("Erro ao agendar lembrete único: \(error)")
        }

        await refreshPendingNotifications()
    }

    /// Cancela lembretes de um schedule específico
    func cancelMedicationReminders(scheduleId: UUID) async {
        let requests = await center.pendingNotificationRequests()
        let medicationIds = requests
            .filter { $0.identifier.contains("medication_\(scheduleId.uuidString)") }
            .map { $0.identifier }

        center.removePendingNotificationRequests(withIdentifiers: medicationIds)
        Logger.info("Cancelados \(medicationIds.count) lembretes de medicamento")
    }

    /// Cancela todos os lembretes de medicamento
    func cancelAllMedicationReminders() async {
        let requests = await center.pendingNotificationRequests()
        let medicationIds = requests
            .filter { $0.identifier.hasPrefix("medication_") }
            .map { $0.identifier }

        center.removePendingNotificationRequests(withIdentifiers: medicationIds)
        Logger.info("Cancelados todos os \(medicationIds.count) lembretes de medicamento")
    }

    /// Agenda lembrete de estoque baixo
    func scheduleLowStockReminder(
        schedule: MedicationSchedule,
        babyName: String
    ) async {
        guard let dosesRemaining = schedule.dosesRemaining,
              dosesRemaining <= schedule.lowStockAlert else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "medication.lowStock.title".localized
        content.body = String(
            format: "medication.lowStock.body".localized,
            schedule.medicationName,
            dosesRemaining
        )
        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"
        content.userInfo = [
            "type": "medication_low_stock",
            "schedule_id": schedule.id.uuidString,
            "medication_name": schedule.medicationName
        ]

        // Agenda para 1 minuto no futuro (notificação imediata)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)

        let identifier = "medication_low_stock_\(schedule.id.uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            // Remove notificação anterior de estoque baixo do mesmo medicamento
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            try await center.add(request)
            Logger.info("Agendado alerta de estoque baixo para \(schedule.medicationName)")
        } catch {
            Logger.error("Erro ao agendar alerta de estoque baixo: \(error)")
        }
    }

    /// Reagenda todos os lembretes de medicamento ativos
    func rescheduleAllMedicationReminders(schedules: [MedicationSchedule], babyName: String) async {
        // Cancela todos primeiro
        await cancelAllMedicationReminders()

        // Reagenda cada um
        for schedule in schedules where schedule.canReceiveReminders {
            await scheduleMedicationReminders(schedule: schedule, babyName: babyName)

            // Verifica estoque baixo
            if schedule.isLowStock {
                await scheduleLowStockReminder(schedule: schedule, babyName: babyName)
            }
        }

        Logger.info("Reagendados lembretes para \(schedules.count) medicamentos")
    }

    // MARK: - Helpers

    private func parseTimeString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString)
    }
}
