import Foundation

// MARK: - Medication Schedule
/// Representa um agendamento de medicamento com horários e frequência
struct MedicationSchedule: Identifiable, Codable, Equatable {
    let id: UUID
    let babyId: UUID
    var medicationName: String
    var dose: String?
    var notes: String?
    var frequency: MedicationFrequency
    var reminderTimes: [String] // ["08:00", "14:00", "20:00"]
    var startDate: Date
    var endDate: Date?
    var durationType: DurationType
    var durationDays: Int?
    var dosesRemaining: Int?
    var dosesPerTake: Double
    var lowStockAlert: Int
    var isActive: Bool
    var isPaused: Bool
    var pausedUntil: Date?
    var createdBy: UUID?
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Computed Properties

    /// Verifica se o medicamento está em baixo estoque
    var isLowStock: Bool {
        guard let remaining = dosesRemaining else { return false }
        return remaining <= lowStockAlert
    }

    /// Verifica se o medicamento acabou
    var isOutOfStock: Bool {
        guard let remaining = dosesRemaining else { return false }
        return remaining <= 0
    }

    /// Verifica se o tratamento expirou
    var isExpired: Bool {
        guard let endDate = endDate else { return false }
        return Date() > endDate
    }

    /// Verifica se pode receber lembretes (ativo, não pausado, não expirado)
    var canReceiveReminders: Bool {
        isActive && !isPaused && !isExpired && !isOutOfStock
    }

    /// Próximo horário de lembrete hoje
    var nextReminderToday: Date? {
        let now = Date()
        let calendar = Calendar.current

        for timeString in reminderTimes.sorted() {
            if let time = parseTime(timeString) {
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute

                if let reminderDate = calendar.date(from: components), reminderDate > now {
                    return reminderDate
                }
            }
        }
        return nil
    }

    /// Próximo horário de lembrete (hoje ou amanhã)
    var nextReminder: Date? {
        if let todayReminder = nextReminderToday {
            return todayReminder
        }

        // Se não tiver mais hoje, pegar o primeiro de amanhã
        guard let firstTime = reminderTimes.sorted().first,
              let time = parseTime(firstTime) else {
            return nil
        }

        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) else {
            return nil
        }

        var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        return calendar.date(from: components)
    }

    /// Tempo restante até o próximo lembrete formatado
    var timeUntilNextReminder: String? {
        guard let next = nextReminder else { return nil }

        let now = Date()
        let interval = next.timeIntervalSince(now)

        if interval < 0 { return nil }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 24 {
            return "amanhã"
        } else if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "agora"
        }
    }

    /// Texto descritivo da frequência (chave de localização)
    var frequencyDescription: String {
        frequency.displayName
    }

    /// Chave de localização para duração
    var durationLocalizationKey: String {
        switch durationType {
        case .continuous:
            return "medication.duration.continuous"
        case .days:
            return "medication.duration.days"
        case .untilDate:
            return "medication.duration.until"
        }
    }

    // MARK: - Private Helpers

    private func parseTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString)
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case medicationName = "medication_name"
        case dose
        case notes
        case frequency
        case reminderTimes = "reminder_times"
        case startDate = "start_date"
        case endDate = "end_date"
        case durationType = "duration_type"
        case durationDays = "duration_days"
        case dosesRemaining = "doses_remaining"
        case dosesPerTake = "doses_per_take"
        case lowStockAlert = "low_stock_alert"
        case isActive = "is_active"
        case isPaused = "is_paused"
        case pausedUntil = "paused_until"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        babyId = try container.decode(UUID.self, forKey: .babyId)
        medicationName = try container.decode(String.self, forKey: .medicationName)
        dose = try container.decodeIfPresent(String.self, forKey: .dose)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        frequency = try container.decode(MedicationFrequency.self, forKey: .frequency)
        reminderTimes = try container.decode([String].self, forKey: .reminderTimes)
        durationType = try container.decode(DurationType.self, forKey: .durationType)
        durationDays = try container.decodeIfPresent(Int.self, forKey: .durationDays)
        dosesRemaining = try container.decodeIfPresent(Int.self, forKey: .dosesRemaining)
        dosesPerTake = try container.decodeIfPresent(Double.self, forKey: .dosesPerTake) ?? 1.0
        lowStockAlert = try container.decodeIfPresent(Int.self, forKey: .lowStockAlert) ?? 5
        isActive = try container.decode(Bool.self, forKey: .isActive)
        isPaused = try container.decodeIfPresent(Bool.self, forKey: .isPaused) ?? false
        pausedUntil = try container.decodeIfPresent(Date.self, forKey: .pausedUntil)
        createdBy = try container.decodeIfPresent(UUID.self, forKey: .createdBy)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)

        // Parse dates - Supabase returns DATE as string "YYYY-MM-DD"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        if let startDateString = try? container.decode(String.self, forKey: .startDate) {
            startDate = dateFormatter.date(from: startDateString) ?? Date()
        } else {
            startDate = try container.decode(Date.self, forKey: .startDate)
        }

        if let endDateString = try? container.decodeIfPresent(String.self, forKey: .endDate) {
            endDate = dateFormatter.date(from: endDateString)
        } else {
            endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        }
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        babyId: UUID,
        medicationName: String,
        dose: String? = nil,
        notes: String? = nil,
        frequency: MedicationFrequency,
        reminderTimes: [String],
        startDate: Date = Date(),
        endDate: Date? = nil,
        durationType: DurationType = .continuous,
        durationDays: Int? = nil,
        dosesRemaining: Int? = nil,
        dosesPerTake: Double = 1.0,
        lowStockAlert: Int = 5,
        isActive: Bool = true,
        isPaused: Bool = false,
        pausedUntil: Date? = nil,
        createdBy: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.babyId = babyId
        self.medicationName = medicationName
        self.dose = dose
        self.notes = notes
        self.frequency = frequency
        self.reminderTimes = reminderTimes
        self.startDate = startDate
        self.endDate = endDate
        self.durationType = durationType
        self.durationDays = durationDays
        self.dosesRemaining = dosesRemaining
        self.dosesPerTake = dosesPerTake
        self.lowStockAlert = lowStockAlert
        self.isActive = isActive
        self.isPaused = isPaused
        self.pausedUntil = pausedUntil
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Medication Frequency
/// Frequências disponíveis para medicamentos
enum MedicationFrequency: String, Codable, CaseIterable, Identifiable {
    case every4Hours = "4h"
    case every6Hours = "6h"
    case every8Hours = "8h"
    case every12Hours = "12h"
    case onceDaily = "24h"
    case twiceDaily = "2x"
    case threeTimesDaily = "3x"
    case asNeeded = "sos"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .every4Hours: return "medication.frequency.every4h".localized
        case .every6Hours: return "medication.frequency.every6h".localized
        case .every8Hours: return "medication.frequency.every8h".localized
        case .every12Hours: return "medication.frequency.every12h".localized
        case .onceDaily: return "medication.frequency.onceDaily".localized
        case .twiceDaily: return "medication.frequency.twiceDaily".localized
        case .threeTimesDaily: return "medication.frequency.threeTimesDaily".localized
        case .asNeeded: return "medication.frequency.asNeeded".localized
        case .custom: return "medication.frequency.custom".localized
        }
    }

    var icon: String {
        switch self {
        case .every4Hours, .every6Hours, .every8Hours, .every12Hours:
            return "clock.arrow.2.circlepath"
        case .onceDaily:
            return "sun.max"
        case .twiceDaily:
            return "sun.and.horizon"
        case .threeTimesDaily:
            return "clock.badge.checkmark"
        case .asNeeded:
            return "hand.raised"
        case .custom:
            return "slider.horizontal.3"
        }
    }

    /// Horários sugeridos para cada frequência
    var suggestedTimes: [String] {
        switch self {
        case .every4Hours:
            return ["06:00", "10:00", "14:00", "18:00", "22:00"]
        case .every6Hours:
            return ["06:00", "12:00", "18:00", "00:00"]
        case .every8Hours:
            return ["06:00", "14:00", "22:00"]
        case .every12Hours:
            return ["08:00", "20:00"]
        case .onceDaily:
            return ["09:00"]
        case .twiceDaily:
            return ["08:00", "20:00"]
        case .threeTimesDaily:
            return ["08:00", "14:00", "20:00"]
        case .asNeeded:
            return []
        case .custom:
            return []
        }
    }

    /// Intervalo em horas (para frequências baseadas em intervalo)
    var intervalHours: Int? {
        switch self {
        case .every4Hours: return 4
        case .every6Hours: return 6
        case .every8Hours: return 8
        case .every12Hours: return 12
        case .onceDaily: return 24
        default: return nil
        }
    }
}

// MARK: - Duration Type
/// Tipo de duração do tratamento
enum DurationType: String, Codable, CaseIterable, Identifiable {
    case continuous = "continuous"
    case days = "days"
    case untilDate = "until_date"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .continuous: return "medication.durationType.continuous".localized
        case .days: return "medication.durationType.days".localized
        case .untilDate: return "medication.durationType.untilDate".localized
        }
    }

    var icon: String {
        switch self {
        case .continuous: return "infinity"
        case .days: return "calendar.badge.clock"
        case .untilDate: return "calendar"
        }
    }
}

// MARK: - Medication Log
/// Registro de administração de medicamento
struct MedicationLog: Identifiable, Codable, Equatable {
    let id: UUID
    let scheduleId: UUID
    let babyId: UUID
    var scheduledTime: Date
    var actualTime: Date?
    var status: MedicationLogStatus
    var doseGiven: String?
    var notes: String?
    var snoozeCount: Int
    var snoozedUntil: Date?
    var givenBy: UUID?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case scheduleId = "schedule_id"
        case babyId = "baby_id"
        case scheduledTime = "scheduled_time"
        case actualTime = "actual_time"
        case status
        case doseGiven = "dose_given"
        case notes
        case snoozeCount = "snooze_count"
        case snoozedUntil = "snoozed_until"
        case givenBy = "given_by"
        case createdAt = "created_at"
    }

    init(
        id: UUID = UUID(),
        scheduleId: UUID,
        babyId: UUID,
        scheduledTime: Date,
        actualTime: Date? = nil,
        status: MedicationLogStatus,
        doseGiven: String? = nil,
        notes: String? = nil,
        snoozeCount: Int = 0,
        snoozedUntil: Date? = nil,
        givenBy: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.scheduleId = scheduleId
        self.babyId = babyId
        self.scheduledTime = scheduledTime
        self.actualTime = actualTime
        self.status = status
        self.doseGiven = doseGiven
        self.notes = notes
        self.snoozeCount = snoozeCount
        self.snoozedUntil = snoozedUntil
        self.givenBy = givenBy
        self.createdAt = createdAt
    }
}

// MARK: - Medication Log Status
/// Status do registro de medicamento
enum MedicationLogStatus: String, Codable, CaseIterable, Identifiable {
    case given = "given"
    case skipped = "skipped"
    case snoozed = "snoozed"
    case missed = "missed"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .given: return "medication.status.given".localized
        case .skipped: return "medication.status.skipped".localized
        case .snoozed: return "medication.status.snoozed".localized
        case .missed: return "medication.status.missed".localized
        }
    }

    var icon: String {
        switch self {
        case .given: return "checkmark.circle.fill"
        case .skipped: return "forward.fill"
        case .snoozed: return "clock.badge.exclamationmark"
        case .missed: return "exclamationmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .given: return "success"
        case .skipped: return "warning"
        case .snoozed: return "primaryBlue"
        case .missed: return "error"
        }
    }
}

// MARK: - Snooze Duration
/// Durações disponíveis para adiar medicamento
enum SnoozeDuration: Int, CaseIterable, Identifiable {
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case oneHour = 60

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .fifteenMinutes: return "15 min"
        case .thirtyMinutes: return "30 min"
        case .oneHour: return "1 hora"
        }
    }

    var minutes: Int { rawValue }
}

// MARK: - Insert DTO
/// DTO para inserção de novo schedule
struct MedicationScheduleInsert: Codable {
    let babyId: UUID
    let medicationName: String
    let dose: String?
    let notes: String?
    let frequency: String
    let reminderTimes: [String]
    let startDate: String
    let endDate: String?
    let durationType: String
    let durationDays: Int?
    let dosesRemaining: Int?
    let dosesPerTake: Double
    let lowStockAlert: Int
    let isActive: Bool
    let createdBy: UUID?

    enum CodingKeys: String, CodingKey {
        case babyId = "baby_id"
        case medicationName = "medication_name"
        case dose
        case notes
        case frequency
        case reminderTimes = "reminder_times"
        case startDate = "start_date"
        case endDate = "end_date"
        case durationType = "duration_type"
        case durationDays = "duration_days"
        case dosesRemaining = "doses_remaining"
        case dosesPerTake = "doses_per_take"
        case lowStockAlert = "low_stock_alert"
        case isActive = "is_active"
        case createdBy = "created_by"
    }

    init(from schedule: MedicationSchedule, userId: UUID?) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        self.babyId = schedule.babyId
        self.medicationName = schedule.medicationName
        self.dose = schedule.dose
        self.notes = schedule.notes
        self.frequency = schedule.frequency.rawValue
        self.reminderTimes = schedule.reminderTimes
        self.startDate = dateFormatter.string(from: schedule.startDate)
        self.endDate = schedule.endDate.map { dateFormatter.string(from: $0) }
        self.durationType = schedule.durationType.rawValue
        self.durationDays = schedule.durationDays
        self.dosesRemaining = schedule.dosesRemaining
        self.dosesPerTake = schedule.dosesPerTake
        self.lowStockAlert = schedule.lowStockAlert
        self.isActive = schedule.isActive
        self.createdBy = userId
    }
}

// MARK: - Log Insert DTO
/// DTO para inserção de log de medicamento
struct MedicationLogInsert: Codable {
    let scheduleId: UUID
    let babyId: UUID
    let scheduledTime: Date
    let actualTime: Date?
    let status: String
    let doseGiven: String?
    let notes: String?
    let snoozeCount: Int
    let snoozedUntil: Date?
    let givenBy: UUID?

    enum CodingKeys: String, CodingKey {
        case scheduleId = "schedule_id"
        case babyId = "baby_id"
        case scheduledTime = "scheduled_time"
        case actualTime = "actual_time"
        case status
        case doseGiven = "dose_given"
        case notes
        case snoozeCount = "snooze_count"
        case snoozedUntil = "snoozed_until"
        case givenBy = "given_by"
    }

    init(from log: MedicationLog, userId: UUID?) {
        self.scheduleId = log.scheduleId
        self.babyId = log.babyId
        self.scheduledTime = log.scheduledTime
        self.actualTime = log.actualTime
        self.status = log.status.rawValue
        self.doseGiven = log.doseGiven
        self.notes = log.notes
        self.snoozeCount = log.snoozeCount
        self.snoozedUntil = log.snoozedUntil
        self.givenBy = userId ?? log.givenBy
    }
}
