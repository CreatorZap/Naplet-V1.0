import SwiftUI

// MARK: - Bottle Feeding Sheet
struct BottleFeedingSheet: View {
    @ObservedObject var viewModel: FeedingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedAmount: Double = 120
    @State private var selectedType: BottleContentType = .formula

    var body: some View {
        ZStack {
            NapletColors.background
                .ignoresSafeArea()

            VStack(spacing: NapletSpacing.xl) {
                // Drag Indicator
                Capsule()
                    .fill(NapletColors.textMuted.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, NapletSpacing.sm)

                // Header
                VStack(spacing: NapletSpacing.sm) {
                    Image(systemName: "waterbottle")
                        .font(.system(size: 48))
                        .foregroundColor(NapletColors.info)

                    Text("feeding.bottle.start".localized)
                        .font(NapletTypography.title2())
                        .foregroundColor(NapletColors.textPrimary)
                }
                .padding(.top, NapletSpacing.md)

                // Amount Selector
                NapletCard {
                    VStack(spacing: NapletSpacing.md) {
                        Text("feeding.bottle.amount".localized)
                            .font(NapletTypography.headline())
                            .foregroundColor(NapletColors.textPrimary)

                        // Amount with +/- buttons
                        HStack(spacing: NapletSpacing.lg) {
                            Button {
                                if selectedAmount > 10 {
                                    selectedAmount -= 10
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(NapletColors.info)
                            }

                            VStack(spacing: 4) {
                                Text("\(Int(selectedAmount))")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(NapletColors.textPrimary)

                                Text("ml")
                                    .font(NapletTypography.body())
                                    .foregroundColor(NapletColors.textMuted)
                            }
                            .frame(width: 120)

                            Button {
                                selectedAmount += 10
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(NapletColors.info)
                            }
                        }

                        // Quick amounts
                        HStack(spacing: NapletSpacing.sm) {
                            ForEach([60, 90, 120, 150, 180], id: \.self) { amount in
                                QuickAmountButton(
                                    amount: amount,
                                    isSelected: Int(selectedAmount) == amount
                                ) {
                                    selectedAmount = Double(amount)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, NapletSpacing.lg)

                // Type Selector
                NapletCard {
                    VStack(alignment: .leading, spacing: NapletSpacing.md) {
                        Text("feeding.bottle.type".localized)
                            .font(NapletTypography.headline())
                            .foregroundColor(NapletColors.textPrimary)

                        HStack(spacing: NapletSpacing.sm) {
                            ForEach(BottleContentType.allCases, id: \.self) { type in
                                BottleTypeButton(
                                    type: type,
                                    isSelected: selectedType == type
                                ) {
                                    selectedType = type
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, NapletSpacing.lg)

                Spacer()

                // Start Button
                Button {
                    viewModel.bottleAmount = selectedAmount
                    viewModel.bottleType = selectedType
                    Task {
                        await viewModel.startBottleFeeding()
                        dismiss()
                    }
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("feeding.bottle.startTimer".localized)
                    }
                    .font(NapletTypography.body(weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, NapletSpacing.md)
                    .background(NapletColors.info)
                    .cornerRadius(12)
                }
                .padding(.horizontal, NapletSpacing.lg)
                .padding(.bottom, NapletSpacing.lg)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }
}

// MARK: - Quick Amount Button
struct QuickAmountButton: View {
    let amount: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text("\(amount)")
                .font(NapletTypography.caption(weight: .medium))
                .foregroundColor(isSelected ? .white : NapletColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? NapletColors.info : NapletColors.cardBackground)
                .cornerRadius(8)
        }
    }
}

// MARK: - Bottle Type Button
struct BottleTypeButton: View {
    let type: BottleContentType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: NapletSpacing.sm) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? NapletColors.info : NapletColors.textMuted)

                Text(type.displayName)
                    .font(NapletTypography.caption(weight: .medium))
                    .foregroundColor(isSelected ? NapletColors.textPrimary : NapletColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NapletSpacing.md)
            .background(isSelected ? NapletColors.info.opacity(0.1) : NapletColors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? NapletColors.info : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Solid Feeding Sheet
struct SolidFeedingSheet: View {
    @ObservedObject var viewModel: FeedingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var notes: String = ""

    var body: some View {
        ZStack {
            NapletColors.background
                .ignoresSafeArea()

            VStack(spacing: NapletSpacing.xl) {
                // Drag Indicator
                Capsule()
                    .fill(NapletColors.textMuted.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, NapletSpacing.sm)

                // Header
                VStack(spacing: NapletSpacing.sm) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 48))
                        .foregroundColor(NapletColors.warning)

                    Text("feeding.solid.title".localized)
                        .font(NapletTypography.title2())
                        .foregroundColor(NapletColors.textPrimary)

                    Text("feeding.solid.subtitle".localized)
                        .font(NapletTypography.body())
                        .foregroundColor(NapletColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, NapletSpacing.md)
                .padding(.horizontal, NapletSpacing.lg)

                // Notes input
                NapletCard {
                    VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                        Text("feeding.solid.notes".localized)
                            .font(NapletTypography.caption(weight: .semibold))
                            .foregroundColor(NapletColors.textSecondary)

                        TextField("feeding.solid.notesPlaceholder".localized, text: $notes, axis: .vertical)
                            .font(NapletTypography.body())
                            .foregroundColor(NapletColors.textPrimary)
                            .lineLimit(3...6)
                            .padding(NapletSpacing.md)
                            .background(NapletColors.background)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, NapletSpacing.lg)

                // Quick food suggestions
                NapletCard {
                    VStack(alignment: .leading, spacing: NapletSpacing.md) {
                        Text("feeding.solid.suggestions".localized)
                            .font(NapletTypography.caption(weight: .semibold))
                            .foregroundColor(NapletColors.textSecondary)

                        FlowLayout(spacing: 8) {
                            ForEach(foodSuggestions, id: \.self) { food in
                                FoodSuggestionChip(food: food) {
                                    if notes.isEmpty {
                                        notes = food
                                    } else {
                                        notes += ", \(food)"
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, NapletSpacing.lg)

                Spacer()

                // Save Button
                Button {
                    Task {
                        await viewModel.recordSolidFeeding(notes: notes.isEmpty ? nil : notes)
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("feeding.solid.save".localized)
                    }
                    .font(NapletTypography.body(weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, NapletSpacing.md)
                    .background(NapletColors.warning)
                    .cornerRadius(12)
                }
                .padding(.horizontal, NapletSpacing.lg)
                .padding(.bottom, NapletSpacing.lg)
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

    private var foodSuggestions: [String] {
        [
            "feeding.food.fruit".localized,
            "feeding.food.vegetable".localized,
            "feeding.food.cereal".localized,
            "feeding.food.meat".localized,
            "feeding.food.dairy".localized,
            "feeding.food.egg".localized
        ]
    }
}

// MARK: - Food Suggestion Chip
struct FoodSuggestionChip: View {
    let food: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(food)
                .font(NapletTypography.caption(weight: .medium))
                .foregroundColor(NapletColors.warning)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(NapletColors.warning.opacity(0.1))
                .cornerRadius(16)
        }
    }
}

// MARK: - Preview
#Preview("Bottle Sheet") {
    BottleFeedingSheet(viewModel: FeedingViewModel(baby: Baby.preview))
}

#Preview("Solid Sheet") {
    SolidFeedingSheet(viewModel: FeedingViewModel(baby: Baby.preview))
}
