import SwiftUI

// MARK: - Time Adjust Buttons
/// Componente reutilizável para ajustar horário com botões -1/+1 min
struct TimeAdjustButtons: View {
    @Binding var date: Date
    var accentColor: Color = NapletColors.primaryPurple
    var showDate: Bool = true

    var body: some View {
        VStack(spacing: NapletSpacing.md) {
            HStack(spacing: NapletSpacing.xl) {
                // Minus button
                Button {
                    date = date.addingTimeInterval(-60)
                    hapticFeedback()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(accentColor)
                        Text("-1 min")
                            .font(NapletTypography.caption())
                            .foregroundColor(NapletColors.textSecondary)
                    }
                }

                // Time display
                VStack(spacing: 4) {
                    Text(formattedTime)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(NapletColors.textPrimary)

                    if showDate {
                        Text(formattedDate)
                            .font(NapletTypography.caption())
                            .foregroundColor(NapletColors.textMuted)
                    }
                }
                .frame(minWidth: 140)

                // Plus button
                Button {
                    date = date.addingTimeInterval(60)
                    hapticFeedback()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(accentColor)
                        Text("+1 min")
                            .font(NapletTypography.caption())
                            .foregroundColor(NapletColors.textSecondary)
                    }
                }
            }
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Time Adjust Card
/// Versão com NapletCard incluso
struct TimeAdjustCard: View {
    @Binding var date: Date
    var title: String = "time"
    var accentColor: Color = NapletColors.primaryPurple
    var showDate: Bool = true

    var body: some View {
        NapletCard {
            VStack(spacing: NapletSpacing.md) {
                Text(title.localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TimeAdjustButtons(
                    date: $date,
                    accentColor: accentColor,
                    showDate: showDate
                )
            }
        }
    }
}

// MARK: - Preview
#Preview("Time Adjust Buttons") {
    ZStack {
        NapletColors.background
            .ignoresSafeArea()

        VStack(spacing: 24) {
            TimeAdjustButtons(date: .constant(Date()))

            TimeAdjustButtons(
                date: .constant(Date()),
                accentColor: NapletColors.primaryPink
            )

            TimeAdjustCard(
                date: .constant(Date()),
                title: "health.time"
            )
        }
        .padding()
    }
}
