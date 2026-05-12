import Foundation

// MARK: - Growth Record
// Linha do histórico de crescimento (peso, altura, perímetro cefálico).
// Persistida em `growth_records` no Supabase. Encoder usa snake_case.

struct GrowthRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let babyId: UUID
    let userId: UUID
    let recordDate: String       // "yyyy-MM-dd" em UTC
    var weightKg: Decimal?
    var heightCm: Decimal?
    var headCircumferenceCm: Decimal?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case userId = "user_id"
        case recordDate = "record_date"
        case weightKg = "weight_kg"
        case heightCm = "height_cm"
        case headCircumferenceCm = "head_circumference_cm"
        case notes
    }

    /// Data efetiva (parse de `recordDate`). Cai para `.distantPast` se vier inválida.
    var recordDateValue: Date {
        GrowthRecord.dateParser.date(from: recordDate) ?? .distantPast
    }

    private static let dateParser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: - Unit-aware getters

    /// Peso na unidade pedida. Armazenado em `kg` internamente.
    func weight(in unit: GrowthUnit) -> Double? {
        guard let kg = weightKg.map({ NSDecimalNumber(decimal: $0).doubleValue }) else { return nil }
        return unit == .metric ? kg : kg * 2.20462
    }

    /// Altura na unidade pedida. Armazenada em `cm` internamente.
    func height(in unit: GrowthUnit) -> Double? {
        guard let cm = heightCm.map({ NSDecimalNumber(decimal: $0).doubleValue }) else { return nil }
        return unit == .metric ? cm : cm * 0.393701
    }

    /// Perímetro cefálico na unidade pedida. Armazenado em `cm` internamente.
    func headCircumference(in unit: GrowthUnit) -> Double? {
        guard let cm = headCircumferenceCm.map({ NSDecimalNumber(decimal: $0).doubleValue }) else { return nil }
        return unit == .metric ? cm : cm * 0.393701
    }
}

// MARK: - Insert DTO
// Payload de criação. `id` e timestamps são gerados pelo Supabase.

struct GrowthRecordInsert: Codable {
    let babyId: UUID
    let userId: UUID
    let recordDate: String
    let weightKg: Decimal?
    let heightCm: Decimal?
    let headCircumferenceCm: Decimal?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case babyId = "baby_id"
        case userId = "user_id"
        case recordDate = "record_date"
        case weightKg = "weight_kg"
        case heightCm = "height_cm"
        case headCircumferenceCm = "head_circumference_cm"
        case notes
    }
}

// MARK: - Chart Type
// Tipo de medida visualizada no gráfico de crescimento.

enum GrowthChartType: String, CaseIterable, Identifiable {
    case weight
    case height
    case headCircumference

    var id: String { rawValue }

    /// SF Symbol exibido no seletor do gráfico.
    var iconName: String {
        switch self {
        case .weight:            return "scalemass.fill"
        case .height:            return "ruler.fill"
        case .headCircumference: return "circle.dashed"
        }
    }

    /// Chave de localização. Strings já existem em Localizable.strings:
    ///   growth.chart.weight, growth.chart.height, growth.chart.head
    var titleKey: String {
        switch self {
        case .weight:            return "growth.chart.weight"
        case .height:            return "growth.chart.height"
        case .headCircumference: return "growth.chart.head"
        }
    }
}

// MARK: - Unit System
// Métrico (kg, cm) ou imperial (lb, in). Conversão acontece nos getters do GrowthRecord
// (saída) e em GrowthViewModel.parseDecimal (entrada).

enum GrowthUnit: String, CaseIterable, Identifiable {
    case metric
    case imperial

    var id: String { rawValue }

    var weightLabel: String {
        switch self {
        case .metric:   return "kg"
        case .imperial: return "lb"
        }
    }

    var lengthLabel: String {
        switch self {
        case .metric:   return "cm"
        case .imperial: return "in"
        }
    }
}

// MARK: - Chart Data Point
// Ponto plotado no Swift Charts. `id = UUID()` é OK porque o array é
// re-construído a cada update do GrowthViewModel; não há mutation em-place.

struct GrowthDataPoint: Identifiable {
    let id = UUID()
    let ageInDays: Int
    let value: Double
    let date: Date
}
