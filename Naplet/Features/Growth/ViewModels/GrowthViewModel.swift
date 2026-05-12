import Foundation
import SwiftUI

// MARK: - Growth ViewModel
@MainActor
class GrowthViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var loadError: String? = nil
    @Published var selectedChartType: GrowthChartType = .weight
    @Published var unit: GrowthUnit = .metric
    @Published var showingAddSheet = false
    @Published var isSaving = false
    @Published var saveError: String? = nil

    // Add form fields
    @Published var addDate: Date = Date()
    @Published var addWeightText: String = ""
    @Published var addHeightText: String = ""
    @Published var addHeadText: String = ""
    @Published var addNotes: String = ""

    // MARK: - Dependencies
    private let repository = GrowthRepository.shared
    let babyId: UUID
    let birthDate: Date

    // MARK: - Init
    init(babyId: UUID, birthDate: Date) {
        self.babyId = babyId
        self.birthDate = birthDate
    }

    // MARK: - Computed Properties

    var records: [GrowthRecord] {
        repository.records
    }

    var sortedRecordsDescending: [GrowthRecord] {
        repository.records.sorted { $0.recordDateValue > $1.recordDateValue }
    }

    var latestWeight: String {
        guard let record = repository.records.last,
              let value = record.weight(in: unit) else {
            return "--"
        }
        return String(format: "%.1f %@", value, unit.weightLabel)
    }

    var latestHeight: String {
        guard let record = repository.records.last,
              let value = record.height(in: unit) else {
            return "--"
        }
        return String(format: "%.1f %@", value, unit.lengthLabel)
    }

    var latestHeadCircumference: String {
        guard let record = repository.records.last,
              let value = record.headCircumference(in: unit) else {
            return "--"
        }
        return String(format: "%.1f %@", value, unit.lengthLabel)
    }

    // MARK: - Chart Data

    func chartDataPoints(for type: GrowthChartType) -> [GrowthDataPoint] {
        let calendar = Calendar.current
        return records.compactMap { record in
            let ageInDays = calendar.dateComponents([.day], from: birthDate, to: record.recordDateValue).day ?? 0
            let value: Double?
            switch type {
            case .weight:
                value = record.weight(in: unit)
            case .height:
                value = record.height(in: unit)
            case .headCircumference:
                value = record.headCircumference(in: unit)
            }
            guard let v = value else { return nil }
            return GrowthDataPoint(ageInDays: max(ageInDays, 0), value: v, date: record.recordDateValue)
        }
    }

    var chartUnitLabel: String {
        switch selectedChartType {
        case .weight:
            return unit.weightLabel
        case .height, .headCircumference:
            return unit.lengthLabel
        }
    }

    // MARK: - Actions

    func loadRecords() async {
        isLoading = true
        loadError = nil

        do {
            _ = try await repository.fetchRecords(babyId: babyId)
        } catch {
            loadError = error.localizedDescription
            #if DEBUG
            print("Error loading growth records: \(error)")
            #endif
        }

        isLoading = false
    }

    func prepareAddRecord() {
        addDate = Date()
        addWeightText = ""
        addHeightText = ""
        addHeadText = ""
        addNotes = ""
        showingAddSheet = true
    }

    func saveRecord() async {
        isSaving = true
        saveError = nil

        let weightKg: Decimal? = parseDecimal(addWeightText, fromUnit: unit, type: .weight)
        let heightCm: Decimal? = parseDecimal(addHeightText, fromUnit: unit, type: .height)
        let headCm: Decimal? = parseDecimal(addHeadText, fromUnit: unit, type: .headCircumference)

        // At least one measurement required
        guard weightKg != nil || heightCm != nil || headCm != nil else {
            isSaving = false
            return
        }

        do {
            _ = try await repository.addRecord(
                babyId: babyId,
                recordDate: addDate,
                weightKg: weightKg,
                heightCm: heightCm,
                headCircumferenceCm: headCm,
                notes: addNotes.isEmpty ? nil : addNotes
            )
            showingAddSheet = false
        } catch {
            saveError = error.localizedDescription
            Logger.error("Error saving growth record: \(error)")
            #if DEBUG
            print("Error saving growth record: \(error)")
            #endif
        }

        isSaving = false
    }

    func deleteRecord(_ record: GrowthRecord) async {
        do {
            try await repository.deleteRecord(recordId: record.id)
        } catch {
            loadError = error.localizedDescription
            #if DEBUG
            print("Error deleting growth record: \(error)")
            #endif
        }
    }

    func toggleUnit() {
        unit = unit == .metric ? .imperial : .metric
    }

    // MARK: - Parse Helpers

    private func parseDecimal(_ text: String, fromUnit: GrowthUnit, type: GrowthChartType) -> Decimal? {
        let cleanText = text.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleanText), value > 0 else { return nil }

        switch fromUnit {
        case .metric:
            return Decimal(value)
        case .imperial:
            switch type {
            case .weight:
                // Convert lb to kg
                return Decimal(value / 2.20462)
            case .height, .headCircumference:
                // Convert inches to cm
                return Decimal(value * 2.54)
            }
        }
    }

    // MARK: - Format Helpers

    func formatValue(_ record: GrowthRecord, type: GrowthChartType) -> String {
        switch type {
        case .weight:
            guard let v = record.weight(in: unit) else { return "--" }
            return String(format: "%.2f %@", v, unit.weightLabel)
        case .height:
            guard let v = record.height(in: unit) else { return "--" }
            return String(format: "%.1f %@", v, unit.lengthLabel)
        case .headCircumference:
            guard let v = record.headCircumference(in: unit) else { return "--" }
            return String(format: "%.1f %@", v, unit.lengthLabel)
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    func ageAtRecord(_ record: GrowthRecord) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: birthDate, to: record.recordDateValue)
        let months = components.month ?? 0
        let days = components.day ?? 0

        if months < 1 {
            return String(format: "growth.age_days".localized, "\(days)")
        } else {
            return String(format: "growth.age_months".localized, "\(months)")
        }
    }
}
