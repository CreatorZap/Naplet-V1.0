import Foundation
import Supabase

// MARK: - Medication Schedule Repository
/// Repositório para gerenciar agendamentos de medicamentos
@MainActor
final class MedicationScheduleRepository: ObservableObject {

    // MARK: - Singleton
    static let shared = MedicationScheduleRepository()

    // MARK: - Published Properties
    @Published var activeSchedules: [MedicationSchedule] = []
    @Published var todayLogs: [MedicationLog] = []

    // MARK: - Private Properties
    private let schedulesTable = "medication_schedules"
    private let logsTable = "medication_logs"
    private let supabase = SupabaseService.shared

    // MARK: - Init
    private init() {}

    // MARK: - Schedule CRUD

    /// Cria um novo agendamento de medicamento
    func createSchedule(_ schedule: MedicationSchedule) async throws -> MedicationSchedule {
        guard let userId = supabase.currentUserId else {
            throw MedicationScheduleError.notAuthenticated
        }

        let insertDTO = MedicationScheduleInsert(from: schedule, userId: userId)

        let response: MedicationSchedule = try await supabase.client
            .from(schedulesTable)
            .insert(insertDTO)
            .select()
            .single()
            .execute()
            .value

        // Atualiza lista local
        activeSchedules.append(response)
        activeSchedules.sort { ($0.nextReminder ?? .distantFuture) < ($1.nextReminder ?? .distantFuture) }

        Logger.info("Created medication schedule: \(response.medicationName)")
        return response
    }

    /// Busca todos os schedules ativos de um bebê
    func fetchActiveSchedules(babyId: UUID) async throws -> [MedicationSchedule] {
        let schedules: [MedicationSchedule] = try await supabase.client
            .from(schedulesTable)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .eq("is_active", value: true)
            .order("created_at", ascending: false)
            .execute()
            .value

        activeSchedules = schedules.filter { $0.canReceiveReminders }
        activeSchedules.sort { ($0.nextReminder ?? .distantFuture) < ($1.nextReminder ?? .distantFuture) }

        Logger.info("Fetched \(schedules.count) medication schedules")
        return schedules
    }

    /// Busca um schedule específico
    func fetchSchedule(id: UUID) async throws -> MedicationSchedule {
        let schedule: MedicationSchedule = try await supabase.client
            .from(schedulesTable)
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        return schedule
    }

    /// Atualiza um schedule
    func updateSchedule(_ schedule: MedicationSchedule) async throws -> MedicationSchedule {
        guard let userId = supabase.currentUserId else {
            throw MedicationScheduleError.notAuthenticated
        }

        let updateData: [String: AnyEncodable] = [
            "medication_name": AnyEncodable(schedule.medicationName),
            "dose": AnyEncodable(schedule.dose),
            "notes": AnyEncodable(schedule.notes),
            "frequency": AnyEncodable(schedule.frequency.rawValue),
            "reminder_times": AnyEncodable(schedule.reminderTimes),
            "end_date": AnyEncodable(schedule.endDate.map { formatDate($0) }),
            "duration_type": AnyEncodable(schedule.durationType.rawValue),
            "duration_days": AnyEncodable(schedule.durationDays),
            "doses_remaining": AnyEncodable(schedule.dosesRemaining),
            "doses_per_take": AnyEncodable(schedule.dosesPerTake),
            "low_stock_alert": AnyEncodable(schedule.lowStockAlert),
            "is_active": AnyEncodable(schedule.isActive),
            "is_paused": AnyEncodable(schedule.isPaused),
            "paused_until": AnyEncodable(schedule.pausedUntil)
        ]

        let response: MedicationSchedule = try await supabase.client
            .from(schedulesTable)
            .update(updateData)
            .eq("id", value: schedule.id.uuidString)
            .select()
            .single()
            .execute()
            .value

        // Atualiza lista local
        if let index = activeSchedules.firstIndex(where: { $0.id == schedule.id }) {
            if response.canReceiveReminders {
                activeSchedules[index] = response
            } else {
                activeSchedules.remove(at: index)
            }
        }

        Logger.info("Updated medication schedule: \(response.medicationName)")
        return response
    }

    /// Deleta um schedule
    func deleteSchedule(id: UUID) async throws {
        try await supabase.client
            .from(schedulesTable)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()

        activeSchedules.removeAll { $0.id == id }
        Logger.info("Deleted medication schedule: \(id)")
    }

    /// Desativa um schedule (soft delete)
    func deactivateSchedule(id: UUID) async throws {
        let updateData: [String: AnyEncodable] = [
            "is_active": AnyEncodable(false)
        ]

        try await supabase.client
            .from(schedulesTable)
            .update(updateData)
            .eq("id", value: id.uuidString)
            .execute()

        activeSchedules.removeAll { $0.id == id }
        Logger.info("Deactivated medication schedule: \(id)")
    }

    /// Pausa um schedule
    func pauseSchedule(id: UUID, until: Date? = nil) async throws {
        let updateData: [String: AnyEncodable] = [
            "is_paused": AnyEncodable(true),
            "paused_until": AnyEncodable(until)
        ]

        try await supabase.client
            .from(schedulesTable)
            .update(updateData)
            .eq("id", value: id.uuidString)
            .execute()

        if let index = activeSchedules.firstIndex(where: { $0.id == id }) {
            activeSchedules[index].isPaused = true
            activeSchedules[index].pausedUntil = until
        }

        Logger.info("Paused medication schedule: \(id)")
    }

    /// Retoma um schedule pausado
    func resumeSchedule(id: UUID) async throws {
        let updateData: [String: AnyEncodable] = [
            "is_paused": AnyEncodable(false),
            "paused_until": AnyEncodable(nil as Date?)
        ]

        try await supabase.client
            .from(schedulesTable)
            .update(updateData)
            .eq("id", value: id.uuidString)
            .execute()

        if let index = activeSchedules.firstIndex(where: { $0.id == id }) {
            activeSchedules[index].isPaused = false
            activeSchedules[index].pausedUntil = nil
        }

        Logger.info("Resumed medication schedule: \(id)")
    }

    /// Atualiza doses restantes
    func updateDosesRemaining(id: UUID, doses: Int) async throws {
        let updateData: [String: AnyEncodable] = [
            "doses_remaining": AnyEncodable(doses)
        ]

        try await supabase.client
            .from(schedulesTable)
            .update(updateData)
            .eq("id", value: id.uuidString)
            .execute()

        if let index = activeSchedules.firstIndex(where: { $0.id == id }) {
            activeSchedules[index].dosesRemaining = doses
        }

        Logger.info("Updated doses remaining for schedule \(id): \(doses)")
    }

    // MARK: - Log CRUD

    /// Registra administração de medicamento
    func logMedicationGiven(
        scheduleId: UUID,
        babyId: UUID,
        scheduledTime: Date,
        doseGiven: String? = nil,
        notes: String? = nil
    ) async throws -> MedicationLog {
        guard let userId = supabase.currentUserId else {
            throw MedicationScheduleError.notAuthenticated
        }

        let log = MedicationLog(
            scheduleId: scheduleId,
            babyId: babyId,
            scheduledTime: scheduledTime,
            actualTime: Date(),
            status: .given,
            doseGiven: doseGiven,
            notes: notes,
            givenBy: userId
        )

        let insertDTO = MedicationLogInsert(from: log, userId: userId)

        let response: MedicationLog = try await supabase.client
            .from(logsTable)
            .insert(insertDTO)
            .select()
            .single()
            .execute()
            .value

        todayLogs.append(response)
        Logger.info("Logged medication given for schedule: \(scheduleId)")

        // Também registra no health_records para manter histórico unificado
        try await syncToHealthRecords(scheduleId: scheduleId, babyId: babyId, log: response)

        return response
    }

    /// Registra medicamento pulado
    func logMedicationSkipped(
        scheduleId: UUID,
        babyId: UUID,
        scheduledTime: Date,
        notes: String? = nil
    ) async throws -> MedicationLog {
        guard let userId = supabase.currentUserId else {
            throw MedicationScheduleError.notAuthenticated
        }

        let log = MedicationLog(
            scheduleId: scheduleId,
            babyId: babyId,
            scheduledTime: scheduledTime,
            actualTime: Date(),
            status: .skipped,
            notes: notes,
            givenBy: userId
        )

        let insertDTO = MedicationLogInsert(from: log, userId: userId)

        let response: MedicationLog = try await supabase.client
            .from(logsTable)
            .insert(insertDTO)
            .select()
            .single()
            .execute()
            .value

        todayLogs.append(response)
        Logger.info("Logged medication skipped for schedule: \(scheduleId)")

        return response
    }

    /// Registra medicamento adiado (snooze)
    func logMedicationSnoozed(
        scheduleId: UUID,
        babyId: UUID,
        scheduledTime: Date,
        snoozeDuration: SnoozeDuration
    ) async throws -> MedicationLog {
        guard let userId = supabase.currentUserId else {
            throw MedicationScheduleError.notAuthenticated
        }

        let snoozedUntil = Calendar.current.date(
            byAdding: .minute,
            value: snoozeDuration.minutes,
            to: Date()
        ) ?? Date()

        // Verifica se já existe um log para este horário e incrementa snooze_count
        let existingLogs: [MedicationLog] = try await supabase.client
            .from(logsTable)
            .select()
            .eq("schedule_id", value: scheduleId.uuidString)
            .eq("scheduled_time", value: ISO8601DateFormatter().string(from: scheduledTime))
            .eq("status", value: "snoozed")
            .execute()
            .value

        let snoozeCount = (existingLogs.first?.snoozeCount ?? 0) + 1

        let log = MedicationLog(
            scheduleId: scheduleId,
            babyId: babyId,
            scheduledTime: scheduledTime,
            status: .snoozed,
            snoozeCount: snoozeCount,
            snoozedUntil: snoozedUntil,
            givenBy: userId
        )

        let insertDTO = MedicationLogInsert(from: log, userId: userId)

        let response: MedicationLog = try await supabase.client
            .from(logsTable)
            .insert(insertDTO)
            .select()
            .single()
            .execute()
            .value

        todayLogs.append(response)
        Logger.info("Logged medication snoozed for schedule: \(scheduleId), until: \(snoozedUntil)")

        return response
    }

    /// Busca logs do dia para um bebê
    func fetchTodayLogs(babyId: UUID) async throws -> [MedicationLog] {
        let startOfDay = Calendar.current.startOfDay(for: Date())

        let logs: [MedicationLog] = try await supabase.client
            .from(logsTable)
            .select()
            .eq("baby_id", value: babyId.uuidString)
            .gte("scheduled_time", value: ISO8601DateFormatter().string(from: startOfDay))
            .order("scheduled_time", ascending: false)
            .execute()
            .value

        todayLogs = logs
        Logger.info("Fetched \(logs.count) medication logs for today")
        return logs
    }

    /// Busca logs de um schedule específico
    func fetchLogsForSchedule(scheduleId: UUID, limit: Int = 10) async throws -> [MedicationLog] {
        let logs: [MedicationLog] = try await supabase.client
            .from(logsTable)
            .select()
            .eq("schedule_id", value: scheduleId.uuidString)
            .order("scheduled_time", ascending: false)
            .limit(limit)
            .execute()
            .value

        return logs
    }

    // MARK: - Queries

    /// Retorna o próximo medicamento a ser dado
    func getNextMedication(babyId: UUID) async throws -> (schedule: MedicationSchedule, nextTime: Date)? {
        let schedules = try await fetchActiveSchedules(babyId: babyId)

        var nextMed: (schedule: MedicationSchedule, nextTime: Date)?

        for schedule in schedules where schedule.canReceiveReminders {
            if let nextTime = schedule.nextReminder {
                if let current = nextMed {
                    if nextTime < current.nextTime {
                        nextMed = (schedule, nextTime)
                    }
                } else {
                    nextMed = (schedule, nextTime)
                }
            }
        }

        return nextMed
    }

    /// Retorna medicamentos com estoque baixo
    func getLowStockMedications(babyId: UUID) async throws -> [MedicationSchedule] {
        let schedules = try await fetchActiveSchedules(babyId: babyId)
        return schedules.filter { $0.isLowStock }
    }

    /// Verifica se já existe log para um horário específico
    func hasLogForScheduledTime(scheduleId: UUID, scheduledTime: Date) async throws -> Bool {
        let logs: [MedicationLog] = try await supabase.client
            .from(logsTable)
            .select()
            .eq("schedule_id", value: scheduleId.uuidString)
            .eq("scheduled_time", value: ISO8601DateFormatter().string(from: scheduledTime))
            .in("status", values: ["given", "skipped"])
            .execute()
            .value

        return !logs.isEmpty
    }

    // MARK: - Sync with Health Records

    /// Sincroniza log com health_records para manter histórico unificado
    private func syncToHealthRecords(scheduleId: UUID, babyId: UUID, log: MedicationLog) async throws {
        guard log.status == .given else { return }

        // Busca informações do schedule
        let schedule = try await fetchSchedule(id: scheduleId)

        // Usa o HealthRepository para criar o registro
        let healthRepo = HealthRepository.shared
        _ = try await healthRepo.addMedication(
            babyId: babyId,
            name: schedule.medicationName,
            dose: log.doseGiven ?? schedule.dose,
            recordedAt: log.actualTime ?? Date(),
            notes: log.notes
        )

        Logger.info("Synced medication log to health_records")
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Errors
enum MedicationScheduleError: Error, LocalizedError {
    case notAuthenticated
    case scheduleNotFound
    case invalidData
    case alreadyLogged

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .scheduleNotFound:
            return "Medication schedule not found"
        case .invalidData:
            return "Invalid medication data"
        case .alreadyLogged:
            return "Medication already logged for this time"
        }
    }
}
