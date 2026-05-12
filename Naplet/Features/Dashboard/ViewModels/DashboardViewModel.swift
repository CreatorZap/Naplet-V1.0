import Foundation
import SwiftUI
import UIKit
import Combine
import WidgetKit

// MARK: - Baby Awake Status
enum BabyAwakeStatus: String {
    case happy = "happy"           // 0-60% da janela
    case gettingSleepy = "sleepy"  // 60-85% da janela
    case tired = "tired"           // 85-100% da janela
    case overtired = "overtired"   // >100% da janela

    var icon: String {
        switch self {
        case .happy: return "sun.max.fill"           // Sol feliz
        case .gettingSleepy: return "moon.stars.fill" // Lua com estrelas
        case .tired: return "moon.zzz.fill"          // Lua dormindo
        case .overtired: return "heart.fill"         // Coracao (empatia, nao alarme)
        }
    }

    var color: Color {
        switch self {
        case .happy: return NapletColors.success
        case .gettingSleepy: return NapletColors.warning
        case .tired: return NapletColors.primaryPurple  // Roxo ao inves de vermelho
        case .overtired: return NapletColors.primaryPink // Rosa ao inves de vermelho (mais empatico)
        }
    }

    var messageKey: String {
        switch self {
        case .happy: return "wakeWindow.status.happy"
        case .gettingSleepy: return "wakeWindow.status.sleepy"
        case .tired: return "wakeWindow.status.tired"
        case .overtired: return "wakeWindow.status.overtired"
        }
    }

    var tipKey: String {
        switch self {
        case .happy: return "wakeWindow.tip.happy"
        case .gettingSleepy: return "wakeWindow.tip.sleepy"
        case .tired: return "wakeWindow.tip.tired"
        case .overtired: return "wakeWindow.tip.overtired"
        }
    }
}

// MARK: - Dashboard ViewModel
@MainActor
class DashboardViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var currentBaby: Baby?
    @Published var currentProfile: Profile?
    @Published var isLoading = false
    @Published var isSleeping = false
    @Published var sleepStartTime: Date?
    @Published var todaysSleepRecords: [SleepRecord] = []
    @Published var todayActivities: [ActivityItem] = []
    @Published var errorMessage: String?
    @Published var showQualitySheet = false

    // MARK: - Wake Window Properties
    @Published var lastWakeTime: Date?
    @Published var timeAwake: TimeInterval = 0
    @Published var wakeWindowProgress: Double = 0 // 0.0 a 1.0
    @Published var babyStatus: BabyAwakeStatus = .happy
    @Published var sleepRecommendation: Baby.SleepRecommendation = .nap

    // MARK: - Timeline Properties
    @Published var timelineEvents: [TimelineEvent] = []

    // MARK: - User Preferences
    @AppStorage("wakeWindowAlertsEnabled") private var wakeWindowAlertsEnabled = true
    @AppStorage("alertMinutesBefore") private var alertMinutesBefore = 15

    // MARK: - Dependencies
    private let babyRepository = BabyRepository()
    private let sleepRepository = SleepRepository()
    private let feedingRepository = FeedingRepository.shared
    private let diaperRepository = DiaperRepository.shared
    private let bathRepository = BathRepository.shared
    private let healthRepository = HealthRepository.shared
    private let notificationService = NotificationService.shared
    private let wakeWindowNotificationManager = WakeWindowNotificationManager.shared
    private let watchConnectivity = iOSConnectivityManager.shared
    private let learningService = SleepLearningService.shared

    // MARK: - Timer
    private var timer: Timer?
    private var wakeWindowTimer: Timer?
    @Published var currentSleepDuration: TimeInterval = 0

    // MARK: - Watch Connectivity
    private var watchCancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "dashboard.greeting.morning".localized
        case 12..<17: return "dashboard.greeting.afternoon".localized
        case 17..<21: return "dashboard.greeting.evening".localized
        default: return "dashboard.greeting.night".localized
        }
    }

    var totalSleepToday: TimeInterval {
        todaysSleepRecords
            .filter { !$0.isActive }
            .reduce(0) { $0 + ($1.duration ?? 0) }
    }

    var totalSleepFormatted: String {
        let hours = Int(totalSleepToday) / 3600
        let minutes = (Int(totalSleepToday) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var numberOfNaps: Int {
        todaysSleepRecords.filter { $0.type == .nap && !$0.isActive }.count
    }

    var totalSleepMinutes: Int {
        Int(totalSleepToday / 60)
    }

    var currentSleepType: SleepRecord.SleepType? {
        sleepRepository.activeSleep?.type
    }

    // MARK: - Init
    init() {
        setupWatchConnectivity()
        setupWidgetObservers()
    }

    var currentSleepFormatted: String {
        let hours = Int(currentSleepDuration) / 3600
        let minutes = (Int(currentSleepDuration) % 3600) / 60
        let seconds = Int(currentSleepDuration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Load Data
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Carregar perfil do usuário
            if let userId = SupabaseService.shared.currentUser?.id {
                await loadUserProfile(userId: userId)
            }
            
            // Carregar bebês
            if SupabaseService.shared.currentUser != nil {
                try await babyRepository.fetchBabies()
                currentBaby = babyRepository.currentBaby
            }

            // Se não tiver bebê no Supabase, tentar carregar do UserDefaults
            if currentBaby == nil {
                loadBabyFromUserDefaults()
            }

            // Carregar registros de sono de hoje
            if let baby = currentBaby, SupabaseService.shared.currentUser != nil {
                try await sleepRepository.fetchTodaysRecords(for: baby.id)
                todaysSleepRecords = sleepRepository.sleepRecords

                // Verificar se há sono ativo
                if let activeSleep = sleepRepository.activeSleep {
                    isSleeping = true
                    sleepStartTime = activeSleep.startTime
                    startTimer()
                }

                // Carregar todas as atividades do dia
                await loadTodayActivities(for: baby.id)

                // Atualizar aprendizado de sono (se tiver dados suficientes)
                await updateSleepLearning()

                // Iniciar timer de wake window se nao estiver dormindo
                if !isSleeping {
                    startWakeWindowTimer()

                    // Reschedule nap reminder on app open if baby is awake
                    if wakeWindowAlertsEnabled {
                        wakeWindowNotificationManager.rescheduleIfNeeded(
                            baby: baby,
                            lastWakeTime: lastWakeTime,
                            isSleeping: false
                        )
                    }
                }
            }
        } catch is CancellationError {
            // Ignorar erros de cancelamento - sao esperados durante refresh
            Logger.info("Data load cancelled (expected during refresh)")
            // NAO mostrar erro para o usuario
        } catch let error as NSError {
            // Ignorar erros de cancelamento do URLSession (codigo -999)
            if error.code == NSURLErrorCancelled || error.code == -999 {
                Logger.info("Network request cancelled (expected during refresh)")
                loadBabyFromUserDefaults()
                return
            }

            // Ignorar erros de "cancelled" em qualquer forma
            let errorDescription = error.localizedDescription.lowercased()
            if errorDescription.contains("cancel") || errorDescription.contains("cancelado") {
                Logger.info("Operation cancelled (expected during refresh)")
                loadBabyFromUserDefaults()
                return
            }

            Logger.error("Failed to load data: \(error)")
            errorMessage = "error.loadDataFailed".localized
            // Fallback para dados locais
            loadBabyFromUserDefaults()
        } catch {
            // Ignorar erros genericos de cancelamento
            let errorDescription = "\(error)".lowercased()
            if errorDescription.contains("cancel") || errorDescription.contains("cancelado") {
                Logger.info("Operation cancelled (expected during refresh)")
                loadBabyFromUserDefaults()
                return
            }

            Logger.error("Failed to load data: \(error)")
            errorMessage = "error.loadDataFailed".localized
            // Fallback para dados locais
            loadBabyFromUserDefaults()
        }

        isLoading = false

        // Sync with Apple Watch
        syncWithWatch()

        // Update home screen widget
        updateWidget()
    }
    
    // MARK: - Load User Profile
    private func loadUserProfile(userId: UUID) async {
        do {
            let profile: Profile = try await SupabaseService.shared.client
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            self.currentProfile = profile
            Logger.info("DashboardViewModel: Profile loaded - \(profile.displayName ?? "no name")")
        } catch {
            Logger.error("DashboardViewModel: Failed to load profile - \(error)")
            // Não é crítico, apenas loga o erro
        }
    }
    
    // MARK: - Reload Profile (public)
    /// Recarrega o perfil do usuário (chamado após edição)
    func reloadProfile() async {
        guard let userId = SupabaseService.shared.currentUser?.id else { return }
        await loadUserProfile(userId: userId)
    }

    private func loadBabyFromUserDefaults() {
        if let babyData = UserDefaults.standard.dictionary(forKey: "currentBaby"),
           let name = babyData["name"] as? String,
           let birthDateTimestamp = babyData["birthDate"] as? TimeInterval {

            let genderString = babyData["gender"] as? String
            let gender = genderString.flatMap { Baby.Gender(rawValue: $0) }

            currentBaby = Baby(
                id: UUID(),
                name: name,
                birthDate: Date(timeIntervalSince1970: birthDateTimestamp),
                gender: gender,
                photoURL: nil,
                ownerId: UUID()
            )
            Logger.info("Baby loaded from UserDefaults: \(name)")
        } else {
            #if DEBUG
            if AppEnvironment.current.useMockData {
                currentBaby = Baby.preview
                Logger.info("Using preview baby (mock mode)")
            }
            #endif
        }
    }

    // MARK: - Sleep Actions
    func startSleep(type: SleepRecord.SleepType = .nap) async {
        guard let baby = currentBaby else {
            errorMessage = "error.noBabySelected".localized
            return
        }

        do {
            let record = try await sleepRepository.startSleep(babyId: baby.id, type: type)
            isSleeping = true
            sleepStartTime = record.startTime
            todaysSleepRecords.insert(record, at: 0)
            startTimer()

            // Parar timer do wake window (bebe esta dormindo)
            stopWakeWindowTimer()

            // Cancelar lembretes de soneca (já está dormindo)
            notificationService.cancelNapReminders(for: baby.id)
            wakeWindowNotificationManager.cancelNapReminder(babyId: baby.id)

            // Agendar lembrete para acordar (se for nap, não night sleep)
            if type == .nap {
                await notificationService.scheduleWakeReminder(for: baby, sleepStartTime: record.startTime)
            }

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            // Sync with Apple Watch
            syncWithWatch()

            // Update home screen widget
            updateWidget()
        } catch {
            Logger.error("Failed to start sleep: \(error)")
            errorMessage = "error.sleepStartFailed".localized
        }
    }

    func stopSleep(quality: SleepRecord.SleepQuality? = nil, notes: String? = nil) async {
        do {
            if let record = try await sleepRepository.stopSleep(quality: quality, notes: notes) {
                // Atualizar lista local
                if let index = todaysSleepRecords.firstIndex(where: { $0.id == record.id }) {
                    todaysSleepRecords[index] = record
                }
            }

            isSleeping = false
            sleepStartTime = nil
            stopTimer()

            // Cancelar reminder de acordar
            if let baby = currentBaby {
                notificationService.cancelNapReminders(for: baby.id)

                // Agendar notificação para próxima soneca baseada no wake window
                await notificationService.scheduleNapReminder(for: baby, wakeUpTime: Date())

                // Agendar alertas de wake window (se habilitado)
                await scheduleWakeWindowNotification()

                // Agendar nap reminder via WakeWindowCalculator (30 min antes da janela)
                if wakeWindowAlertsEnabled {
                    wakeWindowNotificationManager.scheduleNapReminder(baby: baby, lastWakeTime: Date())
                }

                // Atualizar lastWakeTime para agora (bebe acabou de acordar)
                lastWakeTime = Date()

                // Iniciar timer do wake window
                startWakeWindowTimer()
            }

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Track para sistema de rating
            RatingManager.shared.trackSleepRecorded()

            // Sync with Apple Watch
            syncWithWatch()

            // Update home screen widget
            updateWidget()
        } catch {
            Logger.error("Failed to stop sleep: \(error)")
            errorMessage = "error.sleepStopFailed".localized
        }
    }

    // MARK: - Wake Window Notification
    private func scheduleWakeWindowNotification() async {
        guard wakeWindowAlertsEnabled,
              let baby = currentBaby else { return }

        // Pega o último horário que o bebê acordou
        let lastWakeTime: Date
        if let lastSleep = todaysSleepRecords.first(where: { $0.endTime != nil }),
           let endTime = lastSleep.endTime {
            lastWakeTime = endTime
        } else {
            // Se não tem registro, assume que acordou agora
            lastWakeTime = Date()
        }

        // Calcula wake window médio em minutos
        let wakeWindowMinutes = Int(baby.recommendedWakeWindow / 60)

        await notificationService.scheduleWakeWindowAlert(
            babyName: baby.name,
            wakeWindowMinutes: wakeWindowMinutes,
            lastWakeTime: lastWakeTime,
            alertBeforeMinutes: alertMinutesBefore,
            baby: baby
        )
    }

    // MARK: - Wake Window Calculation
    private func updateWakeWindowStatus() {
        guard !isSleeping, let baby = currentBaby else {
            wakeWindowProgress = 0
            babyStatus = .happy
            sleepRecommendation = .nap
            return
        }

        // Atualizar recomendacao de sono baseada no horario
        sleepRecommendation = baby.currentSleepRecommendation()

        // Encontrar ultimo horario que o bebe acordou
        if let lastSleep = todaysSleepRecords.first(where: { $0.endTime != nil }) {
            lastWakeTime = lastSleep.endTime
        } else {
            // Se nao tem registro hoje, usar nil (nao mostrar contagem)
            lastWakeTime = nil
            wakeWindowProgress = 0
            babyStatus = .happy
            return
        }

        guard let wakeTime = lastWakeTime else { return }

        // Calcular tempo acordado
        timeAwake = Date().timeIntervalSince(wakeTime)
        let wakeWindowSeconds = baby.recommendedWakeWindow

        // Calcular progresso (0.0 a 1.0+)
        wakeWindowProgress = min(timeAwake / wakeWindowSeconds, 1.5) // Cap em 150%

        // Determinar status do bebe
        let percentage = timeAwake / wakeWindowSeconds
        switch percentage {
        case 0..<0.6:
            babyStatus = .happy
        case 0.6..<0.85:
            babyStatus = .gettingSleepy
        case 0.85..<1.0:
            babyStatus = .tired
        default:
            babyStatus = .overtired
        }
    }

    // MARK: - Sleep Learning

    /// Atualiza as preferencias aprendidas baseado no historico
    private func updateSleepLearning() async {
        guard var baby = currentBaby else { return }

        // So atualizar se nao atualizou nas ultimas 6 horas
        if baby.sleepPreferences.isLearningUpToDate {
            return
        }

        do {
            // Carregar registros dos ultimos 14 dias
            let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
            let recentRecords = try await sleepRepository.fetchRecords(
                for: baby.id,
                from: fourteenDaysAgo,
                to: Date()
            )

            // Calcular preferencias aprendidas
            let updatedPreferences = learningService.calculateLearnedPreferences(
                from: recentRecords,
                existingPreferences: baby.sleepPreferences
            )

            // Atualizar o bebe com as novas preferencias
            baby.sleepPreferences = updatedPreferences

            // Atualizar o bebe atual
            self.currentBaby = baby

            #if DEBUG
            if updatedPreferences.hasReliableLearning {
                Logger.info("Aprendizado atualizado: Wake \(updatedPreferences.learnedWakeTime?.formatted ?? "nil"), Bedtime \(updatedPreferences.learnedBedtime?.formatted ?? "nil"), Nap \(updatedPreferences.learnedNapDuration ?? 0)min, Window \(updatedPreferences.learnedWakeWindow ?? 0)min")
            }
            #endif

        } catch {
            Logger.error("Erro ao atualizar aprendizado: \(error)")
        }
    }

    // MARK: - Timeline
    private func updateTimeline() {
        guard let baby = currentBaby else {
            timelineEvents = []
            return
        }

        timelineEvents = TimelineCalculator.generateTimeline(
            for: baby,
            sleepRecords: todaysSleepRecords,
            wakeTime: lastWakeTime
        )
    }

    // MARK: - Update Sleep Preferences

    /// Atualiza as preferencias de sono do bebe atual
    func updateBabySleepPreferences(_ preferences: BabySleepPreferences) async {
        guard var baby = currentBaby else { return }

        // Atualizar localmente
        baby.sleepPreferences = preferences
        currentBaby = baby

        // Atualizar timeline com novas preferencias
        updateTimeline()

        // Atualizar no Supabase
        do {
            try await babyRepository.updateSleepPreferences(babyId: baby.id, preferences: preferences)
            Logger.info("DashboardViewModel: Sleep preferences updated for \(baby.name)")
        } catch {
            Logger.error("DashboardViewModel: Failed to update sleep preferences: \(error)")
        }
    }

    var timeUntilNap: TimeInterval {
        guard let baby = currentBaby, let wakeTime = lastWakeTime else { return 0 }
        let wakeWindowSeconds = baby.recommendedWakeWindow
        let elapsed = Date().timeIntervalSince(wakeTime)
        return max(wakeWindowSeconds - elapsed, 0)
    }

    var timeAwakeFormatted: String {
        let minutes = Int(timeAwake / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)min"
        }
    }

    var timeUntilNapFormatted: String {
        let minutes = Int(timeUntilNap / 60)
        if minutes <= 0 {
            return "wakeWindow.timeUp".localized
        } else if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)min"
        }
    }

    func toggleSleep() async {
        if isSleeping {
            // Mostrar sheet para qualidade do sono
            showQualitySheet = true
        } else {
            await startSleep()
        }
    }

    // MARK: - Timer
    private func startTimer() {
        stopTimer()
        updateDuration()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateDuration()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        currentSleepDuration = 0
    }

    private func updateDuration() {
        guard let startTime = sleepStartTime else { return }
        currentSleepDuration = Date().timeIntervalSince(startTime)
    }

    // MARK: - Wake Window Timer
    private func startWakeWindowTimer() {
        stopWakeWindowTimer()
        updateWakeWindowStatus()
        updateTimeline()
        wakeWindowTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateWakeWindowStatus()
                self?.updateTimeline()
            }
        }
    }

    private func stopWakeWindowTimer() {
        wakeWindowTimer?.invalidate()
        wakeWindowTimer = nil
    }

    func refreshData() async {
        await loadData()
    }

    // MARK: - Load All Today Activities
    private func loadTodayActivities(for babyId: UUID) async {
        // CORREÇÃO: Garantir que temos os dados de sono mais recentes
        // Se todaysSleepRecords estiver vazio, carregar antes de montar atividades
        if todaysSleepRecords.isEmpty {
            do {
                try await sleepRepository.fetchTodaysRecords(for: babyId)
                todaysSleepRecords = sleepRepository.sleepRecords
                Logger.info("✅ Sleep records loaded in loadTodayActivities: \(todaysSleepRecords.count) records")
            } catch {
                Logger.error("❌ Failed to load sleep records in loadTodayActivities: \(error)")
            }
        }

        do {
            // Carregar todas as atividades em paralelo
            async let feedingRecords = feedingRepository.fetchTodayRecords(babyId: babyId)
            async let diaperRecords = diaperRepository.fetchTodayRecords(babyId: babyId)
            async let bathRecords = bathRepository.fetchTodayRecords(babyId: babyId)
            async let healthRecords = healthRepository.fetchTodayRecords(babyId: babyId)

            // Aguardar todas as chamadas
            let (feedings, diapers, baths, healths) = try await (
                feedingRecords,
                diaperRecords,
                bathRecords,
                healthRecords
            )

            // Combinar todas as atividades
            var activities: [ActivityItem] = []

            // Adicionar sono (agora garantido que está carregado)
            activities.append(contentsOf: todaysSleepRecords.map { ActivityItem(type: .sleep($0)) })

            // Adicionar alimentação
            activities.append(contentsOf: feedings.map { ActivityItem(type: .feeding($0)) })

            // Adicionar fraldas
            activities.append(contentsOf: diapers.map { ActivityItem(type: .diaper($0)) })

            // Adicionar banhos
            activities.append(contentsOf: baths.map { ActivityItem(type: .bath($0)) })

            // Adicionar saúde (temperatura e medicamentos)
            activities.append(contentsOf: healths.map { ActivityItem(type: .health($0)) })

            // Ordenar por horário (mais recente primeiro)
            todayActivities = activities.sorted { $0.sortDate > $1.sortDate }

            let finalSleepCount = todayActivities.filter { if case .sleep = $0.type { return true }; return false }.count
            Logger.info("Loaded \(todayActivities.count) activities for today (including \(finalSleepCount) sleep records)")
        } catch {
            Logger.error("Failed to load today activities: \(error)")
            // Fallback: usar apenas sleep records já carregados
            todayActivities = todaysSleepRecords.map { ActivityItem(type: .sleep($0)) }
        }
    }

    // MARK: - Watch Connectivity

    private func setupWatchConnectivity() {
        // Listen for watch requests to start sleep
        NotificationCenter.default.publisher(for: .watchRequestedStartSleep)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                if let type = notification.userInfo?["type"] as? SleepRecord.SleepType {
                    Task {
                        await self.startSleep(type: type)
                        // Send reply if handler exists
                        if let replyHandler = notification.userInfo?["replyHandler"] as? ([String: Any]) -> Void {
                            replyHandler(["success": true])
                        }
                        // Sync with watch
                        self.syncWithWatch()
                    }
                }
            }
            .store(in: &watchCancellables)

        // Listen for watch requests to stop sleep
        NotificationCenter.default.publisher(for: .watchRequestedStopSleep)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                Task {
                    await self.stopSleep()
                    // Send reply with updated stats
                    if let replyHandler = notification.userInfo?["replyHandler"] as? ([String: Any]) -> Void {
                        replyHandler([
                            "success": true,
                            "todayTotalSleep": self.totalSleepMinutes,
                            "todayNaps": self.numberOfNaps
                        ])
                    }
                    // Sync with watch
                    self.syncWithWatch()
                }
            }
            .store(in: &watchCancellables)

        // Listen for watch sync requests
        NotificationCenter.default.publisher(for: .watchRequestedSync)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                self.handleWatchSyncRequest(notification)
            }
            .store(in: &watchCancellables)

        // Listen for watch becoming reachable - auto sync
        NotificationCenter.default.publisher(for: .watchBecameReachable)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Logger.info("📱 Watch became reachable - syncing data")
                self.syncWithWatch()
            }
            .store(in: &watchCancellables)
    }

    private func handleWatchSyncRequest(_ notification: Notification) {
        guard let baby = currentBaby else { return }

        let response: [String: Any] = [
            "baby": [
                "id": baby.id.uuidString,
                "name": baby.name,
                "ageDescription": baby.ageDescription,
                "recommendedWakeWindow": Int(baby.recommendedWakeWindow / 60)
            ],
            "isSleeping": isSleeping,
            "sleepType": currentSleepType?.rawValue ?? "",
            "sleepStartTime": sleepStartTime?.timeIntervalSince1970 ?? 0,
            "todayTotalSleep": totalSleepMinutes,
            "todayNaps": numberOfNaps
        ]

        if let replyHandler = notification.userInfo?["replyHandler"] as? ([String: Any]) -> Void {
            replyHandler(response)
        }
    }

    func syncWithWatch() {
        guard let baby = currentBaby else { return }

        watchConnectivity.sendSleepUpdate(
            baby: baby,
            isSleeping: isSleeping,
            sleepType: currentSleepType,
            sleepStartTime: sleepStartTime,
            todayTotalSleep: totalSleepMinutes,
            todayNaps: numberOfNaps
        )
    }

    // MARK: - Widget Support

    private func setupWidgetObservers() {
        NotificationCenter.default.addObserver(
            forName: .widgetRequestedStartSleep,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.startSleep(type: .nap)
            }
        }

        NotificationCenter.default.addObserver(
            forName: .widgetRequestedStopSleep,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.toggleSleep()
            }
        }
    }

    private func updateWidget() {
        guard let baby = currentBaby else { return }

        WidgetDataManager.updateWidget(
            babyName: baby.name,
            isSleeping: isSleeping,
            sleepType: currentSleepType?.rawValue,
            sleepStartTime: sleepStartTime,
            todayTotalSleepMinutes: totalSleepMinutes,
            todayNapsCount: numberOfNaps
        )
    }

    deinit {
        timer?.invalidate()
        wakeWindowTimer?.invalidate()
        watchCancellables.removeAll()
    }
}
