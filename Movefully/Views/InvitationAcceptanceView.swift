import SwiftUI
import FirebaseAuth

// MARK: - Invitation Acceptance View
struct InvitationAcceptanceView: View {
    let invitationId: String
    @StateObject private var invitationService = InvitationService()
    @State private var invitation: ClientInvitation?
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var isAccepting = false
    @State private var showingSuccessView = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                if isLoading {
                    loadingView
                } else if let invitation = invitation {
                    invitationDetailsView(invitation: invitation)
                } else {
                    errorView
                }
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
        .task {
            await loadInvitation()
        }
        .sheet(isPresented: $showingSuccessView) {
            InvitationSuccessView()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: MovefullyTheme.Colors.primaryTeal))
            
            Text("Loading invitation...")
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Invitation Details View
    private func invitationDetailsView(invitation: ClientInvitation) -> some View {
        VStack(spacing: MovefullyTheme.Layout.paddingXL) {
            Spacer()
            
            // Header
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 64))
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                
                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                    Text("You're Invited!")
                        .font(MovefullyTheme.Typography.title1)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("\(invitation.trainerName) has invited you to join Movefully")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Invitation Details Card
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                if let clientName = invitation.clientName {
                    InvitationDetailRow(title: "Client Name", value: clientName)
                }
                
                InvitationDetailRow(title: "Email", value: invitation.clientEmail)
                InvitationDetailRow(title: "Trainer", value: invitation.trainerName)
                
                if let personalNote = invitation.personalNote, !personalNote.isEmpty {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text("Personal Message")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text(personalNote)
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .padding(MovefullyTheme.Layout.paddingM)
                            .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    }
                }
                
                // Expiration notice
                ExpirationNoticeView(expirationDate: invitation.expiresAt)
            }
            .padding(MovefullyTheme.Layout.paddingL)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 8, x: 0, y: 4)
            
            Spacer()
            
            // Accept Button
            Button {
                Task {
                    await acceptInvitation()
                }
            } label: {
                HStack {
                    if isAccepting {
                        ProgressView()
                            .scaleEffect(0.9)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                    }
                    
                    Text(isAccepting ? "Accepting..." : "Accept Invitation")
                        .font(MovefullyTheme.Typography.buttonLarge)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MovefullyTheme.Layout.paddingL)
                .background(MovefullyTheme.Colors.primaryTeal)
                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                .shadow(color: MovefullyTheme.Colors.primaryTeal.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(isAccepting || invitation.status != .pending || invitation.expiresAt < Date())
            .opacity(isAccepting || invitation.status != .pending || invitation.expiresAt < Date() ? 0.6 : 1.0)
            
            // Error message if present
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .padding(MovefullyTheme.Layout.paddingM)
                    .background(MovefullyTheme.Colors.textSecondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
            }
        }
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingXL) {
            Spacer()
            
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                
                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                    Text("Invitation Not Found")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("This invitation link may be invalid or expired.")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .padding(MovefullyTheme.Layout.paddingM)
                    .background(MovefullyTheme.Colors.textSecondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
            }
            
            Spacer()
        }
    }
    
    // MARK: - Methods
    private func loadInvitation() async {
        // Simulate loading the invitation by ID
        // In production, this would fetch from Firestore
                            try? await Task.sleep(for: .seconds(1))
        
        // For demo, create a sample invitation
        invitation = ClientInvitation(
            id: invitationId,
            trainerId: "trainer1",
            trainerName: "Alex Martinez",
            clientEmail: "client@example.com",
            clientName: "New Client",
            personalNote: "Welcome to Movefully! I'm excited to help you on your wellness journey.",
            status: .pending,
            createdAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
        )
        
        isLoading = false
    }
    
    private func acceptInvitation() async {
                                    guard invitation != nil else { return }
        
        isAccepting = true
        errorMessage = ""
        
        do {
            // In production, this would accept the invitation via the service
            try await Task.sleep(for: .seconds(2))
            
            isAccepting = false
            showingSuccessView = true
            
        } catch {
            isAccepting = false
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Supporting Views

struct InvitationDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
        }
    }
}

struct ExpirationNoticeView: View {
    let expirationDate: Date
    
    private var timeRemaining: String {
        let timeInterval = expirationDate.timeIntervalSinceNow
        let days = Int(timeInterval / (24 * 60 * 60))
        
        if days > 1 {
            return "Expires in \(days) days"
        } else if days == 1 {
            return "Expires tomorrow"
        } else if timeInterval > 0 {
            let hours = Int(timeInterval / (60 * 60))
            return "Expires in \(hours) hours"
        } else {
            return "Invitation expired"
        }
    }
    
    private var isExpired: Bool {
        expirationDate < Date()
    }
    
    var body: some View {
        HStack {
            Image(systemName: isExpired ? "clock.badge.exclamationmark" : "clock")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isExpired ? MovefullyTheme.Colors.textSecondary : MovefullyTheme.Colors.primaryTeal)
            
            Text(timeRemaining)
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(isExpired ? MovefullyTheme.Colors.textSecondary : MovefullyTheme.Colors.primaryTeal)
            
            Spacer()
        }
        .padding(MovefullyTheme.Layout.paddingS)
        .background((isExpired ? MovefullyTheme.Colors.textSecondary : MovefullyTheme.Colors.primaryTeal).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
    }
}

// MARK: - Success View
struct InvitationSuccessView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                Spacer()
                
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(MovefullyTheme.Colors.success)
                    
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Text("Welcome to Movefully!")
                            .font(MovefullyTheme.Typography.title1)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("Your invitation has been accepted successfully. You can now start your wellness journey!")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                Button("Get Started") {
                    dismiss()
                }
                .font(MovefullyTheme.Typography.buttonLarge)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MovefullyTheme.Layout.paddingL)
                .background(MovefullyTheme.Colors.primaryTeal)
                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                .shadow(color: MovefullyTheme.Colors.primaryTeal.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
    }
}

#Preview {
    InvitationAcceptanceView(invitationId: "sample-invitation-id")
} 