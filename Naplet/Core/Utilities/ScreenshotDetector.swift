import SwiftUI
import UIKit

// MARK: - Screenshot Detector View Modifier
struct ScreenshotDetectorModifier: ViewModifier {
    @State private var showScreenshotAlert = false
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
                // Small delay to ensure the screenshot was captured
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showScreenshotAlert = true
                    HapticManager.shared.success()
                }
            }
            .alert("screenshot.alert.title".localized, isPresented: $showScreenshotAlert) {
                Button("screenshot.alert.share".localized) {
                    openInstagram()
                }
                Button("screenshot.alert.later".localized, role: .cancel) {}
            } message: {
                Text("screenshot.alert.message".localized)
            }
    }
    
    private func openInstagram() {
        // Try to open Instagram app directly to @naplet.app profile
        let instagramURL = URL(string: "instagram://user?username=naplet.app")!
        let webURL = URL(string: "https://instagram.com/naplet.app")!
        
        if UIApplication.shared.canOpenURL(instagramURL) {
            UIApplication.shared.open(instagramURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }
}

// MARK: - View Extension
extension View {
    /// Detects when user takes a screenshot and shows a prompt to share on Instagram
    func detectScreenshot() -> some View {
        modifier(ScreenshotDetectorModifier())
    }
}

