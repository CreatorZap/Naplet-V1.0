import Foundation
import SwiftUI

// MARK: - Baby Model
struct Baby: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var birthDate: Date
    var gender: Gender?
    var photoURL: String?
    var createdAt: Date
    var updatedAt: Date
    var ownerId: UUID

    /// Preferencias de sono personalizadas (definidas pelos pais ou aprendidas)
    /// Armazenado localmente, nao sincronizado com Supabase
    var sleepPreferences: BabySleepPreferences = BabySleepPreferences()

    // MARK: - Computed Properties

    var ageInMonths: Int {
        Calendar.current.dateComponents([.month], from: birthDate, to: Date()).month ?? 0
    }

    var ageInWeeks: Int {
        Calendar.current.dateComponents([.weekOfYear], from: birthDate, to: Date()).weekOfYear ?? 0
    }

    var ageDescription: String {
        let months = ageInMonths
        if months < 1 {
            let weeks = ageInWeeks
            if weeks == 0 {
                return "baby.age.newborn".localized
            }
            return weeks == 1 ? "baby.age.1week".localized : "baby.age.weeks".localized(with: weeks)
        } else if months == 1 {
            return "baby.age.1month".localized
        } else if months < 24 {
            return "baby.age.months".localized(with: months)
        } else {
            let years = months / 12
            return years == 1 ? "baby.age.1year".localized : "baby.age.years".localized(with: years)
        }
    }

    /// Primeira letra do nome (para avatar)
    var initial: String {
        String(name.prefix(1)).uppercased()
    }

    /// Verifica se é recém-nascido (0-3 meses)
    var isNewborn: Bool {
        ageInMonths <= 3
    }

    /// Verifica se é bebê (4-12 meses)
    var isInfant: Bool {
        ageInMonths > 3 && ageInMonths <= 12
    }

    /// Verifica se é toddler (1-3 anos)
    var isToddler: Bool {
        ageInMonths > 12 && ageInMonths <= 36
    }

    // MARK: - Wake Window (em minutos)
    var recommendedWakeWindowMinutes: ClosedRange<Int> {
        let months = ageInMonths
        switch months {
        case 0:
            return 45...60
        case 1:
            return 60...90
        case 2:
            return 75...105
        case 3:
            return 75...120
        case 4:
            return 90...150
        case 5...6:
            return 120...180
        case 7...8:
            return 150...210
        case 9...11:
            return 180...240
        case 12...17:
            return 210...300
        case 18...23:
            return 300...360
        default:
            return 360...420
        }
    }

    /// Wake window médio em segundos (para notificações)
    var recommendedWakeWindow: TimeInterval {
        let range = recommendedWakeWindowMinutes
        let averageMinutes = (range.lowerBound + range.upperBound) / 2
        return TimeInterval(averageMinutes * 60)
    }

    // MARK: - Número recomendado de sonecas por dia
    var recommendedNapsPerDay: ClosedRange<Int> {
        let months = ageInMonths
        switch months {
        case 0...2:
            return 4...6
        case 3...4:
            return 3...5
        case 5...6:
            return 3...4
        case 7...8:
            return 2...3
        case 9...14:
            return 2...2
        case 15...23:
            return 1...2
        default:
            return 1...1
        }
    }

    // MARK: - Horario recomendado de dormir (bedtime) por idade
    /// Retorna o horario recomendado de dormir no formato (hora, minuto)
    var recommendedBedtime: (hour: Int, minute: Int) {
        let months = ageInMonths
        switch months {
        case 0...2:
            return (20, 0)  // 20:00 - Recem-nascidos dormem tarde
        case 3...4:
            return (19, 30) // 19:30
        case 5...6:
            return (19, 0)  // 19:00
        case 7...8:
            return (18, 30) // 18:30
        case 9...12:
            return (18, 30) // 18:30
        case 13...18:
            return (19, 0)  // 19:00
        case 19...24:
            return (19, 30) // 19:30
        default:
            return (20, 0)  // 20:00 - Criancas maiores
        }
    }

    /// Horario maximo para a ultima soneca do dia
    /// Depois desse horario, nao deve haver mais sonecas - apenas sono noturno
    var lastNapCutoffTime: (hour: Int, minute: Int) {
        let months = ageInMonths
        switch months {
        case 0...2:
            return (18, 0)  // 18:00 - Ultima soneca ate 18h
        case 3...4:
            return (17, 30) // 17:30
        case 5...6:
            return (17, 0)  // 17:00
        case 7...8:
            return (16, 30) // 16:30
        case 9...12:
            return (16, 0)  // 16:00
        case 13...18:
            return (15, 30) // 15:30
        case 19...24:
            return (15, 0)  // 15:00
        default:
            return (14, 30) // 14:30 - Criancas maiores
        }
    }

    /// Horario recomendado para acordar de manha
    var recommendedWakeTime: (hour: Int, minute: Int) {
        let months = ageInMonths
        switch months {
        case 0...3:
            return (7, 0)   // 7:00 - Flexivel para recem-nascidos
        case 4...12:
            return (6, 30)  // 6:30
        case 13...24:
            return (7, 0)   // 7:00
        default:
            return (7, 0)   // 7:00
        }
    }

    /// Intervalo minimo entre ultima soneca e bedtime (em minutos)
    var minimumWakeBeforeBedtime: Int {
        let months = ageInMonths
        switch months {
        case 0...2:
            return 60   // 1 hora
        case 3...4:
            return 90   // 1.5 horas
        case 5...6:
            return 120  // 2 horas
        case 7...12:
            return 150  // 2.5 horas
        case 13...18:
            return 180  // 3 horas
        default:
            return 210  // 3.5 horas
        }
    }

    // MARK: - Metodos de Verificacao de Horario

    /// Verifica se ainda e horario valido para soneca
    /// - Parameter currentTime: Hora atual (default: agora)
    /// - Returns: true se ainda pode fazer soneca, false se ja e hora de preparar para dormir
    func isNapTimeValid(at currentTime: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let currentMinutes = hour * 60 + minute

        let cutoffMinutes = lastNapCutoffTime.hour * 60 + lastNapCutoffTime.minute

        return currentMinutes < cutoffMinutes
    }

    /// Verifica se e horario de preparar para o sono noturno
    /// - Parameter currentTime: Hora atual (default: agora)
    /// - Returns: true se esta dentro de 1 hora do bedtime
    func isBedtimePreparation(at currentTime: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let currentMinutes = hour * 60 + minute

        let bedtimeMinutes = recommendedBedtime.hour * 60 + recommendedBedtime.minute
        let prepStartMinutes = bedtimeMinutes - 60 // 1 hora antes

        return currentMinutes >= prepStartMinutes && currentMinutes < bedtimeMinutes
    }

    /// Verifica se ja passou do horario de dormir
    /// - Parameter currentTime: Hora atual (default: agora)
    /// - Returns: true se ja passou do bedtime recomendado
    func isPastBedtime(at currentTime: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let currentMinutes = hour * 60 + minute

        let bedtimeMinutes = recommendedBedtime.hour * 60 + recommendedBedtime.minute

        // Considera "passou do bedtime" entre bedtime e meia-noite
        return currentMinutes >= bedtimeMinutes && currentMinutes < 24 * 60
    }

    /// Tipo de sono recomendado para o horario atual
    enum SleepRecommendation {
        case nap           // Hora de soneca
        case prepareBedtime // Preparar para dormir
        case bedtime       // Hora de dormir (sono noturno)
        case pastBedtime   // Ja passou do horario
        case tooEarly      // Muito cedo (madrugada/manha bem cedo)
    }

    func currentSleepRecommendation(at currentTime: Date = Date()) -> SleepRecommendation {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let currentMinutes = hour * 60 + minute

        let wakeMinutes = recommendedWakeTime.hour * 60 + recommendedWakeTime.minute
        let cutoffMinutes = lastNapCutoffTime.hour * 60 + lastNapCutoffTime.minute
        let prepMinutes = (recommendedBedtime.hour * 60 + recommendedBedtime.minute) - 60
        let bedtimeMinutes = recommendedBedtime.hour * 60 + recommendedBedtime.minute

        // Madrugada (0h - 5h) ou antes do horario de acordar
        if currentMinutes < wakeMinutes - 60 {
            return .tooEarly
        }

        // Horario de sonecas (acordar ate cutoff)
        if currentMinutes < cutoffMinutes {
            return .nap
        }

        // Entre cutoff e 1h antes do bedtime - nao fazer soneca, mas ainda nao e hora de dormir
        if currentMinutes < prepMinutes {
            return .nap // Pode ter uma ultima janela de sono curta
        }

        // 1 hora antes do bedtime - preparar
        if currentMinutes < bedtimeMinutes {
            return .prepareBedtime
        }

        // Depois do bedtime mas antes de meia-noite
        if currentMinutes < 24 * 60 {
            return .pastBedtime
        }

        return .tooEarly
    }

    /// Formata o horario de bedtime para exibicao
    var bedtimeFormatted: String {
        String(format: "%02d:%02d", recommendedBedtime.hour, recommendedBedtime.minute)
    }

    /// Formata o horario de ultima soneca para exibicao
    var lastNapCutoffFormatted: String {
        String(format: "%02d:%02d", lastNapCutoffTime.hour, lastNapCutoffTime.minute)
    }

    // MARK: - Metodos com Preferencias Personalizadas

    /// Horario de acordar efetivo (personalizado > aprendido > padrao por idade)
    var effectiveWakeTime: TimeOfDay {
        let defaultTime = TimeOfDay(hour: recommendedWakeTime.hour, minute: recommendedWakeTime.minute)
        return sleepPreferences.effectiveWakeTime(defaultTime: defaultTime)
    }

    /// Horario de dormir efetivo (personalizado > aprendido > padrao por idade)
    var effectiveBedtime: TimeOfDay {
        let defaultTime = TimeOfDay(hour: recommendedBedtime.hour, minute: recommendedBedtime.minute)
        return sleepPreferences.effectiveBedtime(defaultTime: defaultTime)
    }

    /// Duracao de soneca efetiva em minutos (personalizado > aprendido > 60min)
    var effectiveNapDuration: Int {
        return sleepPreferences.effectiveNapDuration(defaultMinutes: 60)
    }

    /// Janela de sono efetiva em minutos (personalizado > aprendido > padrao por idade)
    var effectiveWakeWindow: Int {
        let range = recommendedWakeWindowMinutes
        let defaultMinutes = (range.lowerBound + range.upperBound) / 2
        return sleepPreferences.effectiveWakeWindow(defaultMinutes: defaultMinutes)
    }

    /// Horario limite para ultima soneca efetivo
    var effectiveLastNapCutoff: TimeOfDay {
        // Calcular baseado no bedtime efetivo - tempo minimo acordado antes de dormir
        let bedtime = effectiveBedtime
        let minWakeBeforeBed = minimumWakeBeforeBedtime

        var cutoffMinutes = bedtime.totalMinutes - minWakeBeforeBed
        if cutoffMinutes < 0 { cutoffMinutes += 24 * 60 }

        return TimeOfDay(hour: cutoffMinutes / 60, minute: cutoffMinutes % 60)
    }

    /// Formata o horario de bedtime efetivo para exibicao
    var effectiveBedtimeFormatted: String {
        effectiveBedtime.formatted
    }

    /// Formata o horario de ultima soneca efetivo para exibicao
    var effectiveLastNapCutoffFormatted: String {
        effectiveLastNapCutoff.formatted
    }

    // MARK: - Total de sono recomendado por dia (em horas)
    var recommendedSleepHours: ClosedRange<Double> {
        let months = ageInMonths
        switch months {
        case 0...2:
            return 14...17
        case 3...4:
            return 12...16
        case 5...11:
            return 12...15
        case 12...23:
            return 11...14
        default:
            return 10...13
        }
    }

    // MARK: - Gender Enum
    enum Gender: String, Codable, CaseIterable {
        case male = "male"
        case female = "female"
        case other = "other"

        var displayName: String {
            switch self {
            case .male: return "baby.gender.male".localized
            case .female: return "baby.gender.female".localized
            case .other: return "baby.gender.other".localized
            }
        }

        var icon: String {
            switch self {
            case .male: return "figure.stand"
            case .female: return "figure.stand.dress"
            case .other: return "figure.wave"
            }
        }

        var color: Color {
            switch self {
            case .male: return NapletColors.primaryBlue
            case .female: return NapletColors.primaryPink
            case .other: return NapletColors.primaryPurple
            }
        }
    }

    // MARK: - Init
    init(
        id: UUID = UUID(),
        name: String,
        birthDate: Date,
        gender: Gender? = nil,
        photoURL: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        ownerId: UUID,
        sleepPreferences: BabySleepPreferences = BabySleepPreferences()
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ownerId = ownerId
        self.sleepPreferences = sleepPreferences
    }
}

// MARK: - Supabase Coding Keys
extension Baby {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case birthDate = "birth_date"
        case gender
        case photoURL = "photo_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case ownerId = "owner_id"
    }
    
    // MARK: - Custom Decoder for Supabase date formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        gender = try container.decodeIfPresent(Gender.self, forKey: .gender)
        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        ownerId = try container.decode(UUID.self, forKey: .ownerId)
        
        // Handle birth_date (DATE format: "2024-12-09")
        let birthDateString = try container.decode(String.self, forKey: .birthDate)
        if let date = Baby.dateOnlyFormatter.date(from: birthDateString) {
            birthDate = date
        } else if let date = Baby.iso8601Formatter.date(from: birthDateString) {
            birthDate = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .birthDate, in: container, debugDescription: "Cannot parse birth_date: \(birthDateString)")
        }
        
        // Handle created_at (TIMESTAMPTZ format)
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        createdAt = Baby.parseTimestamp(createdAtString) ?? Date()
        
        // Handle updated_at (TIMESTAMPTZ format)
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        updatedAt = Baby.parseTimestamp(updatedAtString) ?? Date()

        // sleepPreferences nao vem do Supabase, e armazenado localmente
        sleepPreferences = BabySleepPreferences()
    }
    
    // MARK: - Date Formatters
    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static func parseTimestamp(_ string: String) -> Date? {
        // Try ISO8601 with fractional seconds
        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601.date(from: string) {
            return date
        }
        
        // Try ISO8601 without fractional seconds
        iso8601.formatOptions = [.withInternetDateTime]
        if let date = iso8601.date(from: string) {
            return date
        }
        
        // Try Supabase format with timezone offset
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
        if let date = formatter.date(from: string) {
            return date
        }
        
        // Try without microseconds
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        if let date = formatter.date(from: string) {
            return date
        }
        
        // Try Supabase format: "2026-01-19 04:17:36.952047+00"
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSXXXXX"
        if let date = formatter.date(from: string) {
            return date
        }
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssXXXXX"
        return formatter.date(from: string)
    }
}

// MARK: - Mock Data
extension Baby {
    static let preview = Baby(
        name: "Sofia",
        birthDate: Calendar.current.date(byAdding: .month, value: -4, to: Date())!,
        gender: .female,
        ownerId: UUID()
    )

    static let previewList = [
        Baby(name: "Sofia", birthDate: Calendar.current.date(byAdding: .month, value: -4, to: Date())!, gender: .female, ownerId: UUID()),
        Baby(name: "Miguel", birthDate: Calendar.current.date(byAdding: .month, value: -8, to: Date())!, gender: .male, ownerId: UUID())
    ]
}
