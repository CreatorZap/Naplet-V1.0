import WidgetKit
import SwiftUI

// MARK: - Quick Action Provider
struct QuickActionProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickActionEntry {
        QuickActionEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickActionEntry) -> Void) {
        let data = WidgetDataManager.loadWidgetData()
        completion(QuickActionEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickActionEntry>) -> Void) {
        let data = WidgetDataManager.loadWidgetData()
        let entry = QuickActionEntry(date: Date(), data: data)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
        completion(timeline)
    }
}

// MARK: - Quick Action Entry
struct QuickActionEntry: TimelineEntry {
    let date: Date
    let data: WidgetSleepData
}

// MARK: - Quick Action Widget
struct NapletQuickActionWidget: Widget {
    let kind: String = "NapletQuickActionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickActionProvider()) { entry in
            QuickActionWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetColors.background
                }
        }
        .configurationDisplayName(WidgetStrings.quickActionTitle)
        .description(WidgetStrings.quickActionDescription)
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Quick Action Widget View
struct QuickActionWidgetView: View {
    let entry: QuickActionEntry

    var body: some View {
        ZStack {
            // Background gradient
            WidgetColors.gradientCard

            VStack(spacing: 12) {
                // Baby name
                Text(entry.data.babyName)
                    .font(.caption)
                    .foregroundColor(WidgetColors.textSecondary)

                // Action button (Deep Link)
                Link(destination: URL(string: entry.data.isSleeping ? "naplet://stopSleep" : "naplet://startSleep")!) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    entry.data.isSleeping ?
                                    LinearGradient(
                                        colors: [WidgetColors.warning, WidgetColors.awakeColor],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    WidgetColors.gradientPrimary
                                )
                                .frame(width: 60, height: 60)
                                .shadow(
                                    color: entry.data.isSleeping ? WidgetColors.warning.opacity(0.4) : WidgetColors.primaryPurple.opacity(0.4),
                                    radius: 8
                                )

                            Image(systemName: entry.data.isSleeping ? "sun.max.fill" : "moon.zzz.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }

                        Text(entry.data.isSleeping ? WidgetStrings.wakeUp : WidgetStrings.sleep)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(WidgetColors.textPrimary)
                    }
                }

                // Current status
                if entry.data.isSleeping {
                    Text(entry.data.formattedDuration)
                        .font(.caption)
                        .foregroundColor(WidgetColors.primaryPurple)
                        .monospacedDigit()
                }
            }
            .padding()
        }
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    NapletQuickActionWidget()
} timeline: {
    QuickActionEntry(date: .now, data: .placeholder)
    QuickActionEntry(date: .now, data: WidgetSleepData(
        babyName: "Alice",
        isSleeping: true,
        sleepType: "nap",
        sleepStartTime: Date().addingTimeInterval(-1800),
        todayTotalSleepMinutes: 120,
        todayNapsCount: 2,
        lastUpdated: Date()
    ))
}
