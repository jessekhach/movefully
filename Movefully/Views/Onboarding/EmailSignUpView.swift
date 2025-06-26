import SwiftUI
import FirebaseAuth

struct EmailSignUpView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @StateObject private var bootstrapService: UserBootstrapService
    @EnvironmentObject var urlHandler: URLHandlingService
    @StateObject private var invitationService = InvitationService()
    @State private var showBootstrapLoading = false
    
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    
    init() {
        // We'll initialize this properly in onAppear since we need access to authViewModel
        _bootstrapService = StateObject(wrappedValue: UserBootstrapService(authViewModel: AuthenticationViewModel()))
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Text("Create with Email")
                        .font(MovefullyTheme.Typography.title1)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        .padding(.top, MovefullyTheme.Layout.paddingL)

                    Text("We'll create your account and get you started.")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, MovefullyTheme.Layout.paddingL)
                    
                    MovefullyTextField(
                        placeholder: "Full Name",
                        text: $fullName,
                        icon: "person.fill"
                    )
                    
                    MovefullyTextField(
                        placeholder: "Email",
                        text: $email,
                        icon: "envelope.fill",
                        keyboardType: .emailAddress
                    )
                    
                    MovefullySecureField(
                        placeholder: "Password (8+ characters)",
                        text: $password,
                        icon: "lock.fill"
                    )
                    
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
                Button(action: handleEmailSignUp) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Account & Continue")
                    }
                }
                .buttonStyle(MovefullyPrimaryButtonStyle())
                .disabled(!isFormValid() || authViewModel.isLoading)
                .padding()
            }
        }
        .onAppear {
            // Initialize bootstrap service with actual authViewModel
            bootstrapService.authViewModel = authViewModel
            prefillName()
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
    
    private func isFormValid() -> Bool {
        return !fullName.isEmpty && !email.isEmpty && password.count >= 8
    }
    
    private func prefillName() {
        if let trainerData = coordinator.getStoredTrainerData() {
            self.fullName = trainerData.name
        } else if let clientData = coordinator.getStoredClientData() {
            self.fullName = clientData.name
        } else if !coordinator.tempTrainerName.isEmpty {
            self.fullName = coordinator.tempTrainerName
        } else if !coordinator.tempClientName.isEmpty {
            self.fullName = coordinator.tempClientName
        }
        authViewModel.errorMessage = nil
    }
    
    private func handleEmailSignUp() {
        showBootstrapLoading = true
        
        // Debug logging
        print("🎯 EmailSignUpView: Starting email signup process")
        print("🎯 EmailSignUpView: Checking for pending invitation...")
        print("🎯 EmailSignUpView: urlHandler.pendingInvitationId = \(urlHandler.pendingInvitationId ?? "nil")")
        
        // Check if there's a pending invitation
        if let invitationId = urlHandler.pendingInvitationId {
            print("🎯 EmailSignUpView: Detected pending invitation during email signup")
            handleInvitationSignUp(invitationId: invitationId)
        } else {
            print("🎯 EmailSignUpView: No pending invitation found, proceeding with normal signup")
            // Normal sign up flow
            handleNormalSignUp()
        }
    }
    
    private func handleInvitationSignUp(invitationId: String) {
        let profileData = coordinator.getProfileForCreation()
        authViewModel.signUp(
            email: email,
            password: password,
            fullName: fullName,
            profileData: profileData
        ) { result in
            switch result {
            case .success:
                // Authentication successful, now accept the invitation
                Task {
                    await self.acceptInvitationAfterAuth(invitationId: invitationId)
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.showBootstrapLoading = false
                    print("❌ Email Sign Up failed: \(error)")
                    // Error is already handled by the authViewModel's errorMessage property
                }
            }
        }
    }
    
    private func handleNormalSignUp() {
        let profileData = coordinator.getProfileForCreation()
        authViewModel.signUp(
            email: email,
            password: password,
            fullName: fullName,
            profileData: profileData
        ) { result in
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
                    print("❌ Email Sign Up failed: \(error)")
                    // Error is already handled by the authViewModel's errorMessage property
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
            
            // Since user is already authenticated via email sign up, we need to create the client document directly
            let client = Client(
                id: currentUser.uid,
                name: fullName.isEmpty ? (invitation.clientName ?? "Client") : fullName,
                email: currentUser.email ?? invitation.clientEmail,
                trainerId: invitation.trainerId,
                status: .active
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

#if DEBUG
struct EmailSignUpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EmailSignUpView()
                .environmentObject(AuthenticationViewModel())
                .environmentObject(OnboardingCoordinator())
        }
    }
}
#endif 