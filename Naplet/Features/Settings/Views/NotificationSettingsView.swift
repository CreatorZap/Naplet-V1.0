import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @StateObject private var notificationService = NotificationService.shared
    @AppStorage("napReminderEnabled") private var napReminderEnabled = true
    @AppStorage("wakeReminderEnabled") private var wakeReminderEnabled = true
    @AppStorage("wakeWindowAlertsEnabled") private var wakeWindowAlertsEnabled = true
    @AppStorage("bedtimeReminderEnabled") private var bedtimeReminderEnabled = false
    @AppStorage("bedtimeHour") private var bedtimeHour = 19
    @AppStorage("bedtimeMinute") private var bedtimeMinute = 30
    @AppStorage("alertMinutesBefore") private var alertMinutesBefore = 15

    @State private var showTimePicker = false

    var baby: Baby?

    var body: some View {
        ZStack {
            NapletColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: NapletSpacing.lg) {
                    // Authorization Status
                    authorizationCard

                    // Reminder Settings
                    if notificationService.isAuthorized {
                        // Wake Window Alerts
                        wakeWindowCard

                        // Bedtime Reminder
                        bedtimeCard

                        // Legacy Settings
                        legacySettingsCard

                        // Pending Notifications
                        pendingNotificationsCard
                    }
                }
                .padding(.horizontal, NapletSpacing.lg)
                .padding(.top, NapletSpacing.md)
            }
        }
        .navigationTitle("notifications.title".localized)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await notificationService.checkAuthorizationStatus()
            await notificationService.refreshPendingNotifications()
        }
    }

    // MARK: - Authorization Card
    private var authorizationCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: NapletSpacing.md) {
                HStack {
                    Image(systemName: notificationService.isAuthorized ? "bell.badge.fill" : "bell.slash.fill")
                        .font(.system(size: 24))
                        .foregroundColor(notificationService.isAuthorized ? NapletColors.success : NapletColors.error)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("notifications.title".localized)
                            .font(.system(size: NapletTypography.headline, weight: .semibold))
                            .foregroundColor(NapletColors.textPrimary)

                        Text(notificationService.isAuthorized ? "notifications.status.enabled".localized : "notifications.status.disabled".localized)
                            .font(.system(size: NapletTypography.caption))
                            .foregroundColor(notificationService.isAuthorized ? NapletColors.success : NapletColors.textMuted)
                    }

                    Spacer()

                    if !notificationService.isAuthorized {
                        Button("notifications.enable".localized) {
                            Task {
                                let granted = await notificationService.requestAuthorization()
                                if !granted {
                                    notificationService.openSettings()
                                }
                            }
                        }
                        .font(.system(size: NapletTypography.subheadline, weight: .semibold))
                        .foregroundColor(NapletColors.primaryPurple)
                    }
                }

                if !notificationService.isAuthorized {
                    Text("notifications.enableDescription".localized)
                        .font(.system(size: NapletTypography.caption))
                        .foregroundColor(NapletColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Wake Window Card
    private var wakeWindowCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: NapletSpacing.md) {
                Toggle(isOn: $wakeWindowAlertsEnabled) {
                    HStack(spacing: NapletSpacing.sm) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 20))
                            .foregroundColor(NapletColors.primaryPurple)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("notifications.wakeWindow.title".localized)
                                .font(.system(size: NapletTypography.subheadline, weight: .semibold))
                                .foregroundColor(NapletColors.textPrimary)

                            Text("notifications.wakeWindow.subtitle".localized)
                                .font(.system(size: NapletTypography.caption))
                                .foregroundColor(NapletColors.textMuted)
                        }
                    }
                }
                .tint(NapletColors.primaryPurple)

                if wakeWindowAlertsEnabled {
                    Divider()
                        .background(NapletColors.backgroundTertiary)

                    VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                        Text("notifications.wakeWindow.alertBefore".localized)
                            .font(.system(size: NapletTypography.caption))
                            .foregroundColor(NapletColors.textSecondary)

                        Picker("notifications.wakeWindow.alertBefore".localized, selection: $alertMinutesBefore) {
                            Text("notifications.alertTime.10min".localized).tag(10)
                            Text("notifications.alertTime.15min".localized).tag(15)
                            Text("notifications.alertTime.20min".localized).tag(20)
                            Text("notifications.alertTime.30min".localized).tag(30)
                        }
                        .pickerStyle(.segmented)
                    }

                    if let baby = baby {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                            Text("notifications.wakeWindow.recommended".localized(with: baby.name, baby.recommendedWakeWindowMinutes.lowerBound, baby.recommendedWakeWindowMinutes.upperBound))
                                .font(.system(size: NapletTypography.caption))
                        }
                        .foregroundColor(NapletColors.textMuted)
                        .padding(.top, NapletSpacing.xs)
                    }
                }
            }
        }
    }

    // MARK: - Bedtime Card
    private var bedtimeCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: NapletSpacing.md) {
                Toggle(isOn: $bedtimeReminderEnabled) {
                    HStack(spacing: NapletSpacing.sm) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 20))
                            .foregroundColor(NapletColors.primaryBlue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("notifications.bedtime.title".localized)
                                .font(.system(size: NapletTypography.subheadline, weight: .semibold))
                                .foregroundColor(NapletColors.textPrimary)

                            Text("notifications.bedtime.subtitle".localized)
                                .font(.system(size: NapletTypography.caption))
                                .foregroundColor(NapletColors.textMuted)
                        }
                    }
                }
                .tint(NapletColors.primaryBlue)
                .onChange(of: bedtimeReminderEnabled) { _, newValue in
                    if newValue {
                        scheduleBedtimeIfNeeded()
                    } else {
                        Task {
                            await notificationService.cancelBedtimeReminders()
                            await notificationService.refreshPendingNotifications()
                        }
                    }
                }

                if bedtimeReminderEnabled {
                    Divider()
                        .background(NapletColors.backgroundTertiary)

                    Button(action: { showTimePicker = true }) {
                        HStack {
                            Text("notifications.bedtime.time".localized)
                                .font(.system(size: NapletTypography.subheadline))
                                .foregroundColor(NapletColors.textSecondary)

                            Spacer()

                            Text(String(format: "%02d:%02d", bedtimeHour, bedtimeMinute))
                                .font(.system(size: NapletTypography.headline, weight: .semibold, design: .rounded))
                                .foregroundColor(NapletColors.primaryBlue)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(NapletColors.textMuted)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showTimePicker) {
            TimePickerSheet(
                hour: $bedtimeHour,
                minute: $bedtimeMinute,
                onSave: {
                    scheduleBedtimeIfNeeded()
                }
            )
        }
    }

    // MARK: - Legacy Settings Card
    private var legacySettingsCard: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.md) {
            Text("notifications.other.title".localized)
                .font(.system(size: NapletTypography.footnote, weight: .semibold))
                .foregroundColor(NapletColors.textMuted)

            NapletCard {
                VStack(spacing: NapletSpacing.md) {
                    // Nap Reminder Toggle
                    Toggle(isOn: $napReminderEnabled) {
                        HStack {
                            Image(systemName: "moon.zzz.fill")
                                .foregroundColor(NapletColors.primaryPurple)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("notifications.napReminder.title".localized)
                                    .font(.system(size: NapletTypography.body))
                                    .foregroundColor(NapletColors.textPrimary)

                                Text("notifications.napReminder.subtitle".localized)
                                    .font(.system(size: NapletTypography.caption))
                                    .foregroundColor(NapletColors.textMuted)
                            }
                        }
                    }
                    .tint(NapletColors.primaryPurple)

                    Divider()
                        .background(NapletColors.backgroundTertiary)

                    // Wake Reminder Toggle
                    Toggle(isOn: $wakeReminderEnabled) {
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(NapletColors.warning)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("notifications.wakeReminder.title".localized)
                                    .font(.system(size: NapletTypography.body))
                                    .foregroundColor(NapletColors.textPrimary)

                                Text("notifications.wakeReminder.subtitle".localized)
                                    .font(.system(size: NapletTypography.caption))
                                    .foregroundColor(NapletColors.textMuted)
                            }
                        }
                    }
                    .tint(NapletColors.primaryPurple)
                }
            }
        }
    }

    // MARK: - Pending Notifications Card
    private var pendingNotificationsCard: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.md) {
            HStack {
                Text("notifications.pending".localized)
                    .font(.system(size: NapletTypography.footnote, weight: .semibold))
                    .foregroundColor(NapletColors.textMuted)

                Spacer()

                if !notificationService.pendingNotifications.isEmpty {
                    Text("\(notificationService.pendingNotifications.count)")
                        .font(.system(size: NapletTypography.caption, weight: .bold))
                        .foregroundColor(NapletColors.primaryPurple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(NapletColors.primaryPurple.opacity(0.2))
                        .cornerRadius(8)
                }
            }

            NapletCard {
                if notificationService.pendingNotifications.isEmpty {
                    HStack {
                        Image(systemName: "bell.slash")
                            .foregroundColor(NapletColors.textMuted)

                        Text("notifications.noPending".localized)
                            .font(.system(size: NapletTypography.body))
                            .foregroundColor(NapletColors.textMuted)

                        Spacer()
                    }
                    .padding(.vertical, NapletSpacing.sm)
                } else {
                    VStack(spacing: NapletSpacing.sm) {
                        ForEach(notificationService.pendingNotifications.prefix(5), id: \.identifier) { request in
                            PendingNotificationRow(request: request)

                            if request.identifier != notificationService.pendingNotifications.prefix(5).last?.identifier {
                                Divider()
                                    .background(NapletColors.backgroundTertiary)
                            }
                        }

                        if notificationService.pendingNotifications.count > 5 {
                            Text("notifications.moreCount".localized(with: notificationService.pendingNotifications.count - 5))
                                .font(.system(size: NapletTypography.caption))
                                .foregroundColor(NapletColors.textMuted)
                        }
                    }
                }
            }

            if !notificationService.pendingNotifications.isEmpty {
                Button("notifications.cancelAll".localized) {
                    notificationService.cancelAllNotifications()
                    Task {
                        await notificationService.refreshPendingNotifications()
                    }
                }
                .font(.system(size: NapletTypography.caption, weight: .medium))
                .foregroundColor(NapletColors.error)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Helper Methods
    private func scheduleBedtimeIfNeeded() {
        guard bedtimeReminderEnabled else { return }
        let babyName = baby?.name ?? "o bebê"
        Task {
            await notificationService.scheduleBedtimeReminder(
                babyName: babyName,
                bedtimeHour: bedtimeHour,
                bedtimeMinute: bedtimeMinute
            )
            await notificationService.refreshPendingNotifications()
        }
    }
}

// MARK: - Pending Notification Row
struct PendingNotificationRow: View {
    let request: UNNotificationRequest

    var triggerDate: Date? {
        if let trigger = request.trigger as? UNCalendarNotificationTrigger {
            return trigger.nextTriggerDate()
        } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
            return Date().addingTimeInterval(trigger.timeInterval)
        }
        return nil
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(request.content.title)
                    .font(.system(size: NapletTypography.subheadline, weight: .medium))
                    .foregroundColor(NapletColors.textPrimary)
                    .lineLimit(1)

                if let date = triggerDate {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: NapletTypography.caption))
                        .foregroundColor(NapletColors.textMuted)
                }
            }

            Spacer()

            Image(systemName: "bell.fill")
                .font(.caption)
                .foregroundColor(NapletColors.primaryPurple)
        }
        .padding(.vertical, NapletSpacing.xs)
    }
}

// MARK: - Time Picker Sheet
struct TimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hour: Int
    @Binding var minute: Int
    var onSave: () -> Void

    @State private var selectedTime: Date = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                NapletColors.background
                    .ignoresSafeArea()

                VStack {
                    DatePicker(
                        "notifications.bedtime.timeLabel".localized,
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("notifications.bedtime.selectTime".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel.localized) { dismiss() }
                        .foregroundColor(NapletColors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.save.localized) {
                        let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                        hour = components.hour ?? 19
                        minute = components.minute ?? 30
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(NapletColors.primaryPurple)
                }
            }
        }
        .onAppear {
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            selectedTime = Calendar.current.date(from: components) ?? Date()
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView(baby: Baby.preview)
    }
}
