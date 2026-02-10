import Foundation
import SwiftUI
import UIKit

@MainActor
final class ReferralViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var referralCode: String = ""
    @Published var totalReferrals: Int = 0
    @Published var isAmbassador: Bool = false
    @Published var ambassadorSince: Date?
    @Published var referrals: [Referral] = []

    @Published var isLoading: Bool = false
    @Published var showCopiedToast: Bool = false
    @Published var errorMessage: String?

    // MARK: - Computed Properties

    var shareURL: URL {
        URL(string: "https://naplet.app/r/\(referralCode)")!
    }

    var shareMessage: String {
        "referral.share.message".localized
            .replacingOccurrences(of: "{code}", with: referralCode)
            .replacingOccurrences(of: "{url}", with: shareURL.absoluteString)
    }

    var referralsUntilAmbassador: Int {
        max(0, 5 - totalReferrals)
    }

    var progress: Double {
        min(1.0, Double(totalReferrals) / 5.0)
    }

    var progressText: String {
        if isAmbassador {
            return "referral.ambassador.achieved".localized
        }
        return "referral.progress.text".localized
            .replacingOccurrences(of: "{count}", with: "\(totalReferrals)")
            .replacingOccurrences(of: "{remaining}", with: "\(referralsUntilAmbassador)")
    }

    // MARK: - Dependencies

    private let repository: ReferralRepositoryProtocol

    // MARK: - Init

    init(repository: ReferralRepositoryProtocol = ReferralRepository()) {
        self.repository = repository
    }

    // MARK: - Load Data

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            let stats = try await repository.fetchReferralStats()

            referralCode = stats.referralCode
            totalReferrals = stats.totalReferrals
            isAmbassador = stats.isAmbassador
            ambassadorSince = stats.ambassadorSince

            referrals = try await repository.fetchMyReferrals()

            Logger.info("ReferralViewModel: Loaded - Code: \(referralCode), Total: \(totalReferrals), Ambassador: \(isAmbassador)")

        } catch {
            Logger.error("ReferralViewModel: Failed to load data - \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Copy Code

    func copyCode() {
        UIPasteboard.general.string = referralCode

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Show toast
        withAnimation(.spring(response: 0.3)) {
            showCopiedToast = true
        }

        // Hide toast after 2s
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.spring(response: 0.3)) {
                showCopiedToast = false
            }
        }
    }

    // MARK: - Share to WhatsApp

    func shareToWhatsApp() {
        let text = shareMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        guard let url = URL(string: "whatsapp://send?text=\(text)") else {
            shareGeneric()
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // WhatsApp not installed, use generic share
            shareGeneric()
        }
    }

    // MARK: - Share to Instagram

    func shareToInstagram() {
        // Instagram doesn't support direct text sharing via URL scheme
        // Redirect to generic share where user can select Instagram
        shareGeneric()
    }

    // MARK: - Generic Share

    func shareGeneric() {
        let items: [Any] = [shareMessage, shareURL]

        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        // Exclude some activities that don't make sense
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .print,
            .saveToCameraRoll
        ]

        presentActivityController(activityVC)
    }

    // MARK: - Present Activity Controller

    private func presentActivityController(_ activityVC: UIActivityViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        // Find the topmost presented view controller
        var topController = rootVC
        while let presented = topController.presentedViewController {
            topController = presented
        }

        // Handle iPad popover
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topController.view
            popover.sourceRect = CGRect(
                x: topController.view.bounds.midX,
                y: topController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        topController.present(activityVC, animated: true)
    }
}
