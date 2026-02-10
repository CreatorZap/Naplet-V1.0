import Foundation

// MARK: - Baby Sleep Preferences
/// Preferencias de sono personalizadas do bebe
/// Pode ser definido manualmente pelos pais ou calculado automaticamente
struct BabySleepPreferences: Codable, Equatable {

    // MARK: - Horarios Personalizados (definidos pelos pais)

    /// Horario que o bebe costuma acordar de manha (nil = usar padrao por idade)
    var customWakeTime: TimeOfDay?

    /// Horario que o bebe costuma dormir a noite (nil = usar padrao por idade)
    var customBedtime: TimeOfDay?

    /// Duracao media de soneca em minutos (nil = usar padrao 60min)
    var customNapDuration: Int?

    /// Janela de sono personalizada em minutos (nil = usar padrao por idade)
    var customWakeWindow: Int?

    // MARK: - Dados Aprendidos (calculados automaticamente)

    /// Horario medio que acorda (calculado do historico)
    var learnedWakeTime: TimeOfDay?

    /// Horario medio que dorme (calculado do historico)
    var learnedBedtime: TimeOfDay?

    /// Duracao media real de soneca em minutos
    var learnedNapDuration: Int?

    /// Janela de sono media real em minutos
    var learnedWakeWindow: Int?

    /// Data da ultima atualizacao dos dados aprendidos
    var lastLearningUpdate: Date?

    /// Numero de dias de dados usados no aprendizado
    var daysOfData: Int = 0

    // MARK: - Metodos de Acesso (prioriza custom > learned > default)

    /// Retorna o horario de acordar a usar (custom > learned > default)
    func effectiveWakeTime(defaultTime: TimeOfDay) -> TimeOfDay {
        return customWakeTime ?? learnedWakeTime ?? defaultTime
    }

    /// Retorna o horario de dormir a usar (custom > learned > default)
    func effectiveBedtime(defaultTime: TimeOfDay) -> TimeOfDay {
        return customBedtime ?? learnedBedtime ?? defaultTime
    }

    /// Retorna a duracao de soneca a usar (custom > learned > default 60min)
    func effectiveNapDuration(defaultMinutes: Int = 60) -> Int {
        return customNapDuration ?? learnedNapDuration ?? defaultMinutes
    }

    /// Retorna a janela de sono a usar (custom > learned > default)
    func effectiveWakeWindow(defaultMinutes: Int) -> Int {
        return customWakeWindow ?? learnedWakeWindow ?? defaultMinutes
    }

    /// Verifica se tem dados suficientes para aprendizado confiavel (minimo 3 dias)
    var hasReliableLearning: Bool {
        return daysOfData >= 3
    }

    /// Verifica se os dados de aprendizado estao atualizados (ultimas 24h)
    var isLearningUpToDate: Bool {
        guard let lastUpdate = lastLearningUpdate else { return false }
        return Date().timeIntervalSince(lastUpdate) < 24 * 60 * 60
    }

    // MARK: - Init

    init() {}
}

// MARK: - Time of Day (Helper)
struct TimeOfDay: Codable, Equatable {
    var hour: Int
    var minute: Int

    var totalMinutes: Int {
        return hour * 60 + minute
    }

    var formatted: String {
        return String(format: "%02d:%02d", hour, minute)
    }

    init(hour: Int, minute: Int) {
        self.hour = max(0, min(23, hour))
        self.minute = max(0, min(59, minute))
    }

    init(from date: Date) {
        let calendar = Calendar.current
        self.hour = calendar.component(.hour, from: date)
        self.minute = calendar.component(.minute, from: date)
    }

    func toDate(on referenceDate: Date = Date()) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? referenceDate
    }
}
