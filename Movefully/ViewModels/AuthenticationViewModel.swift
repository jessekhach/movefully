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
    @Published var isOnboardingInProgress: Bool = false
    
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
                print("🔍 AuthVM: Auth state changed - user: \(user?.uid ?? "nil")")
                print("🔍 AuthVM: Previous isAuthenticated: \(self?.isAuthenticated ?? false)")
                print("🔍 AuthVM: Previous isOnboardingInProgress: \(self?.isOnboardingInProgress ?? false)")
                
                self?.isAuthenticated = user != nil
                
                print("🔍 AuthVM: New isAuthenticated: \(self?.isAuthenticated ?? false)")
                
                if let user = user {
                    self?.userEmail = user.email ?? ""
                    print("🔍 AuthVM: Calling fetchUserDataWithRetry for user: \(user.uid)")
                    self?.fetchUserDataWithRetry(userId: user.uid)
                } else {
                    print("🔍 AuthVM: No user - calling clearUserData()")
                    self?.clearUserData()
                }
            }
        }
    }
    
    func checkAuthenticationState() {
        if let user = Auth.auth().currentUser {
            isAuthenticated = true
            userEmail = user.email ?? ""
            fetchUserDataWithRetry(userId: user.uid)
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
    
    func handleAppleSignInResult(authorization: ASAuthorization, profileData: Any?, completion: @escaping (Result<Void, Error>) -> Void) {
        // Generate a new nonce for this request
        let nonce = randomNonceString()
        currentNonce = nonce
        
        // Now call the existing handler
        handleAppleSignIn(authorization: authorization, profileData: profileData, completion: completion)
    }
    
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
        
        print("🔍 AuthVM: Starting Apple Sign-In with Firebase")
        print("🔍 AuthVM: Setting isOnboardingInProgress to true")
        
        self.isLoading = true
        self.isOnboardingInProgress = true
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("❌ Firebase auth error: \(error.localizedDescription)")
                    self?.isOnboardingInProgress = false // Clear flag on error
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
                    
                    Task {
                        do {
                            try await self.createUserProfile(uid: user.uid, name: name, email: email, role: role, profileData: profileData)
                            if !name.isEmpty {
                                let changeRequest = user.createProfileChangeRequest()
                                changeRequest.displayName = name
                                try? await changeRequest.commitChanges()
                            }
                            completion(.success(()))
                        } catch {
                            print("❌ Error creating user profile: \(error.localizedDescription)")
                            completion(.failure(error))
                        }
                    }
                } else {
                    // Add a small delay to ensure auth state is fully settled before proceeding
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    // MARK: - User Profile Creation
    
    private func createUserProfile(uid: String, name: String, email: String, role: String, profileData: Any?) async throws {
        let userRef = db.collection("users").document(uid)
        
        // 1. Create the main user document with profile data
        var userData: [String: Any] = [
            "name": name,
            "email": email,
            "role": role,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp()
        ]
        
        // Add additional profile data to users collection for consistency
        if let trainerData = profileData as? TrainerProfileData {
            if !trainerData.title.isEmpty {
                userData["title"] = trainerData.title
            }
            userData["specialties"] = trainerData.specialties
            userData["yearsOfExperience"] = trainerData.yearsOfExperience
            if let bio = trainerData.bio, !bio.isEmpty {
                userData["bio"] = bio
            }
            if let location = trainerData.location, !location.isEmpty {
                userData["location"] = location
            }
            if let phoneNumber = trainerData.phoneNumber, !phoneNumber.isEmpty {
                userData["phoneNumber"] = phoneNumber
            }
            if let website = trainerData.website, !website.isEmpty {
                userData["website"] = website
            }
        }
        
        do {
            try await userRef.setData(userData)
            print("✅ User document created for \(uid)")
        } catch {
            print("❌ Error creating user document: \(error.localizedDescription)")
            throw NSError(domain: "AuthenticationError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Could not save user data: \(error.localizedDescription)"])
        }
        
        // 2. Create the role-specific profile document
        do {
            if let trainerData = profileData as? TrainerProfileData {
                let trainerRef = db.collection("trainers").document(uid)
                var trainerProfile: [String: Any] = [
                    "name": trainerData.name,
                    "email": email,
                    "specialties": trainerData.specialties,
                    "yearsOfExperience": trainerData.yearsOfExperience,
                    "createdAt": Timestamp(),
                    "updatedAt": Timestamp()
                ]
                
                // Add optional fields only if they have values
                if !trainerData.title.isEmpty {
                    trainerProfile["title"] = trainerData.title
                }
                if let bio = trainerData.bio, !bio.isEmpty {
                    trainerProfile["bio"] = bio
                }
                if let location = trainerData.location, !location.isEmpty {
                    trainerProfile["location"] = location
                }
                if let phoneNumber = trainerData.phoneNumber, !phoneNumber.isEmpty {
                    trainerProfile["phoneNumber"] = phoneNumber
                }
                if let website = trainerData.website, !website.isEmpty {
                    trainerProfile["website"] = website
                }
                
                try await trainerRef.setData(trainerProfile)
                print("✅ Trainer profile created for \(uid) with fields: \(trainerProfile.keys)")
            } else if let clientData = profileData as? ClientProfileData {
                let clientRef = db.collection("clients").document(uid)
                let clientProfile: [String: Any] = [
                    "name": clientData.name,
                    "fitnessLevel": clientData.fitnessLevel,
                    "goals": clientData.goals,
                    "email": email
                ]
                try await clientRef.setData(clientProfile)
                print("✅ Client profile created for \(uid)")
            }
        } catch {
            print("❌ Error creating role-specific profile: \(error.localizedDescription)")
            // Don't throw here - the main user document was created successfully
            // Just log the error for role-specific profile creation
            print("⚠️ Role-specific profile creation failed, but user document exists")
        }
    }
    
    // MARK: - Email/Password Authentication
    
    func signUp(email: String, password: String, fullName: String, profileData: Any?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !email.isEmpty, !password.isEmpty, !fullName.isEmpty else {
            let error = NSError(domain: "AuthenticationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please fill in all fields."])
            completion(.failure(error))
            return
        }
        
        print("🔐 Starting signup process for: \(email)")
        print("🔐 Password length: \(password.count)")
        print("🔐 Full name: \(fullName)")
        print("🔐 Profile data type: \(type(of: profileData))")
        
        isLoading = true
        errorMessage = nil
        isOnboardingInProgress = true
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Firebase auth error: \(error.localizedDescription)")
                    print("❌ Firebase auth error code: \((error as NSError).code)")
                    print("❌ Firebase auth error domain: \((error as NSError).domain)")
                    print("❌ Firebase auth error userInfo: \((error as NSError).userInfo)")
                    
                    // Provide user-friendly error messages
                    let userFriendlyError: Error
                    let errorCode = (error as NSError).code
                    
                    switch errorCode {
                    case 17007: // ERROR_EMAIL_ALREADY_IN_USE
                        userFriendlyError = NSError(domain: "AuthenticationError", code: -1, 
                            userInfo: [NSLocalizedDescriptionKey: "This email is already registered. Please sign in instead or use a different email address."])
                    case 17026: // ERROR_WEAK_PASSWORD
                        userFriendlyError = NSError(domain: "AuthenticationError", code: -1, 
                            userInfo: [NSLocalizedDescriptionKey: "Password is too weak. Please choose a stronger password with at least 8 characters."])
                    case 17008: // ERROR_INVALID_EMAIL
                        userFriendlyError = NSError(domain: "AuthenticationError", code: -1, 
                            userInfo: [NSLocalizedDescriptionKey: "Please enter a valid email address."])
                    case 17999: // ERROR_INTERNAL_ERROR
                        if let userInfo = (error as NSError).userInfo["FIRAuthErrorUserInfoDeserializedResponseKey"] as? [String: Any],
                           let message = userInfo["message"] as? String,
                           message.contains("PASSWORD_DOES_NOT_MEET_REQUIREMENTS") {
                            userFriendlyError = NSError(domain: "AuthenticationError", code: -1, 
                                userInfo: [NSLocalizedDescriptionKey: "Password must be at least 8 characters long"])
                        } else {
                            userFriendlyError = error
                        }
                    default:
                        userFriendlyError = error
                    }
                    
                    self?.errorMessage = userFriendlyError.localizedDescription
                    self?.isOnboardingInProgress = false // Clear flag on error
                    completion(.failure(userFriendlyError))
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
                Task {
                    do {
                        try await self.createUserProfile(uid: user.uid, name: fullName, email: email, role: role, profileData: profileData)
                        
                        // Update Firebase Auth display name
                        let changeRequest = user.createProfileChangeRequest()
                        changeRequest.displayName = fullName
                        do {
                            try await changeRequest.commitChanges()
                        } catch {
                            print("⚠️ Error updating display name: \(error.localizedDescription)")
                        }
                        
                        await MainActor.run {
                            self.userName = fullName
                            self.userEmail = email
                        }
                        completion(.success(()))
                    } catch {
                        print("❌ Error creating user profile during sign up: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
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
                    print("❌ Firebase sign in error: \(error.localizedDescription)")
                    print("❌ Firebase sign in error code: \((error as NSError).code)")
                    
                    // Provide user-friendly error messages
                    let errorCode = (error as NSError).code
                    let userFriendlyMessage: String
                    
                    switch errorCode {
                    case 17009: // ERROR_WRONG_PASSWORD
                        userFriendlyMessage = "Incorrect password. Please try again or use 'Forgot Password' to reset."
                    case 17011: // ERROR_USER_NOT_FOUND
                        userFriendlyMessage = "No account found with this email. Please check your email or sign up for a new account."
                    case 17008: // ERROR_INVALID_EMAIL
                        userFriendlyMessage = "Please enter a valid email address."
                    case 17010: // ERROR_USER_DISABLED
                        userFriendlyMessage = "This account has been disabled. Please contact support."
                    case 17020: // ERROR_NETWORK_ERROR
                        userFriendlyMessage = "Network error. Please check your connection and try again."
                    case 17999: // ERROR_TOO_MANY_REQUESTS
                        userFriendlyMessage = "Too many failed attempts. Please try again later."
                    default:
                        userFriendlyMessage = error.localizedDescription
                    }
                    
                    self?.errorMessage = userFriendlyMessage
                    return
                }
            }
        }
    }
    
    func sendPasswordReset(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !email.isEmpty else {
            let error = NSError(domain: "AuthenticationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please enter your email address."])
            completion(.failure(error))
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Firebase password reset error: \(error.localizedDescription)")
                    print("❌ Firebase password reset error code: \((error as NSError).code)")
                    
                    // Provide user-friendly error messages
                    let errorCode = (error as NSError).code
                    let userFriendlyMessage: String
                    
                    switch errorCode {
                    case 17011: // ERROR_USER_NOT_FOUND
                        userFriendlyMessage = "No account found with this email address."
                    case 17008: // ERROR_INVALID_EMAIL
                        userFriendlyMessage = "Please enter a valid email address."
                    case 17020: // ERROR_NETWORK_ERROR
                        userFriendlyMessage = "Network error. Please check your connection and try again."
                    default:
                        userFriendlyMessage = error.localizedDescription
                    }
                    
                    let userFriendlyError = NSError(domain: "AuthenticationError", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: userFriendlyMessage])
                    
                    self?.errorMessage = userFriendlyMessage
                    completion(.failure(userFriendlyError))
                    return
                }
                
                completion(.success(()))
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
    
    // MARK: - Deprecated Methods (Should not be used in production)
    // This method exists only for emergency fallback scenarios
    // In a properly functioning app, roles should only be set during onboarding
    private func selectRole(_ role: String) {
        guard let user = Auth.auth().currentUser else { return }
        
        print("⚠️ WARNING: selectRole called - this indicates a system failure")
        
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
    
    func fetchUserDataWithRetry(userId: String, retryCount: Int = 0) {
        fetchUserData(userId: userId) { [weak self] success in
            if !success && retryCount < 3 {
                // Retry with increasing delays to allow for token propagation
                let delay = retryCount == 0 ? 1.0 : (retryCount == 1 ? 2.0 : 3.0)
                print("🔄 Retrying user data fetch (attempt \(retryCount + 1)) after \(delay)s delay...")
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self?.fetchUserDataWithRetry(userId: userId, retryCount: retryCount + 1)
                }
            } else if !success && retryCount >= 3 {
                // After 4 attempts (0, 1, 2, 3), the user document doesn't exist
                // This indicates an orphaned Firebase Auth account (user deleted from Firestore but not Auth)
                print("🚨 Orphaned account detected - user exists in Auth but not in Firestore")
                self?.handleOrphanedAccount()
            }
        }
    }
    
    private func fetchUserData(userId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        print("📊 Fetching user data for: \(userId)")
        
        // Check if this is right after authentication (token might not be propagated yet)
        let isRecentAuth = Date().timeIntervalSince(Auth.auth().currentUser?.metadata.lastSignInDate ?? Date.distantPast) < 5.0
        
        if isRecentAuth {
            print("🔄 Recent authentication detected - waiting for token propagation...")
            // Add a short delay to allow Firebase Auth token to propagate to Firestore
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.performUserDataFetch(userId: userId, completion: completion)
            }
        } else {
            performUserDataFetch(userId: userId, completion: completion)
        }
    }
    
    private func performUserDataFetch(userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("📊 Error fetching user data: \(error.localizedDescription)")
                    // Check if it's a permissions error (token not propagated yet)
                    if (error as NSError).code == 7 { // PERMISSION_DENIED
                        print("🔄 Permission denied - token may not be propagated yet")
                        // Don't treat this as a hard failure immediately
                        completion(false)
                        return
                    }
                }
                
                if let document = document, document.exists {
                    let data = document.data()
                    let newRole = data?["role"] as? String
                    let newName = data?["name"] as? String ?? ""
                    
                    print("🔍 AuthVM: Setting userRole from \(self?.userRole ?? "nil") to \(newRole ?? "nil")")
                    print("🔍 AuthVM: Setting userName from \(self?.userName ?? "") to \(newName)")
                    
                    self?.userRole = newRole
                    self?.userName = newName
                    print("📊 User data fetched - Role: \(self?.userRole ?? "nil"), Name: \(self?.userName ?? "")")
                    completion(true)
                } else {
                    print("📊 No user data found")
                    print("🔍 AuthVM: Setting userRole to nil")
                    self?.userRole = nil
                    self?.userName = ""
                    completion(false)
                }
            }
        }
    }
    
    private func clearUserData() {
        print("🔍 AuthVM: clearUserData() called")
        print("🔍 AuthVM: Clearing userRole from \(userRole ?? "nil") to nil")
        print("🔍 AuthVM: Clearing isOnboardingInProgress from \(isOnboardingInProgress) to false")
        
        userRole = nil
        userName = ""
        userEmail = ""
        errorMessage = nil
        isOnboardingInProgress = false
    }
    
    func completeOnboarding() {
        isOnboardingInProgress = false
    }
    
    private func handleOrphanedAccount() {
        print("🧹 Cleaning up orphaned account - signing out user")
        
        // Clear any cached data
        clearUserData()
        clearAppCache()
        
        // Sign out from Firebase Auth
        do {
            try Auth.auth().signOut()
            print("✅ Successfully signed out orphaned account")
        } catch {
            print("❌ Error signing out orphaned account: \(error.localizedDescription)")
            // Force clear the auth state even if signOut fails
            Auth.auth().currentUser?.delete { deleteError in
                if let deleteError = deleteError {
                    print("❌ Error deleting orphaned auth user: \(deleteError.localizedDescription)")
                } else {
                    print("✅ Successfully deleted orphaned auth user")
                }
            }
        }
        
        // Show a user-friendly message
        errorMessage = "Your account needs to be set up again. Please sign in to continue."
    }
    
    private func clearAppCache() {
        // Clear UserDefaults cache
        UserDefaults.standard.removeObject(forKey: "lastAppUse")
        
        // Clear cache services that might have stale data
        ProgressDataCacheService.shared.clearCache()
        WorkoutDataCacheService.shared.clearCache()
        
        // Clear any other cached data that might reference the deleted user
        print("🧹 App cache cleared for orphaned account")
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
