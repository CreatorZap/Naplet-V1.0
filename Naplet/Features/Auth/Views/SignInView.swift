import SwiftUI
import AuthenticationServices
import CryptoKit

struct SignInView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @EnvironmentObject var appState: AppState
    
    // Apple Sign In
    @State private var currentNonce: String?
    
    // Navigation
    @State private var showEmailSignIn = false
    
    // UI State
    @State private var isLoading = false
    @State private var loadingProvider: AuthProvider?
    @State private var errorMessage: String?
    @State private var agreedToTerms = true
    
    // Animations
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 50
    
    enum AuthProvider {
        case apple, google, email
    }
    
    var body: some View {
        ZStack {
            // MARK: - Background
            backgroundView
            
            // MARK: - Content
            VStack(spacing: 0) {
                Spacer()
                
                // Logo & Branding
                brandingSection
                
                Spacer()
                
                // Social Proof
                socialProofSection
                    .padding(.bottom, 40)
                
                // Terms Agreement
                termsAgreement
                    .padding(.bottom, 20)
                
                // Auth Buttons
                authButtonsSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            animateEntrance()
        }
        .alert("auth.error.title".localized, isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("common.ok".localized) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showEmailSignIn) {
            EmailSignInView()
                .environmentObject(supabaseService)
                .environmentObject(appState)
        }
    }
    
    // MARK: - Background
    private var backgroundView: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.07, blue: 0.14),
                    Color(red: 0.05, green: 0.04, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Floating stars
            FloatingStarsView(starCount: 25)
                .opacity(0.6)
                .ignoresSafeArea()
            
            // Subtle glow at top
            RadialGradient(
                colors: [
                    NapletColors.primaryPurple.opacity(0.15),
                    Color.clear
                ],
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Branding Section
    private var brandingSection: some View {
        VStack(spacing: 24) {
            // Logo with glow
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                NapletColors.primaryPurple.opacity(0.3),
                                NapletColors.primaryPink.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 25)
                
                // Moon icon
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 70, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
            
            // App name
            Text("naplet")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(contentOpacity)
            
            // Tagline
            Text("auth.tagline".localized)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(contentOpacity)
        }
    }
    
    // MARK: - Social Proof Section
    private var socialProofSection: some View {
        VStack(spacing: 16) {
            // Stars
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 22))
                        .foregroundColor(NapletColors.primaryPurple.opacity(0.8))
                }
            }
            
            // Rating text
            Text("auth.socialProof.headline".localized)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(NapletColors.textSecondary)
            
            // Badges
            HStack(spacing: 24) {
                // Badge 1
                badgeView(
                    topText: "App Store",
                    mainText: "auth.badge.editorsChoice.main".localized,
                    bottomText: "auth.badge.editorsChoice.sub".localized
                )
                
                // Badge 2
                badgeView(
                    topText: "App Store",
                    mainText: "auth.badge.appOfDay.main".localized,
                    bottomText: "auth.badge.appOfDay.sub".localized
                )
            }
            .padding(.top, 8)
        }
        .opacity(contentOpacity)
    }
    
    private func badgeView(topText: String, mainText: String, bottomText: String) -> some View {
        HStack(spacing: 8) {
            // Laurel left
            Image(systemName: "laurel.leading")
                .font(.system(size: 28))
                .foregroundColor(NapletColors.textMuted.opacity(0.5))
            
            VStack(spacing: 2) {
                Text(topText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(NapletColors.textMuted)
                
                Text(mainText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(NapletColors.textSecondary)
                
                Text(bottomText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)
            }
            
            // Laurel right
            Image(systemName: "laurel.trailing")
                .font(.system(size: 28))
                .foregroundColor(NapletColors.textMuted.opacity(0.5))
        }
    }
    
    // MARK: - Terms Agreement
    private var termsAgreement: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                agreedToTerms.toggle()
            }
            HapticManager.shared.lightImpact()
        }) {
            HStack(alignment: .top, spacing: 12) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(agreedToTerms ? NapletColors.primaryPurple : NapletColors.textMuted.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if agreedToTerms {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(NapletColors.primaryPurple.opacity(0.2))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(NapletColors.primaryPurple)
                    }
                }
                
                // Text
                Group {
                    Text("auth.terms.agree".localized + " ")
                        .foregroundColor(NapletColors.textMuted) +
                    Text("auth.terms.termsAndConditions".localized)
                        .foregroundColor(NapletColors.primaryPurple)
                        .underline() +
                    Text(" " + "auth.terms.and".localized + " ")
                        .foregroundColor(NapletColors.textMuted) +
                    Text("auth.terms.privacyPolicy".localized)
                        .foregroundColor(NapletColors.primaryPurple)
                        .underline() +
                    Text(" " + "auth.terms.ofNaplet".localized)
                        .foregroundColor(NapletColors.textMuted)
                }
                .font(.system(size: 14))
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
            }
            .padding(.horizontal, 24)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(contentOpacity)
    }
    
    // MARK: - Auth Buttons Section
    private var authButtonsSection: some View {
        VStack(spacing: 14) {
            // Apple Button
            Button(action: {
                guard agreedToTerms else {
                    errorMessage = "auth.error.acceptTerms".localized
                    HapticManager.shared.warning()
                    return
                }
                HapticManager.shared.lightImpact()
                triggerAppleSignIn()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("auth.button.continueApple".localized)
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                )
            }
            .disabled(isLoading)
            .opacity(isLoading && loadingProvider != .apple ? 0.6 : 1)
            .overlay {
                if isLoading && loadingProvider == .apple {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        )
                }
            }
            
            // Google Button
            Button(action: {
                guard agreedToTerms else {
                    errorMessage = "auth.error.acceptTerms".localized
                    HapticManager.shared.warning()
                    return
                }
                HapticManager.shared.lightImpact()
                signInWithGoogle()
            }) {
                HStack(spacing: 12) {
                    // Google Icon
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .yellow, .green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("auth.button.continueGoogle".localized)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(NapletColors.textMuted.opacity(0.3), lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )
                )
            }
            .disabled(isLoading)
            .opacity(isLoading && loadingProvider != .google ? 0.6 : 1)
            .overlay {
                if isLoading && loadingProvider == .google {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
            }
            
            // Email Button
            Button(action: {
                guard agreedToTerms else {
                    errorMessage = "auth.error.acceptTerms".localized
                    HapticManager.shared.warning()
                    return
                }
                HapticManager.shared.lightImpact()
                showEmailSignIn = true
            }) {
                Text("auth.button.continueEmail".localized)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)
            }
            .padding(.top, 8)
            .disabled(isLoading)
        }
        .offset(y: buttonsOffset)
        .opacity(contentOpacity)
    }
    
    // MARK: - Animations
    private func animateEntrance() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            contentOpacity = 1.0
        }
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4)) {
            buttonsOffset = 0
        }
    }
    
    // MARK: - Apple Sign In
    private func triggerAppleSignIn() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = AppleSignInCoordinator.shared
        authorizationController.presentationContextProvider = AppleSignInCoordinator.shared
        
        AppleSignInCoordinator.shared.onCompletion = { result in
            handleAppleSignIn(result)
        }
        
        authorizationController.performRequests()
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: identityToken, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = "auth.error.credentials".localized
                HapticManager.shared.error()
                return
            }
            
            isLoading = true
            loadingProvider = .apple
            
            Task {
                do {
                    _ = try await supabaseService.signInWithApple(idToken: idTokenString, nonce: nonce)
                    await MainActor.run {
                        HapticManager.shared.success()
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "auth.error.signIn".localized
                        HapticManager.shared.error()
                        Logger.error(error, context: "Sign in with Apple failed")
                    }
                }
                await MainActor.run {
                    isLoading = false
                    loadingProvider = nil
                }
            }
            
        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = "auth.error.cancelled".localized
                HapticManager.shared.warning()
            }
        }
    }
    
    // MARK: - Google Sign In
    private func signInWithGoogle() {
        isLoading = true
        loadingProvider = .google
        
        Task {
            do {
                try await supabaseService.signInWithGoogle()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    HapticManager.shared.warning()
                    Logger.error(error, context: "Sign in with Google failed")
                }
            }
            await MainActor.run {
                isLoading = false
                loadingProvider = nil
            }
        }
    }
    
    // MARK: - Crypto Helpers
    private func randomNonceString(length: Int = 32) -> String {
        guard length > 0 else { return UUID().uuidString }
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            return UUID().uuidString + UUID().uuidString
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Apple Sign In Coordinator
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static let shared = AppleSignInCoordinator()
    var onCompletion: ((Result<ASAuthorization, Error>) -> Void)?
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return UIWindow()
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        onCompletion?(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onCompletion?(.failure(error))
    }
}

// MARK: - Email Sign In View
struct EmailSignInView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccessMessage = false
    
    var body: some View {
        NavigationView {
            ZStack {
                NapletColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text(isSignUp ? "auth.email.createAccount".localized : "auth.email.signIn".localized)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(NapletColors.textPrimary)
                            
                            Text(isSignUp ? "auth.email.createSubtitle".localized : "auth.email.signInSubtitle".localized)
                                .font(.system(size: 16))
                                .foregroundColor(NapletColors.textSecondary)
                        }
                        .padding(.top, 20)
                        
                        // Form
                        VStack(spacing: 16) {
                            // Name field (only for sign up)
                            if isSignUp {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("auth.email.name".localized)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(NapletColors.textSecondary)
                                    
                                    TextField("auth.email.namePlaceholder".localized, text: $displayName)
                                        .textFieldStyle(NapletTextFieldStyle())
                                        .textContentType(.name)
                                        .autocapitalization(.words)
                                }
                            }
                            
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("auth.email.email".localized)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(NapletColors.textSecondary)
                                
                                TextField("auth.email.emailPlaceholder".localized, text: $email)
                                    .textFieldStyle(NapletTextFieldStyle())
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("auth.email.password".localized)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(NapletColors.textSecondary)
                                
                                SecureField("••••••••", text: $password)
                                    .textFieldStyle(NapletTextFieldStyle())
                                    .textContentType(isSignUp ? .newPassword : .password)
                            }
                            
                            // Confirm password (only for sign up)
                            if isSignUp {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("auth.email.confirmPassword".localized)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(NapletColors.textSecondary)
                                    
                                    SecureField("••••••••", text: $confirmPassword)
                                        .textFieldStyle(NapletTextFieldStyle())
                                        .textContentType(.newPassword)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Submit Button
                        Button(action: submitForm) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(isSignUp ? "auth.email.createButton".localized : "auth.email.signInButton".localized)
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1 : 0.6)
                        .padding(.horizontal, 24)
                        
                        // Toggle Sign Up / Sign In
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                isSignUp.toggle()
                                // Reset fields when switching
                                password = ""
                                confirmPassword = ""
                                displayName = ""
                            }
                            HapticManager.shared.lightImpact()
                        }) {
                            HStack(spacing: 4) {
                                Text(isSignUp ? "auth.email.haveAccount".localized : "auth.email.noAccount".localized)
                                    .foregroundColor(NapletColors.textSecondary)
                                
                                Text(isSignUp ? "auth.email.signInLink".localized : "auth.email.createLink".localized)
                                    .foregroundColor(NapletColors.primaryPurple)
                                    .fontWeight(.semibold)
                            }
                            .font(.system(size: 15))
                        }
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(NapletColors.textSecondary)
                    }
                }
            }
            .alert("auth.error.title".localized, isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("common.ok".localized) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("auth.success.title".localized, isPresented: $showSuccessMessage) {
                Button("common.ok".localized) {
                    dismiss()
                }
            } message: {
                Text("auth.success.accountCreated".localized)
            }
        }
    }
    
    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && !displayName.isEmpty && password == confirmPassword && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    private func submitForm() {
        // Validate
        guard isValidEmail(email) else {
            errorMessage = "auth.validation.invalidEmail".localized
            HapticManager.shared.warning()
            return
        }
        
        if isSignUp {
            guard password.count >= 6 else {
                errorMessage = "auth.validation.passwordMinLength".localized
                HapticManager.shared.warning()
                return
            }
            
            guard password == confirmPassword else {
                errorMessage = "auth.validation.passwordMismatch".localized
                HapticManager.shared.warning()
                return
            }
            
            guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
                errorMessage = "auth.validation.enterName".localized
                HapticManager.shared.warning()
                return
            }
        }
        
        isLoading = true
        HapticManager.shared.lightImpact()
        
        Task {
            do {
                if isSignUp {
                    _ = try await supabaseService.signUpWithMetadata(
                        email: email,
                        password: password,
                        displayName: displayName.trimmingCharacters(in: .whitespaces)
                    )
                    await MainActor.run {
                        showSuccessMessage = true
                        HapticManager.shared.success()
                    }
                } else {
                    _ = try await supabaseService.signIn(email: email, password: password)
                    await MainActor.run {
                        HapticManager.shared.success()
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = parseAuthError(error)
                    HapticManager.shared.error()
                    Logger.error(error, context: "Email auth failed")
                }
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func parseAuthError(_ error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("invalid") || errorString.contains("wrong") {
            return "auth.error.invalidCredentials".localized
        } else if errorString.contains("confirm") || errorString.contains("verify") {
            return "auth.error.emailNotConfirmed".localized
        } else if errorString.contains("exists") || errorString.contains("already") {
            return "auth.error.emailAlreadyRegistered".localized
        } else if errorString.contains("rate") || errorString.contains("too many") {
            return "auth.error.tooManyAttempts".localized
        }
        
        return "auth.error.generic".localized
    }
}

#Preview {
    SignInView()
        .environmentObject(SupabaseService.shared)
        .environmentObject(AppState())
}
