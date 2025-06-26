import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @StateObject private var bootstrapService: UserBootstrapService
    @State private var showBootstrapLoading = false
    
    init() {
        _bootstrapService = StateObject(wrappedValue: UserBootstrapService(authViewModel: AuthenticationViewModel()))
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                Spacer()
                
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 50))
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    .padding(.bottom, MovefullyTheme.Layout.paddingL)

                Text("Welcome Back")
                    .font(MovefullyTheme.Typography.title1)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .padding(.bottom, MovefullyTheme.Layout.paddingS)
                
                Text("Continue your wellness journey")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, MovefullyTheme.Layout.paddingL)
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Apple Sign In Button
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                print("✅ Apple Sign In successful")
                                handleAppleSignIn(authorization)
                            case .failure(let error):
                                print("❌ Apple Sign In failed: \(error)")
                                authViewModel.errorMessage = "Sign in failed. Please try again."
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 44)
                    .cornerRadius(MovefullyTheme.Layout.cornerRadiusM)
                    
                    Text("or")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    // Email Sign In Button
                    Button(action: {
                        coordinator.goToEmailSignIn()
                    }) {
                        Text("Sign In with Email")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    }
                    .buttonStyle(MovefullyPrimaryButtonStyle())
                }
                
                Spacer()
            }
            .padding(MovefullyTheme.Layout.paddingL)
            .opacity(showBootstrapLoading ? 0.3 : 1.0)
            .blur(radius: showBootstrapLoading ? 3 : 0)
            .animation(.easeInOut(duration: 0.3), value: showBootstrapLoading)
            
            // Bootstrap Loading Overlay
            if showBootstrapLoading {
                MovefullyBootstrapLoadingView(bootstrapService: bootstrapService)
                    .transition(.opacity.combined(with: .scale))
            }
        }
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
        }
        .onAppear {
            bootstrapService.authViewModel = authViewModel
        }
        .alert("Error", isPresented: .constant(authViewModel.errorMessage != nil)) {
            Button("OK") {
                authViewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func handleAppleSignIn(_ authorization: ASAuthorization) {
        print("🔍 SignInView: handleAppleSignIn called")
        showBootstrapLoading = true
        
        authViewModel.handleAppleSignInResult(authorization: authorization, profileData: nil) { result in
            print("🔍 SignInView: Apple Sign-In result received: \(result)")
            switch result {
            case .success:
                DispatchQueue.main.async {
                    print("🔍 SignInView: Apple Sign-In successful, waiting for user data to load...")
                    self.waitForUserDataThenBootstrap()
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.showBootstrapLoading = false
                    print("❌ SignInView: Apple Sign In failed: \(error)")
                    self.authViewModel.errorMessage = "Sign in failed. Please try again."
                }
            }
        }
    }
    
    private func waitForUserDataThenBootstrap() {
        print("🔍 SignInView: Waiting for userRole to be set...")
        
        // Check if user data is already loaded
        if authViewModel.userRole != nil {
            print("🔍 SignInView: User data already loaded, starting bootstrap immediately")
            runBootstrap()
            return
        }
        
        // Otherwise, wait for user data to load with a timeout
        var checkCount = 0
        let maxChecks = 20 // 10 seconds maximum (500ms * 20)
        
        func checkUserData() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                checkCount += 1
                print("🔍 SignInView: Check \(checkCount)/\(maxChecks) - userRole: \(self.authViewModel.userRole ?? "nil")")
                
                if let userRole = self.authViewModel.userRole {
                    print("🔍 SignInView: User data loaded (role: \(userRole)), starting bootstrap")
                    self.runBootstrap()
                } else if checkCount >= maxChecks {
                    print("❌ SignInView: Timeout waiting for user data, bootstrap failed")
                    self.showBootstrapLoading = false
                    self.authViewModel.errorMessage = "Sign in failed. Please try again."
                } else {
                    checkUserData()
                }
            }
        }
        
        checkUserData()
    }
    
    private func runBootstrap() {
        print("🔍 SignInView: Starting bootstrap with user data loaded")
        bootstrapService.bootstrap(context: .signIn) { bootstrapResult in
            DispatchQueue.main.async {
                self.showBootstrapLoading = false
                print("🔍 SignInView: Bootstrap completed with result: \(bootstrapResult)")
                
                switch bootstrapResult {
                case .success():
                    print("✅ SignInView: Bootstrap completed successfully")
                    // Clear onboarding state to allow navigation to main app
                    self.authViewModel.isOnboardingInProgress = false
                    print("🔍 SignInView: Cleared isOnboardingInProgress - navigation should proceed")
                    
                case .failure(let error):
                    print("❌ SignInView: Bootstrap failed: \(error)")
                    self.authViewModel.isOnboardingInProgress = false
                    self.authViewModel.errorMessage = "Sign in failed. Please try again."
                }
            }
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(OnboardingCoordinator())
} 