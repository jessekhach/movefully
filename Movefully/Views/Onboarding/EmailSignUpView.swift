import SwiftUI

struct EmailSignUpView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var coordinator: OnboardingCoordinator
    
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    
    var body: some View {
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
        .background(MovefullyTheme.Colors.backgroundPrimary.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
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
        EmailSignUpView()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(OnboardingCoordinator())
    }
} 