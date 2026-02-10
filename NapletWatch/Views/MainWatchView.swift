import SwiftUI

// MARK: - Main Watch View
struct MainWatchView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @State private var showingConfirmation = false
    @State private var showingSleepTypePicker = false

    var body: some View {
        VStack(spacing: 8) {
            if connectivity.isSleeping {
                sleepingLayout
            } else {
                awakeLayout
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WatchColors.background)
    }

    // MARK: - Awake Layout
    private var awakeLayout: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 4)

            // Baby name (destaque)
            Text(connectivity.currentBaby?.name ?? "Bebê")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            // Status
            HStack(spacing: 6) {
                Circle()
                    .fill(WatchColors.awakeColor)
                    .frame(width: 8, height: 8)

                Text(NSLocalizedString("watch.awake", comment: ""))
                    .font(.caption)
                    .foregroundColor(WatchColors.textSecondary)
            }

            Spacer(minLength: 8)

            // Botão Dormir
            sleepButton

            Spacer(minLength: 8)

            // Stats
            statsSection
        }
    }

    // MARK: - Sleeping Layout
    private var sleepingLayout: some View {
        VStack(spacing: 6) {
            // Header compacto: Nome + Status
            HStack {
                Text(connectivity.currentBaby?.name ?? "Bebê")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(WatchColors.primaryPurple)
                        .frame(width: 6, height: 6)

                    Text(NSLocalizedString("watch.sleeping", comment: ""))
                        .font(.caption2)
                        .foregroundColor(WatchColors.textSecondary)
                }
            }
            .padding(.horizontal, 4)

            Spacer(minLength: 4)

            // Timer GRANDE (destaque principal)
            if let duration = connectivity.currentSleepDuration {
                Text(formatDuration(duration))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(WatchColors.primaryPurple)
                    .monospacedDigit()
            }

            // Tipo de sono
            if let type = connectivity.sleepType {
                HStack(spacing: 4) {
                    Image(systemName: type.icon)
                        .font(.caption2)
                    Text(type.displayName)
                        .font(.caption)
                }
                .foregroundColor(WatchColors.primaryPurple.opacity(0.8))
            }

            Spacer(minLength: 8)

            // Botão Acordar (compacto)
            wakeButton
        }
        .confirmationDialog(
            NSLocalizedString("sleep.endSleep", comment: ""),
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button(NSLocalizedString("watch.wakeUp", comment: "")) {
                connectivity.stopSleep()
            }
            Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) { }
        }
    }

    // MARK: - Sleep Button (Roxo)
    private var sleepButton: some View {
        Button(action: {
            showingSleepTypePicker = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 20))

                Text(NSLocalizedString("watch.sleep", comment: ""))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(WatchColors.gradientPrimary)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSleepTypePicker) {
            SleepTypePickerView()
        }
    }

    // MARK: - Wake Button (Laranja - Compacto)
    private var wakeButton: some View {
        Button(action: {
            showingConfirmation = true
        }) {
            HStack(spacing: 6) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 18))

                Text(NSLocalizedString("watch.wakeUp", comment: ""))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(WatchColors.gradientAwake)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 8) {
            StatBox(
                icon: "moon.fill",
                value: formatMinutes(connectivity.todayTotalSleep),
                label: NSLocalizedString("watch.todaySleep", comment: "")
            )

            StatBox(
                icon: "zzz",
                value: "\(connectivity.todayNaps)",
                label: NSLocalizedString("watch.naps", comment: "")
            )
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h\(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(WatchColors.primaryPurple)

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 9))
                .foregroundColor(WatchColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(WatchColors.cardBackground)
        .cornerRadius(10)
    }
}

// MARK: - Preview
#Preview {
    MainWatchView()
        .environmentObject(WatchConnectivityManager.shared)
}
