import SwiftUI
import FirebaseAuth
import AuthenticationServices
import Combine
import Foundation

// MARK: - Invitation Acceptance View
struct InvitationAcceptanceView: View {
    let invitationId: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var urlHandler: URLHandlingService
    @StateObject private var invitationService = InvitationService()
    @StateObject private var authViewModel = AuthenticationViewModel()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var invitation: ClientInvitation?
    @State private var acceptanceComplete = false
    @State private var showManualEntry = false
    @State private var authCancellable: AnyCancellable?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    LoadingStateView()
                        .onAppear {
                            print("🎯 InvitationAcceptanceView: Showing LoadingStateView")
                        }
                } else if let invitation = invitation {
                    if acceptanceComplete {
                        SuccessStateView(trainerName: invitation.trainerName)
                            .onAppear {
                                print("🎯 InvitationAcceptanceView: Showing SuccessStateView")
                            }
                    } else {
                        AccountCreationForm(invitation: invitation)
                            .onAppear {
                                print("🎯 InvitationAcceptanceView: Showing AccountCreationForm with invitation for trainer: \(invitation.trainerName)")
                            }
                    }
                } else {
                    ErrorStateView()
                        .onAppear {
                            print("🎯 InvitationAcceptanceView: Showing ErrorStateView - no invitation loaded")
                        }
                }
            }
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: handleCancel)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
            .onAppear {
                print("🎯 InvitationAcceptanceView: View appeared. InvitationID: \(invitationId)")
                print("🎯 InvitationAcceptanceView: Current state - isLoading: \(isLoading), invitation: \(invitation?.trainerName ?? "nil"), acceptanceComplete: \(acceptanceComplete)")
                Task {
            await loadInvitation()
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    @ViewBuilder
    private func LoadingStateView() -> some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: MovefullyTheme.Colors.primaryTeal))
                .scaleEffect(1.2)
            
            Text("Loading invitation...")
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func AccountCreationForm(invitation: ClientInvitation) -> some View {
        ScrollView {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                // Header
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                
                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Text("Welcome to Movefully!")
                            .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                        Text("You've been invited by **\(invitation.trainerName)** to join as a client")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
                .padding(.top, MovefullyTheme.Layout.paddingXL)
            
                // Sign-in Options
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Apple Sign-In (Primary Option)
                    if AuthenticationViewModel.isSignInWithAppleAvailable {
                        Button(action: handleAppleSignIn) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "applelogo")
                                        .font(.title2)
                                    Text("Sign in with Apple")
                            .font(MovefullyTheme.Typography.bodyMedium)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.black)
                            .cornerRadius(MovefullyTheme.Layout.cornerRadiusM)
                        }
                        .disabled(isLoading)
                        
                        // Alternative option text
                        VStack(spacing: MovefullyTheme.Layout.paddingS) {
                            HStack {
                                Rectangle()
                                    .fill(MovefullyTheme.Colors.textSecondary.opacity(0.3))
                                    .frame(height: 1)
                        
                                Text("or")
                                    .font(MovefullyTheme.Typography.caption)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                                
                                Rectangle()
                                    .fill(MovefullyTheme.Colors.textSecondary.opacity(0.3))
                                    .frame(height: 1)
                            }
                            
                            Button("Create account with email") {
                                showManualEntry = true
                            }
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        }
                    } else {
                        // Fallback to manual entry if Apple Sign-In not available
                        ManualEntryForm(invitation: invitation)
                    }
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            }
        }
        .sheet(isPresented: $showManualEntry) {
            NavigationStack {
                VStack {
                    ManualEntryForm(invitation: invitation)
                }
                .navigationTitle("Create Account")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showManualEntry = false
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func ManualEntryForm(invitation: ClientInvitation) -> some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                MovefullyTextField(
                    placeholder: invitation.clientEmail,
                    text: .constant(invitation.clientEmail)
                )
                .disabled(true)
                .opacity(0.7)
            }
            
            Button(action: handleManualAcceptInvitation) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(isLoading ? "Creating Account..." : "Accept Invitation")
                        .font(MovefullyTheme.Typography.bodyMedium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(MovefullyTheme.Colors.primaryTeal)
                .foregroundColor(.white)
                .cornerRadius(MovefullyTheme.Layout.cornerRadiusM)
            }
            .disabled(isLoading)
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
    }
    
    @ViewBuilder
    private func SuccessStateView(trainerName: String) -> some View {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                
                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                    Text("Welcome aboard!")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("Your account has been created successfully. You're now connected with **\(trainerName)** and ready to start your fitness journey!")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Button("Get Started") {
                dismiss()
            }
            .font(MovefullyTheme.Typography.bodyMedium)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(MovefullyTheme.Colors.primaryTeal)
            .foregroundColor(.white)
            .cornerRadius(MovefullyTheme.Layout.cornerRadiusM)
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, MovefullyTheme.Layout.paddingXXL)
    }
    
    @ViewBuilder
    private func ErrorStateView() -> some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(MovefullyTheme.Colors.accent)
                
                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                    Text("Invalid Invitation")
                        .font(MovefullyTheme.Typography.title3)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("This invitation link is invalid or has expired. Please contact your trainer for a new invitation.")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Button("Close") {
                handleCancel()
            }
            .font(MovefullyTheme.Typography.bodyMedium)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
                    .background(MovefullyTheme.Colors.textSecondary.opacity(0.1))
            .foregroundColor(MovefullyTheme.Colors.textPrimary)
            .cornerRadius(MovefullyTheme.Layout.cornerRadiusM)
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, MovefullyTheme.Layout.paddingXXL)
        }
    
    // MARK: - Computed Properties
    // Removed form validation since we're using Apple Sign-In
    
    // MARK: - Methods
    
    private func loadInvitation() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let invitation = try await invitationService.getInvitationDetails(invitationId: invitationId)
            await MainActor.run {
                self.invitation = invitation
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    private func handleAppleSignIn() {
                                    guard invitation != nil else { return }
        
        isLoading = true
        urlHandler.isProcessingInvitation = true
        
        print("🍎 Setting up authentication listener for invitation acceptance")
        print("🍎 Current authentication state: \(authViewModel.isAuthenticated)")
        
        // If user is already authenticated, we need a different approach
        if authViewModel.isAuthenticated {
            print("🍎 User already authenticated, will proceed after Apple Sign-In completes")
            // Set up a timer-based check since the auth state won't change
            authCancellable = Timer.publish(every: 0.5, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    // Check if Apple Sign-In process is complete (loading stopped and still authenticated)
                    if !self.authViewModel.isLoading && self.authViewModel.isAuthenticated && self.isLoading {
                        print("🍎 Apple Sign-In process completed, starting invitation acceptance")
                        self.authCancellable?.cancel()
                        self.authCancellable = nil
                        Task {
                            await self.completeInvitationAcceptance()
                        }
                    }
                }
        } else {
            // Set up listener for when Apple Sign-In completes
            authCancellable = authViewModel.$isAuthenticated
                .dropFirst() // Skip the initial value
                .sink { isAuthenticated in
                    print("🍎 Authentication state changed: \(isAuthenticated), isLoading: \(self.isLoading)")
                    
                    if isAuthenticated && self.isLoading {
                        print("🍎 Authentication successful, starting invitation acceptance")
                        // Delay slightly to ensure Firebase user is fully set up
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            Task {
                                await self.completeInvitationAcceptance()
                            }
                        }
                    }
                }
        }
        
        // Start the Apple Sign-In process
        print("🍎 Starting Apple Sign-In for invitation acceptance")
        authViewModel.signInWithApple()
    }
    
    private func handleManualAcceptInvitation() {
        guard let invitation = invitation else { return }
        
        isLoading = true
        
        Task {
            do {
                // For manual entry, we'll create a temporary password account
                // This is a simplified approach - in production you might want to collect a password
                let tempPassword = UUID().uuidString.prefix(12) + "!"
                
                // Create Firebase account
                _ = try await Auth.auth().createUser(
                    withEmail: invitation.clientEmail,
                    password: String(tempPassword)
                )
                
                await completeInvitationAcceptance()
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
    }
}
        }
    }
    
    @MainActor
    private func completeInvitationAcceptance() async {
        guard let invitation = invitation else { return }
        
        print("🔄 Starting invitation acceptance process")
        
        do {
            let acceptedClient = try await invitationService.acceptInvitation(invitationId: invitationId)
            print("🍎 Invitation acceptance successful: \(acceptedClient)")
            
            // Refresh user data in AuthenticationViewModel to recognize the new client role
            authViewModel.checkAuthenticationState()
            
            DispatchQueue.main.async {
                self.acceptanceComplete = true
                self.isLoading = false
                
                print("🍎 Invitation acceptance completed successfully")
                
                // Add a delay to ensure the AuthenticationViewModel has time to update userRole
                // before clearing the URL handler state, which will trigger ContentView to re-render
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Clean up the URL handler state
                    self.urlHandler.isProcessingInvitation = false
                    self.urlHandler.pendingInvitationId = nil
                    self.urlHandler.showInvitationAcceptance = false
                    print("🎯 URL handler state cleared - should now show client dashboard")
                }
            }
        } catch {
            print("❌ Invitation acceptance failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                self.urlHandler.isProcessingInvitation = false
            }
        }
        
        // Clean up the authentication listener
        authCancellable?.cancel()
        authCancellable = nil
    }
    
    private func handleCancel() {
        // Cancel any pending auth listener
        authCancellable?.cancel()
        authCancellable = nil
        
        urlHandler.clearPendingInvitation()
                        dismiss()
                    }
}

// MARK: - Preview

#Preview {
    InvitationAcceptanceView(invitationId: "sample-invitation-id")
        .environmentObject(URLHandlingService())
} 