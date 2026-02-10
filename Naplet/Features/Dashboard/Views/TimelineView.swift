import SwiftUI

// MARK: - Collapsible Timeline View
struct TimelineView: View {
    let events: [TimelineEvent]
    let baby: Baby?
    var onConfigureTapped: (() -> Void)? = nil

    @State private var isExpanded: Bool = false

    // Próximo evento importante (não passado, não é "agora")
    private var nextEvent: TimelineEvent? {
        events.first { event in
            !event.isPast && event.type != .currentTime
        }
    }

    // Evento atual
    private var currentEvent: TimelineEvent? {
        events.first { $0.type == .currentTime }
    }

    // Número de eventos futuros
    private var futureEventsCount: Int {
        events.filter { !$0.isPast && $0.type != .currentTime }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header compacto (sempre visível)
            compactHeader

            // Timeline expandida
            if isExpanded {
                expandedContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
    }

    // MARK: - Compact Header

    private var compactHeader: some View {
        Button {
            withAnimation {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: NapletSpacing.md) {
                // Ícone do próximo evento
                ZStack {
                    Circle()
                        .fill((nextEvent?.type.color ?? NapletColors.primaryCyan).opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: nextEvent?.type.icon ?? "clock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(nextEvent?.type.color ?? NapletColors.primaryCyan)
                }

                // Informação do próximo evento
                VStack(alignment: .leading, spacing: 2) {
                    Text("timeline.title".localized)
                        .font(.system(size: NapletTypography.caption))
                        .foregroundColor(NapletColors.textMuted)

                    if let next = nextEvent {
                        HStack(spacing: 4) {
                            Text(next.label)
                                .font(.system(size: NapletTypography.subheadline, weight: .semibold))
                                .foregroundColor(NapletColors.textPrimary)

                            Text("timeline.at".localized)
                                .font(.system(size: NapletTypography.caption))
                                .foregroundColor(NapletColors.textMuted)

                            Text(next.timeFormatted)
                                .font(.system(size: NapletTypography.subheadline, weight: .medium, design: .monospaced))
                                .foregroundColor(next.type.color)
                        }
                    } else {
                        Text("timeline.noMoreEvents".localized)
                            .font(.system(size: NapletTypography.subheadline))
                            .foregroundColor(NapletColors.textSecondary)
                    }
                }

                Spacer()

                // Badge com número de eventos
                if futureEventsCount > 0 && !isExpanded {
                    Text("\(futureEventsCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(NapletColors.primaryPurple)
                        .clipShape(Circle())
                }

                // Botão de configuração
                if let onConfig = onConfigureTapped {
                    Button {
                        onConfig()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14))
                            .foregroundColor(NapletColors.primaryPurple)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(NapletColors.primaryPurple.opacity(0.1))
                            )
                    }
                }

                // Seta de expansão
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(NapletColors.textMuted)
            }
            .padding(NapletSpacing.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Divider
            Rectangle()
                .fill(NapletColors.backgroundTertiary)
                .frame(height: 1)
                .padding(.horizontal, NapletSpacing.md)

            // Timeline events
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    TimelineEventRow(
                        event: event,
                        isLast: index == events.count - 1,
                        showConnector: index < events.count - 1
                    )
                }
            }
            .padding(NapletSpacing.md)

            // Footer com número de sonecas
            if let baby = baby {
                HStack {
                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 12))
                        Text(String(format: "timeline.napsRecommended".localized,
                                   baby.recommendedNapsPerDay.lowerBound,
                                   baby.recommendedNapsPerDay.upperBound))
                    }
                    .font(.system(size: NapletTypography.caption))
                    .foregroundColor(NapletColors.textMuted)
                    .padding(.horizontal, NapletSpacing.md)
                    .padding(.bottom, NapletSpacing.sm)
                }
            }
        }
    }
}

// MARK: - Timeline Event Row
struct TimelineEventRow: View {
    let event: TimelineEvent
    let isLast: Bool
    let showConnector: Bool

    var body: some View {
        HStack(alignment: .top, spacing: NapletSpacing.md) {
            // Coluna do tempo
            Text(event.timeFormatted)
                .font(.system(size: NapletTypography.caption, weight: .medium, design: .monospaced))
                .foregroundColor(event.isPast ? NapletColors.textMuted : NapletColors.textSecondary)
                .frame(width: 50, alignment: .trailing)

            // Coluna do ícone + linha conectora
            VStack(spacing: 0) {
                // Ícone
                ZStack {
                    Circle()
                        .fill(event.type.color.opacity(event.isPast ? 0.15 : 0.2))
                        .frame(width: 28, height: 28)

                    Image(systemName: event.type.icon)
                        .font(.system(size: 12))
                        .foregroundColor(event.isPast ? event.type.color.opacity(0.5) : event.type.color)
                }

                // Linha conectora
                if showConnector {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    event.type.color.opacity(0.2),
                                    NapletColors.backgroundTertiary
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2)
                        .frame(height: 20)
                }
            }

            // Coluna do conteúdo
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(event.label)
                        .font(.system(size: NapletTypography.subheadline, weight: .medium))
                        .foregroundColor(event.isPast ? NapletColors.textMuted : NapletColors.textPrimary)

                    if let duration = event.durationFormatted {
                        Text("(\(duration))")
                            .font(.system(size: NapletTypography.caption))
                            .foregroundColor(NapletColors.textMuted)
                    }

                    // Badge para evento atual
                    if event.type == .currentTime {
                        Text("timeline.current".localized)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(NapletColors.primaryCyan)
                            .cornerRadius(4)
                    }
                }

                if let sublabel = event.sublabel {
                    Text(sublabel)
                        .font(.system(size: NapletTypography.caption))
                        .foregroundColor(
                            sublabel == "timeline.inProgress".localized
                                ? NapletColors.success
                                : NapletColors.textMuted
                        )
                }
            }

            Spacer()
        }
        .padding(.bottom, showConnector ? 0 : NapletSpacing.xs)
    }
}

// MARK: - Preview
#if DEBUG
struct TimelineView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            NapletColors.background.ignoresSafeArea()

            VStack {
                TimelineView(
                    events: [
                        TimelineEvent(type: .wakeUp, time: Date().addingTimeInterval(-6*3600), endTime: nil, label: "Acordou", sublabel: nil, isPast: true),
                        TimelineEvent(type: .napCompleted, time: Date().addingTimeInterval(-4*3600), endTime: Date().addingTimeInterval(-3*3600), label: "Soneca 1", sublabel: nil, isPast: true),
                        TimelineEvent(type: .currentTime, time: Date(), endTime: nil, label: "Agora", sublabel: nil, isPast: false),
                        TimelineEvent(type: .napPredicted, time: Date().addingTimeInterval(1*3600), endTime: Date().addingTimeInterval(2*3600), label: "Soneca 2", sublabel: "Previsão", isPast: false),
                        TimelineEvent(type: .bedtime, time: Date().addingTimeInterval(5*3600), endTime: nil, label: "Hora de dormir", sublabel: nil, isPast: false)
                    ],
                    baby: nil,
                    onConfigureTapped: {}
                )
                .padding()

                Spacer()
            }
        }
    }
}
#endif
