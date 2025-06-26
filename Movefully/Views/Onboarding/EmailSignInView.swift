import SwiftUI
import FirebaseAuth

struct EmailSignInView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @StateObject private var bootstrapService: UserBootstrapService
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showForgotPassword = false
    @State private var showBootstrapLoading = false
    
    init() {
        _bootstrapService = StateObject(wrappedValue: UserBootstrapService(authViewModel: AuthenticationViewModel()))
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Text("Sign In")
                        .font(MovefullyTheme.Typography.title1)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        .padding(.top, MovefullyTheme.Layout.paddingL)

                    Text("Welcome back to your wellness journey")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, MovefullyTheme.Layout.paddingL)
                    
                    // Email field
                    MovefullyTextField(
                        placeholder: "Email",
                        text: $email,
                        icon: "envelope",
                        keyboardType: .emailAddress,
                        autocapitalization: .never,
                        disableAutocorrection: true
                    )
                    
                    // Password field
                    HStack {
                        if showPassword {
                            MovefullyTextField(
                                placeholder: "Password",
                                text: $password,
                                icon: "lock"
                            )
                        } else {
                            MovefullySecureField(
                                placeholder: "Password",
                                text: $password,
                                icon: "lock"
                            )
                        }
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .font(.body)
                        }
                        .padding(.trailing, MovefullyTheme.Layout.paddingS)
                    }
                    
                    // Forgot Password Link
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            showForgotPassword = true
                        }
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    }
                    
                    if let errorMessage = authViewModel.errorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(MovefullyTheme.Colors.warmOrange)
                            .font(MovefullyTheme.Typography.caption)
                            .padding(.top)
                    }
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            }
            .background(MovefullyTheme.Colors.backgroundPrimary.ignoresSafeArea())
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
            
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: handleEmailSignIn) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                    }
                }
                .buttonStyle(MovefullyPrimaryButtonStyle())
                .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                .padding()
            }
        }
        .onAppear {
            bootstrapService.authViewModel = authViewModel
        }
        .alert("Forgot Password", isPresented: $showForgotPassword) {
            Button("Cancel", role: .cancel) { }
            Button("Send Reset Email") {
                handleForgotPassword()
            }
        } message: {
            Text("Enter your email address to receive a password reset link.")
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
    
    private func handleEmailSignIn() {
        showBootstrapLoading = true
        
        // Set onboarding flag to prevent ContentView from interfering
        authViewModel.isOnboardingInProgress = true
        
        // Use the existing signIn method
        authViewModel.signIn(email: email, password: password)
        
        // Monitor auth state changes to trigger bootstrap
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.authViewModel.errorMessage == nil && Auth.auth().currentUser != nil {
                // Sign in successful, start bootstrap
                self.bootstrapService.bootstrap(context: .signIn) { result in
                    DispatchQueue.main.async {
                        self.showBootstrapLoading = false
                        
                        switch result {
                        case .success():
                            print("✅ Bootstrap completed successfully")
                            // Clear onboarding state to allow navigation to main app
                            self.authViewModel.isOnboardingInProgress = false
                            
                        case .failure(let error):
                            print("❌ Bootstrap failed: \(error)")
                            self.authViewModel.isOnboardingInProgress = false
                            self.authViewModel.errorMessage = "Sign in failed. Please try again."
                        }
                    }
                }
            } else {
                // Sign in failed
                self.showBootstrapLoading = false
            }
        }
    }
    
    private func handleForgotPassword() {
        guard !email.isEmpty else {
            authViewModel.errorMessage = "Please enter your email address first."
            return
        }
        
        authViewModel.sendPasswordReset(email: email) { result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    self.authViewModel.errorMessage = "Password reset email sent to \(self.email)"
                case .failure(let error):
                    self.authViewModel.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    EmailSignInView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(OnboardingCoordinator())
} 