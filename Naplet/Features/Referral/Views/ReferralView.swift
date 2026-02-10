import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - Referral View

struct ReferralView: View {

    @StateObject private var viewModel = ReferralViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showQRCode = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    headerSection
                    benefitsCard
                    codeSection
                    shareButtons
                    progressCard

                    if !viewModel.referrals.isEmpty {
                        referralsListSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(NapletColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(NapletColors.textSecondary)
                    }
                }
            }
            .overlay(alignment: .top) {
                if viewModel.showCopiedToast {
                    copiedToast
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
        .sheet(isPresented: $showQRCode) {
            QRCodeSheet(
                url: viewModel.shareURL,
                code: viewModel.referralCode
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            // Gift icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [NapletColors.primaryPurple.opacity(0.3), NapletColors.primaryPink.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "gift.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 16)

            VStack(spacing: 8) {
                Text("referral.title".localized)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(NapletColors.textPrimary)

                Text("referral.subtitle".localized)
                    .font(.system(size: 15))
                    .foregroundColor(NapletColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 8)
            }
        }
    }

    // MARK: - Benefits Card

    private var benefitsCard: some View {
        VStack(spacing: 0) {
            ReferralBenefitRow(
                icon: "person.badge.plus",
                iconColor: NapletColors.primaryPurple,
                title: "referral.benefit.friend.title".localized,
                subtitle: "referral.benefit.friend.subtitle".localized
            )

            Divider()
                .background(NapletColors.backgroundTertiary)
                .padding(.vertical, 4)

            ReferralBenefitRow(
                icon: "medal.fill",
                iconColor: NapletColors.warning,
                title: "referral.benefit.you.title".localized,
                subtitle: "referral.benefit.you.subtitle".localized
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
        )
    }

    // MARK: - Code Section

    private var codeSection: some View {
        VStack(spacing: 12) {
            HStack {
                if viewModel.referralCode.isEmpty {
                    ProgressView()
                        .tint(NapletColors.primaryPurple)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(viewModel.referralCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(NapletColors.textPrimary)
                        .tracking(6)
                }

                Spacer()

                Button {
                    viewModel.copyCode()
                } label: {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(NapletColors.primaryPurple)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(NapletColors.primaryPurple.opacity(0.15))
                        )
                }
                .disabled(viewModel.referralCode.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(NapletColors.cardBackground)
            )
        }
    }

    // MARK: - Share Buttons

    private var shareButtons: some View {
        HStack(spacing: 16) {
            ShareOptionButton(
                icon: "qrcode",
                label: "QR Code",
                gradientColors: [NapletColors.textPrimary, NapletColors.textSecondary]
            ) {
                showQRCode = true
            }

            ShareOptionButton(
                icon: "message.fill",
                label: "WhatsApp",
                gradientColors: [Color(hex: "#25D366"), Color(hex: "#128C7E")]
            ) {
                viewModel.shareToWhatsApp()
            }

            ShareOptionButton(
                icon: "square.and.arrow.up.fill",
                label: "referral.share.more".localized,
                gradientColors: [NapletColors.primaryPurple, NapletColors.primaryPink]
            ) {
                viewModel.shareGeneric()
            }
        }
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        VStack(spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    if viewModel.isAmbassador {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(NapletColors.warning)
                            .font(.system(size: 18, weight: .semibold))
                    }

                    Text(viewModel.isAmbassador
                        ? "referral.ambassador.title".localized
                        : "referral.progress.title".localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(NapletColors.textPrimary)
                }

                Spacer()

                Text("\(viewModel.totalReferrals)/5")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(NapletColors.primaryPurple)
            }

            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(NapletColors.backgroundTertiary)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * viewModel.progress)
                        .animation(.spring(response: 0.5), value: viewModel.progress)
                }
            }
            .frame(height: 8)

            Text(viewModel.progressText)
                .font(.system(size: 13))
                .foregroundColor(NapletColors.textMuted)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
        )
    }

    // MARK: - Referrals List Section

    private var referralsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("referral.list.title".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)
                .padding(.leading, 4)

            ForEach(viewModel.referrals) { referral in
                HStack(spacing: 14) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [NapletColors.primaryPurple.opacity(0.7), NapletColors.primaryPink.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text("referral.friend".localized)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(NapletColors.textPrimary)

                        Text(referral.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 13))
                            .foregroundColor(NapletColors.textMuted)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(NapletColors.success)
                        .font(.system(size: 22))
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(NapletColors.cardBackground)
                )
            }
        }
    }

    // MARK: - Copied Toast

    private var copiedToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(NapletColors.success)

            Text("referral.code.copied".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(NapletColors.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(NapletColors.cardBackground)
                .shadow(color: NapletColors.primaryPurple.opacity(0.2), radius: 12, y: 4)
        )
        .padding(.top, 60)
    }
}

// MARK: - Referral Benefit Row

struct ReferralBenefitRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(NapletColors.textPrimary)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(NapletColors.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Share Option Button

struct ShareOptionButton: View {
    let icon: String
    let label: String
    let gradientColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(NapletColors.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - QR Code Sheet

struct QRCodeSheet: View {
    let url: URL
    let code: String

    @Environment(\.dismiss) private var dismiss
    @State private var showSavedToast = false

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // QR Code
                    qrCodeImage
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: NapletColors.primaryPurple.opacity(0.15), radius: 20, y: 8)

                    // Code Display
                    VStack(spacing: 8) {
                        Text("referral.qrcode.yourCode".localized)
                            .font(.system(size: 14))
                            .foregroundColor(NapletColors.textSecondary)

                        Text(code)
                            .font(.system(size: 26, weight: .bold, design: .monospaced))
                            .foregroundColor(NapletColors.textPrimary)
                            .tracking(4)
                    }

                    // Instructions
                    Text("referral.qrcode.instructions".localized)
                        .font(.system(size: 13))
                        .foregroundColor(NapletColors.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 32)
                .padding(.bottom, 16)
            }
            .safeAreaInset(edge: .bottom) {
                // Action Buttons
                HStack(spacing: 14) {
                    // Save to Photos
                    Button {
                        saveQRCodeToPhotos()
                    } label: {
                        Label("referral.qrcode.save".localized, systemImage: "square.and.arrow.down")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(NapletColors.primaryPurple)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(NapletColors.primaryPurple.opacity(0.15))
                            )
                    }

                    // Share
                    ShareLink(item: qrCodeUIImage, preview: SharePreview("Naplet QR Code", image: qrCodeUIImage)) {
                        Label("referral.qrcode.share".localized, systemImage: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(NapletColors.background)
            }
            .background(NapletColors.background.ignoresSafeArea())
            .navigationTitle("referral.qrcode.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(NapletColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(NapletColors.textSecondary)
                    }
                }
            }
            .overlay(alignment: .top) {
                if showSavedToast {
                    savedToast
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - QR Code Generation

    private var qrCodeImage: Image {
        Image(uiImage: generateQRCode())
    }

    private var qrCodeUIImage: Image {
        Image(uiImage: generateQRCodeWithLogo())
    }

    private func generateQRCode() -> UIImage {
        filter.message = Data(url.absoluteString.utf8)

        if let outputImage = filter.outputImage {
            // Scale up for better quality
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)

            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }

        return UIImage(systemName: "qrcode") ?? UIImage()
    }

    private func generateQRCodeWithLogo() -> UIImage {
        let qrCode = generateQRCode()
        let size = CGSize(width: 300, height: 300)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }

        // Draw white background
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))

        // Draw QR code
        qrCode.draw(in: CGRect(origin: .zero, size: size))

        // Draw app icon in center (optional - creates a nice branded look)
        if let appIcon = UIImage(named: "AppIcon") {
            let logoSize: CGFloat = 60
            let logoRect = CGRect(
                x: (size.width - logoSize) / 2,
                y: (size.height - logoSize) / 2,
                width: logoSize,
                height: logoSize
            )

            // White background for logo
            UIColor.white.setFill()
            UIBezierPath(roundedRect: logoRect.insetBy(dx: -4, dy: -4), cornerRadius: 12).fill()

            appIcon.draw(in: logoRect)
        }

        return UIGraphicsGetImageFromCurrentImageContext() ?? qrCode
    }

    // MARK: - Save to Photos

    private func saveQRCodeToPhotos() {
        let image = generateQRCodeWithLogo()
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Show toast
        withAnimation(.spring(response: 0.3)) {
            showSavedToast = true
        }

        // Hide toast after 2s
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.spring(response: 0.3)) {
                showSavedToast = false
            }
        }
    }

    // MARK: - Saved Toast

    private var savedToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(NapletColors.success)

            Text("referral.qrcode.saved".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(NapletColors.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(NapletColors.cardBackground)
                .shadow(color: NapletColors.primaryPurple.opacity(0.2), radius: 12, y: 4)
        )
        .padding(.top, 60)
    }
}

// MARK: - Preview

#Preview {
    ReferralView()
}
