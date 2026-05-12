import Foundation

// MARK: - Wake Window Calculator
//
// Algoritmo central de janelas de sono baseado em referências pediátricas
// consagradas: Huckleberry, Precious Little Sleep (Alexis Dubief), Taking Cara Babies.
//
// Wake Window = período de tempo acordado ideal entre sonecas. Bebês que
// excedem ficam superestimulados (custa mais dormir). Bebês colocados pra
// dormir antes da janela mínima não estão cansados o suficiente.
//
// Buffer de 15 minutos entre o teto da janela e o estado overdue para evitar
// falsos positivos (variabilidade individual entre bebês).
//
// TODO Sprint futura: DashboardViewModel.wakeWindowProgress deve usar
// WakeWindowCalculator.wakeWindowProgress(...) para fonte única da verdade.
// Hoje o ViewModel usa `baby.recommendedWakeWindow` (escalar) em sua própria
// fórmula. Manter ambos por ora; consolidar quando refatorar o Dashboard.

// MARK: - Status

/// Estado atual da janela de sono. Consumido por WakeWindowCardView e
/// (no futuro) por WakeWindowNotificationManager.
enum WakeWindowStatus {
    case sleeping      // bebê está dormindo agora
    case fresh         // acordou recentemente, abaixo da janela mínima
    case optimal       // dentro da janela ideal (entre min e max)
    case closing       // passou do max, mas ainda dentro do buffer (15min)
    case overdue       // ultrapassou o buffer, sinal de cansaço excessivo
}

// MARK: - Range

/// Faixa de tempo (em minutos) da janela de sono para uma idade.
/// `Equatable` para uso em testes e comparações futuras.
struct WakeWindowRange: Equatable {
    let minMinutes: Int
    let maxMinutes: Int

    var minSeconds: TimeInterval { TimeInterval(minMinutes) * 60 }
    var maxSeconds: TimeInterval { TimeInterval(maxMinutes) * 60 }
}

// MARK: - Calculator

/// Namespace estático com a API pública do algoritmo.
/// Não é instanciável.
enum WakeWindowCalculator {

    /// Buffer entre o teto da janela e o estado overdue.
    /// Compensa variabilidade individual entre bebês (~15 min).
    private static let overdueBufferSeconds: TimeInterval = 15 * 60

    // MARK: - Public API

    /// Janela de sono típica para a idade em meses.
    /// Idades negativas caem no fallback de 0 meses. Idades >= 24 ficam no cap superior.
    ///
    /// Fontes da tabela:
    ///   • Huckleberry — Sleep Schedule Reference
    ///   • Precious Little Sleep (Alexis Dubief) — Wake Window by Age
    ///   • Taking Cara Babies — Newborn to Toddler Sleep Guides
    static func wakeWindow(forAgeInMonths months: Int) -> WakeWindowRange {
        let clamped = max(months, 0)
        switch clamped {
        case 0:        return WakeWindowRange(minMinutes: 45,  maxMinutes: 60)   // recém-nascido
        case 1:        return WakeWindowRange(minMinutes: 60,  maxMinutes: 90)   // 1 mês
        case 2:        return WakeWindowRange(minMinutes: 75,  maxMinutes: 105)  // 2 meses
        case 3:        return WakeWindowRange(minMinutes: 90,  maxMinutes: 120)  // 3 meses
        case 4:        return WakeWindowRange(minMinutes: 105, maxMinutes: 135)  // 4 meses (regressão)
        case 5:        return WakeWindowRange(minMinutes: 120, maxMinutes: 150)  // 5 meses
        case 6...8:    return WakeWindowRange(minMinutes: 150, maxMinutes: 180)  // 6-8m, 2h30-3h
        case 9...11:   return WakeWindowRange(minMinutes: 180, maxMinutes: 240)  // 9-11m, 3h-4h
        case 12...17:  return WakeWindowRange(minMinutes: 240, maxMinutes: 300)  // 12-17m, 4h-5h
        case 18...23:  return WakeWindowRange(minMinutes: 300, maxMinutes: 360)  // 18-23m, 5h-6h
        default:       return WakeWindowRange(minMinutes: 300, maxMinutes: 360)  // 24+ (cap, wake window estabiliza)
        }
    }

    /// Status atual da janela de sono, dado o último despertar e a idade.
    ///
    /// Regras:
    ///   1. `isSleeping == true` → `.sleeping` (independente do resto)
    ///   2. `lastWakeTime == nil` → `.fresh` (sem dado, padrão neutro)
    ///   3. `timeAwake < range.minSeconds` → `.fresh`
    ///   4. `timeAwake ∈ [min, max)` → `.optimal`
    ///   5. `timeAwake ∈ [max, max + 15min)` → `.closing`
    ///   6. `timeAwake >= max + 15min` → `.overdue`
    ///
    /// O parâmetro `sleepStartTime` está reservado para uso futuro (subdivisão de
    /// `.sleeping` por duração do sono atual). Hoje não influencia a lógica.
    static func napWindowStatus(
        lastWakeTime: Date?,
        ageInMonths: Int,
        isSleeping: Bool,
        sleepStartTime: Date?
    ) -> WakeWindowStatus {
        if isSleeping { return .sleeping }
        guard let wakeTime = lastWakeTime else { return .fresh }

        let timeAwake = Date().timeIntervalSince(wakeTime)
        let range = wakeWindow(forAgeInMonths: ageInMonths)

        if timeAwake < range.minSeconds {
            return .fresh
        } else if timeAwake < range.maxSeconds {
            return .optimal
        } else if timeAwake < range.maxSeconds + overdueBufferSeconds {
            return .closing
        } else {
            return .overdue
        }
    }

    /// Progresso na janela (0.0 a 1.5). Normalizado pelo teto da janela (`max`).
    /// API pública para alinhamento futuro com DashboardViewModel.
    ///
    /// - 0.0 se dormindo ou sem `lastWakeTime`
    /// - 1.0 = bebê está exatamente no teto da janela (max)
    /// - >1.0 = passou do teto; cap em 1.5 (150%) para evitar valores explosivos
    static func wakeWindowProgress(
        lastWakeTime: Date?,
        ageInMonths: Int,
        isSleeping: Bool
    ) -> Double {
        if isSleeping { return 0.0 }
        guard let wakeTime = lastWakeTime else { return 0.0 }

        let timeAwake = Date().timeIntervalSince(wakeTime)
        let range = wakeWindow(forAgeInMonths: ageInMonths)
        let progress = timeAwake / range.maxSeconds
        return min(max(progress, 0), 1.5)
    }

    /// Segundos até o bebê entrar em estado overdue.
    /// Útil para o WakeWindowNotificationManager (arquivo 6) agendar alertas
    /// pré-overdue (ex: "30 min antes da janela fechar").
    ///
    /// Retorna `nil` quando:
    ///   - o bebê já está dormindo
    ///   - não há `lastWakeTime` registrado
    ///   - o bebê já entrou em overdue (overshooting)
    static func timeUntilOverdue(
        lastWakeTime: Date?,
        ageInMonths: Int,
        isSleeping: Bool
    ) -> TimeInterval? {
        if isSleeping { return nil }
        guard let wakeTime = lastWakeTime else { return nil }

        let timeAwake = Date().timeIntervalSince(wakeTime)
        let range = wakeWindow(forAgeInMonths: ageInMonths)
        let overdueThreshold = range.maxSeconds + overdueBufferSeconds
        let remaining = overdueThreshold - timeAwake
        return remaining > 0 ? remaining : nil
    }
}
