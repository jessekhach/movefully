import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

@MainActor
class AuthenticationViewModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
    @Published var user: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var requiresProfileSetup: Bool = false
    @Published var userRole: String? = nil
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    // Apple Sign-In properties
    private var currentNonce: String?
    private var authorizationController: ASAuthorizationController?
    private var pendingProfileData: Any?
    private var appleSignInCompletion: ((Result<Void, Error>) -> Void)?
    
    // Apple Sign-In availability
    static var isSignInWithAppleAvailable: Bool {
        return true // Apple Sign-In is always available on iOS 13+
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
        
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        self.authorizationController = authorizationController
        authorizationController.performRequests()
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
    
    // MARK: - Apple Sign-In Handler
    
    func handleAppleSignIn(authorization: ASAuthorization, profileData: Any?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            let authError = NSError(domain: "com.movefully.auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not retrieve Apple ID Credential."])
            completion(.failure(authError))
            return
        }
        
        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
        
        self.isLoading = true
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("❌ Firebase auth error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let user = authResult?.user, let self = self else {
                    let authError = NSError(domain: "com.movefully.auth", code: -2, userInfo: [NSLocalizedDescriptionKey: "User creation failed unexpectedly."])
                    completion(.failure(authError))
                    return
                }
                
                let isNewUser = authResult?.additionalUserInfo?.isNewUser ?? false
                
                if isNewUser {
                    let name = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    let email = appleIDCredential.email ?? user.email ?? ""
                    let role = (profileData is TrainerProfileData) ? "trainer" : "client"
                    
                    self.createUserProfile(uid: user.uid, name: name, email: email, role: role, profileData: profileData)
                    
                    if !name.isEmpty {
                        let changeRequest = user.createProfileChangeRequest()
                        changeRequest.displayName = name
                        changeRequest.commitChanges()
                    }
                }
                completion(.success(()))
            }
        }
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
        errorMessage = nil
        
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
        errorMessage = nil
        
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
        errorMessage = nil
        
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
        errorMessage = nil
    }
    
    // MARK: - Apple Sign-In Delegates

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
    @objc func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("🍎 Authorization controller completed successfully.")
        
        handleAppleSignIn(authorization: authorization, profileData: self.pendingProfileData) { result in
            // Use the original completion handler to signal success or failure
            self.handleSignInCompletion(result: result)
        }
    }
    
    @objc func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Authorization controller failed with error: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            // Clear temporary data
            self.currentNonce = nil
            self.authorizationController = nil
            
            // Call completion handler with error
            self.appleSignInCompletion?(.failure(error))
            self.appleSignInCompletion = nil
        }
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the main window for presentation
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available for Apple Sign-In presentation")
        }
        return window
    }
} 
