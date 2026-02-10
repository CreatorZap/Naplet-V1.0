import SwiftUI

// MARK: - Sleep Location Picker

struct SleepLocationPicker: View {
    @Binding var selectedLocation: SleepLocation?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(NapletColors.primaryPurple)
                    .font(.system(size: 18))

                Text("where_baby_slept".localized)
                    .font(.headline)
                    .foregroundColor(NapletColors.textPrimary)

                Spacer()

                Text("common.optional".localized)
                    .font(.caption)
                    .foregroundColor(NapletColors.textSecondary)
            }

            // Grid 4x2
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(SleepLocation.allCases) { location in
                    LocationButton(
                        location: location,
                        isSelected: selectedLocation == location
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if selectedLocation == location {
                                selectedLocation = nil
                            } else {
                                selectedLocation = location
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
        )
    }
}

// MARK: - Location Button

private struct LocationButton: View {
    let location: SleepLocation
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: location.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? location.color : NapletColors.textSecondary)

                Text(location.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected
                        ? location.color.opacity(0.2)
                        : NapletColors.backgroundSecondary
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? location.color : Color.clear, lineWidth: 2)
            )
            .foregroundColor(isSelected ? location.color : NapletColors.textSecondary)
        }
        .buttonStyle(SleepScaleButtonStyle())
    }
}

// MARK: - Scale Animation

struct SleepScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        NapletColors.background.ignoresSafeArea()

        VStack {
            SleepLocationPicker(selectedLocation: .constant(.crib))
            SleepLocationPicker(selectedLocation: .constant(nil))
        }
        .padding()
    }
}
