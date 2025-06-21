import SwiftUI
import AuthenticationServices

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
            // Pre-fill name from the profile setup step
            if !coordinator.tempTrainerName.isEmpty {
                self.fullName = coordinator.tempTrainerName
            } else if !coordinator.tempClientName.isEmpty {
                self.fullName = coordinator.tempClientName
            }
            // Clear any previous error messages
            authViewModel.errorMessage = ""
        }
    }
    
    private var appleSignInPrompt: some View {
        VStack {
            Spacer()
            
            Text("Create Your Account")
                .font(MovefullyTheme.Typography.title1)
                .padding(.bottom, MovefullyTheme.Layout.paddingM)

            Text("Create your account securely with Apple. We won't see your password and it's easier to get started.")
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
            
            Spacer()

            Button("Or continue with Email") {
                showEmailSignUp = true
            }
            .font(MovefullyTheme.Typography.body)
            .foregroundColor(MovefullyTheme.Colors.textSecondary)
            .padding(.bottom, MovefullyTheme.Layout.paddingM)
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: handleAppleSignIn) {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Continue with Apple")
                    }
                }
                .buttonStyle(MovefullyPrimaryButtonStyle())
                .padding(.bottom, MovefullyTheme.Layout.paddingM)
            }
        }
    }
    
    private var emailSignUpForm: some View {
        ScrollView {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                
                Text("Create with Email")
                    .font(MovefullyTheme.Typography.title1)
                    .padding(.top, MovefullyTheme.Layout.paddingXL)
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
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button(action: { showEmailSignUp = false }) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            }

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
    
    private func handleAppleSignIn() {
        let profileData = coordinator.getProfileForCreation()
        authViewModel.signInWithApple(profileData: profileData) { result in
            switch result {
            case .success:
                coordinator.nextStep()
            case .failure(let error):
                // Don't show "cancelled" errors
                if (error as? ASAuthorizationError)?.code != .canceled {
                    authViewModel.errorMessage = error.localizedDescription
                }
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
}

#Preview {
    NavigationView {
        AccountCreationView()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(OnboardingCoordinator())
    }
} 