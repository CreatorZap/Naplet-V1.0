import Foundation
import PDFKit
import UIKit

// MARK: - PDF Report Service
class PDFReportService {
    static let shared = PDFReportService()

    private init() {}

    // MARK: - Complete Report Data Structure
    struct CompleteReportData {
        let baby: Baby
        let startDate: Date
        let endDate: Date

        // Sleep
        let sleepRecords: [SleepRecord]
        let totalSleepHours: Double
        let averageSleepPerDay: Double
        let totalNaps: Int
        let averageNapDuration: TimeInterval
        let longestSleep: TimeInterval
        let shortestSleep: TimeInterval
        let qualityDistribution: [SleepRecord.SleepQuality: Int]

        // Feeding
        let feedingRecords: [FeedingRecord]
        let totalFeedings: Int
        let breastFeedingCount: Int
        let breastFeedingMinutes: Int
        let bottleFeedingCount: Int
        let bottleTotalMl: Double
        let solidFeedingCount: Int

        // Diapers
        let diaperRecords: [DiaperRecord]
        let totalDiaperChanges: Int
        let wetCount: Int
        let dirtyCount: Int
        let mixedCount: Int

        // Health - Temperature
        let temperatureRecords: [HealthRecord]
        let highestTemperature: Double?
        let lowestTemperature: Double?
        let feverCount: Int

        // Health - Medications
        let medicationRecords: [HealthRecord]

        // Vaccination
        let appliedVaccinations: [VaccinationWithDetails]
        let pendingVaccinations: [VaccinationWithDetails]
        let overdueVaccinations: [VaccinationWithDetails]
    }

    // MARK: - Legacy Report Data (for backwards compatibility)
    struct ReportData {
        let baby: Baby
        let records: [SleepRecord]
        let startDate: Date
        let endDate: Date
        let totalSleepHours: Double
        let averageSleepPerDay: Double
        let totalNaps: Int
        let averageNapDuration: TimeInterval
        let longestSleep: TimeInterval
        let shortestSleep: TimeInterval
        let qualityDistribution: [SleepRecord.SleepQuality: Int]
    }

    // MARK: - Generate Complete Report Data
    func generateCompleteReportData(
        baby: Baby,
        sleepRecords: [SleepRecord],
        feedingRecords: [FeedingRecord],
        diaperRecords: [DiaperRecord],
        healthRecords: [HealthRecord],
        vaccinationsWithDetails: [VaccinationWithDetails] = [],
        period: TimePeriod
    ) -> CompleteReportData {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -period.days, to: endDate)!

        // Filter records within period
        let filteredSleep = sleepRecords.filter { $0.startTime >= startDate && $0.startTime <= endDate }
        let filteredFeeding = feedingRecords.filter { $0.startTime >= startDate && $0.startTime <= endDate }
        let filteredDiapers = diaperRecords.filter { $0.changedAt >= startDate && $0.changedAt <= endDate }
        let filteredHealth = healthRecords.filter { $0.recordedAt >= startDate && $0.recordedAt <= endDate }

        // Sleep Statistics
        let completedSleep = filteredSleep.filter { $0.endTime != nil }
        let sleepDurations = completedSleep.compactMap { $0.duration }
        let totalSleepSeconds = sleepDurations.reduce(0, +)
        let totalSleepHours = totalSleepSeconds / 3600
        let daysInPeriod = max(period.days, 1)
        let averageSleepPerDay = totalSleepHours / Double(daysInPeriod)

        let naps = completedSleep.filter { $0.type == .nap }
        let napDurations = naps.compactMap { $0.duration }
        let averageNapDuration = napDurations.isEmpty ? 0 : napDurations.reduce(0, +) / Double(napDurations.count)

        var qualityDistribution: [SleepRecord.SleepQuality: Int] = [.good: 0, .restless: 0, .difficult: 0]
        for record in completedSleep {
            if let quality = record.quality {
                qualityDistribution[quality, default: 0] += 1
            }
        }

        // Feeding Statistics
        let completedFeeding = filteredFeeding.filter { $0.endTime != nil }
        let breastRecords = completedFeeding.filter { $0.type == .breast }
        let bottleRecords = completedFeeding.filter { $0.type == .bottle }
        let solidRecords = completedFeeding.filter { $0.type == .solid }

        let totalBreastMinutes = breastRecords.reduce(0) { sum, record in
            sum + (record.durationLeftSeconds ?? 0) + (record.durationRightSeconds ?? 0)
        } / 60

        let totalBottleMl = bottleRecords.reduce(0.0) { sum, record in
            sum + (record.bottleAmountMl ?? 0)
        }

        // Diaper Statistics
        let wetCount = filteredDiapers.filter { $0.content == .wet }.count
        let dirtyCount = filteredDiapers.filter { $0.content == .dirty }.count
        let mixedCount = filteredDiapers.filter { $0.content == .mixed }.count

        // Temperature Statistics
        let temperatureRecords = filteredHealth.filter { $0.type == .temperature }
        let temperatures = temperatureRecords.compactMap { $0.temperatureCelsius }
        let highestTemp = temperatures.max()
        let lowestTemp = temperatures.min()
        let feverCount = temperatures.filter { $0 >= 37.5 }.count

        // Medication Records
        let medicationRecords = filteredHealth.filter { $0.type == .medication }

        // Vaccination Statistics - filter by period for applied
        let appliedVaccinations = vaccinationsWithDetails.filter { detail in
            guard detail.vaccination.status == .completed,
                  let applicationDate = detail.vaccination.applicationDate else { return false }
            return applicationDate >= startDate && applicationDate <= endDate
        }

        // Pending vaccinations (not applied yet)
        let pendingVaccinations = vaccinationsWithDetails.filter { detail in
            detail.vaccination.status == .pending
        }.sorted { $0.vaccine.ageMonths < $1.vaccine.ageMonths }

        // Overdue vaccinations
        let overdueVaccinations = vaccinationsWithDetails.filter { detail in
            detail.isOverdue(babyBirthDate: baby.birthDate)
        }

        return CompleteReportData(
            baby: baby,
            startDate: startDate,
            endDate: endDate,
            sleepRecords: filteredSleep,
            totalSleepHours: totalSleepHours,
            averageSleepPerDay: averageSleepPerDay,
            totalNaps: naps.count,
            averageNapDuration: averageNapDuration,
            longestSleep: sleepDurations.max() ?? 0,
            shortestSleep: sleepDurations.min() ?? 0,
            qualityDistribution: qualityDistribution,
            feedingRecords: filteredFeeding,
            totalFeedings: completedFeeding.count,
            breastFeedingCount: breastRecords.count,
            breastFeedingMinutes: totalBreastMinutes,
            bottleFeedingCount: bottleRecords.count,
            bottleTotalMl: totalBottleMl,
            solidFeedingCount: solidRecords.count,
            diaperRecords: filteredDiapers,
            totalDiaperChanges: filteredDiapers.count,
            wetCount: wetCount,
            dirtyCount: dirtyCount,
            mixedCount: mixedCount,
            temperatureRecords: temperatureRecords,
            highestTemperature: highestTemp,
            lowestTemperature: lowestTemp,
            feverCount: feverCount,
            medicationRecords: medicationRecords,
            appliedVaccinations: appliedVaccinations,
            pendingVaccinations: Array(pendingVaccinations.prefix(5)),
            overdueVaccinations: overdueVaccinations
        )
    }

    // MARK: - Generate Legacy Report Data (backwards compatibility)
    func generateReportData(baby: Baby, records: [SleepRecord], period: TimePeriod) -> ReportData {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -period.days, to: endDate)!

        let filteredRecords = records.filter { record in
            record.startTime >= startDate && record.startTime <= endDate
        }

        let completedRecords = filteredRecords.filter { $0.endTime != nil }
        let durations = completedRecords.compactMap { $0.duration }

        let totalSeconds = durations.reduce(0, +)
        let totalSleepHours = totalSeconds / 3600

        let daysInPeriod = max(period.days, 1)
        let averageSleepPerDay = totalSleepHours / Double(daysInPeriod)

        let naps = completedRecords.filter { $0.type == .nap }
        let napDurations = naps.compactMap { $0.duration }
        let averageNapDuration = napDurations.isEmpty ? 0 : napDurations.reduce(0, +) / Double(napDurations.count)

        var qualityDistribution: [SleepRecord.SleepQuality: Int] = [.good: 0, .restless: 0, .difficult: 0]
        for record in completedRecords {
            if let quality = record.quality {
                qualityDistribution[quality, default: 0] += 1
            }
        }

        return ReportData(
            baby: baby,
            records: filteredRecords,
            startDate: startDate,
            endDate: endDate,
            totalSleepHours: totalSleepHours,
            averageSleepPerDay: averageSleepPerDay,
            totalNaps: naps.count,
            averageNapDuration: averageNapDuration,
            longestSleep: durations.max() ?? 0,
            shortestSleep: durations.min() ?? 0,
            qualityDistribution: qualityDistribution
        )
    }

    // MARK: - Generate Complete PDF
    func generateCompletePDF(from data: CompleteReportData) -> Data {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - (margin * 2)

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let pdfData = pdfRenderer.pdfData { context in
            context.beginPage()
            var yPosition: CGFloat = margin

            // Header
            yPosition = drawCompleteHeader(data: data, yPosition: yPosition, contentWidth: contentWidth, margin: margin)

            // Baby Info Section
            yPosition = drawBabyInfoSection(data: data, yPosition: yPosition, contentWidth: contentWidth, margin: margin)

            // Sleep Section
            yPosition = drawCompleteSleepSection(data: data, yPosition: yPosition, contentWidth: contentWidth, margin: margin, context: context, pageHeight: pageHeight)

            // Feeding Section
            if yPosition > pageHeight - 200 {
                context.beginPage()
                yPosition = margin
            }
            yPosition = drawFeedingSection(data: data, yPosition: yPosition, contentWidth: contentWidth, margin: margin, context: context, pageHeight: pageHeight)

            // Diaper Section
            if yPosition > pageHeight - 150 {
                context.beginPage()
                yPosition = margin
            }
            yPosition = drawDiaperSection(data: data, yPosition: yPosition, contentWidth: contentWidth, margin: margin)

            // Temperature Section
            if yPosition > pageHeight - 150 {
                context.beginPage()
                yPosition = margin
            }
            yPosition = drawTemperatureSection(data: data, yPosition: yPosition, contentWidth: contentWidth, margin: margin, context: context, pageHeight: pageHeight)

            // Medication Section
            if yPosition > pageHeight - 150 {
                context.beginPage()
                yPosition = margin
            }
            yPosition = drawMedicationSection(data: data, yPosition: yPosition, contentWidth: contentWidth, margin: margin, context: context, pageHeight: pageHeight)

            // Vaccination Section
            if yPosition > pageHeight - 150 {
                context.beginPage()
                yPosition = margin
            }
            _ = drawVaccinationSection(data: data, yPosition: yPosition, contentWidth: contentWidth, margin: margin, context: context, pageHeight: pageHeight)

            // Footer
            drawFooter(pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
        }

        return pdfData
    }

    // MARK: - Generate Legacy PDF (backwards compatibility)
    func generatePDF(from data: ReportData) -> Data {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - (margin * 2)

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let pdfData = pdfRenderer.pdfData { context in
            context.beginPage()
            var yPosition: CGFloat = margin

            yPosition = drawHeader(data: data, yPosition: yPosition, contentWidth: contentWidth, margin: margin)
            yPosition = drawSummarySection(data: data, yPosition: yPosition, contentWidth: contentWidth, margin: margin)
            yPosition = drawQualitySection(data: data, yPosition: yPosition, contentWidth: contentWidth, margin: margin)
            yPosition = drawRecommendationsSection(data: data, yPosition: yPosition, contentWidth: contentWidth, margin: margin, context: context, pageHeight: pageHeight)

            if yPosition > pageHeight - 200 {
                context.beginPage()
                yPosition = margin
            }

            _ = drawDailyRecordsSection(data: data, yPosition: yPosition, contentWidth: contentWidth, margin: margin, context: context, pageHeight: pageHeight)
            drawFooter(pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
        }

        return pdfData
    }

    // MARK: - Draw Complete Header
    private func drawCompleteHeader(data: CompleteReportData, yPosition: CGFloat, contentWidth: CGFloat, margin: CGFloat) -> CGFloat {
        var y = yPosition

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 26, weight: .bold),
            .foregroundColor: UIColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 1.0)
        ]

        let title = "pdf.report.title".localized
        title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttributes)
        y += 40

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = Locale.current

        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.darkGray
        ]

        let periodText = "\("pdf.label.period".localized) \(dateFormatter.string(from: data.startDate)) \("pdf.label.to".localized) \(dateFormatter.string(from: data.endDate))"
        periodText.draw(at: CGPoint(x: margin, y: y), withAttributes: subtitleAttributes)
        y += 20

        let generatedText = "\("pdf.label.generated".localized) \(dateFormatter.string(from: Date()))"
        generatedText.draw(at: CGPoint(x: margin, y: y), withAttributes: subtitleAttributes)
        y += 30

        // Separator
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: margin, y: y))
        linePath.addLine(to: CGPoint(x: margin + contentWidth, y: y))
        UIColor.lightGray.setStroke()
        linePath.lineWidth = 1
        linePath.stroke()
        y += 20

        return y
    }

    // MARK: - Draw Baby Info Section
    private func drawBabyInfoSection(data: CompleteReportData, yPosition: CGFloat, contentWidth: CGFloat, margin: CGFloat) -> CGFloat {
        var y = yPosition

        let sectionIcon = "•"
        let sectionTitle = " " + "pdf.section.baby_info".localized

        let iconTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 1.0)
        ]

        (sectionIcon + sectionTitle).draw(at: CGPoint(x: margin, y: y), withAttributes: iconTitleAttributes)
        y += 30

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]

        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        "pdf.label.name".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
        data.baby.name.draw(at: CGPoint(x: margin + 100, y: y), withAttributes: valueAttributes)
        y += 20

        "pdf.label.age".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
        data.baby.ageDescription.draw(at: CGPoint(x: margin + 100, y: y), withAttributes: valueAttributes)
        y += 20

        let birthFormatter = DateFormatter()
        birthFormatter.dateStyle = .long
        birthFormatter.locale = Locale.current

        "pdf.label.birth".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
        birthFormatter.string(from: data.baby.birthDate).draw(at: CGPoint(x: margin + 100, y: y), withAttributes: valueAttributes)
        y += 35

        return y
    }

    // MARK: - Draw Complete Sleep Section
    private func drawCompleteSleepSection(data: CompleteReportData, yPosition: CGFloat, contentWidth: CGFloat, margin: CGFloat, context: UIGraphicsPDFRendererContext, pageHeight: CGFloat) -> CGFloat {
        var y = yPosition

        let sectionIcon = "•"
        let sectionTitle = " " + "pdf.section.sleep".localized

        let iconTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor(red: 0.3, green: 0.3, blue: 0.7, alpha: 1.0)
        ]

        (sectionIcon + sectionTitle).draw(at: CGPoint(x: margin, y: y), withAttributes: iconTitleAttributes)
        y += 25

        if data.sleepRecords.isEmpty {
            let noDataAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 11),
                .foregroundColor: UIColor.gray
            ]
            "pdf.sleep.no_records".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: noDataAttributes)
            return y + 40
        }

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]

        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        let columnWidth = contentWidth / 2

        // Row 1
        "pdf.sleep.total".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
        String(format: "%.1f " + "pdf.hours".localized, data.totalSleepHours).draw(at: CGPoint(x: margin + 110, y: y), withAttributes: valueAttributes)

        "pdf.sleep.daily_average".localized.draw(at: CGPoint(x: margin + columnWidth, y: y), withAttributes: labelAttributes)
        String(format: "%.1f " + "pdf.hours".localized, data.averageSleepPerDay).draw(at: CGPoint(x: margin + columnWidth + 110, y: y), withAttributes: valueAttributes)
        y += 20

        // Row 2
        "pdf.sleep.total_naps".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
        "\(data.totalNaps)".draw(at: CGPoint(x: margin + 110, y: y), withAttributes: valueAttributes)

        "pdf.sleep.average_duration".localized.draw(at: CGPoint(x: margin + columnWidth, y: y), withAttributes: labelAttributes)
        formatDuration(data.averageNapDuration).draw(at: CGPoint(x: margin + columnWidth + 110, y: y), withAttributes: valueAttributes)
        y += 20

        // Row 3
        "pdf.sleep.longest".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
        formatDuration(data.longestSleep).draw(at: CGPoint(x: margin + 110, y: y), withAttributes: valueAttributes)

        "pdf.sleep.shortest".localized.draw(at: CGPoint(x: margin + columnWidth, y: y), withAttributes: labelAttributes)
        formatDuration(data.shortestSleep).draw(at: CGPoint(x: margin + columnWidth + 110, y: y), withAttributes: valueAttributes)
        y += 30

        // Quality bars
        let total = data.qualityDistribution.values.reduce(0, +)
        if total > 0 {
            "pdf.sleep.quality".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
            y += 20

            let qualities: [(SleepRecord.SleepQuality, String, UIColor)] = [
                (.good, "pdf.quality.good".localized, UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)),
                (.restless, "pdf.quality.restless".localized, UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)),
                (.difficult, "pdf.quality.difficult".localized, UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0))
            ]

            for (quality, label, color) in qualities {
                let count = data.qualityDistribution[quality] ?? 0
                let percentage = Double(count) / Double(total)

                label.draw(at: CGPoint(x: margin + 10, y: y + 2), withAttributes: labelAttributes)

                let bgRect = CGRect(x: margin + 70, y: y, width: 150, height: 16)
                UIColor(white: 0.9, alpha: 1.0).setFill()
                UIBezierPath(roundedRect: bgRect, cornerRadius: 3).fill()

                let fillWidth = 150 * CGFloat(percentage)
                if fillWidth > 0 {
                    let fillRect = CGRect(x: margin + 70, y: y, width: fillWidth, height: 16)
                    color.setFill()
                    UIBezierPath(roundedRect: fillRect, cornerRadius: 3).fill()
                }

                let percentText = String(format: "%.0f%%", percentage * 100)
                percentText.draw(at: CGPoint(x: margin + 230, y: y + 2), withAttributes: labelAttributes)
                y += 22
            }
        }

        y += 15
        return y
    }

    // MARK: - Draw Feeding Section
    private func drawFeedingSection(data: CompleteReportData, yPosition: CGFloat, contentWidth: CGFloat, margin: CGFloat, context: UIGraphicsPDFRendererContext, pageHeight: CGFloat) -> CGFloat {
        var y = yPosition

        let sectionIcon = "•"
        let sectionTitle = " " + "pdf.section.feeding".localized

        let iconTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor(red: 0.2, green: 0.6, blue: 0.8, alpha: 1.0)
        ]

        (sectionIcon + sectionTitle).draw(at: CGPoint(x: margin, y: y), withAttributes: iconTitleAttributes)
        y += 25

        if data.feedingRecords.isEmpty {
            let noDataAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 11),
                .foregroundColor: UIColor.gray
            ]
            "pdf.feeding.no_records".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: noDataAttributes)
            return y + 40
        }

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]

        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        "pdf.feeding.total".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
        "\(data.totalFeedings)".draw(at: CGPoint(x: margin + 130, y: y), withAttributes: valueAttributes)
        y += 20

        if data.breastFeedingCount > 0 {
            "pdf.feeding.breastfeeding".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
            "\(data.breastFeedingCount) \("pdf.times".localized) (\(data.breastFeedingMinutes) min total)".draw(at: CGPoint(x: margin + 130, y: y), withAttributes: valueAttributes)
            y += 20
        }

        if data.bottleFeedingCount > 0 {
            "pdf.feeding.bottle".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
            "\(data.bottleFeedingCount) \("pdf.times".localized) (\(Int(data.bottleTotalMl)) ml total)".draw(at: CGPoint(x: margin + 130, y: y), withAttributes: valueAttributes)
            y += 20
        }

        if data.solidFeedingCount > 0 {
            "pdf.feeding.solids".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
            "\(data.solidFeedingCount) \("pdf.times".localized)".draw(at: CGPoint(x: margin + 130, y: y), withAttributes: valueAttributes)
            y += 20
        }

        // Recent feeding records table
        y += 10
        let recentRecords = Array(data.feedingRecords.prefix(10))
        if !recentRecords.isEmpty {
            "pdf.feeding.recent".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
            y += 20

            let headerRect = CGRect(x: margin, y: y, width: contentWidth, height: 18)
            UIColor(red: 0.2, green: 0.6, blue: 0.8, alpha: 1.0).setFill()
            UIBezierPath(roundedRect: headerRect, cornerRadius: 3).fill()

            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
                .foregroundColor: UIColor.white
            ]

            "pdf.table.date".localized.draw(at: CGPoint(x: margin + 5, y: y + 3), withAttributes: headerAttributes)
            "pdf.table.time".localized.draw(at: CGPoint(x: margin + 70, y: y + 3), withAttributes: headerAttributes)
            "pdf.table.type".localized.draw(at: CGPoint(x: margin + 130, y: y + 3), withAttributes: headerAttributes)
            "pdf.table.details".localized.draw(at: CGPoint(x: margin + 220, y: y + 3), withAttributes: headerAttributes)
            y += 22

            let rowAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"

            for (index, record) in recentRecords.enumerated() {
                if index % 2 == 0 {
                    let rowRect = CGRect(x: margin, y: y, width: contentWidth, height: 16)
                    UIColor(white: 0.95, alpha: 1.0).setFill()
                    UIBezierPath(rect: rowRect).fill()
                }

                dateFormatter.string(from: record.startTime).draw(at: CGPoint(x: margin + 5, y: y + 2), withAttributes: rowAttributes)
                timeFormatter.string(from: record.startTime).draw(at: CGPoint(x: margin + 70, y: y + 2), withAttributes: rowAttributes)

                let typeText: String
                switch record.type {
                case .breast: typeText = "pdf.feeding.type.breast".localized
                case .bottle: typeText = "pdf.feeding.type.bottle".localized
                case .solid: typeText = "pdf.feeding.type.solid".localized
                case .pumping: typeText = "pdf.feeding.type.pumping".localized
                }
                typeText.draw(at: CGPoint(x: margin + 130, y: y + 2), withAttributes: rowAttributes)

                var details = ""
                if record.type == .breast {
                    let leftMin = (record.durationLeftSeconds ?? 0) / 60
                    let rightMin = (record.durationRightSeconds ?? 0) / 60
                    if leftMin > 0 || rightMin > 0 {
                        details = "E: \(leftMin)min D: \(rightMin)min"
                    }
                } else if record.type == .bottle, let ml = record.bottleAmountMl {
                    details = "\(Int(ml)) ml"
                }
                details.draw(at: CGPoint(x: margin + 220, y: y + 2), withAttributes: rowAttributes)

                y += 16
            }
        }

        y += 20
        return y
    }

    // MARK: - Draw Diaper Section
    private func drawDiaperSection(data: CompleteReportData, yPosition: CGFloat, contentWidth: CGFloat, margin: CGFloat) -> CGFloat {
        var y = yPosition

        let sectionIcon = "•"
        let sectionTitle = " " + "pdf.section.diapers".localized

        let iconTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        ]

        (sectionIcon + sectionTitle).draw(at: CGPoint(x: margin, y: y), withAttributes: iconTitleAttributes)
        y += 25

        if data.diaperRecords.isEmpty {
            let noDataAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 11),
                .foregroundColor: UIColor.gray
            ]
            "pdf.diaper.no_records".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: noDataAttributes)
            return y + 40
        }

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]

        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        "pdf.diaper.total".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
        "\(data.totalDiaperChanges)".draw(at: CGPoint(x: margin + 120, y: y), withAttributes: valueAttributes)
        y += 20

        let daysInPeriod = max(Calendar.current.dateComponents([.day], from: data.startDate, to: data.endDate).day ?? 1, 1)
        let avgPerDay = Double(data.totalDiaperChanges) / Double(daysInPeriod)

        "pdf.diaper.daily_average".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
        String(format: "%.1f", avgPerDay).draw(at: CGPoint(x: margin + 120, y: y), withAttributes: valueAttributes)
        y += 25

        // Distribution
        "pdf.diaper.distribution".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
        y += 18

        let distributions: [(String, Int, UIColor)] = [
            ("pdf.diaper.wet".localized, data.wetCount, UIColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1.0)),
            ("pdf.diaper.dirty".localized, data.dirtyCount, UIColor(red: 0.7, green: 0.5, blue: 0.3, alpha: 1.0)),
            ("pdf.diaper.mixed".localized, data.mixedCount, UIColor(red: 0.5, green: 0.3, blue: 0.7, alpha: 1.0))
        ]

        for (label, count, color) in distributions where count > 0 {
            let rect = CGRect(x: margin + 10, y: y, width: 10, height: 10)
            color.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 2).fill()

            "\(label): \(count)".draw(at: CGPoint(x: margin + 25, y: y - 1), withAttributes: labelAttributes)
            y += 18
        }

        y += 15
        return y
    }

    // MARK: - Draw Temperature Section
    private func drawTemperatureSection(data: CompleteReportData, yPosition: CGFloat, contentWidth: CGFloat, margin: CGFloat, context: UIGraphicsPDFRendererContext, pageHeight: CGFloat) -> CGFloat {
        var y = yPosition

        let sectionIcon = "•"
        let sectionTitle = " " + "pdf.section.temperature".localized

        let iconTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0)
        ]

        (sectionIcon + sectionTitle).draw(at: CGPoint(x: margin, y: y), withAttributes: iconTitleAttributes)
        y += 25

        if data.temperatureRecords.isEmpty {
            let noDataAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 11),
                .foregroundColor: UIColor.gray
            ]
            "pdf.temperature.no_records".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: noDataAttributes)
            return y + 40
        }

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]

        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        "pdf.temperature.total".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
        "\(data.temperatureRecords.count)".draw(at: CGPoint(x: margin + 130, y: y), withAttributes: valueAttributes)
        y += 20

        if let highest = data.highestTemperature {
            "pdf.temperature.highest".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
            let tempColor = highest >= 37.5 ? UIColor.red : UIColor.black
            let tempAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: tempColor
            ]
            String(format: "%.1f°C", highest).draw(at: CGPoint(x: margin + 130, y: y), withAttributes: tempAttributes)
            y += 20
        }

        if let lowest = data.lowestTemperature {
            "pdf.temperature.lowest".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
            String(format: "%.1f°C", lowest).draw(at: CGPoint(x: margin + 130, y: y), withAttributes: valueAttributes)
            y += 20
        }

        if data.feverCount > 0 {
            let feverAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: UIColor.red
            ]
            "pdf.temperature.fever_records".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
            "\(data.feverCount)".draw(at: CGPoint(x: margin + 180, y: y), withAttributes: feverAttributes)
            y += 20
        }

        // Temperature records table
        y += 10
        let recentTemps = Array(data.temperatureRecords.prefix(10))
        if !recentTemps.isEmpty {
            "pdf.temperature.records".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
            y += 20

            let headerRect = CGRect(x: margin, y: y, width: contentWidth * 0.7, height: 18)
            UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0).setFill()
            UIBezierPath(roundedRect: headerRect, cornerRadius: 3).fill()

            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
                .foregroundColor: UIColor.white
            ]

            "pdf.table.date".localized.draw(at: CGPoint(x: margin + 5, y: y + 3), withAttributes: headerAttributes)
            "pdf.table.time".localized.draw(at: CGPoint(x: margin + 70, y: y + 3), withAttributes: headerAttributes)
            "pdf.temperature.label".localized.draw(at: CGPoint(x: margin + 130, y: y + 3), withAttributes: headerAttributes)
            "pdf.table.status".localized.draw(at: CGPoint(x: margin + 220, y: y + 3), withAttributes: headerAttributes)
            y += 22

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"

            for (index, record) in recentTemps.enumerated() {
                if index % 2 == 0 {
                    let rowRect = CGRect(x: margin, y: y, width: contentWidth * 0.7, height: 16)
                    UIColor(white: 0.95, alpha: 1.0).setFill()
                    UIBezierPath(rect: rowRect).fill()
                }

                let rowAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                    .foregroundColor: UIColor.darkGray
                ]

                dateFormatter.string(from: record.recordedAt).draw(at: CGPoint(x: margin + 5, y: y + 2), withAttributes: rowAttributes)
                timeFormatter.string(from: record.recordedAt).draw(at: CGPoint(x: margin + 70, y: y + 2), withAttributes: rowAttributes)

                if let temp = record.temperatureCelsius {
                    let tempColor = temp >= 37.5 ? UIColor.red : UIColor.darkGray
                    let tempRowAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 9, weight: .medium),
                        .foregroundColor: tempColor
                    ]
                    String(format: "%.1f°C", temp).draw(at: CGPoint(x: margin + 130, y: y + 2), withAttributes: tempRowAttributes)

                    let status = TemperatureStatus.from(celsius: temp)
                    let statusText: String
                    switch status {
                    case .normal: statusText = "pdf.temperature.status.normal".localized
                    case .elevated: statusText = "pdf.temperature.status.elevated".localized
                    case .fever: statusText = "pdf.temperature.status.fever".localized
                    case .highFever: statusText = "pdf.temperature.status.high_fever".localized
                    case .low: statusText = "pdf.temperature.status.low".localized
                    }
                    statusText.draw(at: CGPoint(x: margin + 220, y: y + 2), withAttributes: rowAttributes)
                }

                y += 16
            }
        }

        y += 20
        return y
    }

    // MARK: - Draw Medication Section
    private func drawMedicationSection(data: CompleteReportData, yPosition: CGFloat, contentWidth: CGFloat, margin: CGFloat, context: UIGraphicsPDFRendererContext, pageHeight: CGFloat) -> CGFloat {
        var y = yPosition

        let sectionIcon = "•"
        let sectionTitle = " " + "pdf.section.medications".localized

        let iconTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor(red: 0.0, green: 0.7, blue: 0.8, alpha: 1.0)
        ]

        (sectionIcon + sectionTitle).draw(at: CGPoint(x: margin, y: y), withAttributes: iconTitleAttributes)
        y += 25

        if data.medicationRecords.isEmpty {
            let noDataAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 11),
                .foregroundColor: UIColor.gray
            ]
            "pdf.medication.no_records".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: noDataAttributes)
            return y + 40
        }

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]

        "pdf.medication.total".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.black
        ]
        "\(data.medicationRecords.count)".draw(at: CGPoint(x: margin + 150, y: y), withAttributes: valueAttributes)
        y += 25

        // Medication records table
        let headerRect = CGRect(x: margin, y: y, width: contentWidth, height: 18)
        UIColor(red: 0.0, green: 0.7, blue: 0.8, alpha: 1.0).setFill()
        UIBezierPath(roundedRect: headerRect, cornerRadius: 3).fill()

        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: UIColor.white
        ]

        "pdf.table.date".localized.draw(at: CGPoint(x: margin + 5, y: y + 3), withAttributes: headerAttributes)
        "pdf.table.time".localized.draw(at: CGPoint(x: margin + 70, y: y + 3), withAttributes: headerAttributes)
        "pdf.medication.name".localized.draw(at: CGPoint(x: margin + 130, y: y + 3), withAttributes: headerAttributes)
        "pdf.medication.dosage".localized.draw(at: CGPoint(x: margin + 300, y: y + 3), withAttributes: headerAttributes)
        y += 22

        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let recordsToShow = Array(data.medicationRecords.prefix(20))

        for (index, record) in recordsToShow.enumerated() {
            if y > pageHeight - 60 {
                context.beginPage()
                y = margin
            }

            if index % 2 == 0 {
                let rowRect = CGRect(x: margin, y: y, width: contentWidth, height: 16)
                UIColor(white: 0.95, alpha: 1.0).setFill()
                UIBezierPath(rect: rowRect).fill()
            }

            dateFormatter.string(from: record.recordedAt).draw(at: CGPoint(x: margin + 5, y: y + 2), withAttributes: rowAttributes)
            timeFormatter.string(from: record.recordedAt).draw(at: CGPoint(x: margin + 70, y: y + 2), withAttributes: rowAttributes)
            (record.medicationName ?? "-").draw(at: CGPoint(x: margin + 130, y: y + 2), withAttributes: rowAttributes)
            (record.medicationDose ?? "-").draw(at: CGPoint(x: margin + 300, y: y + 2), withAttributes: rowAttributes)

            y += 16
        }

        if data.medicationRecords.count > recordsToShow.count {
            y += 5
            let moreText = String(format: "pdf.more_records".localized, data.medicationRecords.count - recordsToShow.count)
            let moreAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 9),
                .foregroundColor: UIColor.gray
            ]
            moreText.draw(at: CGPoint(x: margin, y: y), withAttributes: moreAttributes)
            y += 15
        }

        y += 20
        return y
    }

    // MARK: - Draw Vaccination Section
    private func drawVaccinationSection(data: CompleteReportData, yPosition: CGFloat, contentWidth: CGFloat, margin: CGFloat, context: UIGraphicsPDFRendererContext, pageHeight: CGFloat) -> CGFloat {
        var y = yPosition

        let sectionIcon = "•"
        let sectionTitle = " " + "pdf.section.vaccination".localized

        let iconTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor(red: 0.55, green: 0.36, blue: 0.97, alpha: 1.0) // Roxo Naplet
        ]

        (sectionIcon + sectionTitle).draw(at: CGPoint(x: margin, y: y), withAttributes: iconTitleAttributes)
        y += 25

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]

        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        // Applied vaccinations in period
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: UIColor.darkGray
        ]

        "pdf.vaccination.applied_in_period".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: subtitleAttributes)
        y += 20

        if data.appliedVaccinations.isEmpty {
            let noDataAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 11),
                .foregroundColor: UIColor.gray
            ]
            "pdf.vaccination.no_records".localized.draw(at: CGPoint(x: margin + 10, y: y), withAttributes: noDataAttributes)
            y += 25
        } else {
            // Table header for applied vaccinations
            let headerRect = CGRect(x: margin, y: y, width: contentWidth * 0.9, height: 18)
            UIColor(red: 0.55, green: 0.36, blue: 0.97, alpha: 1.0).setFill()
            UIBezierPath(roundedRect: headerRect, cornerRadius: 3).fill()

            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
                .foregroundColor: UIColor.white
            ]

            "pdf.table.date".localized.draw(at: CGPoint(x: margin + 5, y: y + 3), withAttributes: headerAttributes)
            "pdf.vaccination.vaccine".localized.draw(at: CGPoint(x: margin + 70, y: y + 3), withAttributes: headerAttributes)
            "pdf.vaccination.dose".localized.draw(at: CGPoint(x: margin + 250, y: y + 3), withAttributes: headerAttributes)
            "pdf.vaccination.location".localized.draw(at: CGPoint(x: margin + 310, y: y + 3), withAttributes: headerAttributes)
            y += 22

            let rowAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yy"

            for (index, detail) in data.appliedVaccinations.prefix(10).enumerated() {
                if y > pageHeight - 80 {
                    context.beginPage()
                    y = margin
                }

                if index % 2 == 0 {
                    let rowRect = CGRect(x: margin, y: y, width: contentWidth * 0.9, height: 16)
                    UIColor(white: 0.95, alpha: 1.0).setFill()
                    UIBezierPath(rect: rowRect).fill()
                }

                let dateStr = detail.vaccination.applicationDate != nil ? dateFormatter.string(from: detail.vaccination.applicationDate!) : "-"
                dateStr.draw(at: CGPoint(x: margin + 5, y: y + 2), withAttributes: rowAttributes)
                detail.vaccine.localizedName.draw(at: CGPoint(x: margin + 70, y: y + 2), withAttributes: rowAttributes)
                detail.vaccine.doseText.draw(at: CGPoint(x: margin + 250, y: y + 2), withAttributes: rowAttributes)
                (detail.vaccination.location ?? "-").draw(at: CGPoint(x: margin + 310, y: y + 2), withAttributes: rowAttributes)

                y += 16
            }

            if data.appliedVaccinations.count > 10 {
                let moreText = String(format: "pdf.more_vaccines".localized, data.appliedVaccinations.count - 10)
                let moreAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: 9),
                    .foregroundColor: UIColor.gray
                ]
                moreText.draw(at: CGPoint(x: margin, y: y), withAttributes: moreAttributes)
                y += 15
            }

            y += 15
        }

        // Overdue vaccinations (if any)
        if !data.overdueVaccinations.isEmpty {
            if y > pageHeight - 100 {
                context.beginPage()
                y = margin
            }

            let overdueAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0)
            ]

            "pdf.vaccination.overdue".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: overdueAttributes)
            y += 20

            let overdueRowAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1.0)
            ]

            for detail in data.overdueVaccinations.prefix(5) {
                let row = "• \(detail.vaccine.localizedName) - \(detail.vaccine.doseText) (recomendada: \(detail.vaccine.recommendedAgeText))"
                row.draw(at: CGPoint(x: margin + 10, y: y), withAttributes: overdueRowAttributes)
                y += 16
            }
            y += 10
        }

        // Pending vaccinations (next ones)
        if y > pageHeight - 100 {
            context.beginPage()
            y = margin
        }

        "pdf.vaccination.pending".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: subtitleAttributes)
        y += 20

        if data.pendingVaccinations.isEmpty && data.overdueVaccinations.isEmpty {
            let allDoneAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor(red: 0.13, green: 0.77, blue: 0.37, alpha: 1.0) // Verde
            ]
            "pdf.vaccination.all_done".localized.draw(at: CGPoint(x: margin + 10, y: y), withAttributes: allDoneAttributes)
            y += 25
        } else if !data.pendingVaccinations.isEmpty {
            for detail in data.pendingVaccinations.prefix(5) {
                let recommendedDate = detail.recommendedDate(babyBirthDate: data.baby.birthDate)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM/yyyy"
                dateFormatter.locale = Locale.current

                let row = "• \(detail.vaccine.localizedName) - \(detail.vaccine.doseText) (\("pdf.vaccination.from".localized) \(dateFormatter.string(from: recommendedDate)))"
                row.draw(at: CGPoint(x: margin + 10, y: y), withAttributes: labelAttributes)
                y += 16
            }
        }

        y += 20
        return y
    }

    // MARK: - Legacy Draw Methods (unchanged for backwards compatibility)

    private func drawHeader(data: ReportData, yPosition: CGFloat, contentWidth: CGFloat, margin: CGFloat) -> CGFloat {
        var y = yPosition

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 1.0)
        ]

        let title = "pdf.sleep_report.title".localized
        title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttributes)
        y += 35

        let babyInfoAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor.darkGray
        ]

        let babyInfo = "\(data.baby.name) - \(data.baby.ageDescription)"
        babyInfo.draw(at: CGPoint(x: margin, y: y), withAttributes: babyInfoAttributes)
        y += 22

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = Locale.current

        let periodText = "\("pdf.label.period".localized) \(dateFormatter.string(from: data.startDate)) \("pdf.label.to".localized) \(dateFormatter.string(from: data.endDate))"
        periodText.draw(at: CGPoint(x: margin, y: y), withAttributes: babyInfoAttributes)
        y += 40

        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: margin, y: y))
        linePath.addLine(to: CGPoint(x: margin + contentWidth, y: y))
        UIColor.lightGray.setStroke()
        linePath.lineWidth = 1
        linePath.stroke()
        y += 20

        return y
    }

    private func drawSummarySection(data: ReportData, yPosition: CGFloat, contentWidth: CGFloat, margin: CGFloat) -> CGFloat {
        var y = yPosition

        let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        "pdf.summary.title".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: sectionTitleAttributes)
        y += 30

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]

        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        let columnWidth = contentWidth / 2
        let rowHeight: CGFloat = 25

        "pdf.sleep.total".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
        String(format: "%.1f " + "pdf.hours".localized, data.totalSleepHours).draw(at: CGPoint(x: margin + 120, y: y), withAttributes: valueAttributes)

        "pdf.sleep.daily_average".localized.draw(at: CGPoint(x: margin + columnWidth, y: y), withAttributes: labelAttributes)
        String(format: "%.1f " + "pdf.hours".localized, data.averageSleepPerDay).draw(at: CGPoint(x: margin + columnWidth + 120, y: y), withAttributes: valueAttributes)
        y += rowHeight

        "pdf.sleep.total_naps".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
        "\(data.totalNaps)".draw(at: CGPoint(x: margin + 120, y: y), withAttributes: valueAttributes)

        "pdf.sleep.average_duration".localized.draw(at: CGPoint(x: margin + columnWidth, y: y), withAttributes: labelAttributes)
        formatDuration(data.averageNapDuration).draw(at: CGPoint(x: margin + columnWidth + 120, y: y), withAttributes: valueAttributes)
        y += rowHeight

        "pdf.sleep.longest".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttributes)
        formatDuration(data.longestSleep).draw(at: CGPoint(x: margin + 120, y: y), withAttributes: valueAttributes)

        "pdf.sleep.shortest".localized.draw(at: CGPoint(x: margin + columnWidth, y: y), withAttributes: labelAttributes)
        formatDuration(data.shortestSleep).draw(at: CGPoint(x: margin + columnWidth + 120, y: y), withAttributes: valueAttributes)
        y += 40

        return y
    }

    private func drawQualitySection(data: ReportData, yPosition: CGFloat, contentWidth: CGFloat, margin: CGFloat) -> CGFloat {
        var y = yPosition

        let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        "pdf.sleep.quality".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: sectionTitleAttributes)
        y += 30

        let total = data.qualityDistribution.values.reduce(0, +)
        guard total > 0 else {
            let noDataAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.gray
            ]
            "pdf.quality.no_records".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: noDataAttributes)
            return y + 40
        }

        let barWidth: CGFloat = 200
        let barHeight: CGFloat = 20
        let spacing: CGFloat = 8

        let qualities: [(SleepRecord.SleepQuality, String, UIColor)] = [
            (.good, "pdf.quality.good".localized, UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)),
            (.restless, "pdf.quality.restless".localized, UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)),
            (.difficult, "pdf.quality.difficult".localized, UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0))
        ]

        for (quality, label, color) in qualities {
            let count = data.qualityDistribution[quality] ?? 0
            let percentage = Double(count) / Double(total)

            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor.darkGray
            ]
            label.draw(at: CGPoint(x: margin, y: y + 2), withAttributes: labelAttributes)

            let bgRect = CGRect(x: margin + 70, y: y, width: barWidth, height: barHeight)
            UIColor(white: 0.9, alpha: 1.0).setFill()
            UIBezierPath(roundedRect: bgRect, cornerRadius: 4).fill()

            let fillWidth = barWidth * CGFloat(percentage)
            if fillWidth > 0 {
                let fillRect = CGRect(x: margin + 70, y: y, width: fillWidth, height: barHeight)
                color.setFill()
                UIBezierPath(roundedRect: fillRect, cornerRadius: 4).fill()
            }

            let percentText = String(format: "%.0f%% (%d)", percentage * 100, count)
            let percentAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: UIColor.darkGray
            ]
            percentText.draw(at: CGPoint(x: margin + 280, y: y + 3), withAttributes: percentAttributes)

            y += barHeight + spacing
        }

        y += 20
        return y
    }

    private func drawRecommendationsSection(data: ReportData, yPosition: CGFloat, contentWidth: CGFloat, margin: CGFloat, context: UIGraphicsPDFRendererContext, pageHeight: CGFloat) -> CGFloat {
        var y = yPosition

        let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        "pdf.recommendations.title".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: sectionTitleAttributes)
        y += 25

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]

        let recommendations = generateRecommendations(data: data)

        for recommendation in recommendations {
            if y > pageHeight - 80 {
                context.beginPage()
                y = margin
            }

            let bulletPoint = "• "
            bulletPoint.draw(at: CGPoint(x: margin, y: y), withAttributes: textAttributes)

            let textRect = CGRect(x: margin + 15, y: y, width: contentWidth - 15, height: 50)
            recommendation.draw(with: textRect, options: .usesLineFragmentOrigin, attributes: textAttributes, context: nil)

            y += 35
        }

        y += 15
        return y
    }

    private func drawDailyRecordsSection(data: ReportData, yPosition: CGFloat, contentWidth: CGFloat, margin: CGFloat, context: UIGraphicsPDFRendererContext, pageHeight: CGFloat) -> CGFloat {
        var y = yPosition

        let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        "pdf.daily_records.title".localized.draw(at: CGPoint(x: margin, y: y), withAttributes: sectionTitleAttributes)
        y += 25

        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: UIColor.white
        ]

        let headerRect = CGRect(x: margin, y: y, width: contentWidth, height: 20)
        UIColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 1.0).setFill()
        UIBezierPath(roundedRect: headerRect, cornerRadius: 4).fill()

        let columns: [(String, CGFloat)] = [
            ("pdf.table.date".localized, margin + 5),
            ("pdf.table.type".localized, margin + 80),
            ("pdf.table.start".localized, margin + 140),
            ("pdf.table.end".localized, margin + 200),
            ("pdf.table.duration".localized, margin + 260),
            ("pdf.table.quality".localized, margin + 330)
        ]

        for (title, x) in columns {
            title.draw(at: CGPoint(x: x, y: y + 4), withAttributes: headerAttributes)
        }
        y += 25

        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let sortedRecords = data.records.sorted { $0.startTime > $1.startTime }
        let recordsToShow = Array(sortedRecords.prefix(30))

        for (index, record) in recordsToShow.enumerated() {
            if y > pageHeight - 60 {
                context.beginPage()
                y = margin

                let headerRect = CGRect(x: margin, y: y, width: contentWidth, height: 20)
                UIColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 1.0).setFill()
                UIBezierPath(roundedRect: headerRect, cornerRadius: 4).fill()

                for (title, x) in columns {
                    title.draw(at: CGPoint(x: x, y: y + 4), withAttributes: headerAttributes)
                }
                y += 25
            }

            if index % 2 == 0 {
                let rowRect = CGRect(x: margin, y: y, width: contentWidth, height: 18)
                UIColor(white: 0.95, alpha: 1.0).setFill()
                UIBezierPath(rect: rowRect).fill()
            }

            dateFormatter.string(from: record.startTime).draw(at: CGPoint(x: margin + 5, y: y + 3), withAttributes: rowAttributes)

            let typeText = record.type == .nap ? "pdf.sleep.type.nap".localized : "pdf.sleep.type.night".localized
            typeText.draw(at: CGPoint(x: margin + 80, y: y + 3), withAttributes: rowAttributes)

            timeFormatter.string(from: record.startTime).draw(at: CGPoint(x: margin + 140, y: y + 3), withAttributes: rowAttributes)

            if let endTime = record.endTime {
                timeFormatter.string(from: endTime).draw(at: CGPoint(x: margin + 200, y: y + 3), withAttributes: rowAttributes)
            } else {
                "pdf.sleep.in_progress".localized.draw(at: CGPoint(x: margin + 200, y: y + 3), withAttributes: rowAttributes)
            }

            if let duration = record.duration {
                formatDuration(duration).draw(at: CGPoint(x: margin + 260, y: y + 3), withAttributes: rowAttributes)
            }

            if let quality = record.quality {
                let qualityText: String
                switch quality {
                case .good: qualityText = "pdf.quality.good".localized
                case .restless: qualityText = "pdf.quality.restless".localized
                case .difficult: qualityText = "pdf.quality.difficult".localized
                }
                qualityText.draw(at: CGPoint(x: margin + 330, y: y + 3), withAttributes: rowAttributes)
            }

            y += 18
        }

        if recordsToShow.count < data.records.count {
            y += 10
            let moreText = String(format: "pdf.more_records".localized, data.records.count - recordsToShow.count)
            let moreAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 9),
                .foregroundColor: UIColor.gray
            ]
            moreText.draw(at: CGPoint(x: margin, y: y), withAttributes: moreAttributes)
            y += 20
        }

        return y + 20
    }

    private func drawFooter(pageWidth: CGFloat, pageHeight: CGFloat, margin: CGFloat) {
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: UIColor.gray
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current

        let footerText = "\("pdf.footer.generated_by".localized) \(dateFormatter.string(from: Date()))"
        let footerSize = footerText.size(withAttributes: footerAttributes)

        footerText.draw(
            at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: pageHeight - margin + 10),
            withAttributes: footerAttributes
        )
    }

    // MARK: - Helper Methods
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private func generateRecommendations(data: ReportData) -> [String] {
        var recommendations: [String] = []

        let recommendedRange = data.baby.recommendedSleepHours
        let avgSleep = data.averageSleepPerDay

        if avgSleep < recommendedRange.lowerBound {
            recommendations.append("O sono medio diario esta abaixo do recomendado para a idade. Considere antecipar os horarios de soneca.")
        } else if avgSleep > recommendedRange.upperBound {
            recommendations.append("O sono medio diario esta acima do recomendado. Verifique se as sonecas nao estao muito longas.")
        } else {
            recommendations.append("O tempo de sono esta dentro da faixa recomendada para a idade. Continue mantendo a rotina!")
        }

        let goodCount = data.qualityDistribution[.good] ?? 0
        let totalWithQuality = data.qualityDistribution.values.reduce(0, +)

        if totalWithQuality > 0 {
            let goodPercentage = Double(goodCount) / Double(totalWithQuality)
            if goodPercentage < 0.5 {
                recommendations.append("A qualidade do sono pode ser melhorada. Verifique o ambiente (temperatura, luz, ruido) e a rotina pre-sono.")
            }
        }

        let recommendedNaps = data.baby.recommendedNapsPerDay
        let avgNapsPerDay = Double(data.totalNaps) / Double(max((Calendar.current.dateComponents([.day], from: data.startDate, to: data.endDate).day ?? 1), 1))

        if avgNapsPerDay < Double(recommendedNaps.lowerBound) {
            recommendations.append("O numero de sonecas diarias esta abaixo do recomendado. Tente identificar sinais de sono mais cedo.")
        }

        let wakeWindowRange = data.baby.recommendedWakeWindowMinutes
        recommendations.append("Wake window recomendado para \(data.baby.name): \(wakeWindowRange.lowerBound)-\(wakeWindowRange.upperBound) minutos.")

        return recommendations
    }

    // MARK: - Save PDF
    func savePDF(_ data: Data, fileName: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("\(fileName).pdf")

        do {
            try data.write(to: fileURL)
            Logger.info("PDF saved to: \(fileURL)")
            return fileURL
        } catch {
            Logger.error("Failed to save PDF: \(error)")
            return nil
        }
    }
}

// MARK: - Time Period Extension
enum TimePeriod: String, CaseIterable, Identifiable {
    case week = "7 dias"
    case twoWeeks = "14 dias"
    case month = "30 dias"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .week: return 7
        case .twoWeeks: return 14
        case .month: return 30
        }
    }
}
