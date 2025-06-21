import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

@MainActor
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
    private var pendingProfileData: Any?
    private var appleSignInCompletion: ((Result<Void, Error>) -> Void)?
    
    // Simulator detection
    var isSimulator: Bool {
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
    
    func signInWithApple(profileData: Any?, completion: @escaping (Result<Void, Error>) -> Void) {
        print("🍎 Storing profile data and completion handler for Apple Sign-In...")
        self.pendingProfileData = profileData
        self.appleSignInCompletion = completion
        
        // Now, start the actual sign in flow
        self.performAppleSignIn()
    }
    
    private func performAppleSignIn() {
        print("🍎 Starting Apple Sign-In process...")
        
        // Check if running on simulator and warn user
        if isSimulator {
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
    
    // MARK: - User Profile Creation
    
    private func createUserProfile(uid: String, name: String, email: String, role: String, profileData: Any?) {
        let userRef = db.collection("users").document(uid)
        
        // 1. Create the main user document
        let userData: [String: Any] = [
            "name": name,
            "email": email,
            "role": role,
            "createdAt": Timestamp()
        ]
        
        userRef.setData(userData) { error in
            if let error = error {
                print("❌ Error creating user document: \(error.localizedDescription)")
                self.errorMessage = "Could not save user data. Please try again."
                return
            }
            print("✅ User document created for \(uid)")
            
            // 2. Create the role-specific profile document
            if let trainerData = profileData as? TrainerProfileData {
                let trainerRef = self.db.collection("trainers").document(uid)
                let trainerProfile: [String: Any] = [
                    "name": trainerData.name,
                    "professionalTitle": trainerData.title,
                    "specialties": trainerData.specialties,
                    "yearsOfExperience": trainerData.yearsOfExperience,
                    "bio": trainerData.bio ?? "",
                    "location": trainerData.location ?? "",
                    "phoneNumber": trainerData.phoneNumber ?? "",
                    "website": trainerData.website ?? "",
                    "email": email // Also store email here for convenience
                ]
                trainerRef.setData(trainerProfile) { error in
                    if let error = error {
                        print("❌ Error creating trainer profile: \(error.localizedDescription)")
                    } else {
                        print("✅ Trainer profile created for \(uid)")
                    }
                }
            } else if let clientData = profileData as? ClientProfileData {
                let clientRef = self.db.collection("clients").document(uid)
                let clientProfile: [String: Any] = [
                    "name": clientData.name,
                    "fitnessLevel": clientData.fitnessLevel,
                    "goals": clientData.goals,
                    "email": email // Also store email here for convenience
                ]
                clientRef.setData(clientProfile) { error in
                    if let error = error {
                        print("❌ Error creating client profile: \(error.localizedDescription)")
                    } else {
                        print("✅ Client profile created for \(uid)")
                    }
                }
            }
        }
    }
    
    // MARK: - Email/Password Authentication
    
    func signUp(email: String, password: String, fullName: String, profileData: Any?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !email.isEmpty, !password.isEmpty, !fullName.isEmpty else {
            let error = NSError(domain: "AuthenticationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please fill in all fields."])
            completion(.failure(error))
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Firebase auth error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let user = authResult?.user, let self = self else {
                    let error = NSError(domain: "AuthenticationError", code: -2, userInfo: [NSLocalizedDescriptionKey: "User creation failed unexpectedly."])
                    completion(.failure(error))
                    return
                }
                
                // Determine role from profileData
                let role = (profileData is TrainerProfileData) ? "trainer" : "client"
                
                // Create user profile in Firestore
                self.createUserProfile(uid: user.uid, name: fullName, email: email, role: role, profileData: profileData)
                
                // Update Firebase Auth display name
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = fullName
                changeRequest.commitChanges { error in
                    if let error = error {
                        // This is not a fatal error, so we just log it but still call success
                        print("⚠️ Error updating display name: \(error.localizedDescription)")
                    }
                }
                
                self.userName = fullName
                self.userEmail = email
                completion(.success(()))
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
        guard isSimulator else {
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
        print("🍎 Authorization controller completed successfully.")
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            let authError = NSError(domain: "com.movefully.auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not retrieve Apple ID Credential."])
            handleSignInCompletion(result: .failure(authError))
            return
        }

        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)

        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.handleSignInCompletion(result: .failure(error))
                    return
                }

                guard let user = authResult?.user else {
                    let authError = NSError(domain: "com.movefully.auth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not retrieve user after Apple Sign-In."])
                    self.handleSignInCompletion(result: .failure(authError))
                    return
                }

                // Check if this is a new user
                let isNewUser = authResult?.additionalUserInfo?.isNewUser ?? false

                if isNewUser {
                    print("🍎 New user detected from Apple Sign-In. Creating profile...")
                    guard let email = user.email, let fullName = appleIDCredential.fullName?.formatted() else {
                        let profileError = NSError(domain: "com.movefully.auth", code: -3, userInfo: [NSLocalizedDescriptionKey: "Could not retrieve user details from Apple for profile creation."])
                        self.handleSignInCompletion(result: .failure(profileError))
                        return
                    }

                    let role = (self.pendingProfileData is TrainerProfileData) ? "trainer" : "client"
                    self.createUserProfile(uid: user.uid, name: fullName, email: email, role: role, profileData: self.pendingProfileData)
                } else {
                    print("🍎 Returning user from Apple Sign-In.")
                    // For returning users, data is fetched by the auth state listener.
                }
                
                // Finalize the sign-in process
                self.handleSignInCompletion(result: .success(()))
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("🍎 Authorization controller failed with error: \(error.localizedDescription)")
        handleSignInCompletion(result: .failure(error))
    }
    
    private func handleSignInCompletion(result: Result<Void, Error>) {
        DispatchQueue.main.async {
            self.isLoading = false
            if case .failure(let error) = result {
                self.errorMessage = error.localizedDescription
            }
            // Call the completion handler
            self.appleSignInCompletion?(result)
            
            // Clean up
            self.currentNonce = nil
            self.pendingProfileData = nil
            self.appleSignInCompletion = nil
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
