import SwiftUI

struct RoleSelectionView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var urlHandler: URLHandlingService
    @State private var selectedRole: String? = nil
    @State private var showConfirmation = false
    @State private var showInvitationURLInput = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Spacer()
                    
                    Text("Welcome to Movefully!")
                        .font(.system(size: 32, weight: .light, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("How would you like to use the app?")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .frame(height: geometry.size.height * 0.3)
                
                // Role selection cards
                VStack(spacing: 24) {
                    RoleCard(
                        title: "I'm a Trainer",
                        subtitle: "Help clients achieve their movement goals",
                        icon: "figure.strengthtraining.traditional",
                        gradientColors: [Color(.systemBlue).opacity(0.7), Color(.systemTeal).opacity(0.7)],
                        isSelected: selectedRole == "trainer"
                    ) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            selectedRole = "trainer"
                        }
                    }
                    
                    RoleCard(
                        title: "I'm here to move!",
                        subtitle: "Get guidance and support on your wellness journey",
                        icon: "heart.circle",
                        gradientColors: [Color(.systemPink).opacity(0.7), Color(.systemPurple).opacity(0.7)],
                        isSelected: selectedRole == "client"
                    ) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            selectedRole = "client"
                            showInvitationURLInput = true
                        }
                    }
                    
                    // Continue button
                    if selectedRole != nil {
                        Button(action: {
                            if selectedRole == "trainer" {
                                authViewModel.selectRole("trainer")
                            } else {
                                // For clients, show invitation URL input
                                showInvitationURLInput = true
                            }
                        }) {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Continue")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: selectedRole == "trainer" 
                                        ? [Color(.systemBlue).opacity(0.8), Color(.systemTeal).opacity(0.8)]
                                        : [Color(.systemPink).opacity(0.8), Color(.systemPurple).opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(authViewModel.isLoading)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.top, 8)
                    }
                    
                    // Error message
                    if !authViewModel.errorMessage.isEmpty {
                        Text(authViewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(UIColor.systemBackground),
                    selectedRole == "trainer" 
                        ? Color(.systemTeal).opacity(0.05)
                        : Color(.systemPink).opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .sheet(isPresented: $showInvitationURLInput) {
            InvitationURLEntrySheet(
                onInvitationProcessed: { invitationId in
                    print("🎯 RoleSelectionView: onInvitationProcessed called with invitationId: \(invitationId)")
                    showInvitationURLInput = false
                    print("🎯 RoleSelectionView: Setting pendingInvitationId to: \(invitationId)")
                    urlHandler.pendingInvitationId = invitationId
                    print("🎯 RoleSelectionView: Setting showInvitationAcceptance to true")
                    urlHandler.showInvitationAcceptance = true
                    print("🎯 RoleSelectionView: URL handler state updated")
                },
                onCancel: {
                    print("🎯 RoleSelectionView: onCancel called")
                    showInvitationURLInput = false
                    selectedRole = nil
                }
            )
        }
    }
}

struct RoleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(
                color: isSelected ? gradientColors.first?.opacity(0.3) ?? .clear : .clear,
                radius: isSelected ? 15 : 0,
                x: 0,
                y: isSelected ? 5 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Invitation URL Entry Sheet
struct InvitationURLEntrySheet: View {
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
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        
                        Text("Enter Invitation Link")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Paste the invitation link your trainer sent you")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingXL)
                    
                    // URL Input Field
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text("Invitation URL")
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
    }
    
    private func processInvitation() {
        guard !invitationURL.isEmpty else { return }
        
        print("🎯 InvitationURLEntrySheet: Processing invitation URL: \(invitationURL)")
        
        isProcessing = true
        errorMessage = ""
        
        // Extract invitation ID from URL
        if let invitationId = extractInvitationId(from: invitationURL) {
            print("🎯 InvitationURLEntrySheet: Successfully extracted invitationId: \(invitationId)")
            print("🎯 InvitationURLEntrySheet: Calling onInvitationProcessed")
            onInvitationProcessed(invitationId)
        } else {
            print("🎯 InvitationURLEntrySheet: Failed to extract invitation ID from URL")
            errorMessage = "Invalid invitation link. Please check the URL and try again."
            isProcessing = false
        }
    }
    
    private func extractInvitationId(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        
        // Handle different URL formats:
        // 1. https://movefully.app/invite/{id}
        // 2. movefully://invite/{id}
        // 3. https://movefully.com/invite/{id} (legacy)
        // 4. movefully://invitation/{id} (legacy)
        
        let pathComponents = url.pathComponents
        
        // Check for /invite/ path (current format)
        if let inviteIndex = pathComponents.firstIndex(of: "invite"),
           inviteIndex + 1 < pathComponents.count {
            let invitationId = pathComponents[inviteIndex + 1]
            return invitationId.isEmpty ? nil : invitationId
        }
        
        // Check for /invitation/ path (legacy format)
        if let inviteIndex = pathComponents.firstIndex(of: "invitation"),
           inviteIndex + 1 < pathComponents.count {
            let invitationId = pathComponents[inviteIndex + 1]
            return invitationId.isEmpty ? nil : invitationId
        }
        
        // Check query parameters as fallback
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            if let inviteItem = queryItems.first(where: { $0.name == "id" || $0.name == "invitationId" }) {
                return inviteItem.value
            }
        }
        
        return nil
    }
} 