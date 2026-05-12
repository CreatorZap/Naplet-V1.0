import SwiftUI

// MARK: - Wake Window Card View
//
// Card exibido no Dashboard mostrando o status atual da janela de sono do bebê.
// O tipo `WakeWindowStatus` é definido em `WakeWindowCalculator.swift`.
//
// Inputs:
//   - status: estado computado pelo Calculator (sleeping/fresh/optimal/closing/overdue)
//   - ageInMonths: idade do bebê (exibida discreta no header)
//   - wakeWindowProgress: 0.0 a 1.5 (vide DashboardViewModel.swift:460, cap em 150%).
//     A barra clampa visualmente em 100%, mas a cor reflete overdue quando > 1.0.
//
// TODO (futuro): adicionar subtitle dinâmico ("Acordada há Xh Ym") quando o
// ViewModel expuser `timeAwake` para a View.

struct WakeWindowCardView: View {

    // MARK: - Inputs
    let status: WakeWindowStatus
    let ageInMonths: Int
    let wakeWindowProgress: Double

    // MARK: - Status mapping

    /// Cor primária do status atual.
    private var statusColor: Color {
        switch status {
        case .sleeping: return NapletColors.primaryPurple
        case .fresh:    return NapletColors.primaryBlue
        case .optimal:  return NapletColors.success
        case .closing:  return NapletColors.warning
        case .overdue:  return NapletColors.error
        }
    }

    /// SF Symbol do status.
    private var statusIcon: String {
        switch status {
        case .sleeping: return "moon.zzz.fill"
        case .fresh:    return "sun.haze.fill"
        case .optimal:  return "figure.child"
        case .closing:  return "clock.badge.exclamationmark"
        case .overdue:  return "exclamationmark.triangle.fill"
        }
    }

    /// Chave de localização da label do status.
    private var statusLabelKey: String {
        switch status {
        case .sleeping: return "wakeWindow.status.sleeping"
        case .fresh:    return "wakeWindow.status.fresh"
        case .optimal:  return "wakeWindow.status.optimal"
        case .closing:  return "wakeWindow.status.closing"
        case .overdue:  return "wakeWindow.status.overdue"
        }
    }

    /// Progresso clampado em [0, 1] para a largura da barra.
    /// A cor de overdue já reflete progresso > 1.0; clamp é só visual.
    private var clampedProgress: Double {
        min(max(wakeWindowProgress, 0), 1)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.md) {
            header
            statusLabel
            progressBar
        }
        .padding(NapletSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(statusColor.opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - Header (ícone + título + idade compacta)

    private var header: some View {
        HStack(spacing: NapletSpacing.sm) {
            Image(systemName: statusIcon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(statusColor)

            Text("wakeWindow.card.title".localized)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(NapletColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Spacer()

            Text("\(ageInMonths)m")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(NapletColors.textMuted)
        }
    }

    // MARK: - Status Label (nome grande)

    private var statusLabel: some View {
        Text(statusLabelKey.localized)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(statusColor)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Progress Bar (8pt, cor por status)

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Trilho de fundo
                RoundedRectangle(cornerRadius: 4)
                    .fill(NapletColors.backgroundTertiary)

                // Preenchimento (largura clampada em 100%, cor do status)
                RoundedRectangle(cornerRadius: 4)
                    .fill(statusColor)
                    .frame(width: geo.size.width * clampedProgress)
                    .animation(.easeInOut(duration: 0.4), value: clampedProgress)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Preview

#if DEBUG
struct WakeWindowCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            WakeWindowCardView(status: .sleeping, ageInMonths: 6, wakeWindowProgress: 0)
            WakeWindowCardView(status: .fresh,    ageInMonths: 6, wakeWindowProgress: 0.2)
            WakeWindowCardView(status: .optimal,  ageInMonths: 6, wakeWindowProgress: 0.6)
            WakeWindowCardView(status: .closing,  ageInMonths: 6, wakeWindowProgress: 0.9)
            WakeWindowCardView(status: .overdue,  ageInMonths: 6, wakeWindowProgress: 1.3)
        }
        .padding()
        .background(NapletColors.background)
        .preferredColorScheme(.dark)
    }
}
#endif
