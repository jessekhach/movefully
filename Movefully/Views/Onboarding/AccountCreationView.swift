import SwiftUI
import AuthenticationServices

struct AccountCreationView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var coordinator: OnboardingCoordinator
    
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                
                Text("Create Your Account")
                    .font(MovefullyTheme.Typography.title1)
                    .padding(.vertical, MovefullyTheme.Layout.paddingL)
                
                if authViewModel.isSimulator {
                    MovefullyAlert(
                        message: "Apple Sign-In has limited support on the simulator. Email is recommended for testing.",
                        type: .warning
                    )
                }
                
                // Email/Password form
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
                    MovefullyAlert(message: authViewModel.errorMessage, type: .error)
                        .padding(.top)
                }

                Spacer()
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
        }
        .background(MovefullyTheme.Colors.backgroundPrimary.ignoresSafeArea())
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Action Button
                    Button(action: {
                        authViewModel.signUp(
                            email: email,
                            password: password,
                            fullName: fullName,
                            profileData: coordinator.getProfileForCreation()
                        ) { result in
                            switch result {
                            case .success:
                                coordinator.nextStep()
                            case .failure(let error):
                                authViewModel.errorMessage = error.localizedDescription
                            }
                        }
                    }) {
                        Text("Create Account & Continue")
                    }
                    .buttonStyle(MovefullyPrimaryButtonStyle())
                    .disabled(email.isEmpty || password.count < 8 || fullName.isEmpty)
                    
                    // Social Sign-in
                    Button(action: {
                        authViewModel.signInWithApple(profileData: coordinator.getProfileForCreation()) { result in
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
                    }) {
                        HStack {
                            Image(systemName: "apple.logo")
                            Text("Continue with Apple")
                        }
                    }
                    .buttonStyle(MovefullySecondaryButtonStyle())
                }
                .padding()
            }
        }
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
}

#Preview {
    NavigationView {
        AccountCreationView()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(OnboardingCoordinator())
    }
} 