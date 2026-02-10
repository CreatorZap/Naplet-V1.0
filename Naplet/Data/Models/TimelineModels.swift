import Foundation
import SwiftUI

// MARK: - Timeline Event Type
enum TimelineEventType {
    case wakeUp           // Acordou de manhã
    case napCompleted     // Soneca já realizada
    case napPredicted     // Soneca prevista
    case currentTime      // Momento atual
    case bedtime          // Hora de dormir
    case lastNapCutoff    // Limite para última soneca

    var icon: String {
        switch self {
        case .wakeUp:
            return "sun.max.fill"
        case .napCompleted:
            return "moon.fill"
        case .napPredicted:
            return "moon.stars"
        case .currentTime:
            return "circle.fill"
        case .bedtime:
            return "moon.zzz.fill"
        case .lastNapCutoff:
            return "exclamationmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .wakeUp:
            return NapletColors.warning // Amarelo/laranja
        case .napCompleted:
            return NapletColors.primaryPurple
        case .napPredicted:
            return NapletColors.primaryPurple.opacity(0.5)
        case .currentTime:
            return NapletColors.primaryCyan
        case .bedtime:
            return NapletColors.primaryPink
        case .lastNapCutoff:
            return NapletColors.textMuted
        }
    }
}

// MARK: - Timeline Event
struct TimelineEvent: Identifiable {
    let id = UUID()
    let type: TimelineEventType
    let time: Date
    let endTime: Date? // Para sonecas (duração)
    let label: String
    let sublabel: String?
    let isPast: Bool

    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(time)
    }

    var durationFormatted: String? {
        guard let duration = duration else { return nil }
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)min" : "\(hours)h"
        }
    }

    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
}

// MARK: - Timeline Calculator
struct TimelineCalculator {

    /// Gera a linha do tempo do dia para um bebe usando preferencias inteligentes
    static func generateTimeline(
        for baby: Baby,
        sleepRecords: [SleepRecord],
        wakeTime: Date? = nil
    ) -> [TimelineEvent] {
        var events: [TimelineEvent] = []
        let now = Date()
        let calendar = Calendar.current

        // Filtrar apenas registros de hoje
        let todayRecords = sleepRecords.filter { record in
            calendar.isDateInToday(record.startTime)
        }.sorted { $0.startTime < $1.startTime }

        // 1. Determinar horario que acordou (usando preferencias efetivas)
        let morningWakeTime: Date

        // Verificar se tem sono noturno que terminou hoje
        let nightSleepEnded = todayRecords.first { record in
            record.type == .night && record.endTime != nil
        }

        if let nightSleep = nightSleepEnded, let endTime = nightSleep.endTime {
            // Acordou quando o sono noturno terminou
            morningWakeTime = endTime
        } else if let providedWakeTime = wakeTime {
            morningWakeTime = providedWakeTime
        } else if let firstNap = todayRecords.first(where: { $0.type == .nap }) {
            // Estimar que acordou uma janela de sono antes da primeira soneca
            let wakeWindowSeconds = TimeInterval(baby.effectiveWakeWindow * 60)
            morningWakeTime = firstNap.startTime.addingTimeInterval(-wakeWindowSeconds)
        } else {
            // Usar horario efetivo de acordar (personalizado > aprendido > padrao)
            morningWakeTime = baby.effectiveWakeTime.toDate(on: now)
        }

        // Evento: Acordou (so adicionar se for horario razoavel - apos 4h da manha)
        let wakeHour = calendar.component(.hour, from: morningWakeTime)
        if wakeHour >= 4 && wakeHour <= 12 {
            events.append(TimelineEvent(
                type: .wakeUp,
                time: morningWakeTime,
                endTime: nil,
                label: "timeline.wakeUp".localized,
                sublabel: baby.sleepPreferences.hasReliableLearning ? "timeline.learned".localized : nil,
                isPast: morningWakeTime < now
            ))
        }

        // 2. Adicionar sonecas ja realizadas
        let napRecords = todayRecords.filter { $0.type == .nap }
        for (index, record) in napRecords.enumerated() {
            let napNumber = index + 1
            let isInProgress = record.endTime == nil

            events.append(TimelineEvent(
                type: .napCompleted,
                time: record.startTime,
                endTime: record.endTime,
                label: String(format: "timeline.napNumber".localized, napNumber),
                sublabel: isInProgress ? "timeline.inProgress".localized : nil,
                isPast: !isInProgress
            ))
        }

        // 3. Calcular e adicionar sonecas previstas
        let recommendedNaps = baby.recommendedNapsPerDay
        let avgNaps = (recommendedNaps.lowerBound + recommendedNaps.upperBound) / 2
        let completedNaps = napRecords.count
        let remainingNaps = max(0, avgNaps - completedNaps)

        // Horario limite para ultima soneca (usando preferencia efetiva)
        let cutoffTime = baby.effectiveLastNapCutoff.toDate(on: now)

        if remainingNaps > 0 && now < cutoffTime {
            // Determinar ultimo horario de referencia
            var lastEndTime: Date

            if let lastNap = napRecords.last {
                if let endTime = lastNap.endTime {
                    lastEndTime = endTime
                } else {
                    // Soneca em progresso - estimar fim usando duracao efetiva
                    let napDuration = TimeInterval(baby.effectiveNapDuration * 60)
                    lastEndTime = lastNap.startTime.addingTimeInterval(napDuration)
                }
            } else {
                lastEndTime = morningWakeTime
            }

            // Usar janela de sono e duracao efetivas
            let wakeWindowSeconds = TimeInterval(baby.effectiveWakeWindow * 60)
            let napDurationSeconds = TimeInterval(baby.effectiveNapDuration * 60)

            for i in 0..<remainingNaps {
                let predictedStart = lastEndTime.addingTimeInterval(wakeWindowSeconds)
                let predictedEnd = predictedStart.addingTimeInterval(napDurationSeconds)

                // Nao adicionar sonecas depois do horario de corte
                if predictedStart >= cutoffTime {
                    break
                }

                // Nao adicionar sonecas no passado
                if predictedStart <= now {
                    lastEndTime = predictedEnd
                    continue
                }

                let napNumber = completedNaps + i + 1
                events.append(TimelineEvent(
                    type: .napPredicted,
                    time: predictedStart,
                    endTime: predictedEnd,
                    label: String(format: "timeline.napNumber".localized, napNumber),
                    sublabel: "timeline.predicted".localized,
                    isPast: false
                ))

                lastEndTime = predictedEnd
            }
        }

        // 4. Adicionar horario limite para ultima soneca
        events.append(TimelineEvent(
            type: .lastNapCutoff,
            time: cutoffTime,
            endTime: nil,
            label: "timeline.lastNapCutoff".localized,
            sublabel: nil,
            isPast: cutoffTime < now
        ))

        // 5. Adicionar bedtime (usando preferencia efetiva)
        let bedtime = baby.effectiveBedtime.toDate(on: now)
        events.append(TimelineEvent(
            type: .bedtime,
            time: bedtime,
            endTime: nil,
            label: "timeline.bedtime".localized,
            sublabel: baby.sleepPreferences.customBedtime != nil ? "timeline.custom".localized : nil,
            isPast: bedtime < now
        ))

        // 6. Adicionar indicador de "agora"
        events.append(TimelineEvent(
            type: .currentTime,
            time: now,
            endTime: nil,
            label: "timeline.now".localized,
            sublabel: nil,
            isPast: false
        ))

        // Ordenar por horario
        return events.sorted { $0.time < $1.time }
    }
}
