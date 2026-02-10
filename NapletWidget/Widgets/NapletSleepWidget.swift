import WidgetKit
import SwiftUI

// MARK: - Sleep Status Provider
struct SleepStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> SleepStatusEntry {
        SleepStatusEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SleepStatusEntry) -> Void) {
        let data = WidgetDataManager.loadWidgetData()
        let entry = SleepStatusEntry(date: Date(), data: data)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepStatusEntry>) -> Void) {
        let data = WidgetDataManager.loadWidgetData()
        let currentDate = Date()

        // If sleeping, update every minute to show duration
        let refreshInterval: TimeInterval = data.isSleeping ? 60 : 900 // 1 min or 15 min

        var entries: [SleepStatusEntry] = []

        // Create entries for the next 15 minutes if sleeping
        if data.isSleeping {
            for minuteOffset in 0..<15 {
                let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
                entries.append(SleepStatusEntry(date: entryDate, data: data))
            }
        } else {
            entries.append(SleepStatusEntry(date: currentDate, data: data))
        }

        let nextUpdate = Calendar.current.date(byAdding: .second, value: Int(refreshInterval), to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Sleep Status Entry
struct SleepStatusEntry: TimelineEntry {
    let date: Date
    let data: WidgetSleepData
}

// MARK: - Naplet Sleep Widget
struct NapletSleepWidget: Widget {
    let kind: String = "NapletSleepWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepStatusProvider()) { entry in
            SleepWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetColors.background
                }
        }
        .configurationDisplayName(WidgetStrings.sleepStatusName)
        .description(WidgetStrings.sleepStatusDescription)
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Widget Views
struct SleepWidgetView: View {
    let entry: SleepStatusEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallSleepWidget(data: entry.data)
        case .systemMedium:
            MediumSleepWidget(data: entry.data)
        case .accessoryCircular:
            CircularAccessoryWidget(data: entry.data)
        case .accessoryRectangular:
            RectangularAccessoryWidget(data: entry.data)
        default:
            SmallSleepWidget(data: entry.data)
        }
    }
}

// MARK: - Small Widget
struct SmallSleepWidget: View {
    let data: WidgetSleepData

    var body: some View {
        ZStack {
            // Background gradient
            if data.isSleeping {
                WidgetColors.gradientSleep
            } else {
                WidgetColors.gradientCard
            }

            VStack(spacing: 8) {
                // Status icon
                Image(systemName: data.isSleeping ? "moon.zzz.fill" : "sun.max.fill")
                    .font(.system(size: 32))
                    .foregroundColor(data.isSleeping ? .white : WidgetColors.awakeColor)
                    .shadow(color: data.isSleeping ? WidgetColors.primaryPurple.opacity(0.5) : WidgetColors.warning.opacity(0.5), radius: 8)

                // Baby name
                Text(data.babyName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(WidgetColors.textSecondary)

                // Status/Duration
                if data.isSleeping {
                    Text(data.formattedDuration)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(WidgetColors.textPrimary)
                        .monospacedDigit()
                } else {
                    Text(WidgetStrings.awake)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(WidgetColors.awakeColor)
                }
            }
            .padding()
        }
    }
}

// MARK: - Medium Widget
struct MediumSleepWidget: View {
    let data: WidgetSleepData

    var body: some View {
        ZStack {
            // Background
            if data.isSleeping {
                WidgetColors.gradientSleep
            } else {
                WidgetColors.gradientCard
            }

            HStack(spacing: 16) {
                // Left side - Status
                VStack(spacing: 8) {
                    Image(systemName: data.isSleeping ? "moon.zzz.fill" : "sun.max.fill")
                        .font(.system(size: 40))
                        .foregroundColor(data.isSleeping ? .white : WidgetColors.awakeColor)
                        .shadow(color: data.isSleeping ? WidgetColors.primaryPurple.opacity(0.5) : WidgetColors.warning.opacity(0.5), radius: 10)

                    Text(data.babyName)
                        .font(.headline)
                        .foregroundColor(WidgetColors.textPrimary)

                    if data.isSleeping {
                        Text(data.formattedDuration)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(WidgetColors.textPrimary)
                            .monospacedDigit()
                    } else {
                        Text(WidgetStrings.awake)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(WidgetColors.awakeColor)
                    }
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(WidgetColors.textMuted.opacity(0.3))
                    .frame(width: 1)
                    .padding(.vertical, 12)

                // Right side - Stats
                VStack(alignment: .leading, spacing: 12) {
                    WidgetStatRow(
                        icon: "moon.fill",
                        value: data.formattedTotalSleep,
                        label: WidgetStrings.sleepToday,
                        iconColor: WidgetColors.primaryPurple
                    )

                    WidgetStatRow(
                        icon: "zzz",
                        value: "\(data.todayNapsCount)",
                        label: WidgetStrings.naps,
                        iconColor: WidgetColors.primaryPink
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }
}

// MARK: - Stat Row
struct WidgetStatRow: View {
    let icon: String
    let value: String
    let label: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(WidgetColors.textPrimary)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(WidgetColors.textSecondary)
            }
        }
    }
}

// MARK: - Lock Screen Widgets (iOS 16+)
struct CircularAccessoryWidget: View {
    let data: WidgetSleepData

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                Image(systemName: data.isSleeping ? "moon.zzz.fill" : "sun.max.fill")
                    .font(.system(size: 20))

                if data.isSleeping {
                    Text(shortDuration)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
            }
        }
    }

    var shortDuration: String {
        guard let duration = data.sleepDuration else { return "" }
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}

struct RectangularAccessoryWidget: View {
    let data: WidgetSleepData

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: data.isSleeping ? "moon.zzz.fill" : "sun.max.fill")
                .font(.system(size: 24))

            VStack(alignment: .leading, spacing: 2) {
                Text(data.babyName)
                    .font(.headline)

                if data.isSleeping {
                    Text(WidgetStrings.sleepingFor(data.formattedDuration))
                        .font(.caption)
                } else {
                    Text("\(WidgetStrings.awake) - \(data.formattedTotalSleep)")
                        .font(.caption)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Small", as: .systemSmall) {
    NapletSleepWidget()
} timeline: {
    SleepStatusEntry(date: .now, data: .placeholder)
    SleepStatusEntry(date: .now, data: WidgetSleepData(
        babyName: "Alice",
        isSleeping: true,
        sleepType: "nap",
        sleepStartTime: Date().addingTimeInterval(-1800),
        todayTotalSleepMinutes: 120,
        todayNapsCount: 2,
        lastUpdated: Date()
    ))
}

#Preview("Medium", as: .systemMedium) {
    NapletSleepWidget()
} timeline: {
    SleepStatusEntry(date: .now, data: WidgetSleepData(
        babyName: "Alice",
        isSleeping: true,
        sleepType: "nap",
        sleepStartTime: Date().addingTimeInterval(-1800),
        todayTotalSleepMinutes: 120,
        todayNapsCount: 2,
        lastUpdated: Date()
    ))
}
