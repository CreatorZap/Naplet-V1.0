import SwiftUI

// MARK: - Referral Button (for Home/Dashboard)
struct ReferralButton: View {

    @State private var showReferralSheet = false
    @State private var isAnimating = false

    var body: some View {
        Button {
            showReferralSheet = true
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [NapletColors.primaryPurple.opacity(0.2), NapletColors.primaryPink.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: "gift.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
            }
        }
        .sheet(isPresented: $showReferralSheet) {
            ReferralView()
        }
        .onAppear {
            // Subtle pulse animation to draw attention
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Referral Button Compact (smaller version)
struct ReferralButtonCompact: View {

    @State private var showReferralSheet = false

    var body: some View {
        Button {
            showReferralSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 14, weight: .medium))

                Text("referral.button.invite".localized)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(
                LinearGradient(
                    colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [NapletColors.primaryPurple.opacity(0.15), NapletColors.primaryPink.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .sheet(isPresented: $showReferralSheet) {
            ReferralView()
        }
    }
}

// MARK: - Preview

#Preview("Icon Button") {
    ReferralButton()
        .padding()
        .background(NapletColors.background)
}

#Preview("Compact Button") {
    ReferralButtonCompact()
        .padding()
        .background(NapletColors.background)
}
