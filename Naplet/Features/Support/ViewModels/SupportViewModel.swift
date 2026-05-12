import Foundation
import UIKit
import StoreKit

// MARK: - FAQ ViewModel
@MainActor
final class FAQViewModel: ObservableObject {
    @Published var faqItems: [FAQItem] = []
    @Published var isLoading = false
    @Published var error: String?

    private let supabaseService = SupabaseService.shared

    func loadFAQ() {
        isLoading = true

        Task {
            do {
                // Try to load from Supabase
                faqItems = try await supabaseService.fetchFAQItems()
                isLoading = false
            } catch {
                Logger.warning("Failed to load FAQ from server, using local data: \(error)")
                // Fallback to local FAQ
                loadLocalFAQ()
            }
        }
    }

    private func loadLocalFAQ() {
        faqItems = LocalFAQData.items
        isLoading = false
    }
}

// MARK: - Contact Form ViewModel
@MainActor
final class ContactFormViewModel: ObservableObject {
    // Form fields
    @Published var name = ""
    @Published var email = ""
    @Published var selectedCategory: TicketCategory = .question
    @Published var subject = ""
    @Published var message = ""

    // State
    @Published var isSubmitting = false
    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    @Published var errorMessage = ""

    private let supabaseService = SupabaseService.shared

    init() {
        // Pre-fill email if user is logged in
        Task {
            if let userEmail = try? await supabaseService.getCurrentUserEmail() {
                await MainActor.run {
                    self.email = userEmail
                }
            }
        }
    }

    // Validation
    var isFormValid: Bool {
        !email.isEmpty &&
        email.contains("@") &&
        !subject.isEmpty &&
        !message.isEmpty &&
        message.count >= 10
    }

    // Device info
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var deviceInfo: String {
        let device = UIDevice.current
        return "\(device.model) - iOS \(device.systemVersion)"
    }

    // Submit
    func submitTicket() {
        guard isFormValid else { return }

        isSubmitting = true

        Task {
            do {
                let userId = try? await supabaseService.getCurrentUserId()

                let ticket = SupportTicket(
                    id: nil,
                    userId: userId,
                    userEmail: email,
                    userName: name.isEmpty ? nil : name,
                    category: selectedCategory.rawValue,
                    subject: subject,
                    message: message,
                    appVersion: appVersion,
                    deviceInfo: deviceInfo,
                    status: "open",
                    createdAt: nil
                )

                try await supabaseService.createSupportTicket(ticket)

                isSubmitting = false
                showSuccessAlert = true
                clearForm()

            } catch {
                Logger.error("Failed to submit ticket: \(error)")
                isSubmitting = false
                errorMessage = "support.contact.error.submit".localized
                showErrorAlert = true
            }
        }
    }

    private func clearForm() {
        subject = ""
        message = ""
    }
}

// MARK: - Support Actions
struct SupportActions {
    static func openInstagram() {
        guard let instagramURL = URL(string: "instagram://user?username=naplet.app"),
              let webURL = URL(string: "https://instagram.com/naplet.app") else { return }

        if UIApplication.shared.canOpenURL(instagramURL) {
            UIApplication.shared.open(instagramURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }

    static func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    static func shareApp() {
        let text = "support.share.message".localized
        // ⚠️ IMPORTANTE: Substituir pelo App ID real após criar no App Store Connect
        // Formato: id seguido de números, ex: id1234567890
        // Obter em: App Store Connect → App Information → Apple ID
        let appStoreID = "id6758465410"
        guard let url = URL(string: "https://apps.apple.com/app/naplet/\(appStoreID)") else { return }

        let activityVC = UIActivityViewController(
            activityItems: [text, url],
            applicationActivities: nil
        )

        // Configurar para iPad (evitar crash)
        activityVC.popoverPresentationController?.sourceView = UIView()
        activityVC.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
        activityVC.popoverPresentationController?.permittedArrowDirections = []

        #if DEBUG
        print("📤 [SupportActions] shareApp() called")
        #endif

        // Encontrar o view controller mais ao topo (funciona com sheets)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first {

            var topController = window.rootViewController
            while let presented = topController?.presentedViewController {
                topController = presented
            }

            if let topController = topController {
                topController.present(activityVC, animated: true)
            } else {
                Logger.warning("No top controller found for share sheet")
            }
        } else {
            Logger.warning("No window scene found for share sheet")
        }
    }

    static func openEmail() {
        if let url = URL(string: "mailto:suporte@naplet.app") {
            UIApplication.shared.open(url)
        }
    }
}
