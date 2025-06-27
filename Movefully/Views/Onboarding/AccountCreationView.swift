import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct AccountCreationView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @EnvironmentObject var urlHandler: URLHandlingService
    @StateObject private var bootstrapService: UserBootstrapService
    @StateObject private var invitationService = InvitationService()
    @State private var showBootstrapLoading = false
    
    init() {
        // We'll initialize this properly in onAppear since we need access to authViewModel
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

                Text("Begin Your Journey")
                    .font(MovefullyTheme.Typography.title1)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .padding(.bottom, MovefullyTheme.Layout.paddingS)
                
                Text("Create your account to start your personalized wellness journey")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, MovefullyTheme.Layout.paddingL)
                
                // Apple Sign Up Button
                SignInWithAppleButton(.signUp,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            print("✅ Apple Sign Up successful")
                            handleAppleSignUp(authorization)
                        case .failure(let error):
                            print("❌ Apple Sign Up failed: \(error)")
                            authViewModel.errorMessage = "Sign up failed. Please try again."
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 44)
                .cornerRadius(MovefullyTheme.Layout.cornerRadiusM)
                
                Spacer()
                
                // Discreet email sign up link
                Button("Or sign up with email") {
                    coordinator.goToEmailSignUp()
                }
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
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
            // Initialize bootstrap service with actual authViewModel
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
    
    private func handleAppleSignUp(_ authorization: ASAuthorization) {
        showBootstrapLoading = true
        
        // Check if there's a pending invitation
        if let invitationId = urlHandler.pendingInvitationId {
            print("🎯 AccountCreationView: Detected pending invitation during Apple Sign Up")
            handleInvitationSignUp(authorization, invitationId: invitationId)
        } else {
            // Normal sign up flow
            handleNormalSignUp(authorization)
        }
    }
    
    private func handleInvitationSignUp(_ authorization: ASAuthorization, invitationId: String) {
        // Use the existing method that takes ASAuthorization
        authViewModel.handleAppleSignInResult(authorization: authorization, profileData: coordinator.getProfileForCreation()) { result in
            switch result {
            case .success:
                // Authentication successful, now accept the invitation
                Task {
                    await self.acceptInvitationAfterAuth(invitationId: invitationId)
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.showBootstrapLoading = false
                    print("❌ Apple Sign Up failed: \(error)")
                    self.authViewModel.errorMessage = "Sign up failed. Please try again."
                }
            }
        }
    }
    
    private func handleNormalSignUp(_ authorization: ASAuthorization) {
        // Use the existing method that takes ASAuthorization
        authViewModel.handleAppleSignInResult(authorization: authorization, profileData: coordinator.getProfileForCreation()) { result in
            switch result {
            case .success:
                // Authentication successful, now start bootstrap
                DispatchQueue.main.async {
                    let role = self.coordinator.selectedRole ?? .client
                    self.bootstrapService.bootstrap(context: .signUp(role: role.rawValue)) { bootstrapResult in
                        DispatchQueue.main.async {
                            self.showBootstrapLoading = false
                            
                            switch bootstrapResult {
                            case .success():
                                print("✅ Bootstrap completed successfully")
                                // Mark onboarding as complete so ContentView can navigate
                                self.authViewModel.completeOnboarding()
                                
                            case .failure(let error):
                                print("❌ Bootstrap failed: \(error)")
                                self.authViewModel.errorMessage = "Setup failed. Please try again."
                                self.authViewModel.completeOnboarding() // Clear flag even on failure
                            }
                        }
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.showBootstrapLoading = false
                    print("❌ Apple Sign Up failed: \(error)")
                    self.authViewModel.errorMessage = "Sign up failed. Please try again."
                }
            }
        }
    }
    
    @MainActor
    private func acceptInvitationAfterAuth(invitationId: String) async {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ No current user after authentication")
            showBootstrapLoading = false
            authViewModel.errorMessage = "Authentication failed. Please try again."
            return
        }
        
        do {
            // Get the invitation to validate it first
            let invitation = try await invitationService.validateInvitation(invitationId: invitationId)
            
            // Since user is already authenticated via Apple Sign In, we need to create the client document directly
            // We'll create a modified version that doesn't try to create a new auth account
            let client = Client(
                id: currentUser.uid,
                name: currentUser.displayName ?? invitation.clientName ?? "Client",
                email: currentUser.email ?? invitation.clientEmail,
                trainerId: invitation.trainerId,
                status: .active,
                joinedDate: Date()
            )
            
            // Save client and mark invitation as accepted
            try await invitationService.saveClientDirectly(client)
            try await invitationService.markInvitationAsAcceptedDirectly(invitationId: invitationId, clientId: currentUser.uid)
            
            print("✅ Invitation accepted successfully for authenticated user")
            
            // Clear the invitation state
            urlHandler.clearPendingInvitation()
            
            // Refresh user data and complete onboarding
            authViewModel.checkAuthenticationState()
            authViewModel.completeOnboarding()
            showBootstrapLoading = false
            
        } catch {
            print("❌ Invitation acceptance failed: \(error)")
            showBootstrapLoading = false
            authViewModel.errorMessage = "Failed to connect with trainer. Please try again."
        }
    }
}

#Preview {
    AccountCreationView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(OnboardingCoordinator())
}