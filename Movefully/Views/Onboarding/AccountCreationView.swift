import SwiftUI
import AuthenticationServices

struct AccountCreationView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var coordinator: OnboardingCoordinator
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            Spacer()

            Text("Create Your Account")
                .font(MovefullyTheme.Typography.title1)
                .padding(.bottom, MovefullyTheme.Layout.paddingS)

            Text("Create your account securely with Apple. We won't see your password and it's easier to get started.")
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
            
            Spacer()

            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    // No customization needed for request
                },
                onCompletion: { result in
                    handleAppleSignIn(result: result)
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: MovefullyTheme.Layout.buttonHeightM)
            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)

            Spacer()
            Spacer()
        }
        .background(MovefullyTheme.Colors.backgroundPrimary.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button(action: {
                    coordinator.previousStep()
                }) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                NavigationLink(destination: EmailSignUpView()) {
                    Text("Or continue with Email")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            let profileData = coordinator.getProfileForCreation()
            authViewModel.handleAppleSignIn(authorization: authorization, profileData: profileData) { authResult in
                switch authResult {
                case .success:
                    coordinator.nextStep()
                case .failure(let error):
                    if (error as? ASAuthorizationError)?.code != .canceled {
                        authViewModel.errorMessage = error.localizedDescription
                    }
                }
            }
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
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