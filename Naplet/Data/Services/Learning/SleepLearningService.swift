import Foundation

// MARK: - Sleep Learning Service
/// Servico que analisa o historico de sono e aprende os padroes do bebe
final class SleepLearningService {

    static let shared = SleepLearningService()

    private init() {}

    // MARK: - Calcular Preferencias Aprendidas

    /// Analisa os registros de sono e calcula as preferencias aprendidas
    /// - Parameters:
    ///   - sleepRecords: Registros de sono (ultimos 14 dias recomendado)
    ///   - existingPreferences: Preferencias existentes para atualizar
    /// - Returns: Preferencias atualizadas com dados aprendidos
    func calculateLearnedPreferences(
        from sleepRecords: [SleepRecord],
        existingPreferences: BabySleepPreferences = BabySleepPreferences()
    ) -> BabySleepPreferences {

        var preferences = existingPreferences
        let calendar = Calendar.current

        // Filtrar registros dos ultimos 14 dias
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let recentRecords = sleepRecords.filter { $0.startTime >= fourteenDaysAgo }

        guard !recentRecords.isEmpty else {
            return preferences
        }

        // Contar dias unicos com dados
        let uniqueDays = Set(recentRecords.map { calendar.startOfDay(for: $0.startTime) })
        preferences.daysOfData = uniqueDays.count

        // 1. Calcular horario medio de acordar de manha
        preferences.learnedWakeTime = calculateAverageWakeTime(from: recentRecords)

        // 2. Calcular horario medio de dormir a noite
        preferences.learnedBedtime = calculateAverageBedtime(from: recentRecords)

        // 3. Calcular duracao media de soneca
        preferences.learnedNapDuration = calculateAverageNapDuration(from: recentRecords)

        // 4. Calcular janela de sono media
        preferences.learnedWakeWindow = calculateAverageWakeWindow(from: recentRecords)

        preferences.lastLearningUpdate = Date()

        return preferences
    }

    // MARK: - Calculos Individuais

    /// Calcula o horario medio que o bebe acorda de manha
    private func calculateAverageWakeTime(from records: [SleepRecord]) -> TimeOfDay? {
        let calendar = Calendar.current

        // Pegar o primeiro registro de cada dia (assumindo que e quando acordou)
        // Ou o endTime do sono noturno
        var wakeMinutes: [Int] = []

        // Agrupar por dia
        let groupedByDay = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.startTime)
        }

        for (_, dayRecords) in groupedByDay {
            // Ordenar por horario
            let sorted = dayRecords.sorted { $0.startTime < $1.startTime }

            // Pegar o primeiro registro do dia
            if let first = sorted.first {
                let hour = calendar.component(.hour, from: first.startTime)

                // Se o primeiro registro e antes das 12h, provavelmente acordou antes
                // Estimar que acordou ~1-2h antes da primeira soneca
                if hour < 12 {
                    // Verificar se e sono noturno que terminou
                    if let endTime = first.endTime, first.type == .night {
                        let wakeHour = calendar.component(.hour, from: endTime)
                        let wakeMinute = calendar.component(.minute, from: endTime)
                        if wakeHour >= 5 && wakeHour <= 10 {
                            wakeMinutes.append(wakeHour * 60 + wakeMinute)
                        }
                    }
                }
            }
        }

        // Se nao temos dados de acordar, retornar nil
        guard !wakeMinutes.isEmpty else { return nil }

        let averageMinutes = wakeMinutes.reduce(0, +) / wakeMinutes.count
        return TimeOfDay(hour: averageMinutes / 60, minute: averageMinutes % 60)
    }

    /// Calcula o horario medio que o bebe dorme a noite
    private func calculateAverageBedtime(from records: [SleepRecord]) -> TimeOfDay? {
        let calendar = Calendar.current

        // Filtrar apenas sonos noturnos ou sonos que comecam apos 17h
        let nightRecords = records.filter { record in
            let hour = calendar.component(.hour, from: record.startTime)
            return record.type == .night || hour >= 17
        }

        guard !nightRecords.isEmpty else { return nil }

        var bedtimeMinutes: [Int] = []

        for record in nightRecords {
            let hour = calendar.component(.hour, from: record.startTime)
            let minute = calendar.component(.minute, from: record.startTime)

            // Considerar apenas horarios entre 17h e 23h como bedtime valido
            if hour >= 17 && hour <= 23 {
                bedtimeMinutes.append(hour * 60 + minute)
            }
        }

        guard !bedtimeMinutes.isEmpty else { return nil }

        let averageMinutes = bedtimeMinutes.reduce(0, +) / bedtimeMinutes.count
        return TimeOfDay(hour: averageMinutes / 60, minute: averageMinutes % 60)
    }

    /// Calcula a duracao media de soneca (apenas sonecas, nao sono noturno)
    private func calculateAverageNapDuration(from records: [SleepRecord]) -> Int? {
        let calendar = Calendar.current

        // Filtrar apenas sonecas (nao sono noturno) que foram finalizadas
        let naps = records.filter { record in
            let hour = calendar.component(.hour, from: record.startTime)
            return record.type == .nap && record.endTime != nil && hour < 17
        }

        guard !naps.isEmpty else { return nil }

        var durations: [Int] = []

        for nap in naps {
            if let endTime = nap.endTime {
                let durationMinutes = Int(endTime.timeIntervalSince(nap.startTime) / 60)
                // Considerar apenas sonecas entre 10min e 3h
                if durationMinutes >= 10 && durationMinutes <= 180 {
                    durations.append(durationMinutes)
                }
            }
        }

        guard !durations.isEmpty else { return nil }

        return durations.reduce(0, +) / durations.count
    }

    /// Calcula a janela de sono media (tempo acordado entre sonecas)
    private func calculateAverageWakeWindow(from records: [SleepRecord]) -> Int? {
        let calendar = Calendar.current

        // Agrupar por dia
        let groupedByDay = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.startTime)
        }

        var wakeWindows: [Int] = []

        for (_, dayRecords) in groupedByDay {
            // Ordenar por horario
            let sorted = dayRecords.sorted { $0.startTime < $1.startTime }

            // Calcular tempo entre fim de uma soneca e inicio da proxima
            for i in 0..<(sorted.count - 1) {
                if let endTime = sorted[i].endTime {
                    let nextStart = sorted[i + 1].startTime
                    let wakeMinutes = Int(nextStart.timeIntervalSince(endTime) / 60)

                    // Considerar apenas janelas entre 30min e 6h
                    if wakeMinutes >= 30 && wakeMinutes <= 360 {
                        wakeWindows.append(wakeMinutes)
                    }
                }
            }
        }

        guard !wakeWindows.isEmpty else { return nil }

        return wakeWindows.reduce(0, +) / wakeWindows.count
    }
}
