import Foundation
import Supabase
import Auth
import GoogleSignIn
import CryptoKit

// MARK: - Supabase Service
@MainActor
final class SupabaseService: ObservableObject {

    // MARK: - Singleton
    static let shared = SupabaseService()

    // MARK: - Properties
    let client: SupabaseClient

    @Published var isInitialized = false
    @Published var currentSession: Session?
    @Published var currentUser: User?

    var currentUserId: UUID? {
        currentUser?.id
    }

    // MARK: - Init
    private init() {
        let environment = AppEnvironment.current

        // Use a valid URL for initialization (will run in mock mode if useMockData is true)
        let supabaseURL = URL(string: environment.supabaseURL) ?? URL(string: "https://mock.supabase.co")!

        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: environment.supabaseKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    storage: KeychainAuthStorage(),
                    autoRefreshToken: true
                ),
                global: SupabaseClientOptions.GlobalOptions(
                    logger: environment.isDebug ? SupabaseLogHandler() : nil
                )
            )
        )

        Logger.info("SupabaseService initialized (mock mode: \(environment.useMockData))")

        // Only try to initialize real connection if not in mock mode
        if !environment.useMockData {
            Task {
                await initialize()
            }
        } else {
            isInitialized = true
        }
    }

    // MARK: - Initialization

    private func initialize() async {
        do {
            let session = try await client.auth.session
            self.currentSession = session
            self.currentUser = session.user
            Logger.info("Session found: \(session.user.email ?? "no email")")
            isInitialized = true
        } catch {
            Logger.debug("No existing session: \(error.localizedDescription)")
            isInitialized = true
        }

        // Listen for auth state changes
        Task {
            for await (event, session) in client.auth.authStateChanges {
                Logger.debug("Auth state changed: \(event)")
                self.currentSession = session
                self.currentUser = session?.user
            }
        }
    }

    // MARK: - Auth Methods

    /// Sign in with Apple
    func signInWithApple(idToken: String, nonce: String) async throws -> User {
        let response = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        currentUser = response.user
        return response.user
    }
    
    /// Sign in with Google
    /// Uses GoogleSignIn SDK to authenticate and then signs into Supabase
    func signInWithGoogle() async throws {
        // 1. Generate a random nonce (same approach as Apple Sign In)
        let rawNonce = randomNonceString()
        let hashedNonce = sha256(rawNonce)
        
        // 2. Configure Google Sign In
        let config = GIDConfiguration(clientID: AppConfig.Google.iOSClientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // 3. Get the root view controller
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
            throw NSError(
                domain: "SupabaseService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Não foi possível obter a janela principal"]
            )
        }
        
        // 4. Perform Google Sign In with hashed nonce
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController,
            hint: nil,
            additionalScopes: ["email", "profile"],
            nonce: hashedNonce
        )
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(
                domain: "SupabaseService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Não foi possível obter o token do Google"]
            )
        }
        
        let accessToken = result.user.accessToken.tokenString
        
        // 5. Sign in to Supabase with Google credentials and RAW nonce
        let response = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken,
                nonce: rawNonce  // Pass the RAW nonce, not hashed
            )
        )
        
        currentUser = response.user
        Logger.info("Google Sign In successful: \(response.user.email ?? "unknown")")
    }
    
    // MARK: - Crypto Helpers (for OAuth nonce)
    
    /// Generates a random nonce string for OAuth authentication
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
    
    /// Creates a SHA256 hash of the input string
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> User {
        let response = try await client.auth.signIn(
            email: email,
            password: password
        )
        currentUser = response.user
        return response.user
    }

    /// Sign up with email and password
    func signUp(email: String, password: String) async throws -> User {
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        currentUser = response.user
        return response.user
    }
    
    /// Sign up with email, password and metadata
    func signUpWithMetadata(email: String, password: String, displayName: String) async throws -> User {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: [
                "full_name": AnyJSON.string(displayName),
                "display_name": AnyJSON.string(displayName)
            ]
        )

        currentUser = response.user
        return response.user
    }

    /// Sign out
    func signOut() async throws {
        try await client.auth.signOut()
        currentUser = nil
        currentSession = nil
    }

    /// Get current user
    func getCurrentUser() async -> User? {
        try? await client.auth.user()
    }

    /// Refresh session
    func refreshSession() async throws {
        let session = try await client.auth.refreshSession()
        currentSession = session
        currentUser = session.user
    }

    // MARK: - Password Reset

    /// Send password reset email
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    /// Update password
    func updatePassword(newPassword: String) async throws {
        try await client.auth.update(user: UserAttributes(password: newPassword))
    }
}

// MARK: - Keychain Storage for Auth
final class KeychainAuthStorage: AuthLocalStorage {
    private let keyPrefix = "com.naplet.auth."

    func store(key: String, value: Data) throws {
        let fullKey = keyPrefix + key

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: fullKey,
            kSecValueData as String: value,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Delete existing item if any
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw AuthStorageError.storeFailed(status)
        }
    }

    func retrieve(key: String) throws -> Data? {
        let fullKey = keyPrefix + key

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: fullKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw AuthStorageError.retrieveFailed(status)
        }

        return result as? Data
    }

    func remove(key: String) throws {
        let fullKey = keyPrefix + key

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: fullKey
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthStorageError.removeFailed(status)
        }
    }
}

// MARK: - Auth Storage Errors
enum AuthStorageError: Error, LocalizedError {
    case storeFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case removeFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .storeFailed(let status):
            return "Failed to store auth data: \(status)"
        case .retrieveFailed(let status):
            return "Failed to retrieve auth data: \(status)"
        case .removeFailed(let status):
            return "Failed to remove auth data: \(status)"
        }
    }
}

// MARK: - Supabase Logger
struct SupabaseLogHandler: SupabaseLogger {
    func log(message: SupabaseLogMessage) {
        switch message.level {
        case .verbose, .debug:
            Logger.debug("[Supabase] \(message.description)")
        case .warning:
            Logger.warning("[Supabase] \(message.description)")
        case .error:
            Logger.error("[Supabase] \(message.description)")
        }
    }
}
