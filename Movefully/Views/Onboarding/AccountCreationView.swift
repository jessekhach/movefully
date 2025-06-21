import SwiftUI
import AuthenticationServices
import Firebase
import CryptoKit

struct AccountCreationView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var coordinator: OnboardingCoordinator
    
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var showEmailSignUp = false
    
    var body: some View {
        VStack {
            if showEmailSignUp {
                emailSignUpForm
            } else {
                appleSignInPrompt
            }
        }
        .background(MovefullyTheme.Colors.backgroundPrimary.ignoresSafeArea())
        .navigationBarHidden(true)
        .animation(.easeInOut, value: showEmailSignUp)
        .onAppear {
            if !coordinator.tempTrainerName.isEmpty {
                self.fullName = coordinator.tempTrainerName
            } else if !coordinator.tempClientName.isEmpty {
                self.fullName = coordinator.tempClientName
            }
            authViewModel.errorMessage = ""
        }
        .onDisappear {
            authViewModel.detachListener()
        }
    }
    
    @ViewBuilder
    private var appleSignInPrompt: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text("Create Your Account")
                .font(MovefullyTheme.Typography.title1)
                .padding(.bottom, MovefullyTheme.Layout.paddingM)

            Text("Create your account securely with Apple. We won't see your password and it's easier to get started.")
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXL * 2)

            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    let nonce = randomNonceString()
                    coordinator.currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = sha256(nonce)
                },
                onCompletion: handleAppleSignInCompletion
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: MovefullyTheme.Layout.buttonHeightM)
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            
            Spacer()

            Button("Or continue with Email") {
                showEmailSignUp = true
            }
            .font(MovefullyTheme.Typography.body)
            .foregroundColor(MovefullyTheme.Colors.textSecondary)
            .padding(.vertical, MovefullyTheme.Layout.paddingL)
        }
    }
    
    @ViewBuilder
    private var emailSignUpForm: some View {
        VStack {
            HStack {
                Button(action: { showEmailSignUp = false }) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                Spacer()
            }
            .padding()

            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    Text("Create with Email")
                        .font(MovefullyTheme.Typography.title1)
                        .padding(.bottom, MovefullyTheme.Layout.paddingL)
                    
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        MovefullyTextField(
                            placeholder: "Full Name",
                            text: $fullName,
                            icon: "person.fill"
                        )
                        MovefullyTextField(
                            placeholder: "Email",
                            text: $email,
                            icon: "envelope.fill",
                            keyboardType: .emailAddress,
                            autocapitalization: .never,
                            disableAutocorrection: true
                        )
                        MovefullySecureField(
                            placeholder: "Password (8+ characters)",
                            text: $password,
                            icon: "lock.fill"
                        )
                    }
                    
                    if !authViewModel.errorMessage.isEmpty {
                        Text(authViewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: handleEmailSignUp) {
                    Text("Create Account & Continue")
                }
                .buttonStyle(MovefullyPrimaryButtonStyle())
                .disabled(email.isEmpty || password.isEmpty || fullName.isEmpty)
                .padding(.bottom, MovefullyTheme.Layout.paddingM)
            }
        }
    }

    private func handleEmailSignUp() {
        let profileData = coordinator.getProfileForCreation()
        authViewModel.signUp(email: email, password: password, fullName: fullName, profileData: profileData) { result in
            switch result {
            case .success:
                coordinator.nextStep()
            case .failure(let error):
                authViewModel.errorMessage = error.localizedDescription
            }
        }
    }

    private func handleAppleSignInCompletion(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let nonce = coordinator.currentNonce else {
                authViewModel.errorMessage = "An internal error occurred. Please try again."
                return
            }
            let profileData = coordinator.getProfileForCreation()
            
            authViewModel.signInWithApple(credential: authorization, nonce: nonce, profileData: profileData) { result in
                switch result {
                case .success:
                    // Onboarding will continue via the auth state listener
                    break
                case .failure(let error):
                    authViewModel.errorMessage = "Failed to sign in: \(error.localizedDescription)"
                }
            }
            
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                authViewModel.errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Crypto Helpers

private extension AccountCreationView {
    
    func randomNonceString(length: Int = 32) -> String {
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
                    fatalError("Unable to generate random bytes. OSStatus \(errorCode)")
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
    
    @available(iOS 13, *)
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

#Preview {
    NavigationView {
        AccountCreationView()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(OnboardingCoordinator())
    }
} 