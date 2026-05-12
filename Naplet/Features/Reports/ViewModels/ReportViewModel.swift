import Foundation
import SwiftUI
import UIKit

// MARK: - Report ViewModel
@MainActor
class ReportViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var selectedPeriod: TimePeriod = .week
    @Published var isGenerating = false
    @Published var pdfData: Data?
    @Published var showShareSheet = false
    @Published var errorMessage: String?
    @Published var completeReportData: PDFReportService.CompleteReportData?

    // MARK: - Dependencies
    private let pdfService = PDFReportService.shared
    private let sleepRepository = SleepRepository()
    private let feedingRepository = FeedingRepository.shared
    private let diaperRepository = DiaperRepository.shared
    private let healthRepository = HealthRepository.shared
    private let vaccinationRepository = VaccinationRepository.shared

    // MARK: - Input Properties
    let baby: Baby

    // MARK: - Init
    init(baby: Baby) {
        self.baby = baby
    }

    // MARK: - Generate Report
    func generateReport() async {
        isGenerating = true
        errorMessage = nil

        do {
            let calendar = Calendar.current
            let endDate = Date()
            guard let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: endDate) else { return }

            // Fetch all records in parallel
            async let sleepRecordsTask = fetchSleepRecords(startDate: startDate, endDate: endDate)
            async let feedingRecordsTask = fetchFeedingRecords(startDate: startDate, endDate: endDate)
            async let diaperRecordsTask = fetchDiaperRecords(startDate: startDate, endDate: endDate)
            async let healthRecordsTask = fetchHealthRecords(startDate: startDate, endDate: endDate)
            async let vaccinationsTask = fetchVaccinationsWithDetails()

            let (sleepRecords, feedingRecords, diaperRecords, healthRecords, vaccinations) = try await (
                sleepRecordsTask,
                feedingRecordsTask,
                diaperRecordsTask,
                healthRecordsTask,
                vaccinationsTask
            )

            // Generate complete report data
            let data = pdfService.generateCompleteReportData(
                baby: baby,
                sleepRecords: sleepRecords,
                feedingRecords: feedingRecords,
                diaperRecords: diaperRecords,
                healthRecords: healthRecords,
                vaccinationsWithDetails: vaccinations,
                period: selectedPeriod
            )
            completeReportData = data

            // Generate PDF
            let pdf = pdfService.generateCompletePDF(from: data)
            pdfData = pdf

            Logger.info("Complete report generated successfully for \(baby.name)")
        } catch {
            Logger.error("Failed to generate report: \(error)")
            errorMessage = "report.error.generateFailed".localized + ": \(error.localizedDescription)"
        }

        isGenerating = false
    }

    // MARK: - Fetch Sleep Records
    private func fetchSleepRecords(startDate: Date, endDate: Date) async throws -> [SleepRecord] {
        _ = try await sleepRepository.fetchRecords(for: baby.id, from: startDate, to: endDate)
        return sleepRepository.sleepRecords
    }

    // MARK: - Fetch Feeding Records
    private func fetchFeedingRecords(startDate: Date, endDate: Date) async throws -> [FeedingRecord] {
        return try await feedingRepository.fetchRecords(babyId: baby.id, startDate: startDate, endDate: endDate)
    }

    // MARK: - Fetch Diaper Records
    private func fetchDiaperRecords(startDate: Date, endDate: Date) async throws -> [DiaperRecord] {
        return try await diaperRepository.fetchRecords(babyId: baby.id, startDate: startDate, endDate: endDate)
    }

    // MARK: - Fetch Health Records
    private func fetchHealthRecords(startDate: Date, endDate: Date) async throws -> [HealthRecord] {
        return try await healthRepository.fetchRecords(babyId: baby.id, startDate: startDate, endDate: endDate)
    }

    // MARK: - Fetch Vaccinations
    private func fetchVaccinationsWithDetails() async throws -> [VaccinationWithDetails] {
        return try await vaccinationRepository.fetchVaccinationsWithDetails(babyId: baby.id)
    }

    // MARK: - Share PDF
    func sharePDF() {
        guard pdfData != nil else {
            errorMessage = "report.error.noReport".localized
            return
        }
        showShareSheet = true
    }

    // MARK: - Save PDF
    func savePDF() -> URL? {
        guard let data = pdfData else {
            errorMessage = "report.error.noReport".localized
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "Naplet_\(baby.name)_\(dateFormatter.string(from: Date()))"

        return pdfService.savePDF(data, fileName: fileName)
    }

    // MARK: - Preview Data
    var previewTotalSleep: String {
        guard let data = completeReportData else { return "--" }
        return String(format: "%.1fh", data.totalSleepHours)
    }

    var previewAverageSleep: String {
        guard let data = completeReportData else { return "--" }
        return String(format: "report.sleepPerDay".localized, data.averageSleepPerDay)
    }

    var previewTotalNaps: String {
        guard let data = completeReportData else { return "--" }
        return "\(data.totalNaps)"
    }

    var previewQuality: String {
        guard let data = completeReportData else { return "--" }
        let total = data.qualityDistribution.values.reduce(0, +)
        guard total > 0 else { return "--" }

        let goodCount = data.qualityDistribution[.good] ?? 0
        let percentage = Double(goodCount) / Double(total) * 100
        return String(format: "report.qualityGood".localized, percentage)
    }

    // MARK: - Feeding Preview Data
    var previewTotalFeedings: String {
        guard let data = completeReportData else { return "--" }
        return "\(data.totalFeedings)"
    }

    var previewBreastFeedings: String {
        guard let data = completeReportData else { return "--" }
        return "\(data.breastFeedingCount)"
    }

    var previewBottleFeedings: String {
        guard let data = completeReportData else { return "--" }
        return "\(data.bottleFeedingCount)"
    }

    // MARK: - Diaper Preview Data
    var previewTotalDiapers: String {
        guard let data = completeReportData else { return "--" }
        return "\(data.totalDiaperChanges)"
    }

    // MARK: - Health Preview Data
    var previewTemperatureCount: String {
        guard let data = completeReportData else { return "--" }
        return "\(data.temperatureRecords.count)"
    }

    var previewMedicationCount: String {
        guard let data = completeReportData else { return "--" }
        return "\(data.medicationRecords.count)"
    }

    var previewFeverCount: String {
        guard let data = completeReportData else { return "--" }
        return "\(data.feverCount)"
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // iPad requer popover configurado para nao crashar
        if let popover = controller.popoverPresentationController {
            popover.permittedArrowDirections = .any
            popover.sourceView = UIView()
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Atualiza sourceRect para o centro da tela no iPad
        if let popover = uiViewController.popoverPresentationController,
           let sourceView = popover.sourceView {
            popover.sourceRect = sourceView.bounds
        }
    }
}
