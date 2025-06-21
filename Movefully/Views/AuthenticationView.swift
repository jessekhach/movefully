import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Welcome Back")
                .font(MovefullyTheme.Typography.title1)
            
            Text("Sign in to continue your journey.")
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)

            Spacer()
            
            // Apple Sign-In
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        authViewModel.handleAppleSignIn(authorization: authorization, profileData: nil) { authResult in
                            // The auth view model will handle navigation state
                        }
                    case .failure(let error):
                        if (error as? ASAuthorizationError)?.code != .canceled {
                            authViewModel.errorMessage = error.localizedDescription
                        }
                    }
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal)
            
            // Email/Password fields
            MovefullyTextField(
                placeholder: "Email",
                text: $email,
                icon: "envelope.fill"
            )
            .padding(.horizontal)
            
            MovefullySecureField(
                placeholder: "Password",
                text: $password,
                icon: "lock.fill"
            )
            .padding(.horizontal)
            
            if let errorMessage = authViewModel.errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(MovefullyTheme.Colors.warmOrange)
                    .font(MovefullyTheme.Typography.caption)
                    .padding()
            }
            
            Button(action: {
                authViewModel.signIn(email: email, password: password)
            }) {
                Text("Sign In")
            }
            .buttonStyle(MovefullyPrimaryButtonStyle())
            .padding()
            
            Spacer()
        }
        .background(MovefullyTheme.Colors.backgroundPrimary.ignoresSafeArea())
    }
}

#if DEBUG
struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
            .environmentObject(AuthenticationViewModel())
    }
}
#endif 