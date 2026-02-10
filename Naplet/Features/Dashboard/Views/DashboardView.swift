import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var ratingManager = RatingManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var selectedSleepRecord: SleepRecord?
    @State private var selectedFeedingRecord: FeedingRecord?
    @State private var selectedDiaperRecord: DiaperRecord?
    @State private var selectedBathRecord: BathRecord?
    @State private var selectedHealthRecord: HealthRecord?
    @State private var showChat = false
    @State private var showReport = false
    @State private var showFeeding = false
    @State private var showDiaper = false
    @State private var showTemperature = false
    @State private var showMedication = false
    @State private var showBath = false
    @State private var showProfile = false
    @State private var showVaccination = false
    @State private var showDocuments = false
    @State private var showSleepScheduleSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background with stars
                NapletColors.background
                    .ignoresSafeArea()

                FloatingStarsView(starCount: 15)
                    .opacity(0.5)
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.currentBaby == nil {
                    loadingView
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: NapletSpacing.lg) {
                            headerView
                            sleepStatusCard

                            // Timeline do dia
                            if !viewModel.timelineEvents.isEmpty {
                                TimelineView(
                                    events: viewModel.timelineEvents,
                                    baby: viewModel.currentBaby,
                                    onConfigureTapped: {
                                        showSleepScheduleSettings = true
                                    }
                                )
                                .padding(.horizontal, NapletSpacing.lg)
                            }

                            statsView
                            quickActionsView

                            if !viewModel.todayActivities.isEmpty {
                                recentActivityView
                            } else {
                                emptyActivityView
                            }

                            // Espaço extra para garantir scroll
                            Color.clear
                                .frame(height: 150)
                        }
                        .padding(.bottom, NapletSpacing.xxl)
                    }
                    .scrollBounceBehavior(.always)
                    .refreshable {
                        await viewModel.refreshData()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await viewModel.loadData()
        }
        .onAppear {
            // Track app launch para sistema de rating
            ratingManager.trackAppLaunch()
        }
        .overlay {
            // Rating prompt overlay
            if ratingManager.shouldShowRatingPrompt {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        ratingManager.dismissPrompt()
                    }

                RatingPromptView()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: ratingManager.shouldShowRatingPrompt)
        .sheet(isPresented: $viewModel.showQualitySheet) {
            SleepQualitySheet(viewModel: viewModel)
                .presentationBackground(NapletColors.background)
        }
        .sheet(item: $selectedSleepRecord) { record in
            SleepRecordDetailSheet(record: record)
                .presentationBackground(NapletColors.background)
        }
        .sheet(item: $selectedFeedingRecord) { record in
            FeedingDetailSheet(record: record)
                .presentationBackground(NapletColors.background)
        }
        .sheet(item: $selectedDiaperRecord) { record in
            DiaperDetailSheet(record: record)
                .presentationBackground(NapletColors.background)
        }
        .sheet(item: $selectedBathRecord) { record in
            BathDetailSheet(record: record)
                .presentationBackground(NapletColors.background)
        }
        .sheet(item: $selectedHealthRecord) { record in
            HealthDetailSheet(record: record)
                .presentationBackground(NapletColors.background)
        }
        .sheet(isPresented: $showChat) {
            if let baby = viewModel.currentBaby {
                ChatView(baby: baby, sleepRecords: viewModel.todaysSleepRecords)
                    .presentationBackground(NapletColors.background)
            }
        }
        .sheet(isPresented: $showReport) {
            if let baby = viewModel.currentBaby {
                ReportView(baby: baby)
                    .presentationBackground(NapletColors.background)
            }
        }
        .sheet(isPresented: $showFeeding) {
            if let baby = viewModel.currentBaby {
                FeedingView(baby: baby)
                    .presentationBackground(NapletColors.background)
            }
        }
        .sheet(isPresented: $showDiaper) {
            if let baby = viewModel.currentBaby {
                DiaperChangeView(baby: baby)
                    .presentationBackground(NapletColors.background)
            }
        }
        .sheet(isPresented: $showTemperature) {
            if let baby = viewModel.currentBaby {
                TemperatureView(baby: baby)
                    .presentationBackground(NapletColors.background)
            }
        }
        .sheet(isPresented: $showMedication) {
            if let baby = viewModel.currentBaby {
                MedicationView(baby: baby)
                    .presentationBackground(NapletColors.background)
            }
        }
        .sheet(isPresented: $showBath) {
            if let baby = viewModel.currentBaby {
                BathView(baby: baby)
                    .presentationBackground(NapletColors.background)
            }
        }
        .sheet(isPresented: $showVaccination) {
            if let baby = viewModel.currentBaby {
                NavigationStack {
                    VaccinationDashboardView(baby: baby)
                }
                .presentationBackground(NapletColors.background)
            }
        }
        .sheet(isPresented: $showDocuments) {
            if let baby = viewModel.currentBaby {
                NavigationStack {
                    DocumentsView(baby: baby)
                }
                .presentationBackground(NapletColors.background)
            }
        }
        .sheet(isPresented: $showSleepScheduleSettings) {
            if let baby = viewModel.currentBaby {
                SleepScheduleSettingsView(baby: baby) { newPreferences in
                    Task {
                        await viewModel.updateBabySleepPreferences(newPreferences)
                    }
                }
                .presentationBackground(NapletColors.background)
            }
        }
        .sheet(isPresented: $showProfile, onDismiss: {
            // Recarrega o perfil quando fechar a tela de edição
            Task {
                await viewModel.reloadProfile()
            }
        }) {
            ProfileView()
                .presentationBackground(NapletColors.background)
        }
        .alert(L10n.Common.error.localized, isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(L10n.Common.ok.localized) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .id(localizationManager.refreshID) // Force rebuild when language changes
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: NapletSpacing.lg) {
            AnimatedMoonIcon(size: 80)

            Text(L10n.Common.loading.localized)
                .font(.system(size: NapletTypography.body))
                .foregroundColor(NapletColors.textSecondary)
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: NapletSpacing.xs) {
                Text("\(viewModel.greeting)!")
                    .font(.system(size: NapletTypography.subheadline))
                    .foregroundColor(NapletColors.textSecondary)

                Text(viewModel.currentBaby?.name ?? "Baby")
                    .font(.system(size: NapletTypography.largeTitle, weight: .bold))
                    .foregroundColor(NapletColors.textPrimary)
            }

            Spacer()

            // Referral button
            ReferralButton()

            // Profile button with avatar
            Button {
                showProfile = true
            } label: {
                UserAvatarView(
                    profile: viewModel.currentProfile,
                    size: .medium,
                    showBorder: true
                )
            }
        }
        .padding(.horizontal, NapletSpacing.lg)
        .padding(.top, NapletSpacing.md)
    }

    // MARK: - Sleep Status Card
    private var sleepStatusCard: some View {
        GradientBorderCard(isActive: viewModel.isSleeping) {
            VStack(spacing: NapletSpacing.lg) {
                // Status indicator
                HStack {
                    SleepStatusIndicator(isSleeping: viewModel.isSleeping)

                    Spacer()

                    if let baby = viewModel.currentBaby {
                        Text(baby.ageDescription)
                            .font(.system(size: NapletTypography.caption, weight: .medium))
                            .foregroundColor(NapletColors.textMuted)
                            .padding(.horizontal, NapletSpacing.sm)
                            .padding(.vertical, NapletSpacing.xs)
                            .background(NapletColors.backgroundTertiary)
                            .cornerRadius(8)
                    }
                }

                // Main content
                if viewModel.isSleeping {
                    sleepingView
                } else {
                    awakeView
                }

                // Action Button
                Button(action: {
                    Task {
                        await viewModel.toggleSleep()
                    }
                }) {
                    HStack(spacing: NapletSpacing.sm) {
                        Image(systemName: viewModel.isSleeping ? "sun.max.fill" : "moon.zzz.fill")
                            .font(.system(size: 20, weight: .semibold))

                        Text(viewModel.isSleeping ? "dashboard.wakeUp".localized : "dashboard.startSleep".localized)
                            .font(.system(size: NapletTypography.headline, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, NapletSpacing.md)
                    .background(
                        viewModel.isSleeping ?
                        NapletColors.gradientSunrise :
                        NapletColors.gradientPrimary
                    )
                    .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal, NapletSpacing.lg)
    }

    private var sleepingView: some View {
        VStack(spacing: NapletSpacing.sm) {
            AnimatedMoonIcon(size: 50, isAnimating: true)
                .breathing()

            Text(viewModel.currentSleepFormatted)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(NapletColors.textPrimary)
                .monospacedDigit()

            Text(L10n.Dashboard.Stats.sleepDuration.localized)
                .font(.system(size: NapletTypography.caption))
                .foregroundColor(NapletColors.textMuted)
        }
        .padding(.vertical, NapletSpacing.lg)
    }

    private var awakeView: some View {
        VStack(spacing: NapletSpacing.lg) {
            // Verificar recomendacao de sono baseada no horario
            switch viewModel.sleepRecommendation {
            case .prepareBedtime, .bedtime, .pastBedtime:
                // Horario de preparar ou dormir - mostrar view de bedtime
                bedtimeStatusView
            case .tooEarly:
                // Madrugada - mostrar view especial
                tooEarlyView
            case .nap:
                // Horario de soneca - mostrar wake window normal
                if viewModel.lastWakeTime != nil {
                    wakeWindowStatusView
                } else {
                    // Sem registros - mostrar mensagem de boas-vindas
                    noWakeRecordsView
                }
            }
        }
        .padding(.vertical, NapletSpacing.md)
    }

    // MARK: - Wake Window Status View
    private var wakeWindowStatusView: some View {
        VStack(spacing: NapletSpacing.md) {
            // Icone do status com fundo circular
            ZStack {
                Circle()
                    .fill(viewModel.babyStatus.color.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: viewModel.babyStatus.icon)
                    .font(.system(size: 36))
                    .foregroundColor(viewModel.babyStatus.color)
                    .symbolEffect(.pulse, options: .repeating, value: viewModel.babyStatus == .overtired)
            }
            .breathing(intensity: viewModel.babyStatus == .happy ? 0.05 : 0.1)

            // Tempo acordado
            VStack(spacing: 4) {
                Text("wakeWindow.awakeFor".localized)
                    .font(.system(size: NapletTypography.caption))
                    .foregroundColor(NapletColors.textMuted)

                Text(viewModel.timeAwakeFormatted)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(NapletColors.textPrimary)
                    .monospacedDigit()
            }

            // Barra de progresso da janela de sono
            wakeWindowProgressBar

            // Tempo ate proxima soneca
            if viewModel.timeUntilNap > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14))
                    Text(String(format: "wakeWindow.napIn".localized, viewModel.timeUntilNapFormatted))
                        .font(.system(size: NapletTypography.subheadline, weight: .medium))
                }
                .foregroundColor(viewModel.babyStatus.color)
            }

            // Mensagem de status com nome do bebe
            Text(viewModel.babyStatus.messageKey.localized(with: viewModel.currentBaby?.name ?? ""))
                .font(.system(size: NapletTypography.body))
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, NapletSpacing.sm)

            // Dica pratica
            tipCard
        }
    }

    // MARK: - Wake Window Progress Bar
    private var wakeWindowProgressBar: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(NapletColors.backgroundTertiary)
                        .frame(height: 12)

                    // Progress
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    viewModel.wakeWindowProgress < 0.6 ? NapletColors.success :
                                    viewModel.wakeWindowProgress < 0.85 ? NapletColors.warning :
                                    NapletColors.error,
                                    viewModel.wakeWindowProgress < 0.6 ? NapletColors.success.opacity(0.7) :
                                    viewModel.wakeWindowProgress < 0.85 ? NapletColors.warning.opacity(0.7) :
                                    NapletColors.error.opacity(0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(CGFloat(viewModel.wakeWindowProgress), 1.0), height: 12)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.wakeWindowProgress)
                }
            }
            .frame(height: 12)

            // Labels
            HStack {
                Text("0")
                    .font(.system(size: 10))
                    .foregroundColor(NapletColors.textMuted)
                Spacer()
                if let baby = viewModel.currentBaby {
                    Text("\(Int(baby.recommendedWakeWindow / 60)) min")
                        .font(.system(size: 10))
                        .foregroundColor(NapletColors.textMuted)
                }
            }
        }
        .padding(.horizontal, NapletSpacing.md)
    }

    // MARK: - Tip Card
    private var tipCard: some View {
        HStack(spacing: NapletSpacing.sm) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 16))
                .foregroundColor(NapletColors.warning)

            Text(viewModel.babyStatus.tipKey.localized)
                .font(.system(size: NapletTypography.caption))
                .foregroundColor(NapletColors.textSecondary)
                .lineLimit(2)

            Spacer()
        }
        .padding(NapletSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(NapletColors.warning.opacity(0.1))
        )
        .padding(.horizontal, NapletSpacing.sm)
    }

    // MARK: - No Wake Records View
    private var noWakeRecordsView: some View {
        VStack(spacing: NapletSpacing.md) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 50))
                .foregroundStyle(NapletColors.gradientSunrise)
                .breathing(intensity: 0.1)

            Text(L10n.Dashboard.Status.readyForSleep.localized)
                .font(.system(size: NapletTypography.title2, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)

            if let baby = viewModel.currentBaby {
                let range = baby.recommendedWakeWindowMinutes
                Text(String(format: "wakeWindow.recommended".localized, range.lowerBound, range.upperBound))
                    .font(.system(size: NapletTypography.caption))
                    .foregroundColor(NapletColors.textMuted)
            }

            Text("wakeWindow.startTracking".localized)
                .font(.system(size: NapletTypography.body))
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - Bedtime Status View
    private var bedtimeStatusView: some View {
        VStack(spacing: NapletSpacing.md) {
            // Icone de lua/noite com fundo circular
            ZStack {
                Circle()
                    .fill(NapletColors.primaryBlue.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: bedtimeIcon)
                    .font(.system(size: 36))
                    .foregroundColor(NapletColors.primaryBlue)
                    .symbolEffect(.pulse, options: .repeating, value: viewModel.sleepRecommendation == .pastBedtime)
            }
            .breathing(intensity: 0.1)

            // Titulo baseado no status
            Text(bedtimeTitle)
                .font(.system(size: NapletTypography.title2, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)

            // Horario de bedtime recomendado
            if let baby = viewModel.currentBaby {
                HStack(spacing: 4) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 14))
                    Text(String(format: "bedtime.recommendedTime".localized, baby.bedtimeFormatted))
                        .font(.system(size: NapletTypography.subheadline, weight: .medium))
                }
                .foregroundColor(NapletColors.primaryBlue)
            }

            // Mensagem de status
            Text(bedtimeMessage)
                .font(.system(size: NapletTypography.body))
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, NapletSpacing.sm)

            // Dica para bedtime
            bedtimeTipCard
        }
    }

    private var bedtimeIcon: String {
        switch viewModel.sleepRecommendation {
        case .prepareBedtime:
            return "moon.stars.fill"
        case .bedtime:
            return "moon.zzz.fill"
        case .pastBedtime:
            return "moon.fill"
        default:
            return "moon.stars.fill"
        }
    }

    private var bedtimeTitle: String {
        switch viewModel.sleepRecommendation {
        case .prepareBedtime:
            return "bedtime.prepare.title".localized
        case .bedtime:
            return "bedtime.now.title".localized
        case .pastBedtime:
            return "bedtime.past.title".localized
        default:
            return "bedtime.prepare.title".localized
        }
    }

    private var bedtimeMessage: String {
        let babyName = viewModel.currentBaby?.name ?? ""
        switch viewModel.sleepRecommendation {
        case .prepareBedtime:
            return "bedtime.prepare.message".localized(with: babyName)
        case .bedtime:
            return "bedtime.now.message".localized(with: babyName)
        case .pastBedtime:
            return "bedtime.past.message".localized(with: babyName)
        default:
            return "bedtime.prepare.message".localized(with: babyName)
        }
    }

    private var bedtimeTipCard: some View {
        HStack(spacing: NapletSpacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundColor(NapletColors.primaryBlue)

            Text(bedtimeTip)
                .font(.system(size: NapletTypography.caption))
                .foregroundColor(NapletColors.textSecondary)
                .lineLimit(2)

            Spacer()
        }
        .padding(NapletSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(NapletColors.primaryBlue.opacity(0.1))
        )
        .padding(.horizontal, NapletSpacing.sm)
    }

    private var bedtimeTip: String {
        switch viewModel.sleepRecommendation {
        case .prepareBedtime:
            return "bedtime.tip.prepare".localized
        case .bedtime:
            return "bedtime.tip.now".localized
        case .pastBedtime:
            return "bedtime.tip.past".localized
        default:
            return "bedtime.tip.prepare".localized
        }
    }

    // MARK: - Too Early View
    private var tooEarlyView: some View {
        VStack(spacing: NapletSpacing.md) {
            // Icone de noite/madrugada
            ZStack {
                Circle()
                    .fill(NapletColors.primaryPurple.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 36))
                    .foregroundColor(NapletColors.primaryPurple)
            }
            .breathing(intensity: 0.05)

            Text("tooEarly.title".localized)
                .font(.system(size: NapletTypography.title2, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)

            // Horario recomendado para acordar
            if let baby = viewModel.currentBaby {
                let wakeTime = baby.recommendedWakeTime
                let wakeTimeFormatted = String(format: "%02d:%02d", wakeTime.hour, wakeTime.minute)
                HStack(spacing: 4) {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 14))
                    Text(String(format: "tooEarly.wakeTime".localized, wakeTimeFormatted))
                        .font(.system(size: NapletTypography.subheadline, weight: .medium))
                }
                .foregroundColor(NapletColors.primaryPurple)
            }

            Text("tooEarly.message".localized(with: viewModel.currentBaby?.name ?? ""))
                .font(.system(size: NapletTypography.body))
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, NapletSpacing.sm)

            // Dica para madrugada
            HStack(spacing: NapletSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundColor(NapletColors.primaryPurple)

                Text("tooEarly.tip".localized)
                    .font(.system(size: NapletTypography.caption))
                    .foregroundColor(NapletColors.textSecondary)
                    .lineLimit(2)

                Spacer()
            }
            .padding(NapletSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(NapletColors.primaryPurple.opacity(0.1))
            )
            .padding(.horizontal, NapletSpacing.sm)
        }
    }

    // MARK: - Stats View
    private var statsView: some View {
        HStack(spacing: NapletSpacing.md) {
            // Total Sleep Card
            GlassCard(padding: NapletSpacing.md) {
                HStack(spacing: NapletSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(NapletColors.primaryPurple.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "moon.fill")
                            .font(.system(size: 20))
                            .foregroundColor(NapletColors.primaryPurple)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.totalSleepFormatted)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(NapletColors.textPrimary)
                        
                        Text(L10n.Dashboard.Stats.totalSleep.localized)
                            .font(.system(size: 12))
                            .foregroundColor(NapletColors.textMuted)
                    }
                    
                    Spacer()
                }
            }
            
            // Naps Card
            GlassCard(padding: NapletSpacing.md) {
                HStack(spacing: NapletSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(NapletColors.primaryPink.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "zzz")
                            .font(.system(size: 20))
                            .foregroundColor(NapletColors.primaryPink)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.numberOfNaps)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(NapletColors.textPrimary)
                        
                        Text(L10n.Dashboard.Stats.naps.localized)
                            .font(.system(size: 12))
                            .foregroundColor(NapletColors.textMuted)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, NapletSpacing.lg)
    }

    // MARK: - Quick Actions
    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            Text(L10n.Dashboard.QuickActions.title.localized)
                .font(.system(size: NapletTypography.headline, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)
                .padding(.horizontal, NapletSpacing.lg)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: NapletSpacing.sm),
                GridItem(.flexible(), spacing: NapletSpacing.sm),
                GridItem(.flexible(), spacing: NapletSpacing.sm)
            ], spacing: NapletSpacing.sm) {
                ActionCardEnhanced(
                    icon: "moon.zzz.fill",
                    title: L10n.Dashboard.QuickActions.nap.localized,
                    subtitle: L10n.Dashboard.startSleep.localized,
                    gradientColors: [NapletColors.primaryPurple, NapletColors.primaryPink]
                ) {
                    Task { await viewModel.startSleep(type: .nap) }
                }
                .disabled(viewModel.isSleeping)
                .opacity(viewModel.isSleeping ? 0.5 : 1)

                ActionCardEnhanced(
                    icon: "moon.stars.fill",
                    title: L10n.Dashboard.QuickActions.nightSleep.localized,
                    subtitle: L10n.Dashboard.startSleep.localized,
                    gradientColors: [NapletColors.primaryBlue, NapletColors.primaryCyan]
                ) {
                    Task { await viewModel.startSleep(type: .night) }
                }
                .disabled(viewModel.isSleeping)
                .opacity(viewModel.isSleeping ? 0.5 : 1)

                ActionCardEnhanced(
                    icon: "fork.knife",
                    title: L10n.Feeding.title.localized,
                    subtitle: L10n.Feeding.selectType.localized,
                    gradientColors: [Color(hex: "#F59E0B"), Color(hex: "#FBBF24")]
                ) {
                    showFeeding = true
                }

                ActionCardEnhanced(
                    icon: "drop.triangle.fill",
                    title: "diaper.title".localized,
                    subtitle: "diaper.subtitle".localized,
                    gradientColors: [NapletColors.info, Color(hex: "#60A5FA")]
                ) {
                    showDiaper = true
                }

                ActionCardEnhanced(
                    icon: "thermometer",
                    title: "health.temperature".localized,
                    subtitle: "health.record".localized,
                    gradientColors: [NapletColors.warning, Color(hex: "#FBBF24")]
                ) {
                    showTemperature = true
                }

                ActionCardEnhanced(
                    icon: "pills.fill",
                    title: "health.medication".localized,
                    subtitle: "health.record".localized,
                    gradientColors: [NapletColors.primaryCyan, Color(hex: "#22D3EE")]
                ) {
                    showMedication = true
                }

                ActionCardEnhanced(
                    icon: "bathtub.fill",
                    title: "bath.title".localized,
                    subtitle: "bath.subtitle".localized,
                    gradientColors: [NapletColors.primaryCyan, NapletColors.primaryBlue]
                ) {
                    showBath = true
                }

                ActionCardEnhanced(
                    icon: "syringe.fill",
                    title: "vaccination.dashboard.title".localized,
                    subtitle: "vaccination.progress.title".localized,
                    gradientColors: [NapletColors.primaryPurple, Color(hex: "#A78BFA")]
                ) {
                    showVaccination = true
                }

                ActionCardEnhanced(
                    icon: "folder.fill",
                    title: "documents.title".localized,
                    subtitle: "documents.subtitle".localized,
                    gradientColors: [Color(hex: "#7C3AED"), Color(hex: "#EC4899")]
                ) {
                    showDocuments = true
                }

                // Sleep Report
                ActionCardEnhanced(
                    icon: "doc.text.fill",
                    title: L10n.Report.title.localized,
                    subtitle: L10n.Report.subtitle.localized,
                    gradientColors: [NapletColors.primaryPink, Color(hex: "#F472B6")]
                ) {
                    showReport = true
                }

                // AI Chat (only if enabled)
                if AppConfig.Features.enableAIChat {
                    ActionCardEnhanced(
                        icon: "sparkles",
                        title: L10n.Dashboard.QuickActions.aiChat.localized,
                        subtitle: L10n.AIChat.subtitle.localized,
                        gradientColors: [NapletColors.primaryPurple, NapletColors.primaryBlue]
                    ) {
                        showChat = true
                    }
                }

                ActionCardEnhanced(
                    icon: "chart.bar.fill",
                    title: L10n.Dashboard.QuickActions.statistics.localized,
                    subtitle: L10n.History.title.localized,
                    gradientColors: [NapletColors.success, Color(hex: "#34D399")]
                ) {
                    NotificationCenter.default.post(name: NSNotification.Name("SwitchToHistory"), object: nil)
                }

                ActionCardEnhanced(
                    icon: "gearshape.fill",
                    title: L10n.Dashboard.QuickActions.settings.localized,
                    subtitle: L10n.Settings.preferences.localized,
                    gradientColors: [NapletColors.textSecondary, NapletColors.textMuted]
                ) {
                    NotificationCenter.default.post(name: NSNotification.Name("SwitchToSettings"), object: nil)
                }
            }
            .padding(.horizontal, NapletSpacing.md)
        }
    }

    // MARK: - Recent Activity
    private var recentActivityView: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.md) {
            Text(L10n.Dashboard.todayActivity.localized)
                .font(.system(size: NapletTypography.headline, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)
                .padding(.horizontal, NapletSpacing.lg)

            VStack(spacing: NapletSpacing.sm) {
                ForEach(displayedActivities) { activity in
                    Button {
                        // Abrir detalhe de acordo com o tipo
                        switch activity.type {
                        case .sleep(let record):
                            selectedSleepRecord = record
                        case .feeding(let record):
                            selectedFeedingRecord = record
                        case .diaper(let record):
                            selectedDiaperRecord = record
                        case .bath(let record):
                            selectedBathRecord = record
                        case .health(let record):
                            selectedHealthRecord = record
                        }
                        // Haptic feedback
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        ActivityRowEnhanced(activity: activity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, NapletSpacing.lg)
        }
    }
    
    // MARK: - Displayed Activities (garante que todas as atividades de sono apareçam)
    private var displayedActivities: [ActivityItem] {
        let first10 = Array(viewModel.todayActivities.prefix(10))
        
        // Encontrar todas as atividades de sono que não estão nos primeiros 10
        let sleepActivities = viewModel.todayActivities.filter { activity in
            if case .sleep = activity.type {
                return !first10.contains { $0.id == activity.id }
            }
            return false
        }
        
        // Se houver atividades de sono fora dos primeiros 10, adicioná-las
        if !sleepActivities.isEmpty {
            return first10 + sleepActivities.sorted { $0.sortDate > $1.sortDate }
        }
        
        return first10
    }

    // MARK: - Empty Activity View
    private var emptyActivityView: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.md) {
            Text(L10n.Dashboard.todayActivity.localized)
                .font(.system(size: NapletTypography.headline, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)
                .padding(.horizontal, NapletSpacing.lg)

            GlassCard {
                VStack(spacing: NapletSpacing.md) {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 40))
                        .foregroundStyle(NapletColors.gradientPrimary)
                        .breathing(intensity: 0.1)

                    Text(L10n.Dashboard.noRecords.localized)
                        .font(.system(size: NapletTypography.headline, weight: .medium))
                        .foregroundColor(NapletColors.textPrimary)

                    Text(L10n.Dashboard.noRecordsSubtitle.localized)
                        .font(.system(size: NapletTypography.caption))
                        .foregroundColor(NapletColors.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, NapletSpacing.lg)
            }
            .padding(.horizontal, NapletSpacing.lg)
        }
    }
}

// MARK: - Enhanced Sleep Record Row
struct SleepRecordRowEnhanced: View {
    let record: SleepRecord

    var body: some View {
        GlassCard(padding: NapletSpacing.md) {
            HStack(spacing: NapletSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            record.type == .nap ?
                            NapletColors.primaryPurple.opacity(0.2) :
                            NapletColors.primaryBlue.opacity(0.2)
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: record.type.icon)
                        .font(.system(size: 18))
                        .foregroundColor(
                            record.type == .nap ?
                            NapletColors.primaryPurple :
                            NapletColors.primaryBlue
                        )
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.type.displayName)
                        .font(.system(size: NapletTypography.subheadline, weight: .semibold))
                        .foregroundColor(NapletColors.textPrimary)

                    Text(record.timeRangeFormatted)
                        .font(.system(size: NapletTypography.caption))
                        .foregroundColor(NapletColors.textMuted)
                }

                Spacer()

                // Duration or Active indicator
                if record.isActive {
                    HStack(spacing: 4) {
                        PulsingCircle(color: NapletColors.success, size: 8)

                        Text("dashboard.status.active".localized)
                            .font(.system(size: NapletTypography.caption, weight: .medium))
                            .foregroundColor(NapletColors.success)
                    }
                    .padding(.horizontal, NapletSpacing.sm)
                    .padding(.vertical, NapletSpacing.xs)
                    .background(NapletColors.success.opacity(0.2))
                    .cornerRadius(8)
                } else {
                    Text(record.durationFormatted)
                        .font(.system(size: NapletTypography.subheadline, weight: .bold))
                        .foregroundColor(NapletColors.primaryPurple)
                }
            }
        }
    }
}

// MARK: - Sleep Quality Sheet
struct SleepQualitySheet: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedQuality: SleepRecord.SleepQuality?
    @State private var notes: String = ""
    @FocusState private var isNotesFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                NapletColors.background
                    .ignoresSafeArea()

                FloatingStarsView(starCount: 10)
                    .opacity(0.3)
                    .ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: NapletSpacing.xl) {
                            AnimatedMoonIcon(size: 60)
                                .padding(.top, NapletSpacing.lg)

                            Text(L10n.SleepQuality.title.localized)
                                .font(.system(size: NapletTypography.title2, weight: .bold))
                                .foregroundColor(NapletColors.textPrimary)

                            HStack(spacing: NapletSpacing.md) {
                                ForEach(SleepRecord.SleepQuality.allCases, id: \.self) { quality in
                                    QualityButton(
                                        quality: quality,
                                        isSelected: selectedQuality == quality
                                    ) {
                                        selectedQuality = quality
                                    }
                                }
                            }
                            .padding(.horizontal, NapletSpacing.md)

                            VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                                Text(L10n.SleepQuality.notes.localized)
                                    .font(.system(size: NapletTypography.subheadline))
                                    .foregroundColor(NapletColors.textSecondary)

                                TextField(L10n.SleepQuality.notesPlaceholder.localized, text: $notes, axis: .vertical)
                                    .lineLimit(3...5)
                                    .padding()
                                    .background(NapletColors.backgroundSecondary)
                                    .cornerRadius(12)
                                    .foregroundColor(NapletColors.textPrimary)
                                    .focused($isNotesFocused)
                            }
                            .padding(.horizontal, NapletSpacing.lg)
                            .id("notesSection")

                            // Botao Save
                            Button(action: {
                                isNotesFocused = false
                                Task {
                                    await viewModel.stopSleep(
                                        quality: selectedQuality,
                                        notes: notes.isEmpty ? nil : notes
                                    )
                                    dismiss()
                                }
                            }) {
                                HStack(spacing: NapletSpacing.sm) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))

                                    Text(L10n.Common.save.localized)
                                        .font(.system(size: NapletTypography.headline, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, NapletSpacing.md)
                                .background(NapletColors.gradientPrimary)
                                .cornerRadius(16)
                            }
                            .padding(.horizontal, NapletSpacing.lg)
                            .padding(.top, NapletSpacing.lg)
                            .id("saveButton")

                            // Extra padding for keyboard
                            Color.clear
                                .frame(height: 100)
                        }
                        .padding(.bottom, NapletSpacing.xxl)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: isNotesFocused) { _, focused in
                        if focused {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo("saveButton", anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.skip.localized) {
                        Task {
                            await viewModel.stopSleep(quality: nil, notes: nil)
                            dismiss()
                        }
                    }
                    .foregroundColor(NapletColors.textSecondary)
                }

                // Toolbar para fechar teclado
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        isNotesFocused = false
                    } label: {
                        Text("common.done".localized)
                            .fontWeight(.semibold)
                            .foregroundColor(NapletColors.primaryPurple)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Quality Button
struct QualityButton: View {
    let quality: SleepRecord.SleepQuality
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: NapletSpacing.sm) {
                Image(systemName: quality.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? quality.color : NapletColors.textSecondary)

                Text(quality.displayName)
                    .font(.system(size: NapletTypography.caption))
                    .foregroundColor(isSelected ? NapletColors.textPrimary : NapletColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NapletSpacing.lg)
            .background(isSelected ? quality.color.opacity(0.2) : NapletColors.backgroundSecondary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? quality.color : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1)
            .shadow(color: isSelected ? quality.color.opacity(0.3) : .clear, radius: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
    }
}

// MARK: - Sleep Record Detail Sheet
struct SleepRecordDetailSheet: View {
    let record: SleepRecord

    private var accentColor: Color {
        record.type == .nap ? NapletColors.primaryPurple : NapletColors.primaryBlue
    }

    var body: some View {
        ScrollView {
            VStack(spacing: NapletSpacing.lg) {
                // Drag Indicator
                Capsule()
                    .fill(NapletColors.textMuted.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, NapletSpacing.sm)

                // Header
                VStack(spacing: NapletSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 72, height: 72)

                        Image(systemName: record.type.icon)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(accentColor)
                    }

                    Text(record.type.displayName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(NapletColors.textPrimary)

                    // Duration highlight
                    Text(record.durationFormatted)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                }
                .padding(.top, NapletSpacing.sm)

                // Details
                VStack(spacing: 0) {
                    // Time row
                    DetailRow(
                        icon: "clock",
                        title: "sleepDetail.start".localized,
                        value: record.startTime.formatted(date: .omitted, time: .shortened),
                        color: accentColor
                    )

                    Divider().padding(.leading, 52)

                    DetailRow(
                        icon: "clock.badge.checkmark",
                        title: "sleepDetail.end".localized,
                        value: record.endTime?.formatted(date: .omitted, time: .shortened) ?? "dashboard.status.active".localized,
                        color: record.endTime == nil ? NapletColors.success : accentColor
                    )

                    Divider().padding(.leading, 52)

                    DetailRow(
                        icon: "calendar",
                        title: "sleepDetail.date".localized,
                        value: record.startTime.formatted(date: .abbreviated, time: .omitted),
                        color: accentColor
                    )

                    // Quality
                    if let quality = record.quality {
                        Divider().padding(.leading, 52)
                        DetailRow(
                            icon: quality.icon,
                            title: "sleepDetail.quality".localized,
                            value: quality.displayName,
                            color: quality.color
                        )
                    }
                }
                .background(NapletColors.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal, NapletSpacing.md)

                // Notes
                if let notes = record.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: NapletSpacing.xs) {
                        Text("sleepDetail.notes".localized)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(NapletColors.textSecondary)
                            .padding(.horizontal, NapletSpacing.md)

                        Text(notes)
                            .font(.system(size: 15))
                            .foregroundColor(NapletColors.textPrimary)
                            .padding(NapletSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(NapletColors.cardBackground)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, NapletSpacing.md)
                }

                Spacer(minLength: NapletSpacing.lg)
            }
        }
        .background(NapletColors.background)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }
}

// MARK: - Detail Row Component
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: NapletSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 28)

            Text(title)
                .font(.system(size: 15))
                .foregroundColor(NapletColors.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(NapletColors.textPrimary)
        }
        .padding(.horizontal, NapletSpacing.md)
        .padding(.vertical, 14)
    }
}

// MARK: - Activity Row Enhanced (All Activity Types)
struct ActivityRowEnhanced: View {
    let activity: ActivityItem

    var body: some View {
        GlassCard(padding: NapletSpacing.md) {
            HStack(spacing: NapletSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(activity.type.color.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: activity.type.icon)
                        .font(.system(size: 18))
                        .foregroundColor(activity.type.color)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.type.title)
                        .font(.system(size: NapletTypography.subheadline, weight: .semibold))
                        .foregroundColor(NapletColors.textPrimary)

                    Text(activity.type.subtitle)
                        .font(.system(size: NapletTypography.caption))
                        .foregroundColor(NapletColors.textMuted)
                }

                Spacer()

                // Active indicator only (details will show in modal)
                if activity.type.isActive {
                    HStack(spacing: 4) {
                        PulsingCircle(color: NapletColors.success, size: 8)

                        Text("dashboard.status.active".localized)
                            .font(.system(size: NapletTypography.caption, weight: .medium))
                            .foregroundColor(NapletColors.success)
                    }
                    .padding(.horizontal, NapletSpacing.sm)
                    .padding(.vertical, NapletSpacing.xs)
                    .background(NapletColors.success.opacity(0.2))
                    .cornerRadius(8)
                } else {
                    // Indicador visual sutil de que há mais informações (chevron)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(NapletColors.textMuted.opacity(0.5))
                }
            }
        }
    }
}

// MARK: - Feeding Detail Sheet
struct FeedingDetailSheet: View {
    let record: FeedingRecord

    private var accentColor: Color {
        record.type.color
    }

    private var summaryValue: String {
        switch record.type {
        case .breast:
            let total = (record.durationLeftSeconds ?? 0) + (record.durationRightSeconds ?? 0)
            return "\(total / 60) min"
        case .bottle:
            if let amount = record.bottleAmountMl {
                return "\(Int(amount)) ml"
            }
            return "--"
        case .pumping:
            return "\(record.totalPumpingMl) ml"
        case .solid:
            return record.notes ?? "--"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: NapletSpacing.lg) {
                // Drag Indicator
                Capsule()
                    .fill(NapletColors.textMuted.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, NapletSpacing.sm)

                // Header
                VStack(spacing: NapletSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 72, height: 72)

                        Image(systemName: record.type.icon)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(accentColor)
                    }

                    Text(record.type.displayName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(NapletColors.textPrimary)

                    // Summary highlight
                    Text(summaryValue)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                }
                .padding(.top, NapletSpacing.sm)

                // Details
                VStack(spacing: 0) {
                    // Time row
                    DetailRow(
                        icon: "clock",
                        title: "health.time".localized,
                        value: record.startTime.formatted(date: .omitted, time: .shortened),
                        color: accentColor
                    )

                    Divider().padding(.leading, 52)

                    DetailRow(
                        icon: "calendar",
                        title: "sleepDetail.date".localized,
                        value: record.startTime.formatted(date: .abbreviated, time: .omitted),
                        color: accentColor
                    )

                    // Type specific rows
                    switch record.type {
                    case .breast:
                        if let left = record.durationLeftSeconds, left > 0 {
                            Divider().padding(.leading, 52)
                            DetailRow(
                                icon: "hand.raised.fill",
                                title: "feeding.breast.left".localized,
                                value: "\(left / 60) min",
                                color: accentColor
                            )
                        }
                        if let right = record.durationRightSeconds, right > 0 {
                            Divider().padding(.leading, 52)
                            DetailRow(
                                icon: "hand.raised.fill",
                                title: "feeding.breast.right".localized,
                                value: "\(right / 60) min",
                                color: accentColor
                            )
                        }
                    case .bottle:
                        if let amount = record.bottleAmountMl {
                            Divider().padding(.leading, 52)
                            DetailRow(
                                icon: "drop.fill",
                                title: "feeding.amount".localized,
                                value: "\(Int(amount)) ml",
                                color: accentColor
                            )
                        }
                    case .pumping:
                        Divider().padding(.leading, 52)
                        DetailRow(
                            icon: "drop.fill",
                            title: "feeding.amount".localized,
                            value: "\(record.totalPumpingMl) ml",
                            color: accentColor
                        )
                    case .solid:
                        // Mostrar alimentos/ingredientes se houver notas
                        if let notes = record.notes, !notes.isEmpty {
                            Divider().padding(.leading, 52)
                            DetailRow(
                                icon: "fork.knife",
                                title: "feeding.solid.foods".localized,
                                value: notes,
                                color: accentColor
                            )
                        }
                    }
                }
                .background(NapletColors.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal, NapletSpacing.md)

                // Notes (apenas para tipos que não são sólidos, pois sólidos já mostram acima)
                if record.type != .solid, let notes = record.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: NapletSpacing.xs) {
                        Text("health.notes".localized)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(NapletColors.textSecondary)
                            .padding(.horizontal, NapletSpacing.md)

                        Text(notes)
                            .font(.system(size: 15))
                            .foregroundColor(NapletColors.textPrimary)
                            .padding(NapletSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(NapletColors.cardBackground)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, NapletSpacing.md)
                }

                Spacer(minLength: NapletSpacing.lg)
            }
        }
        .background(NapletColors.background)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }
}

// MARK: - Diaper Detail Sheet
struct DiaperDetailSheet: View {
    let record: DiaperRecord

    private var accentColor: Color {
        record.content.color
    }

    var body: some View {
        ScrollView {
            VStack(spacing: NapletSpacing.lg) {
                // Drag Indicator
                Capsule()
                    .fill(NapletColors.textMuted.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, NapletSpacing.sm)

                // Header
                VStack(spacing: NapletSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 72, height: 72)

                        Image(systemName: record.content.icon)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(accentColor)
                    }

                    Text(record.content.displayName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(NapletColors.textPrimary)

                    // Time ago highlight
                    Text(record.timeAgo)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                }
                .padding(.top, NapletSpacing.sm)

                // Details
                VStack(spacing: 0) {
                    // Content type row
                    DetailRow(
                        icon: record.content.icon,
                        title: "diaper.content".localized,
                        value: record.content.displayName,
                        color: accentColor
                    )

                    Divider().padding(.leading, 52)

                    // Time row
                    DetailRow(
                        icon: "clock",
                        title: "health.time".localized,
                        value: record.changedAt.formatted(date: .omitted, time: .shortened),
                        color: accentColor
                    )

                    Divider().padding(.leading, 52)

                    DetailRow(
                        icon: "calendar",
                        title: "sleepDetail.date".localized,
                        value: record.changedAt.formatted(date: .abbreviated, time: .omitted),
                        color: accentColor
                    )

                    // Weight row if available
                    if let weight = record.weightGrams, weight > 0 {
                        Divider().padding(.leading, 52)
                        DetailRow(
                            icon: "scalemass",
                            title: "diaper.weight".localized,
                            value: "\(weight)g",
                            color: accentColor
                        )
                    }
                }
                .background(NapletColors.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal, NapletSpacing.md)

                // Notes
                if let notes = record.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: NapletSpacing.xs) {
                        Text("health.notes".localized)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(NapletColors.textSecondary)
                            .padding(.horizontal, NapletSpacing.md)

                        Text(notes)
                            .font(.system(size: 15))
                            .foregroundColor(NapletColors.textPrimary)
                            .padding(NapletSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(NapletColors.cardBackground)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, NapletSpacing.md)
                }

                Spacer(minLength: NapletSpacing.lg)
            }
        }
        .background(NapletColors.background)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }
}

// MARK: - Bath Detail Sheet
struct BathDetailSheet: View {
    let record: BathRecord

    private var accentColor: Color {
        NapletColors.primaryCyan
    }

    private var durationFormatted: String {
        guard let endTime = record.endTime else { return "--" }
        let duration = Int(endTime.timeIntervalSince(record.startTime) / 60)
        return "\(duration) min"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: NapletSpacing.lg) {
                // Drag Indicator
                Capsule()
                    .fill(NapletColors.textMuted.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, NapletSpacing.sm)

                // Header
                VStack(spacing: NapletSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 72, height: 72)

                        Image(systemName: "bathtub.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(accentColor)
                    }

                    Text("bath.title".localized)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(NapletColors.textPrimary)

                    // Duration highlight
                    Text(durationFormatted)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                }
                .padding(.top, NapletSpacing.sm)

                // Details
                VStack(spacing: 0) {
                    // Bath Type row
                    DetailRow(
                        icon: record.bathType.icon,
                        title: "bath.type".localized,
                        value: record.bathType.displayName,
                        color: record.bathType.color
                    )

                    Divider().padding(.leading, 52)

                    // Start time row
                    DetailRow(
                        icon: "clock",
                        title: "sleepDetail.start".localized,
                        value: record.startTime.formatted(date: .omitted, time: .shortened),
                        color: accentColor
                    )

                    // End time row
                    if let endTime = record.endTime {
                        Divider().padding(.leading, 52)
                        DetailRow(
                            icon: "clock.badge.checkmark",
                            title: "sleepDetail.end".localized,
                            value: endTime.formatted(date: .omitted, time: .shortened),
                            color: accentColor
                        )
                    }

                    Divider().padding(.leading, 52)

                    DetailRow(
                        icon: "calendar",
                        title: "sleepDetail.date".localized,
                        value: record.startTime.formatted(date: .abbreviated, time: .omitted),
                        color: accentColor
                    )

                    // Mood row
                    if let mood = record.mood {
                        Divider().padding(.leading, 52)
                        DetailRow(
                            icon: mood.icon,
                            title: "bath.mood".localized,
                            value: mood.displayName,
                            color: mood.color
                        )
                    }
                }
                .background(NapletColors.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal, NapletSpacing.md)

                // Notes
                if let notes = record.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: NapletSpacing.xs) {
                        Text("health.notes".localized)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(NapletColors.textSecondary)
                            .padding(.horizontal, NapletSpacing.md)

                        Text(notes)
                            .font(.system(size: 15))
                            .foregroundColor(NapletColors.textPrimary)
                            .padding(NapletSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(NapletColors.cardBackground)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, NapletSpacing.md)
                }

                Spacer(minLength: NapletSpacing.lg)
            }
        }
        .background(NapletColors.background)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }
}

// MARK: - Health Detail Sheet
struct HealthDetailSheet: View {
    let record: HealthRecord

    private var accentColor: Color {
        record.type.color
    }

    private var highlightValue: String {
        switch record.type {
        case .temperature:
            if let temp = record.temperatureCelsius {
                return String(format: "%.1f°C", temp)
            }
            return "--"
        case .medication:
            return record.medicationName ?? "--"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: NapletSpacing.lg) {
                // Drag Indicator
                Capsule()
                    .fill(NapletColors.textMuted.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, NapletSpacing.sm)

                // Header
                VStack(spacing: NapletSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 72, height: 72)

                        Image(systemName: record.type.icon)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(accentColor)
                    }

                    Text(record.type.displayName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(NapletColors.textPrimary)

                    // Highlight value
                    Text(highlightValue)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(record.temperatureStatus?.color ?? accentColor)

                    // Status badge for temperature
                    if record.type == .temperature, let status = record.temperatureStatus {
                        Text(status.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(status.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(status.color.opacity(0.15))
                            .cornerRadius(8)
                    }
                }
                .padding(.top, NapletSpacing.sm)

                // Details
                VStack(spacing: 0) {
                    // Time row
                    DetailRow(
                        icon: "clock",
                        title: "health.time".localized,
                        value: record.recordedAt.formatted(date: .omitted, time: .shortened),
                        color: accentColor
                    )

                    Divider().padding(.leading, 52)

                    DetailRow(
                        icon: "calendar",
                        title: "sleepDetail.date".localized,
                        value: record.recordedAt.formatted(date: .abbreviated, time: .omitted),
                        color: accentColor
                    )

                    // Type specific rows
                    switch record.type {
                    case .temperature:
                        // Mostrar temperatura em Fahrenheit se disponível
                        if let tempC = record.temperatureCelsius {
                            Divider().padding(.leading, 52)
                            let tempF = (tempC * 9/5) + 32
                            DetailRow(
                                icon: "thermometer",
                                title: "health.temperature.fahrenheit".localized,
                                value: String(format: "%.1f°F", tempF),
                                color: accentColor
                            )
                        }
                    case .medication:
                        if let dose = record.medicationDose {
                            Divider().padding(.leading, 52)
                            DetailRow(
                                icon: "drop.fill",
                                title: "health.medication.dose".localized,
                                value: dose,
                                color: accentColor
                            )
                        }
                    }
                }
                .background(NapletColors.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal, NapletSpacing.md)

                // Notes
                if let notes = record.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: NapletSpacing.xs) {
                        Text("health.notes".localized)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(NapletColors.textSecondary)
                            .padding(.horizontal, NapletSpacing.md)

                        Text(notes)
                            .font(.system(size: 15))
                            .foregroundColor(NapletColors.textPrimary)
                            .padding(NapletSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(NapletColors.cardBackground)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, NapletSpacing.md)
                }

                Spacer(minLength: NapletSpacing.lg)
            }
        }
        .background(NapletColors.background)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }
}

#Preview {
    DashboardView()
}
