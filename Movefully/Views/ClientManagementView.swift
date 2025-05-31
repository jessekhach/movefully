import SwiftUI
import FirebaseAuth

@available(iOS 15.0, *)
struct ClientManagementView: View {
    @StateObject private var viewModel = ClientManagementViewModel()
    @State private var searchText = ""
    @State private var selectedSortType = ClientSortType.name
    @State private var showingFilters = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with cleaner layout
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        HStack(spacing: MovefullyTheme.Layout.paddingL) {
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                                Text("Your Clients")
                                    .font(MovefullyTheme.Typography.title1)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Text("Nurture connections, guide wellness journeys")
                                    .font(MovefullyTheme.Typography.callout)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            // Invite Client Button - Cleaner without distractions
                            Button(action: {
                                viewModel.showInviteClientSheet = true
                            }) {
                                HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("Invite")
                                        .font(MovefullyTheme.Typography.buttonSmall)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                                .padding(.vertical, MovefullyTheme.Layout.paddingM)
                                .background(
                                    LinearGradient(
                                        colors: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.primaryTeal.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                                .shadow(color: MovefullyTheme.Colors.primaryTeal.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        
                        // Alert notifications as dedicated row when present
                        if viewModel.alertCount > 0 {
                            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                                HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(MovefullyTheme.Colors.warmOrange)
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Text("\(viewModel.alertCount) client\(viewModel.alertCount == 1 ? "" : "s") need\(viewModel.alertCount == 1 ? "s" : "") attention")
                                        .font(MovefullyTheme.Typography.body)
                                        .foregroundColor(MovefullyTheme.Colors.warmOrange)
                                }
                                
                                Spacer()
                                
                                Button("Review") {
                                    // Handle alert review action
                                }
                                .font(MovefullyTheme.Typography.buttonSmall)
                                .foregroundColor(MovefullyTheme.Colors.warmOrange)
                                .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                                .padding(.vertical, MovefullyTheme.Layout.paddingS)
                                .background(MovefullyTheme.Colors.warmOrange.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                            }
                            .padding(MovefullyTheme.Layout.paddingL)
                            .background(MovefullyTheme.Colors.warmOrange.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                            .overlay(
                                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                                    .stroke(MovefullyTheme.Colors.warmOrange.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
                        // Search field with soft wellness styling
                        TextField("Search your wellness community...", text: $searchText)
                            .movefullySearchFieldStyle()
                            .overlay(
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                        .font(.system(size: 16, weight: .medium))
                                        .padding(.leading, MovefullyTheme.Layout.paddingL)
                                    
                                    Spacer()
                                }, 
                                alignment: .leading
                            )
                            .onChange(of: searchText) { newValue in
                                viewModel.searchClients(with: newValue)
                            }
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                    .padding(.bottom, MovefullyTheme.Layout.paddingL)
                    .background(MovefullyTheme.Colors.cardBackground)
                    
                    // Soft divider
                    Rectangle()
                        .fill(MovefullyTheme.Colors.divider)
                        .frame(height: 1)
                        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 1, x: 0, y: 1)
                    
                    // Client list content
                    if viewModel.isLoading {
                        VStack(spacing: MovefullyTheme.Layout.paddingL) {
                            Spacer(minLength: 200)
                            
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(MovefullyTheme.Colors.primaryTeal)
                            
                            Text("Loading your wellness community...")
                                .font(MovefullyTheme.Typography.body)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            
                            Spacer(minLength: 200)
                        }
                        .frame(maxWidth: .infinity)
                    } else if viewModel.filteredClients.isEmpty {
                        VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                            Spacer(minLength: 100)
                            
                            // Wellness-focused empty state
                            Image(systemName: searchText.isEmpty ? "heart.circle" : "magnifyingglass")
                                .font(.system(size: 64, weight: .light))
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal.opacity(0.6))
                            
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                Text(searchText.isEmpty ? "Your wellness community awaits" : "No clients found")
                                    .font(MovefullyTheme.Typography.title2)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                    .multilineTextAlignment(.center)
                                
                                Text(searchText.isEmpty ? 
                                    "Start building meaningful connections by inviting your first client to join their wellness journey with you." : 
                                    "Try adjusting your search terms to find the client you're looking for.")
                                    .font(MovefullyTheme.Typography.callout)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            }
                            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                            
                            if searchText.isEmpty {
                                Button("Begin Their Journey") {
                                    viewModel.showInviteClientSheet = true
                                }
                                .font(MovefullyTheme.Typography.buttonMedium)
                                .foregroundColor(.white)
                                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                                .padding(.vertical, MovefullyTheme.Layout.paddingL)
                                .background(
                                    LinearGradient(
                                        colors: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.primaryTeal.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                                .shadow(color: MovefullyTheme.Colors.primaryTeal.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            
                            Spacer(minLength: 100)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                    } else {
                        LazyVStack(spacing: MovefullyTheme.Layout.paddingM) {
                            ForEach(viewModel.filteredClients) { client in
                                NavigationLink(destination: ClientDetailView(client: client)) {
                                    ClientRowView(client: client)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                        .padding(.vertical, MovefullyTheme.Layout.paddingL)
                    }
                }
            }
            .movefullyBackground()
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showInviteClientSheet) {
                EnhancedInviteClientSheet()
                    .environmentObject(viewModel)
            }
        }
    }
}

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
                        preferredCoachingStyle: $preferredCoachingStyle
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
    
    var body: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                InviteEmailField(clientEmail: $clientEmail)
                InviteNameField(clientName: $clientName)
                InviteGoalField(clientGoal: $clientGoal)
                InviteInjuriesField(clientInjuries: $clientInjuries)
                InviteCoachingStyleField(preferredCoachingStyle: $preferredCoachingStyle)
            }
        }
    }
}

struct InviteEmailField: View {
    @Binding var clientEmail: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
            Text("Client Email")
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            TextField("Enter their email address", text: $clientEmail)
                .movefullyTextFieldStyle()
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
    }
}

struct InviteNameField: View {
    @Binding var clientName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
            Text("Client Name (Optional)")
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            TextField("Their full name", text: $clientName)
                .movefullyTextFieldStyle()
        }
    }
}

struct InviteGoalField: View {
    @Binding var clientGoal: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
            Text("Goal (Optional)")
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            TextField("What would they like to achieve?", text: $clientGoal, axis: .vertical)
                .movefullyTextFieldStyle()
                .lineLimit(3...6)
        }
    }
}

struct InviteInjuriesField: View {
    @Binding var clientInjuries: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
            Text("Injuries or Notes (Optional)")
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            TextField("Any injuries or special considerations", text: $clientInjuries, axis: .vertical)
                .movefullyTextFieldStyle()
                .lineLimit(2...4)
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
                            VStack(alignment: .leading, spacing: 2) {
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
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(preferredCoachingStyle.rawValue)
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text(preferredCoachingStyle.description)
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
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
                    .movefullyButtonStyle(.secondary)
                    .frame(width: 60, height: 32)
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
                        .font(.system(size: 16, weight: .medium))
                    Text(inviteMethod == .email ? "Send Invitation" : "Share Link")
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

// MARK: - Client Detail View
struct ClientDetailView: View {
    let client: Client
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var showingAddNote = false
    @State private var showingAssignPlan = false
    @State private var newNote = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Profile Header
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Profile Image and Basic Info
                    HStack(spacing: MovefullyTheme.Layout.paddingL) {
                        AsyncImage(url: URL(string: client.profileImageURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(MovefullyTheme.Colors.primaryTeal.opacity(0.2))
                                .overlay(
                                    Text(client.name.prefix(1))
                                        .font(MovefullyTheme.Typography.title2)
                                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                )
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                                Text(client.name)
                                    .font(MovefullyTheme.Typography.title2)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Text(client.email)
                                    .font(MovefullyTheme.Typography.callout)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            }
                            
                            HStack {
                                StatusBadge(status: client.status)
                                
                                Spacer()
                            }
                            
                            Text("Joined \(client.joinedDate, formatter: DateFormatter.monthYear)")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Quick Stats
                    HStack(spacing: MovefullyTheme.Layout.paddingM) {
                        ClientStatCard(
                            icon: "figure.walk",
                            value: "\(client.workoutsCompleted)",
                            label: "Workouts"
                        )
                        
                        ClientStatCard(
                            icon: "flame.fill",
                            value: "\(client.currentStreak)",
                            label: "Day Streak"
                        )
                        
                        ClientStatCard(
                            icon: "calendar",
                            value: timeAgoString(from: client.lastActivity ?? client.joinedDate),
                            label: "Last Active"
                        )
                    }
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.vertical, MovefullyTheme.Layout.paddingL)
                .background(.white)
                
                Divider()
                
                // Tab Selector
                HStack(spacing: 0) {
                    TabButton(title: "Overview", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    TabButton(title: "Progress", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                    TabButton(title: "Notes", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                    TabButton(title: "Plans", isSelected: selectedTab == 3) {
                        selectedTab = 3
                    }
                }
                .background(.white)
                
                Divider()
                
                // Tab Content
                ScrollView {
                    Group {
                        switch selectedTab {
                        case 0:
                            ClientOverviewTab(client: client)
                        case 1:
                            ClientProgressTab(client: client)
                        case 2:
                            ClientNotesTab(client: client, showingAddNote: $showingAddNote)
                        case 3:
                            ClientPlansTab(client: client, showingAssignPlan: $showingAssignPlan)
                        default:
                            ClientOverviewTab(client: client)
                        }
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                }
            }
            .movefullyBackground()
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Send Message", systemImage: "message") {
                            // Send message
                        }
                        Button("Call Client", systemImage: "phone") {
                            // Call client
                        }
                        Button("Edit Details", systemImage: "pencil") {
                            // Edit client
                        }
                        Divider()
                        Button("Remove Client", systemImage: "trash", role: .destructive) {
                            // Remove client
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    }
                }
            }
            .sheet(isPresented: $showingAddNote) {
                AddNoteSheet(client: client, newNote: $newNote)
            }
            .sheet(isPresented: $showingAssignPlan) {
                AssignPlanSheet(client: client)
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let daysAgo = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        
        if daysAgo == 0 {
            return "Today"
        } else if daysAgo == 1 {
            return "Yesterday"
        } else if daysAgo < 7 {
            return "\(daysAgo) days ago"
        } else {
            let weeksAgo = daysAgo / 7
            return "\(weeksAgo) week\(weeksAgo == 1 ? "" : "s") ago"
        }
    }
}

// MARK: - Client Stat Card
struct ClientStatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingS) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            
            Text(value)
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            Text(label)
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 2, x: 0, y: 1)
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                Text(title)
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(isSelected ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.textSecondary)
                
                Rectangle()
                    .fill(isSelected ? MovefullyTheme.Colors.primaryTeal : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MovefullyTheme.Layout.paddingM)
    }
}

// MARK: - Client Overview Tab
struct ClientOverviewTab: View {
    let client: Client
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            // Goals Section
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                Text("Goals")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                    ForEach(client.goals, id: \.self) { goal in
                        HStack(spacing: MovefullyTheme.Layout.paddingM) {
                            Image(systemName: "target")
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                .font(.system(size: 16))
                            
                            Text(goal)
                                .font(MovefullyTheme.Typography.callout)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Spacer()
                        }
                        .padding(MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
                    }
                }
            }
            
            // Recent Activity
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                Text("Recent Activity")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                    ActivityItem(
                        icon: "figure.walk",
                        title: "Completed \"Foundation Builder\"",
                        time: "2 hours ago",
                        type: .workout
                    )
                    
                    ActivityItem(
                        icon: "message",
                        title: "Sent a progress update",
                        time: "1 day ago",
                        type: .message
                    )
                    
                    ActivityItem(
                        icon: "target",
                        title: "Updated fitness goals",
                        time: "3 days ago",
                        type: .goal
                    )
                }
            }
            
            // Contact Information
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                Text("Contact Information")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                    ContactInfoRow(icon: "envelope", title: "Email", value: client.email)
                    if let phone = client.phone {
                        ContactInfoRow(icon: "phone", title: "Phone", value: phone)
                    }
                    ContactInfoRow(icon: "figure.walk", title: "Coaching Style", value: client.coachingStyle.rawValue)
                }
            }
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
        .padding(.bottom, MovefullyTheme.Layout.paddingL)
    }
}

// MARK: - Activity Item
struct ActivityItem: View {
    let icon: String
    let title: String
    let time: String
    let type: ActivityType
    
    enum ActivityType {
        case workout, message, goal
        
        var color: Color {
            switch self {
            case .workout: return MovefullyTheme.Colors.success
            case .message: return MovefullyTheme.Colors.info
            case .goal: return MovefullyTheme.Colors.primaryTeal
            }
        }
    }
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(type.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                Text(title)
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text(time)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
    }
}

// MARK: - Contact Info Row
struct ContactInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                Text(title)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                
                Text(value)
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
            }
            
            Spacer()
        }
        .padding(MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
    }
}

// MARK: - Client Progress Tab
struct ClientProgressTab: View {
    let client: Client
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            // Progress Overview
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                Text("Progress Overview")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    ProgressCard(
                        title: "Total Workouts",
                        value: "\(client.workoutsCompleted)",
                        subtitle: "Since joining",
                        icon: "figure.walk",
                        color: MovefullyTheme.Colors.primaryTeal
                    )
                    
                    ProgressCard(
                        title: "Current Streak",
                        value: "\(client.currentStreak)",
                        subtitle: "Days active",
                        icon: "flame.fill",
                        color: MovefullyTheme.Colors.secondaryPeach
                    )
                }
            }
            
            // Weekly Progress Chart (Mock)
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                Text("Weekly Activity")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                WeeklyActivityChart()
            }
            
            // Recent Workouts
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                Text("Recent Workouts")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                    WorkoutHistoryItem(
                        name: "Foundation Builder",
                        date: "Today, 3:30 PM",
                        duration: "45 min",
                        completed: true
                    )
                    
                    WorkoutHistoryItem(
                        name: "Bodyweight Basics",
                        date: "Yesterday, 2:15 PM",
                        duration: "35 min",
                        completed: true
                    )
                    
                    WorkoutHistoryItem(
                        name: "Gentle Start",
                        date: "Dec 28, 4:00 PM",
                        duration: "25 min",
                        completed: false
                    )
                }
            }
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
        .padding(.bottom, MovefullyTheme.Layout.paddingL)
    }
}

// MARK: - Progress Card
struct ProgressCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)
            
            VStack(spacing: MovefullyTheme.Layout.paddingXS) {
                Text(value)
                    .font(MovefullyTheme.Typography.title2)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text(title)
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text(subtitle)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(MovefullyTheme.Layout.paddingL)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Weekly Activity Chart
struct WeeklyActivityChart: View {
    let mockData = [3, 1, 4, 2, 5, 1, 3] // Mock workout counts for each day
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            HStack(alignment: .bottom, spacing: MovefullyTheme.Layout.paddingS) {
                ForEach(0..<7) { index in
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Rectangle()
                            .fill(MovefullyTheme.Colors.primaryTeal.opacity(0.7))
                            .frame(width: 24, height: CGFloat(mockData[index] * 12))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        Text(dayOfWeek(for: index))
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                }
            }
            .frame(height: 100)
            
            Text("Workouts completed this week")
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
        }
        .padding(MovefullyTheme.Layout.paddingL)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    private func dayOfWeek(for index: Int) -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[index]
    }
}

// MARK: - Workout History Item
struct WorkoutHistoryItem: View {
    let name: String
    let date: String
    let duration: String
    let completed: Bool
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            Image(systemName: completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(completed ? MovefullyTheme.Colors.success : MovefullyTheme.Colors.warning)
            
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                Text(name)
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                HStack {
                    Text(date)
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    Text("•")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    Text(duration)
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            if completed {
                Text("Completed")
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.success)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                    .padding(.vertical, MovefullyTheme.Layout.paddingXS)
                    .background(MovefullyTheme.Colors.success.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
            } else {
                Text("Skipped")
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.warning)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                    .padding(.vertical, MovefullyTheme.Layout.paddingXS)
                    .background(MovefullyTheme.Colors.warning.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
            }
        }
        .padding(MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
    }
}

// MARK: - Client Notes Tab
struct ClientNotesTab: View {
    let client: Client
    @Binding var showingAddNote: Bool
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            // Add Note Button
            Button("Add New Note") {
                showingAddNote = true
            }
            .movefullyButtonStyle(.primary)
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            
            // Notes List
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                Text("Training Notes")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                
                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                    NoteItem(
                        date: "Today, 2:30 PM",
                        content: "Great improvement in form during squats. Increased depth by 15% compared to last session. Client reported feeling more confident.",
                        category: "Progress"
                    )
                    
                    NoteItem(
                        date: "Yesterday, 4:15 PM",
                        content: "Client mentioned some lower back discomfort after last workout. Adjusted plan to include more core strengthening and mobility work.",
                        category: "Health"
                    )
                    
                    NoteItem(
                        date: "Dec 28, 3:45 PM",
                        content: "Discussed nutrition goals and meal prep strategies. Client is interested in plant-based options. Shared some resources.",
                        category: "Nutrition"
                    )
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            }
        }
        .padding(.bottom, MovefullyTheme.Layout.paddingL)
    }
}

// MARK: - Note Item
struct NoteItem: View {
    let date: String
    let content: String
    let category: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                Text(category)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                    .padding(.vertical, MovefullyTheme.Layout.paddingXS)
                    .background(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
                
                Spacer()
                
                Text(date)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            
            Text(content)
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                .lineLimit(nil)
        }
        .padding(MovefullyTheme.Layout.paddingL)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 2, x: 0, y: 1)
    }
}

// MARK: - Client Plans Tab
struct ClientPlansTab: View {
    let client: Client
    @Binding var showingAssignPlan: Bool
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            // Assign Plan Button
            Button("Assign New Plan") {
                showingAssignPlan = true
            }
            .movefullyButtonStyle(.primary)
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            
            // Current Plan
            if let planId = client.workoutPlan, !planId.isEmpty {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                    Text("Current Plan")
                        .font(MovefullyTheme.Typography.title3)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    
                    CurrentPlanCard(planId: planId)
                        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                }
            }
            
            // Plan History
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                Text("Plan History")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                
                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                    PlanHistoryItem(
                        name: "Foundation Builder",
                        duration: "4 weeks",
                        startDate: "Dec 1, 2024",
                        status: "Active",
                        progress: 0.65
                    )
                    
                    PlanHistoryItem(
                        name: "Bodyweight Basics",
                        duration: "3 weeks",
                        startDate: "Nov 10, 2024",
                        status: "Completed",
                        progress: 1.0
                    )
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            }
        }
        .padding(.bottom, MovefullyTheme.Layout.paddingL)
    }
}

// MARK: - Current Plan Card
struct CurrentPlanCard: View {
    let planId: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text("Foundation Builder")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("Perfect for beginners looking to build fundamental strength")
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Text("65%")
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(MovefullyTheme.Colors.divider)
                        .frame(height: 6)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    
                    Rectangle()
                        .fill(MovefullyTheme.Colors.primaryTeal)
                        .frame(width: geometry.size.width * 0.65, height: 6)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
            .frame(height: 6)
            
            HStack {
                HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    Text("Week 3 of 4")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    Text("45 min/session")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
        .padding(MovefullyTheme.Layout.paddingL)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Plan History Item
struct PlanHistoryItem: View {
    let name: String
    let duration: String
    let startDate: String
    let status: String
    let progress: Double
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                Text(name)
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                HStack {
                    Text(duration)
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    Text("•")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    Text("Started \(startDate)")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: MovefullyTheme.Layout.paddingXS) {
                Text(status)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(status == "Active" ? MovefullyTheme.Colors.success : MovefullyTheme.Colors.primaryTeal)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                    .padding(.vertical, MovefullyTheme.Layout.paddingXS)
                    .background((status == "Active" ? MovefullyTheme.Colors.success : MovefullyTheme.Colors.primaryTeal).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
                
                Text("\(Int(progress * 100))%")
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
        }
        .padding(MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
    }
}

// MARK: - Add Note Sheet
struct AddNoteSheet: View {
    let client: Client
    @Binding var newNote: String
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory = "Progress"
    
    let categories = ["Progress", "Health", "Nutrition", "Goals", "General"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                    Text("Add Training Note")
                        .font(MovefullyTheme.Typography.title3)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("Record observations, progress, and important information about \(client.name)'s training.")
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                    Text("Category")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: MovefullyTheme.Layout.paddingS) {
                            ForEach(categories, id: \.self) { category in
                                Button(category) {
                                    selectedCategory = category
                                }
                                .font(MovefullyTheme.Typography.callout)
                                .foregroundColor(selectedCategory == category ? .white : MovefullyTheme.Colors.primaryTeal)
                                .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                                .padding(.vertical, MovefullyTheme.Layout.paddingS)
                                .background(selectedCategory == category ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                            }
                        }
                        .padding(.horizontal, MovefullyTheme.Layout.paddingXS)
                    }
                }
                
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                    Text("Note")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    TextField("Enter your training note...", text: $newNote, axis: .vertical)
                        .font(MovefullyTheme.Typography.callout)
                        .padding(MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                        .overlay(
                            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                                .stroke(MovefullyTheme.Colors.divider, lineWidth: 1)
                        )
                        .lineLimit(5...10)
                }
                
                Spacer()
                
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .movefullyButtonStyle(.tertiary)
                    
                    Button("Save Note") {
                        // Save note logic
                        dismiss()
                    }
                    .movefullyButtonStyle(.primary)
                    .disabled(newNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            .padding(.bottom, MovefullyTheme.Layout.paddingL)
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Assign Plan Sheet
struct AssignPlanSheet: View {
    let client: Client
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                    Text("Assign Workout Plan")
                        .font(MovefullyTheme.Typography.title3)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("Choose a workout plan for \(client.name) based on their goals and fitness level.")
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                // Available plans list
                ScrollView {
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        AssignablePlanCard(
                            name: "Foundation Builder",
                            description: "Perfect for beginners looking to build fundamental strength",
                            duration: "4 weeks",
                            difficulty: "Beginner"
                        )
                        
                        AssignablePlanCard(
                            name: "Bodyweight Basics",
                            description: "Master fundamental movements with bodyweight exercises",
                            duration: "3 weeks",
                            difficulty: "Beginner"
                        )
                        
                        AssignablePlanCard(
                            name: "Strength & Conditioning",
                            description: "Build strength and improve overall conditioning",
                            duration: "6 weeks",
                            difficulty: "Intermediate"
                        )
                    }
                }
                
                Button("Cancel") {
                    dismiss()
                }
                .movefullyButtonStyle(.tertiary)
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            .padding(.bottom, MovefullyTheme.Layout.paddingL)
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Assignable Plan Card
struct AssignablePlanCard: View {
    let name: String
    let description: String
    let duration: String
    let difficulty: String
    
    var body: some View {
        Button(action: {
            // Assign plan logic
        }) {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text(name)
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Text(description)
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(duration)
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Text("•")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Text(difficulty)
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            .padding(MovefullyTheme.Layout.paddingL)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: ClientStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(statusText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.12))
        .clipShape(Capsule())
    }
    
    private var statusText: String {
        switch status {
        case .active:
            return "Active"
        case .new:
            return "New"
        case .needsAttention:
            return "Alert"
        case .paused:
            return "Paused"
        case .pendingInvite:
            return "Invited"
        case .inactive:
            return "Inactive"
        case .trial:
            return "Trial"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .active:
            return MovefullyTheme.Colors.softGreen
        case .new:
            return MovefullyTheme.Colors.gentleBlue
        case .needsAttention:
            return MovefullyTheme.Colors.warmOrange
        case .paused:
            return MovefullyTheme.Colors.mediumGray
        case .pendingInvite:
            return MovefullyTheme.Colors.lavender
        case .inactive:
            return MovefullyTheme.Colors.textTertiary
        case .trial:
            return MovefullyTheme.Colors.primaryTeal
        }
    }
}

// MARK: - Client Row View
struct ClientRowView: View {
    let client: Client
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            // Profile image
            AsyncImage(url: URL(string: client.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(MovefullyTheme.Colors.primaryTeal.opacity(0.2))
                    .overlay(
                        Text(client.name.prefix(1))
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // Client info
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                HStack {
                    Text(client.name)
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    StatusBadge(status: client.status)
                }
                
                Text(client.email)
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                
                Text(client.lastActivity != nil ? "Last active \(timeAgoString(from: client.lastActivity!))" : "No activity yet")
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
        }
        .padding(MovefullyTheme.Layout.paddingL)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 2, x: 0, y: 1)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let daysAgo = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        
        if daysAgo == 0 {
            return "today"
        } else if daysAgo == 1 {
            return "yesterday"
        } else {
            return "\(daysAgo) days ago"
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
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                                Text("Client Name")
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                TextField("Enter client's full name", text: $clientName)
                                    .movefullyTextFieldStyle()
                            }
                            
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                                Text("Email Address")
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                TextField("client@example.com", text: $clientEmail)
                                    .movefullyTextFieldStyle()
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                                Text("Personal Note (Optional)")
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                TextField("Add a personal message...", text: $personalNote, axis: .vertical)
                                    .movefullyTextFieldStyle()
                                    .frame(minHeight: 80)
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