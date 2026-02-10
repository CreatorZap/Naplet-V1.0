import Foundation
import SwiftUI

// MARK: - Sleep Record Model
struct SleepRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let babyId: UUID
    var type: SleepType
    var startTime: Date
    var endTime: Date?
    var quality: SleepQuality?
    var notes: String?
    var recordedBy: UUID
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Novos Campos (Localização e Humor)
    var sleepLocation: SleepLocation?
    var sleepStartMood: SleepStartMood?
    var wakeType: WakeType?
    var wakeMood: WakeMood?

    // Night wakings são carregados separadamente
    var nightWakings: [NightWaking] = []

    // MARK: - Computed Properties
    var isActive: Bool {
        endTime == nil
    }

    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }

    var durationFormatted: String {
        guard let duration = duration else {
            return Date().timeIntervalSince(startTime).formatted
        }
        return duration.formatted
    }

    var durationMinutes: Int? {
        guard let duration = duration else { return nil }
        return Int(duration / 60)
    }

    var totalNightWakingsDuration: TimeInterval {
        nightWakings.reduce(0) { $0 + ($1.duration ?? 0) }
    }

    /// Duração atual para sono em andamento
    var currentDuration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    /// Data do registro
    var date: Date {
        Calendar.current.startOfDay(for: startTime)
    }

    /// Verifica se foi hoje
    var isToday: Bool {
        Calendar.current.isDateInToday(startTime)
    }

    /// Hora de início formatada
    var startTimeFormatted: String {
        startTime.timeString
    }

    /// Hora de término formatada
    var endTimeFormatted: String? {
        endTime?.timeString
    }

    /// Time range formatted (start - end)
    var timeRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: startTime)
        if let end = endTime {
            return "\(start) - \(formatter.string(from: end))"
        }
        return "\(start) - agora"
    }

    // MARK: - Sleep Type
    enum SleepType: String, Codable, CaseIterable {
        case nap = "nap"
        case night = "night"

        var displayName: String {
            switch self {
            case .nap: return "sleep.type.nap".localized
            case .night: return "sleep.type.night".localized
            }
        }

        var icon: String {
            switch self {
            case .nap: return "cloud.sun.fill"
            case .night: return "moon.stars.fill"
            }
        }

        var color: Color {
            switch self {
            case .nap: return NapletColors.napColor
            case .night: return NapletColors.sleepActive
            }
        }
    }

    // MARK: - Sleep Quality
    enum SleepQuality: String, Codable, CaseIterable {
        case good = "good"
        case restless = "restless"
        case difficult = "difficult"

        var displayName: String {
            switch self {
            case .good: return "sleep.quality.good".localized
            case .restless: return "sleep.quality.restless".localized
            case .difficult: return "sleep.quality.difficult".localized
            }
        }

        var icon: String {
            switch self {
            case .good: return "face.smiling.fill"
            case .restless: return "face.dashed.fill"
            case .difficult: return "cloud.rain.fill"
            }
        }

        var color: Color {
            switch self {
            case .good: return NapletColors.success
            case .restless: return NapletColors.warning
            case .difficult: return NapletColors.error
            }
        }

        var value: Int {
            switch self {
            case .good: return 3
            case .restless: return 2
            case .difficult: return 1
            }
        }
    }

    // MARK: - Init
    init(
        id: UUID = UUID(),
        babyId: UUID,
        type: SleepType = .nap,
        startTime: Date = Date(),
        endTime: Date? = nil,
        quality: SleepQuality? = nil,
        notes: String? = nil,
        sleepLocation: SleepLocation? = nil,
        sleepStartMood: SleepStartMood? = nil,
        wakeType: WakeType? = nil,
        wakeMood: WakeMood? = nil,
        nightWakings: [NightWaking] = [],
        recordedBy: UUID,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.babyId = babyId
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.quality = quality
        self.notes = notes
        self.sleepLocation = sleepLocation
        self.sleepStartMood = sleepStartMood
        self.wakeType = wakeType
        self.wakeMood = wakeMood
        self.nightWakings = nightWakings
        self.recordedBy = recordedBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Methods

    /// Finaliza o registro de sono
    mutating func finish(at time: Date = Date(), quality: SleepQuality? = nil) {
        self.endTime = time
        self.quality = quality
        self.updatedAt = Date()
    }
}

// MARK: - Coding Keys (snake_case para Supabase)
extension SleepRecord {
    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case type
        case startTime = "start_time"
        case endTime = "end_time"
        case quality
        case notes
        case sleepLocation = "sleep_location"
        case sleepStartMood = "sleep_start_mood"
        case wakeType = "wake_type"
        case wakeMood = "wake_mood"
        case recordedBy = "recorded_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Custom decoder para ignorar nightWakings e parsear datas do Supabase
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        babyId = try container.decode(UUID.self, forKey: .babyId)
        type = try container.decode(SleepType.self, forKey: .type)
        quality = try container.decodeIfPresent(SleepQuality.self, forKey: .quality)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        recordedBy = try container.decode(UUID.self, forKey: .recordedBy)
        nightWakings = [] // Carregado separadamente

        // Novos campos de localização e humor
        if let locationString = try container.decodeIfPresent(String.self, forKey: .sleepLocation) {
            sleepLocation = SleepLocation(rawValue: locationString)
        } else {
            sleepLocation = nil
        }
        if let startMoodString = try container.decodeIfPresent(String.self, forKey: .sleepStartMood) {
            sleepStartMood = SleepStartMood(rawValue: startMoodString)
        } else {
            sleepStartMood = nil
        }
        if let wakeTypeString = try container.decodeIfPresent(String.self, forKey: .wakeType) {
            wakeType = WakeType(rawValue: wakeTypeString)
        } else {
            wakeType = nil
        }
        if let wakeMoodString = try container.decodeIfPresent(String.self, forKey: .wakeMood) {
            wakeMood = WakeMood(rawValue: wakeMoodString)
        } else {
            wakeMood = nil
        }

        // Parse dates from Supabase format
        let startTimeString = try container.decode(String.self, forKey: .startTime)
        startTime = SleepRecord.parseTimestamp(startTimeString) ?? Date()

        if let endTimeString = try container.decodeIfPresent(String.self, forKey: .endTime) {
            endTime = SleepRecord.parseTimestamp(endTimeString)
        } else {
            endTime = nil
        }

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        createdAt = SleepRecord.parseTimestamp(createdAtString) ?? Date()

        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        updatedAt = SleepRecord.parseTimestamp(updatedAtString) ?? Date()
    }
    
    // MARK: - Date Parsing Helper
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
        
        // Try Supabase format: "2026-01-19 04:17:36.952047+00"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSXXXXX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = formatter.date(from: string) {
            return date
        }
        
        // Try without microseconds
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssXXXXX"
        if let date = formatter.date(from: string) {
            return date
        }
        
        // Try with T separator
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
        if let date = formatter.date(from: string) {
            return date
        }
        
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        return formatter.date(from: string)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(babyId, forKey: .babyId)
        try container.encode(type, forKey: .type)
        try container.encode(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encodeIfPresent(quality, forKey: .quality)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(sleepLocation?.rawValue, forKey: .sleepLocation)
        try container.encodeIfPresent(sleepStartMood?.rawValue, forKey: .sleepStartMood)
        try container.encodeIfPresent(wakeType?.rawValue, forKey: .wakeType)
        try container.encodeIfPresent(wakeMood?.rawValue, forKey: .wakeMood)
        try container.encode(recordedBy, forKey: .recordedBy)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        // nightWakings não é encodado - gerenciado separadamente
    }
}

// MARK: - Sleep Record Insert DTO
/// Para INSERT no Supabase (sem campos auto-gerados)
struct SleepRecordInsert: Codable {
    let babyId: UUID
    let type: SleepRecord.SleepType
    let startTime: Date
    let endTime: Date?
    let quality: SleepRecord.SleepQuality?
    let notes: String?
    let sleepLocation: SleepLocation?
    let sleepStartMood: SleepStartMood?
    let wakeType: WakeType?
    let wakeMood: WakeMood?
    let recordedBy: UUID

    enum CodingKeys: String, CodingKey {
        case babyId = "baby_id"
        case type
        case startTime = "start_time"
        case endTime = "end_time"
        case quality
        case notes
        case sleepLocation = "sleep_location"
        case sleepStartMood = "sleep_start_mood"
        case wakeType = "wake_type"
        case wakeMood = "wake_mood"
        case recordedBy = "recorded_by"
    }

    init(
        babyId: UUID,
        type: SleepRecord.SleepType = .nap,
        startTime: Date = Date(),
        endTime: Date? = nil,
        quality: SleepRecord.SleepQuality? = nil,
        notes: String? = nil,
        sleepLocation: SleepLocation? = nil,
        sleepStartMood: SleepStartMood? = nil,
        wakeType: WakeType? = nil,
        wakeMood: WakeMood? = nil,
        recordedBy: UUID
    ) {
        self.babyId = babyId
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.quality = quality
        self.notes = notes
        self.sleepLocation = sleepLocation
        self.sleepStartMood = sleepStartMood
        self.wakeType = wakeType
        self.wakeMood = wakeMood
        self.recordedBy = recordedBy
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(babyId, forKey: .babyId)
        try container.encode(type, forKey: .type)
        try container.encode(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encodeIfPresent(quality, forKey: .quality)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(sleepLocation?.rawValue, forKey: .sleepLocation)
        try container.encodeIfPresent(sleepStartMood?.rawValue, forKey: .sleepStartMood)
        try container.encodeIfPresent(wakeType?.rawValue, forKey: .wakeType)
        try container.encodeIfPresent(wakeMood?.rawValue, forKey: .wakeMood)
        try container.encode(recordedBy, forKey: .recordedBy)
    }
}

// MARK: - Sleep Record Update DTO
/// Para UPDATE no Supabase (apenas campos editáveis)
struct SleepRecordUpdate: Codable {
    var endTime: Date?
    var quality: SleepRecord.SleepQuality?
    var notes: String?
    var sleepLocation: SleepLocation?
    var sleepStartMood: SleepStartMood?
    var wakeType: WakeType?
    var wakeMood: WakeMood?

    enum CodingKeys: String, CodingKey {
        case endTime = "end_time"
        case quality
        case notes
        case sleepLocation = "sleep_location"
        case sleepStartMood = "sleep_start_mood"
        case wakeType = "wake_type"
        case wakeMood = "wake_mood"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encodeIfPresent(quality, forKey: .quality)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(sleepLocation?.rawValue, forKey: .sleepLocation)
        try container.encodeIfPresent(sleepStartMood?.rawValue, forKey: .sleepStartMood)
        try container.encodeIfPresent(wakeType?.rawValue, forKey: .wakeType)
        try container.encodeIfPresent(wakeMood?.rawValue, forKey: .wakeMood)
    }
}

// MARK: - Night Waking
struct NightWaking: Identifiable, Codable, Equatable {
    let id: UUID
    let sleepRecordId: UUID
    var startTime: Date
    var endTime: Date?
    var reason: WakingReason?
    var notes: String?
    var createdAt: Date

    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }

    var isActive: Bool {
        endTime == nil
    }

    enum WakingReason: String, Codable, CaseIterable {
        case feeding = "feeding"
        case diaper = "diaper"
        case comfort = "comfort"
        case unknown = "unknown"

        var displayName: String {
            switch self {
            case .feeding: return "sleep.wake.feeding".localized
            case .diaper: return "sleep.wake.diaper".localized
            case .comfort: return "sleep.wake.comfort".localized
            case .unknown: return "sleep.wake.unknown".localized
            }
        }

        var icon: String {
            switch self {
            case .feeding: return "drop.fill"
            case .diaper: return "humidity.fill"
            case .comfort: return "heart.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .feeding: return NapletColors.primaryBlue
            case .diaper: return NapletColors.warning
            case .comfort: return NapletColors.primaryPink
            case .unknown: return NapletColors.textMuted
            }
        }
    }

    init(
        id: UUID = UUID(),
        sleepRecordId: UUID,
        startTime: Date = Date(),
        endTime: Date? = nil,
        reason: WakingReason? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sleepRecordId = sleepRecordId
        self.startTime = startTime
        self.endTime = endTime
        self.reason = reason
        self.notes = notes
        self.createdAt = createdAt
    }
}

// MARK: - Night Waking Coding Keys
extension NightWaking {
    enum CodingKeys: String, CodingKey {
        case id
        case sleepRecordId = "sleep_record_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case reason
        case notes
        case createdAt = "created_at"
    }
    
    // Custom decoder for Supabase date formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        sleepRecordId = try container.decode(UUID.self, forKey: .sleepRecordId)
        reason = try container.decodeIfPresent(WakingReason.self, forKey: .reason)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        let startTimeString = try container.decode(String.self, forKey: .startTime)
        startTime = NightWaking.parseTimestamp(startTimeString) ?? Date()
        
        if let endTimeString = try container.decodeIfPresent(String.self, forKey: .endTime) {
            endTime = NightWaking.parseTimestamp(endTimeString)
        } else {
            endTime = nil
        }
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        createdAt = NightWaking.parseTimestamp(createdAtString) ?? Date()
    }
    
    private static func parseTimestamp(_ string: String) -> Date? {
        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601.date(from: string) { return date }
        
        iso8601.formatOptions = [.withInternetDateTime]
        if let date = iso8601.date(from: string) { return date }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSXXXXX"
        if let date = formatter.date(from: string) { return date }
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssXXXXX"
        if let date = formatter.date(from: string) { return date }
        
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
        if let date = formatter.date(from: string) { return date }
        
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        return formatter.date(from: string)
    }
}

// MARK: - Night Waking Insert DTO
struct NightWakingInsert: Codable {
    let sleepRecordId: UUID
    let startTime: Date
    let endTime: Date?
    let reason: NightWaking.WakingReason?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case sleepRecordId = "sleep_record_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case reason
        case notes
    }
}

// MARK: - Sleep Statistics
struct SleepStatistics {
    let totalSleepMinutes: Int
    let nightSleepMinutes: Int
    let napMinutes: Int
    let numberOfNaps: Int
    let averageNapDuration: Int
    let averageQuality: Double?
    let date: Date

    var totalSleepFormatted: String {
        TimeInterval(totalSleepMinutes * 60).formattedDuration
    }

    var nightSleepFormatted: String {
        TimeInterval(nightSleepMinutes * 60).formattedDuration
    }

    var napFormatted: String {
        TimeInterval(napMinutes * 60).formattedDuration
    }

    var averageNapFormatted: String {
        TimeInterval(averageNapDuration * 60).formattedDuration
    }

    var totalHours: Double {
        Double(totalSleepMinutes) / 60.0
    }

    static func calculate(from records: [SleepRecord], for date: Date = Date()) -> SleepStatistics {
        let dayRecords = records.filter { Calendar.current.isDate($0.startTime, inSameDayAs: date) }
        let completedRecords = dayRecords.filter { !$0.isActive }

        let totalMinutes = completedRecords.compactMap { $0.durationMinutes }.reduce(0, +)
        let nightRecords = completedRecords.filter { $0.type == .night }
        let napRecords = completedRecords.filter { $0.type == .nap }

        let nightMinutes = nightRecords.compactMap { $0.durationMinutes }.reduce(0, +)
        let napMinutes = napRecords.compactMap { $0.durationMinutes }.reduce(0, +)

        let avgNap = napRecords.isEmpty ? 0 : napMinutes / napRecords.count

        let qualityValues = completedRecords.compactMap { $0.quality?.value }
        let avgQuality = qualityValues.isEmpty ? nil : Double(qualityValues.reduce(0, +)) / Double(qualityValues.count)

        return SleepStatistics(
            totalSleepMinutes: totalMinutes,
            nightSleepMinutes: nightMinutes,
            napMinutes: napMinutes,
            numberOfNaps: napRecords.count,
            averageNapDuration: avgNap,
            averageQuality: avgQuality,
            date: date
        )
    }
}

// MARK: - Daily Stats Response (from Supabase RPC)
struct DailyStatsResponse: Codable {
    let totalSleepSeconds: Double
    let napCount: Int
    let nightSleepSeconds: Double
    let averageNapSeconds: Double

    enum CodingKeys: String, CodingKey {
        case totalSleepSeconds = "total_sleep_seconds"
        case napCount = "nap_count"
        case nightSleepSeconds = "night_sleep_seconds"
        case averageNapSeconds = "average_nap_seconds"
    }

    func toStatistics(for date: Date = Date()) -> SleepStatistics {
        SleepStatistics(
            totalSleepMinutes: Int(totalSleepSeconds / 60),
            nightSleepMinutes: Int(nightSleepSeconds / 60),
            napMinutes: Int((totalSleepSeconds - nightSleepSeconds) / 60),
            numberOfNaps: napCount,
            averageNapDuration: Int(averageNapSeconds / 60),
            averageQuality: nil,
            date: date
        )
    }
}

// MARK: - Mock Data
extension SleepRecord {
    static let preview = SleepRecord(
        babyId: Baby.preview.id,
        type: .nap,
        startTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
        endTime: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!,
        quality: .good,
        recordedBy: UUID()
    )

    static let activePreview = SleepRecord(
        babyId: Baby.preview.id,
        type: .nap,
        startTime: Date(),
        recordedBy: UUID()
    )

    static func previewList(for babyId: UUID) -> [SleepRecord] {
        let now = Date()
        return [
            SleepRecord(babyId: babyId, type: .night, startTime: Calendar.current.date(byAdding: .hour, value: -10, to: now)!, endTime: Calendar.current.date(byAdding: .hour, value: -2, to: now)!, quality: .good, recordedBy: UUID()),
            SleepRecord(babyId: babyId, type: .nap, startTime: Calendar.current.date(byAdding: .hour, value: -5, to: now)!, endTime: Calendar.current.date(byAdding: .minute, value: -240, to: now)!, quality: .restless, recordedBy: UUID())
        ]
    }
}

extension NightWaking {
    static let preview = NightWaking(
        sleepRecordId: SleepRecord.preview.id,
        startTime: Calendar.current.date(byAdding: .hour, value: -6, to: Date())!,
        endTime: Calendar.current.date(byAdding: .minute, value: -330, to: Date())!,
        reason: .feeding
    )
}
