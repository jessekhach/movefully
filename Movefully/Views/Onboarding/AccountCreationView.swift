import SwiftUI
import AuthenticationServices

struct AccountCreationView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var coordinator: OnboardingCoordinator
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            Spacer()
            
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 50))
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                .padding(.bottom, MovefullyTheme.Layout.paddingL)

            Text("Begin Your Journey")
                .font(MovefullyTheme.Typography.title1)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                .padding(.bottom, MovefullyTheme.Layout.paddingS)

            Text("Create your account securely with Apple. We're here to support your wellness journey with gentle, mindful movement.")
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
            
            Spacer()

            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    // You can add scopes here if needed, e.g., for full name or email
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        authViewModel.handleAppleSignIn(authorization: authorization, profileData: coordinator.getProfileForCreation()) { authResult in
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
}

#if DEBUG
struct AccountCreationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountCreationView()
                .environmentObject(AuthenticationViewModel())
                .environmentObject(OnboardingCoordinator())
        }
    }
}
#endif