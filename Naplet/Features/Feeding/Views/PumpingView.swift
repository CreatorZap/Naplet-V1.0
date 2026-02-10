import SwiftUI

// MARK: - Pumping Sheet
struct PumpingSheet: View {
    @ObservedObject var viewModel: FeedingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var pumpingMode: PumpingMode = .total
    @State private var totalAmount: Int = 100
    @State private var leftAmount: Int = 50
    @State private var rightAmount: Int = 50
    @State private var notes: String = ""
    @State private var recordedAt: Date = Date()

    var body: some View {
        ZStack {
            NapletColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: NapletSpacing.xl) {
                    // Drag Indicator
                    Capsule()
                        .fill(NapletColors.textMuted.opacity(0.3))
                        .frame(width: 36, height: 5)
                        .padding(.top, NapletSpacing.sm)

                    // Header
                    headerSection

                    // Time selector
                    timeSection

                    // Mode selector
                    modeSection

                    // Amount input
                    amountSection

                    // Notes
                    notesSection

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, NapletSpacing.lg)
            }

            // Save button
            VStack {
                Spacer()
                saveButton
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
        .alert("common.success".localized, isPresented: $viewModel.showSuccess) {
            Button("common.ok".localized) {
                dismiss()
            }
        } message: {
            Text(viewModel.successMessage ?? "feeding.saved".localized)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: NapletSpacing.sm) {
            ZStack {
                Circle()
                    .fill(NapletColors.primaryPink.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "drop.degreesign")
                    .font(.system(size: 48))
                    .foregroundColor(NapletColors.primaryPink)
            }

            Text("feeding.pumping.title".localized)
                .font(NapletTypography.title2())
                .foregroundColor(NapletColors.textPrimary)

            Text("feeding.pumping.subtitle".localized)
                .font(NapletTypography.body())
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, NapletSpacing.md)
    }

    // MARK: - Time Section
    private var timeSection: some View {
        NapletCard {
            VStack(spacing: NapletSpacing.md) {
                Text("feeding.pumping.time".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: NapletSpacing.xl) {
                    Button {
                        recordedAt = recordedAt.addingTimeInterval(-60)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(NapletColors.primaryPink)
                            Text("-1 min")
                                .font(NapletTypography.caption())
                                .foregroundColor(NapletColors.textSecondary)
                        }
                    }

                    VStack(spacing: 4) {
                        Text(formattedTime)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(NapletColors.textPrimary)
                    }
                    .frame(minWidth: 140)

                    Button {
                        recordedAt = recordedAt.addingTimeInterval(60)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(NapletColors.primaryPink)
                            Text("+1 min")
                                .font(NapletTypography.caption())
                                .foregroundColor(NapletColors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: recordedAt)
    }

    // MARK: - Mode Section
    private var modeSection: some View {
        NapletCard {
            VStack(spacing: NapletSpacing.md) {
                Text("feeding.pumping.mode".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: NapletSpacing.md) {
                    PumpingModeButton(
                        mode: .total,
                        isSelected: pumpingMode == .total
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            pumpingMode = .total
                        }
                    }

                    PumpingModeButton(
                        mode: .perSide,
                        isSelected: pumpingMode == .perSide
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            pumpingMode = .perSide
                        }
                    }
                }
            }
        }
    }

    // MARK: - Amount Section
    private var amountSection: some View {
        NapletCard {
            VStack(spacing: NapletSpacing.lg) {
                Text("feeding.pumping.amount".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if pumpingMode == .total {
                    totalAmountInput
                } else {
                    perSideAmountInput
                }

                // Quick amounts
                HStack(spacing: NapletSpacing.sm) {
                    ForEach([50, 100, 150, 200], id: \.self) { amount in
                        QuickPumpingAmountButton(
                            amount: amount,
                            isSelected: pumpingMode == .total ? totalAmount == amount : false
                        ) {
                            if pumpingMode == .total {
                                totalAmount = amount
                            }
                        }
                    }
                }
            }
        }
    }

    private var totalAmountInput: some View {
        HStack(spacing: NapletSpacing.lg) {
            Button {
                if totalAmount > 10 {
                    totalAmount -= 10
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(NapletColors.primaryPink)
            }

            VStack(spacing: 4) {
                Text("\(totalAmount)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(NapletColors.textPrimary)

                Text("ml")
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textMuted)
            }
            .frame(width: 140)

            Button {
                totalAmount += 10
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(NapletColors.primaryPink)
            }
        }
    }

    private var perSideAmountInput: some View {
        HStack(spacing: NapletSpacing.xl) {
            // Left side
            VStack(spacing: NapletSpacing.sm) {
                Text("E")
                    .font(NapletTypography.headline())
                    .foregroundColor(NapletColors.textSecondary)

                HStack(spacing: NapletSpacing.md) {
                    Button {
                        if leftAmount > 0 { leftAmount -= 10 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(NapletColors.primaryPink)
                    }

                    VStack {
                        Text("\(leftAmount)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(NapletColors.textPrimary)

                        Text("ml")
                            .font(NapletTypography.caption())
                            .foregroundColor(NapletColors.textMuted)
                    }
                    .frame(width: 60)

                    Button {
                        leftAmount += 10
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(NapletColors.primaryPink)
                    }
                }
            }

            Divider()
                .frame(height: 80)

            // Right side
            VStack(spacing: NapletSpacing.sm) {
                Text("D")
                    .font(NapletTypography.headline())
                    .foregroundColor(NapletColors.textSecondary)

                HStack(spacing: NapletSpacing.md) {
                    Button {
                        if rightAmount > 0 { rightAmount -= 10 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(NapletColors.primaryPink)
                    }

                    VStack {
                        Text("\(rightAmount)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(NapletColors.textPrimary)

                        Text("ml")
                            .font(NapletTypography.caption())
                            .foregroundColor(NapletColors.textMuted)
                    }
                    .frame(width: 60)

                    Button {
                        rightAmount += 10
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(NapletColors.primaryPink)
                    }
                }
            }
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        NapletCard {
            VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                Text("feeding.pumping.notes".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)

                TextField("feeding.pumping.notesPlaceholder".localized, text: $notes, axis: .vertical)
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textPrimary)
                    .lineLimit(2...4)
                    .padding(NapletSpacing.md)
                    .background(NapletColors.background)
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            Task {
                await savePumping()
            }
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("feeding.pumping.save".localized)
            }
            .font(NapletTypography.body(weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NapletSpacing.md)
            .background(NapletColors.primaryPink)
            .cornerRadius(16)
        }
        .padding(.horizontal, NapletSpacing.lg)
        .padding(.bottom, NapletSpacing.xl)
        .background(
            LinearGradient(
                colors: [NapletColors.background.opacity(0), NapletColors.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .allowsHitTesting(false)
        )
    }

    private func savePumping() async {
        viewModel.pumpingMode = pumpingMode
        if pumpingMode == .total {
            viewModel.pumpingTotalMl = totalAmount
        } else {
            viewModel.pumpingLeftMl = leftAmount
            viewModel.pumpingRightMl = rightAmount
        }
        viewModel.feedingNotes = notes.isEmpty ? nil : notes

        await viewModel.recordPumping()
    }
}

// MARK: - Pumping Mode Button
struct PumpingModeButton: View {
    let mode: PumpingMode
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: NapletSpacing.sm) {
                Image(systemName: mode == .total ? "drop.fill" : "arrow.left.arrow.right")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? NapletColors.primaryPink : NapletColors.textMuted)

                Text(mode.displayName)
                    .font(NapletTypography.caption(weight: .medium))
                    .foregroundColor(isSelected ? NapletColors.textPrimary : NapletColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NapletSpacing.md)
            .background(isSelected ? NapletColors.primaryPink.opacity(0.15) : NapletColors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? NapletColors.primaryPink : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Quick Pumping Amount Button
struct QuickPumpingAmountButton: View {
    let amount: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text("\(amount)ml")
                .font(NapletTypography.caption(weight: .medium))
                .foregroundColor(isSelected ? .white : NapletColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? NapletColors.primaryPink : NapletColors.cardBackground)
                .cornerRadius(8)
        }
    }
}

// MARK: - Preview
#Preview {
    PumpingSheet(viewModel: FeedingViewModel(baby: Baby.preview))
}
