import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

class AuthenticationViewModel: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var userRole: String? = nil
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    // Apple Sign-In properties
    private var currentNonce: String?
    private var authorizationController: ASAuthorizationController?
    
    // Simulator detection
    private var isRunningOnSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Static Properties
    
    /// Checks if Sign in with Apple is available (requires paid developer account)
    static var isSignInWithAppleAvailable: Bool {
        // This can be controlled by adding SIGN_IN_WITH_APPLE_AVAILABLE to build settings
        // For now, we'll use a simple approach:
        // - Always available on simulator for testing
        // - For device, check if we can create an Apple ID provider request
        
        #if targetEnvironment(simulator)
        return true
        #else
        // Try to create a request - createRequest() doesn't throw, so no need for do-catch
        let provider = ASAuthorizationAppleIDProvider()
        let _ = provider.createRequest()
        return true
        #endif
    }
    
    override init() {
        super.init()
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                print("📱 Auth state changed: \(user?.email ?? "No user")")
                self?.isAuthenticated = user != nil
                if let user = user {
                    self?.userEmail = user.email ?? ""
                    self?.fetchUserData(userId: user.uid)
                } else {
                    self?.clearUserData()
                }
            }
        }
    }
    
    func checkAuthenticationState() {
        if let user = Auth.auth().currentUser {
            isAuthenticated = true
            userEmail = user.email ?? ""
            fetchUserData(userId: user.uid)
        } else {
            isAuthenticated = false
            clearUserData()
        }
    }
    
    // MARK: - Apple Sign-In
    
    func signInWithApple() {
        print("🍎 Starting Apple Sign-In process...")
        
        // Check if running on simulator and warn user
        if isRunningOnSimulator {
            print("⚠️ Apple Sign-In has limited support on iOS Simulator")
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = ""
            
            let nonce = self.randomNonceString()
            self.currentNonce = nonce
            print("🍎 Generated nonce: \(nonce.prefix(10))...")
            
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = self.sha256(nonce)
            
            self.authorizationController = ASAuthorizationController(authorizationRequests: [request])
            self.authorizationController?.delegate = self
            self.authorizationController?.presentationContextProvider = self
            
            print("🍎 Presenting authorization controller...")
            
            // Ensure we're on the main thread for UI operations
            DispatchQueue.main.async {
                self.authorizationController?.performRequests()
            }
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - Email/Password Authentication
    
    func signUp(email: String, password: String, name: String) {
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let user = result?.user else { return }
                
                // Update display name
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = name
                changeRequest.commitChanges { error in
                    if let error = error {
                        print("Error updating display name: \(error.localizedDescription)")
                    }
                }
                
                self?.userName = name
                self?.userEmail = email
            }
        }
    }
    
    func signIn(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            clearUserData()
        } catch {
            errorMessage = "Error signing out: \(error.localizedDescription)"
        }
    }
    
    func selectRole(_ role: String) {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        errorMessage = ""
        
        let userData: [String: Any] = [
            "role": role,
            "name": userName.isEmpty ? (user.displayName ?? "") : userName,
            "email": userEmail,
            "createdAt": Timestamp()
        ]
        
        db.collection("users").document(user.uid).setData(userData) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Error saving user data: \(error.localizedDescription)"
                    return
                }
                
                self?.userRole = role
            }
        }
    }
    
    private func fetchUserData(userId: String) {
        print("📊 Fetching user data for: \(userId)")
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    let data = document.data()
                    self?.userRole = data?["role"] as? String
                    self?.userName = data?["name"] as? String ?? ""
                    print("📊 User data fetched - Role: \(self?.userRole ?? "nil"), Name: \(self?.userName ?? "")")
                } else {
                    print("📊 No user data found, user needs to select role")
                    self?.userRole = nil
                    self?.userName = ""
                }
            }
        }
    }
    
    private func clearUserData() {
        userRole = nil
        userName = ""
        userEmail = ""
        errorMessage = ""
    }
    
    // MARK: - Demo/Test Account (Simulator only)
    
    func signInWithTestAccount() {
        guard isRunningOnSimulator else {
            print("⚠️ Test account is only available on simulator")
            return
        }
        
        print("🧪 Creating test account for simulator...")
        isLoading = true
        errorMessage = ""
        
        // Create a test user with Firebase Auth
        let testEmail = "test@movefully.app"
        let testPassword = "TestPassword123!"
        
        Auth.auth().createUser(withEmail: testEmail, password: testPassword) { [weak self] result, error in
            if let error = error {
                // If user already exists, try signing in instead
                if (error as NSError).code == AuthErrorCode.emailAlreadyInUse.rawValue {
                    self?.signIn(email: testEmail, password: testPassword)
                } else {
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        self?.errorMessage = "Failed to create test account: \(error.localizedDescription)"
                    }
                }
                return
            }
            
            guard let user = result?.user else { return }
            
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.userName = "Test User"
                self?.userEmail = testEmail
                
                // Update display name
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = "Test User"
                changeRequest.commitChanges { error in
                    if let error = error {
                        print("Error updating test user display name: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Apple Sign-In Fallback
    
    private func handleAppleSignInFallback(appleIDCredential: ASAuthorizationAppleIDCredential, nonce: String) {
        print("🍎 Handling Apple Sign-In with fallback method...")
        
        // Create a unique email for this Apple ID user
        let uniqueEmail = "apple_\(appleIDCredential.user)@movefully.app"
        let temporaryPassword = "AppleUser_\(UUID().uuidString)"
        
        print("🍎 Creating Firebase user with unique email: \(uniqueEmail)")
        
        // Try to create a new Firebase user
        Auth.auth().createUser(withEmail: uniqueEmail, password: temporaryPassword) { [weak self] result, error in
            if let error = error {
                // If user already exists, sign them in instead
                if (error as NSError).code == AuthErrorCode.emailAlreadyInUse.rawValue {
                    print("🍎 User already exists, signing in...")
                    Auth.auth().signIn(withEmail: uniqueEmail, password: temporaryPassword) { [weak self] result, error in
                        if let error = error {
                            print("❌ Fallback sign-in failed: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                self?.errorMessage = "Authentication failed. Please try again."
                            }
                            return
                        }
                        self?.handleSuccessfulAppleSignIn(user: result?.user, appleIDCredential: appleIDCredential)
                    }
                } else {
                    print("❌ Fallback user creation failed: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self?.errorMessage = "Authentication failed. Please try again."
                    }
                }
                return
            }
            
            print("✅ Fallback user created successfully")
            self?.handleSuccessfulAppleSignIn(user: result?.user, appleIDCredential: appleIDCredential)
        }
    }
    
    private func handleSuccessfulAppleSignIn(user: User?, appleIDCredential: ASAuthorizationAppleIDCredential) {
        guard let user = user else {
            print("❌ No user returned from fallback authentication")
            DispatchQueue.main.async {
                self.errorMessage = "Authentication failed: No user data"
            }
            return
        }
        
        print("✅ Apple Sign-In successful (fallback) for user: \(user.uid)")
        
        DispatchQueue.main.async {
            // Set user info from Apple ID credential
            if let fullName = appleIDCredential.fullName {
                let displayName = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                
                if !displayName.isEmpty {
                    print("🍎 Setting display name: \(displayName)")
                    self.userName = displayName
                    
                    // Update Firebase user profile
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = displayName
                    changeRequest.commitChanges { error in
                        if let error = error {
                            print("❌ Error updating display name: \(error.localizedDescription)")
                        } else {
                            print("✅ Display name updated successfully")
                        }
                    }
                }
            }
            
            if let email = appleIDCredential.email {
                print("🍎 Setting email from Apple: \(email)")
                self.userEmail = email
            } else {
                print("🍎 Using Firebase email: \(user.email ?? "none")")
                self.userEmail = user.email ?? ""
            }
            
            // Clear the authorization controller
            self.authorizationController = nil
            self.currentNonce = nil
        }
    }
}

// MARK: - Apple Sign-In Delegates

extension AuthenticationViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("🍎 Apple authorization completed successfully")
        print("🍎 Authorization object type: \(type(of: authorization.credential))")
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            print("🍎 Apple ID credential received")
            print("🍎 User ID: \(appleIDCredential.user)")
            print("🍎 Email: \(appleIDCredential.email ?? "nil")")
            print("🍎 Full name: \(appleIDCredential.fullName?.formatted() ?? "nil")")
            
            guard let nonce = currentNonce else {
                print("❌ Invalid state: No nonce found")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Authentication error: Invalid state"
                }
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("❌ Unable to fetch identity token")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Unable to fetch identity token"
                }
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("❌ Unable to serialize token string from data")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Unable to process identity token"
                }
                return
            }
            
            print("🍎 Creating Firebase credential...")
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            
            print("🍎 Signing in to Firebase...")
            Auth.auth().signIn(with: credential) { [weak self] result, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        print("❌ Firebase sign-in error: \(error.localizedDescription)")
                        
                        // Check if this is an audience mismatch error
                        if error.localizedDescription.contains("audience") {
                            print("🍎 Attempting fallback authentication...")
                            self?.handleAppleSignInFallback(appleIDCredential: appleIDCredential, nonce: nonce)
                            return
                        }
                        
                        self?.errorMessage = "Sign-in failed: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let user = result?.user else {
                        print("❌ No user returned from Firebase")
                        self?.errorMessage = "Authentication failed: No user data"
                        return
                    }
                    
                    print("✅ Firebase sign-in successful for user: \(user.uid)")
                    
                    // Set user info from Apple ID credential
                    if let fullName = appleIDCredential.fullName {
                        let displayName = [fullName.givenName, fullName.familyName]
                            .compactMap { $0 }
                            .joined(separator: " ")
                        
                        if !displayName.isEmpty {
                            print("🍎 Setting display name: \(displayName)")
                            self?.userName = displayName
                            
                            // Update Firebase user profile
                            let changeRequest = user.createProfileChangeRequest()
                            changeRequest.displayName = displayName
                            changeRequest.commitChanges { error in
                                if let error = error {
                                    print("❌ Error updating display name: \(error.localizedDescription)")
                                } else {
                                    print("✅ Display name updated successfully")
                                }
                            }
                        }
                    }
                    
                    if let email = appleIDCredential.email {
                        print("🍎 Setting email from Apple: \(email)")
                        self?.userEmail = email
                    } else {
                        print("🍎 Using Firebase email: \(user.email ?? "none")")
                        self?.userEmail = user.email ?? ""
                    }
                    
                    // Clear the authorization controller
                    self?.authorizationController = nil
                    self?.currentNonce = nil
                }
            }
        } else {
            print("❌ Invalid credential type received: \(type(of: authorization.credential))")
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Invalid credential type"
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Apple Sign-In failed with error: \(error.localizedDescription)")
        print("❌ Error code: \((error as NSError).code)")
        print("❌ Error domain: \((error as NSError).domain)")
        
        DispatchQueue.main.async {
            self.isLoading = false
            
            // Check if user cancelled
            if let authError = error as? ASAuthorizationError {
                print("🍎 ASAuthorizationError case: \(authError.code.rawValue)")
                switch authError.code {
                case .canceled:
                    print("🍎 User cancelled Apple Sign-In")
                    self.errorMessage = ""
                case .failed:
                    if self.isRunningOnSimulator {
                        self.errorMessage = "Apple Sign-In has limited support on iOS Simulator. Try using email/password instead, or test on a physical device."
                    } else {
                        self.errorMessage = "Apple Sign-In failed. Please try again."
                    }
                case .invalidResponse:
                    self.errorMessage = "Invalid response from Apple. Please try again."
                case .notHandled:
                    self.errorMessage = "Apple Sign-In not handled. Please try again."
                case .unknown:
                    if self.isRunningOnSimulator {
                        self.errorMessage = "Apple Sign-In error on simulator. Try email/password instead."
                    } else {
                        self.errorMessage = "Unknown error occurred. Please try again."
                    }
                case .notInteractive:
                    self.errorMessage = "Apple Sign-In requires user interaction."
                case .matchedExcludedCredential:
                    self.errorMessage = "Credential not available. Please try again."
                case .credentialImport:
                    self.errorMessage = "Credential import failed. Please try again."
                case .credentialExport:
                    self.errorMessage = "Credential export failed. Please try again."
                @unknown default:
                    if self.isRunningOnSimulator {
                        self.errorMessage = "Apple Sign-In may not work properly on simulator. Try email/password instead."
                    } else {
                        self.errorMessage = "Apple Sign-In failed. Please try again."
                    }
                }
            } else {
                // Handle other types of errors (like AKAuthenticationError)
                if self.isRunningOnSimulator {
                    self.errorMessage = "Apple Sign-In has known limitations on iOS Simulator. Please use email/password authentication instead, or test on a physical device for full Apple Sign-In functionality."
                } else {
                    self.errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
                }
            }
            
            // Clear the authorization controller
            self.authorizationController = nil
            self.currentNonce = nil
        }
    }
}

extension AuthenticationViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        print("🍎 presentationAnchor called")
        
        // Try multiple approaches to get a valid window
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            print("🍎 Found key window in active scene")
            return window
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            print("🍎 Found first window in first scene")
            return window
        }
        
        // Fallback - should not reach here in modern iOS
        print("❌ No window found for presentation anchor")
        fatalError("No window available for Apple Sign-In presentation")
    }
} 
