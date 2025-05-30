import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

class AuthenticationViewModel: ObservableObject {
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
    
    init() {
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
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
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
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    let data = document.data()
                    self?.userRole = data?["role"] as? String
                    self?.userName = data?["name"] as? String ?? ""
                } else {
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
}

// MARK: - Apple Sign-In Delegates

extension AuthenticationViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { [weak self] result, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let user = result?.user else { return }
                    
                    // Set user info from Apple ID credential
                    if let fullName = appleIDCredential.fullName {
                        let displayName = [fullName.givenName, fullName.familyName]
                            .compactMap { $0 }
                            .joined(separator: " ")
                        
                        if !displayName.isEmpty {
                            self?.userName = displayName
                            
                            // Update Firebase user profile
                            let changeRequest = user.createProfileChangeRequest()
                            changeRequest.displayName = displayName
                            changeRequest.commitChanges { error in
                                if let error = error {
                                    print("Error updating display name: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                    
                    if let email = appleIDCredential.email {
                        self?.userEmail = email
                    } else {
                        self?.userEmail = user.email ?? ""
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
        }
    }
}

extension AuthenticationViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
} 