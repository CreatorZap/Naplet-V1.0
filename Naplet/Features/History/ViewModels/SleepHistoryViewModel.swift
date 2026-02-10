import Foundation
import SwiftUI
import Combine

// MARK: - Data Models for Charts

struct SleepChartData: Identifiable {
    let id = UUID()
    let date: Date
    let totalHours: Double
    let napHours: Double
    let nightHours: Double
    let napCount: Int
}

struct TimeChartData: Identifiable {
    let id = UUID()
    let date: Date
    let timeValue: Double // Hours as decimal (e.g., 7.5 = 7:30)
}

struct NapsChartData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
    let totalDuration: Double
}

struct DailySleepRecord: Identifiable {
    let id = UUID()
    let date: Date
    let totalSleepMinutes: Double
    let napCount: Int
    let nightSleepHours: Double
    let records: [SleepRecord]

    var totalSleepFormatted: String {
        let hours = Int(totalSleepMinutes / 60)
        let minutes = Int(totalSleepMinutes.truncatingRemainder(dividingBy: 60))
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)min"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)min"
        }
    }

    var dateFormatted: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "common.today".localized
        } else if calendar.isDateInYesterday(date) {
            return "common.yesterday".localized
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, d MMM"
            formatter.locale = Locale.current
            return formatter.string(from: date)
        }
    }

    var progressPercentage: Double {
        // 14 hours = 100% (recommended total sleep for babies)
        min(totalSleepMinutes / (14 * 60), 1.0)
    }
}

// MARK: - ViewModel

@MainActor
class SleepHistoryViewModel: ObservableObject {
    @Published var sleepData: [SleepChartData] = []
    @Published var wakeTimeData: [TimeChartData] = []
    @Published var bedtimeData: [TimeChartData] = []
    @Published var napsData: [NapsChartData] = []
    @Published var dailyRecords: [DailySleepRecord] = []
    @Published var isLoading = false
    @Published var currentBaby: Baby?
    
    private let sleepRepository = SleepRepository()
    private var allRecords: [SleepRecord] = []
    private var selectedDays: Int = 7
    
    // MARK: - Computed Properties
    
    var dateRangeFormatted: String {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -selectedDays, to: endDate) ?? endDate
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale.current
        
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    var averageSleepHours: Double {
        guard !sleepData.isEmpty else { return 0 }
        let total = sleepData.reduce(0) { $0 + $1.totalHours }
        return total / Double(sleepData.count)
    }
    
    var averageSleepFormatted: String {
        let hours = Int(averageSleepHours)
        let minutes = Int((averageSleepHours - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }
    
    var averageNapsPerDay: Double {
        guard !napsData.isEmpty else { return 0 }
        let total = napsData.reduce(0) { $0 + $1.count }
        return Double(total) / Double(napsData.count)
    }
    
    var nightSleepPercentage: Double {
        guard !sleepData.isEmpty else { return 0.7 }
        let totalNight = sleepData.reduce(0) { $0 + $1.nightHours }
        let totalAll = sleepData.reduce(0) { $0 + $1.totalHours }
        guard totalAll > 0 else { return 0.7 }
        return totalNight / totalAll
    }
    
    var averageWakeTime: Double {
        guard !wakeTimeData.isEmpty else { return 7.0 }
        let total = wakeTimeData.reduce(0) { $0 + $1.timeValue }
        return total / Double(wakeTimeData.count)
    }
    
    var averageWakeTimeFormatted: String {
        formatTimeValue(averageWakeTime)
    }
    
    var averageBedtime: Double {
        guard !bedtimeData.isEmpty else { return 20.0 }
        let total = bedtimeData.reduce(0) { $0 + $1.timeValue }
        return total / Double(bedtimeData.count)
    }
    
    var averageBedtimeFormatted: String {
        formatTimeValue(averageBedtime)
    }
    
    var bestDaySleepFormatted: String {
        guard let bestDay = sleepData.max(by: { $0.totalHours < $1.totalHours }) else {
            return "-"
        }
        let hours = Int(bestDay.totalHours)
        let minutes = Int((bestDay.totalHours - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }
    
    var totalRecords: Int {
        allRecords.count
    }
    
    var totalNaps: Int {
        allRecords.filter { $0.type == .nap }.count
    }
    
    var averageNapDurationFormatted: String {
        let naps = allRecords.filter { $0.type == .nap && $0.endTime != nil }
        guard !naps.isEmpty else { return "-" }
        
        let totalMinutes = naps.reduce(0) { $0 + ($1.endTime?.timeIntervalSince($1.startTime) ?? 0) / 60 }
        let avgMinutes = totalMinutes / Double(naps.count)
        
        let hours = Int(avgMinutes / 60)
        let minutes = Int(avgMinutes.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var earliestWakeTimeFormatted: String {
        guard let earliest = wakeTimeData.min(by: { $0.timeValue < $1.timeValue }) else {
            return "-"
        }
        return formatTimeValue(earliest.timeValue)
    }
    
    var latestWakeTimeFormatted: String {
        guard let latest = wakeTimeData.max(by: { $0.timeValue < $1.timeValue }) else {
            return "-"
        }
        return formatTimeValue(latest.timeValue)
    }
    
    var averageNightSleepFormatted: String {
        let nightRecords = allRecords.filter { $0.type == .night && $0.endTime != nil }
        guard !nightRecords.isEmpty else { return "-" }
        
        let totalMinutes = nightRecords.reduce(0) { $0 + ($1.endTime?.timeIntervalSince($1.startTime) ?? 0) / 60 }
        let avgMinutes = totalMinutes / Double(nightRecords.count)
        
        let hours = Int(avgMinutes / 60)
        let minutes = Int(avgMinutes.truncatingRemainder(dividingBy: 60))
        return "\(hours)h \(minutes)m"
    }
    
    // MARK: - Methods
    
    func loadData(days: Int = 7) async {
        isLoading = true
        selectedDays = days
        
        defer { isLoading = false }
        
        // Load current baby
        do {
            let babies = try await SupabaseService.shared.client
                .from("babies")
                .select()
                .execute()
                .value as [Baby]
            
            if let baby = babies.first {
                currentBaby = baby
                
                // Load sleep records for the period
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
                
                allRecords = try await sleepRepository.fetchRecords(
                    for: baby.id,
                    from: startDate,
                    to: endDate
                )
                
                processDataForCharts(startDate: startDate, endDate: endDate)
            }
        } catch {
            Logger.error("SleepHistoryViewModel: Error loading data - \(error)")
        }
    }
    
    private func processDataForCharts(startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        
        // Reset all data
        sleepData = []
        wakeTimeData = []
        bedtimeData = []
        napsData = []
        dailyRecords = []
        
        // Group records by day
        var currentDate = startDate
        
        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            let dayRecords = allRecords.filter { record in
                record.startTime >= dayStart && record.startTime < dayEnd
            }
            
            // Calculate total sleep for the day
            var totalMinutes: Double = 0
            var napMinutes: Double = 0
            var nightMinutes: Double = 0
            var napCount = 0
            
            for record in dayRecords {
                guard let endTime = record.endTime else { continue }
                let duration = endTime.timeIntervalSince(record.startTime) / 60
                totalMinutes += duration
                
                if record.type == .nap {
                    napMinutes += duration
                    napCount += 1
                } else {
                    nightMinutes += duration
                }
            }
            
            // Add to sleepData
            sleepData.append(SleepChartData(
                date: currentDate,
                totalHours: totalMinutes / 60,
                napHours: napMinutes / 60,
                nightHours: nightMinutes / 60,
                napCount: napCount
            ))
            
            // Add to napsData
            napsData.append(NapsChartData(
                date: currentDate,
                count: napCount,
                totalDuration: napMinutes / 60
            ))
            
            // Calculate wake time (first wake up from night sleep)
            if let firstMorningWake = dayRecords
                .filter({ $0.type == .night && $0.endTime != nil })
                .sorted(by: { ($0.endTime ?? Date()) < ($1.endTime ?? Date()) })
                .first,
               let wakeTime = firstMorningWake.endTime {
                
                let components = calendar.dateComponents([.hour, .minute], from: wakeTime)
                let timeValue = Double(components.hour ?? 7) + Double(components.minute ?? 0) / 60
                
                wakeTimeData.append(TimeChartData(
                    date: currentDate,
                    timeValue: timeValue
                ))
            }
            
            // Calculate bedtime (last night sleep start)
            if let lastNightSleep = dayRecords
                .filter({ $0.type == .night })
                .sorted(by: { $0.startTime > $1.startTime })
                .first {
                
                let components = calendar.dateComponents([.hour, .minute], from: lastNightSleep.startTime)
                var timeValue = Double(components.hour ?? 20) + Double(components.minute ?? 0) / 60
                
                // Handle times after midnight (adjust to 24+ for proper charting)
                if timeValue < 12 {
                    timeValue += 24
                }
                
                bedtimeData.append(TimeChartData(
                    date: currentDate,
                    timeValue: timeValue
                ))
            }
            
            // Add to daily records
            if totalMinutes > 0 {
                dailyRecords.append(DailySleepRecord(
                    date: currentDate,
                    totalSleepMinutes: totalMinutes,
                    napCount: napCount,
                    nightSleepHours: nightMinutes / 60,
                    records: dayRecords
                ))
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Sort daily records (most recent first)
        dailyRecords.sort { $0.date > $1.date }
    }
    
    private func formatTimeValue(_ value: Double) -> String {
        var adjustedValue = value
        if adjustedValue >= 24 {
            adjustedValue -= 24
        }
        let hours = Int(adjustedValue)
        let minutes = Int((adjustedValue - Double(hours)) * 60)
        return String(format: "%02d:%02d", hours, minutes)
    }
}
