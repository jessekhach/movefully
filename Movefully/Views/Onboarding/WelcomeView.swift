import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @EnvironmentObject var urlHandler: URLHandlingService
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var animateContent = false
    @State private var showInvitationEntry = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Top section - Logo and welcome message
                VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                    // Icon with enhanced visual treatment
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [MovefullyTheme.Colors.primaryTeal.opacity(0.15), MovefullyTheme.Colors.gentleBlue.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.gentleBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateContent)
                    
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Welcome to Movefully")
                            .font(MovefullyTheme.Typography.title1)
                            .fontWeight(.bold)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("The trainer-focused wellness platform")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.top, MovefullyTheme.Layout.paddingXL) // Use fixed padding instead of relative
                    
                // Flexible spacer to push content up but allow for cards
                Spacer()
                    .frame(minHeight: MovefullyTheme.Layout.paddingXXL, maxHeight: 80) // Flexible spacer
                
                // Path selection cards
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    pathSelectionButton(
                        title: "I'm a Wellness Coach",
                        subtitle: "Grow your practice",
                        icon: "figure.mind.and.body",
                        color: MovefullyTheme.Colors.primaryTeal
                    ) {
                        coordinator.selectTrainerPath()
                    }
                    
                    pathSelectionButton(
                        title: "I have an invitation",
                        subtitle: "Join your coach's program",
                        icon: "envelope.circle",
                        color: MovefullyTheme.Colors.gentleBlue
                    ) {
                        showInvitationEntry = true
                    }
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
            }
        }
        .movefullyBackground()
        .toolbar {
            // Toolbar group for the bottom bar
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: {
                    coordinator.goToSignIn()
                }) {
                    Text("Already have an account? **Sign In**")
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, MovefullyTheme.Layout.paddingS)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            animateContent = true
            
            // If user opened the app via invitation link, auto-open the invitation entry sheet
            if let _ = urlHandler.pendingInvitationId {
                print("🎯 WelcomeView: Detected invitation from URL - opening invitation entry sheet")
                showInvitationEntry = true
            }
        }
        .sheet(isPresented: $showInvitationEntry) {
            InvitationEntrySheet(
                initialURL: urlHandler.pendingInvitationId != nil ? "https://movefully.app/invite/\(urlHandler.pendingInvitationId!)" : "",
                onInvitationProcessed: { invitationId in
                    print("🎯 WelcomeView: Processing invitation with ID: \(invitationId)")
                    showInvitationEntry = false
                    urlHandler.pendingInvitationId = invitationId
                    // Don't automatically show invitation acceptance - let onboarding handle it
                    coordinator.selectClientPath()
                },
                onCancel: {
                    showInvitationEntry = false
                    // Clear any pending invitation if user cancels
                    urlHandler.clearPendingInvitation()
                }
            )
        }
    }

    private func pathSelectionButton(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: MovefullyTheme.Layout.paddingL) {
                // Icon background
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text(title)
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
            }
            .padding(MovefullyTheme.Layout.paddingL)
            .frame(maxWidth: .infinity)
            .background(MovefullyTheme.Colors.cardBackground)
            .cornerRadius(MovefullyTheme.Layout.cornerRadiusL)
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Invitation Entry Sheet
struct InvitationEntrySheet: View {
    let initialURL: String
    let onInvitationProcessed: (String) -> Void
    let onCancel: () -> Void
    
    @State private var invitationURL = ""
    @State private var isProcessing = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Header
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Image(systemName: "envelope.open.fill")
                            .font(.system(size: 48))
                            .foregroundColor(MovefullyTheme.Colors.gentleBlue)
                        
                        Text("Enter Your Invitation")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Paste the invitation link your wellness coach sent you")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingXL)
                    
                    // URL Input Field
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text("Invitation Link")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        MovefullyTextField(
                            placeholder: "https://movefully.app/invite/...",
                            text: $invitationURL
                        )
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    
                    // Error message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.warning)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    }
                    
                    // Action buttons
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Button(action: processInvitation) {
                            HStack {
                                if isProcessing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Continue")
                                }
                            }
                        }
                        .buttonStyle(MovefullyButtonStyle(type: .primary))
                        .disabled(invitationURL.isEmpty || isProcessing)
                        .opacity(invitationURL.isEmpty || isProcessing ? 0.6 : 1.0)
                        
                        Button("Cancel", action: onCancel)
                            .buttonStyle(MovefullyButtonStyle(type: .tertiary))
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    
                    Spacer(minLength: MovefullyTheme.Layout.paddingXL)
                }
            }
            .movefullyBackground()
            .navigationTitle("Join Your Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
            .onAppear {
                // Pre-populate with the initial URL if provided
                if !initialURL.isEmpty {
                    invitationURL = initialURL
                }
            }
        }
    }
    
    private func processInvitation() {
        guard !invitationURL.isEmpty else { return }
        
        print("🎯 InvitationEntrySheet: Processing invitation URL: \(invitationURL)")
        
        isProcessing = true
        errorMessage = ""
        
        // Extract invitation ID from URL
        if let invitationId = extractInvitationId(from: invitationURL) {
            print("🎯 InvitationEntrySheet: Successfully extracted invitationId: \(invitationId)")
            onInvitationProcessed(invitationId)
        } else {
            print("🎯 InvitationEntrySheet: Failed to extract invitation ID from URL")
            errorMessage = "Invalid invitation link. Please check the URL and try again."
            isProcessing = false
        }
    }
    
    private func extractInvitationId(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        
        // Handle different URL formats:
        // 1. https://movefully.app/invite/{id}
        // 2. movefully://invite/{id}
        
        let pathComponents = url.pathComponents
        
        // Check for /invite/ path
        if let inviteIndex = pathComponents.firstIndex(of: "invite"),
           inviteIndex + 1 < pathComponents.count {
            let invitationId = pathComponents[inviteIndex + 1]
            return invitationId.isEmpty ? nil : invitationId
        }
        
        return nil
    }
} 