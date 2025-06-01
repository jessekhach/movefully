import SwiftUI
import FirebaseAuth

@available(iOS 15.0, *)
struct ClientManagementView: View {
    @StateObject private var viewModel = ClientManagementViewModel()
    @State private var selectedSortType = ClientSortType.name
    @State private var showingFilters = false

    var body: some View {
        MovefullyTrainerNavigation(
            title: "Your Clients",
            showProfileButton: false
        ) {
            // Alert notifications as dedicated section when present
            if viewModel.alertCount > 0 {
                AlertNotificationCard(alertCount: viewModel.alertCount)
            }
            
            MovefullySearchField(
                placeholder: "Search your wellness community...",
                text: $viewModel.searchText
            )
            
            // Content Section
            if viewModel.isLoading {
                MovefullyLoadingState(message: "Loading your wellness community...")
            } else if viewModel.filteredClients.isEmpty {
                MovefullyEmptyState(
                    icon: viewModel.searchText.isEmpty ? "heart.circle" : "magnifyingglass",
                    title: viewModel.searchText.isEmpty ? "Your wellness community awaits" : "No clients found",
                    description: viewModel.searchText.isEmpty ? 
                        "Start building meaningful connections by inviting your first client to join their wellness journey with you." : 
                        "Try adjusting your search terms to find the client you're looking for.",
                    actionButton: viewModel.searchText.isEmpty ? 
                        MovefullyEmptyState.ActionButton(
                            title: "Begin Their Journey",
                            action: { viewModel.showInviteClientSheet = true }
                        ) : nil
                )
            } else {
                MovefullyListLayout(
                    items: viewModel.filteredClients,
                    spacing: MovefullyTheme.Layout.paddingM,
                    itemView: { client in
                        NavigationLink(destination: ClientDetailView(client: client)) {
                            ClientRowView(client: client)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.showInviteClientSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
                .accessibilityLabel("Invite Client")
            }
        }
        .sheet(isPresented: $viewModel.showInviteClientSheet) {
            EnhancedInviteClientSheet()
                .environmentObject(viewModel)
        }
    }
}

// MARK: - Alert Notification Card
struct AlertNotificationCard: View {
    let alertCount: Int
    
    var body: some View {
        MovefullyAlertBanner(
            title: "\(alertCount) client\(alertCount == 1 ? "" : "s") need\(alertCount == 1 ? "s" : "") attention",
            message: "Review client progress and provide guidance to keep them on track with their wellness journey.",
            type: .warning,
            actionButton: MovefullyAlertBanner.ActionButton(
                title: "Review",
                action: {
                // Handle alert review action
            }
            )
        )
    }
}

// MARK: - Client Row View
// MARK: - Removed duplicate ClientRowView (already exists in ClientRowView.swift)

// MARK: - Enhanced Invite Client Sheet
struct EnhancedInviteClientSheet: View {
    @EnvironmentObject var viewModel: ClientManagementViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var clientEmail: String = ""
    @State private var clientName: String = ""
    @State private var clientGoal: String = ""
    @State private var clientInjuries: String = ""
    @State private var preferredCoachingStyle: CoachingStyle = .hybrid
    @State private var inviteMethod: InviteMethod = .email
    @State private var generatedInviteLink: String = ""
    @State private var personalNote = ""
    
    enum InviteMethod {
        case email, link
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    InviteHeaderView()
                    InviteMethodSelectionView(inviteMethod: $inviteMethod) {
                        generateInviteLink()
                    }
                    InviteFormView(
                        clientEmail: $clientEmail,
                        clientName: $clientName,
                        clientGoal: $clientGoal,
                        clientInjuries: $clientInjuries,
                        preferredCoachingStyle: $preferredCoachingStyle,
                        personalNote: $personalNote
                    )
                    
                    if inviteMethod == .link && !generatedInviteLink.isEmpty {
                        GeneratedLinkView(link: generatedInviteLink)
                    }
                    
                    InviteErrorView(errorMessage: viewModel.errorMessage)
                    
                    InviteSendButton(
                        inviteMethod: inviteMethod,
                        isLoading: viewModel.isLoading,
                        isDisabled: clientEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ) {
                        sendInvitation()
                    }
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXL)
            }
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
        .onReceive(viewModel.$successMessage) { message in
            if !message.isEmpty {
                dismiss()
            }
        }
    }
    
    private func generateInviteLink() {
        let baseURL = "https://movefully.app/invite"
        let inviteCode = UUID().uuidString.prefix(8)
        generatedInviteLink = "\(baseURL)/\(inviteCode)"
    }
    
    private func sendInvitation() {
        let invitation = ClientInvitation(
            id: UUID().uuidString,
            trainerId: "trainer1",
            trainerName: "Your Trainer",
            clientEmail: clientEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            clientName: clientName.isEmpty ? nil : clientName,
            goal: clientGoal.isEmpty ? nil : clientGoal,
            injuries: clientInjuries.isEmpty ? nil : clientInjuries,
            preferredCoachingStyle: preferredCoachingStyle,
            status: .pending,
            createdAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        )
        
        if inviteMethod == .email {
            viewModel.inviteClientWithDetails(invitation)
        } else {
            viewModel.generateInviteLink(invitation)
        }
    }
}

// MARK: - Invite Sheet Subviews
struct InviteHeaderView: View {
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            Text("Invite a Client")
                .font(MovefullyTheme.Typography.title2)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            Text("Send an invitation to start their movement journey with you.")
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, MovefullyTheme.Layout.paddingL)
    }
}

struct InviteMethodSelectionView: View {
    @Binding var inviteMethod: EnhancedInviteClientSheet.InviteMethod
    let onLinkGeneration: () -> Void
    
    var body: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                Text("Invitation Method")
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    InviteMethodButton(
                        title: "Email Invite",
                        subtitle: "Send directly to their inbox",
                        icon: "envelope.fill",
                        isSelected: inviteMethod == .email
                    ) {
                        inviteMethod = .email
                    }
                    
                    InviteMethodButton(
                        title: "Share Link",
                        subtitle: "Generate shareable link",
                        icon: "link",
                        isSelected: inviteMethod == .link
                    ) {
                        inviteMethod = .link
                        onLinkGeneration()
                    }
                }
            }
        }
    }
}

struct InviteFormView: View {
    @Binding var clientEmail: String
    @Binding var clientName: String
    @Binding var clientGoal: String
    @Binding var clientInjuries: String
    @Binding var preferredCoachingStyle: CoachingStyle
    @Binding var personalNote: String
    
    var body: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                MovefullyFormField(title: "Client Name", isRequired: true) {
                    MovefullyTextField(
                        placeholder: "Enter client's full name",
                        text: $clientName,
                        autocapitalization: .words
                    )
                }
                
                MovefullyFormField(title: "Email Address", isRequired: true) {
                    MovefullyTextField(
                        placeholder: "client@example.com",
                        text: $clientEmail,
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )
                }
                
                MovefullyFormField(title: "Personal Note (Optional)", subtitle: "Add a personal touch to your invitation") {
                    MovefullyTextEditor(
                        placeholder: "Add a personal message...",
                        text: $personalNote,
                        minLines: 3,
                        maxLines: 6
                    )
                }
            }
        }
    }
}

struct InviteEmailField: View {
    @Binding var clientEmail: String
    
    var body: some View {
        MovefullyFormField(title: "Client Email", isRequired: true) {
            MovefullyTextField(
                placeholder: "Enter their email address",
                text: $clientEmail,
                keyboardType: .emailAddress,
                autocapitalization: .never,
                disableAutocorrection: true
            )
        }
    }
}

struct InviteNameField: View {
    @Binding var clientName: String
    
    var body: some View {
        MovefullyFormField(title: "Client Name (Optional)") {
            MovefullyTextField(
                placeholder: "Their full name",
                text: $clientName,
                autocapitalization: .words
            )
        }
    }
}

struct InviteGoalField: View {
    @Binding var clientGoal: String
    
    var body: some View {
        MovefullyFormField(title: "Goal (Optional)", subtitle: "What would they like to achieve?") {
            MovefullyTextEditor(
                placeholder: "Their wellness goals and objectives...",
                text: $clientGoal,
                minLines: 3,
                maxLines: 6
            )
        }
    }
}

struct InviteInjuriesField: View {
    @Binding var clientInjuries: String
    
    var body: some View {
        MovefullyFormField(title: "Injuries or Notes (Optional)", subtitle: "Important health considerations") {
            MovefullyTextEditor(
                placeholder: "Any injuries or special considerations...",
                text: $clientInjuries,
                minLines: 2,
                maxLines: 4
            )
        }
    }
}

struct InviteCoachingStyleField: View {
    @Binding var preferredCoachingStyle: CoachingStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
            Text("Preferred Coaching Style")
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            Menu {
                ForEach(CoachingStyle.allCases, id: \.self) { style in
                    Button(action: {
                        preferredCoachingStyle = style
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                                Text(style.rawValue)
                                    .font(MovefullyTheme.Typography.body)
                                Text(style.description)
                                    .font(MovefullyTheme.Typography.caption)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            if preferredCoachingStyle == style {
                                Image(systemName: "checkmark")
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                    .font(MovefullyTheme.Typography.buttonSmall)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                        Text(preferredCoachingStyle.rawValue)
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text(preferredCoachingStyle.description)
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(MovefullyTheme.Typography.buttonSmall)
                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                }
                .padding(MovefullyTheme.Layout.paddingM)
                .background(MovefullyTheme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                .overlay(
                    RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                        .stroke(MovefullyTheme.Colors.divider, lineWidth: 1)
                )
            }
        }
    }
}

struct GeneratedLinkView: View {
    let link: String
    
    var body: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                Text("Invitation Link")
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                HStack {
                    Text(link)
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Button("Copy") {
                        UIPasteboard.general.string = link
                    }
                    .font(MovefullyTheme.Typography.buttonSmall)
                    .foregroundColor(.white)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                    .padding(.vertical, MovefullyTheme.Layout.paddingS)
                    .background(MovefullyTheme.Colors.secondaryPeach)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
                }
                
                Text("Share this link with your client. It expires in 7 days.")
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
        }
    }
}

struct InviteErrorView: View {
    let errorMessage: String
    
    var body: some View {
        if !errorMessage.isEmpty {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(MovefullyTheme.Typography.buttonSmall)
                    .foregroundColor(.red)
                Text(errorMessage)
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(.red)
                Spacer()
            }
            .padding(MovefullyTheme.Layout.paddingM)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
        }
    }
}

struct InviteSendButton: View {
    let inviteMethod: EnhancedInviteClientSheet.InviteMethod
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: inviteMethod == .email ? "paperplane.fill" : "square.and.arrow.up")
                        .font(MovefullyTheme.Typography.buttonSmall)
                    Text(inviteMethod == .email ? "Send Invitation" : "Share Link")
                        .font(MovefullyTheme.Typography.buttonMedium)
                }
            }
        }
        .movefullyButtonStyle(.primary)
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

// MARK: - Supporting Components
struct InviteMethodButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : MovefullyTheme.Colors.primaryTeal)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(isSelected ? .white : MovefullyTheme.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(MovefullyTheme.Layout.paddingM)
            .background(isSelected ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
            .overlay(
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS)
                    .stroke(isSelected ? Color.clear : MovefullyTheme.Colors.primaryTeal.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

extension DateFormatter {
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
}

// MARK: - Invite Client View
struct InviteClientView: View {
    let viewModel: ClientManagementViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var clientName = ""
    @State private var clientEmail = ""
    @State private var personalNote = ""
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingL) {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Invite a New Client")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Send a personalized invitation to start their wellness journey with you.")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    
                    MovefullyCard {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                            MovefullyFormField(title: "Client Name", isRequired: true) {
                                MovefullyTextField(
                                    placeholder: "Enter client's full name",
                                    text: $clientName,
                                    autocapitalization: .words
                                )
                            }
                            
                            MovefullyFormField(title: "Email Address", isRequired: true) {
                                MovefullyTextField(
                                    placeholder: "client@example.com",
                                    text: $clientEmail,
                                    keyboardType: .emailAddress,
                                    autocapitalization: .never
                                )
                            }
                            
                            MovefullyFormField(title: "Personal Note (Optional)", subtitle: "Add a personal touch to your invitation") {
                                MovefullyTextEditor(
                                    placeholder: "Add a personal message...",
                                    text: $personalNote,
                                    minLines: 3,
                                    maxLines: 6
                                )
                            }
                        }
                    }
                    
                    Button("Send Invitation") {
                        // Add invitation logic here
                        dismiss()
                    }
                    .movefullyButtonStyle(.primary)
                    .disabled(clientName.isEmpty || clientEmail.isEmpty)
                    
                    Spacer()
                }
                .padding(MovefullyTheme.Layout.paddingL)
            }
            .movefullyBackground()
            .navigationTitle("Invite Client")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
    }
} 