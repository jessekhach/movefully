import SwiftUI
import FirebaseAuth

struct ClientDetailView: View {
    let client: Client
    @StateObject private var viewModel = ClientDetailViewModel()
    // Progress data
    @StateObject private var progressService = ProgressHistoryService()
    @State private var recentProgressEntries: [ProgressEntry] = []
    @State private var recentMilestones: [Milestone] = []
    @StateObject private var assignmentService = ClientPlanAssignmentService()
    
    // Add refreshed client state to hold latest data from Firestore
    @State private var currentClient: Client
    @State private var isRefreshing = false
    
    @State private var showingAddNoteSheet = false
    @State private var showingAssignCurrentPlanSheet = false
    @State private var showingAssignUpcomingPlanSheet = false
    @State private var showingReplaceCurrentPlanSheet = false
    @State private var showingReplaceUpcomingPlanSheet = false
    @State private var showingRemoveCurrentPlanConfirmation = false
    @State private var showingRemoveUpcomingPlanConfirmation = false
    @State private var showingPlanOptionsSheet = false
    @State private var showingFullNotesView = false
    @State private var showingFullProgressHistory = false
    @State private var showingAddProgressSheet = false
    @State private var showingAddMilestoneSheet = false
    @State private var showingEditProfileSheet = false
    @State private var navigateToMessages = false
    
    // Delete client states
    @State private var showDeleteClientAlert = false
    @State private var showDeleteClientConfirmation = false
    @StateObject private var deletionService = ClientDeletionService()
    @Environment(\.dismiss) private var dismiss
    
    // Copy link feedback
    @State private var showingCopyConfirmation = false
    
    // Initialize currentClient with the passed client
    init(client: Client) {
        self.client = client
        self._currentClient = State(initialValue: client)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Header Section
                    clientHeaderSection
                    
                    // Pending Invitation Section (for pending clients)
                    if client.status == .pending {
                        pendingInvitationSection
                    } else {
                        // Only show these sections for non-pending clients
                        
                        // Quick Actions
                        quickActionsSection
                        
                        // Smart Alerts
                        if !viewModel.smartAlerts.isEmpty {
                            smartAlertsSection
                        }
                        
                        // Profile Information
                        profileInformationSection
                        
                        // Current Plan
                        currentPlanSection
                        
                        // Progress Overview
                        progressHistorySection
                        
                        // Recent Notes
                        recentNotesSection
                    }
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.top, MovefullyTheme.Layout.paddingL) // Add top padding
                .padding(.bottom, MovefullyTheme.Layout.paddingXL)
            }
            .movefullyBackground()
                    .navigationTitle(client.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditProfileSheet = true }) {
                        Label("Edit Profile", systemImage: "person.crop.circle")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showDeleteClientAlert = true }) {
                        Label("Delete Client", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
        .fullScreenCover(isPresented: $navigateToMessages) {
            MessagesNavigationWrapper(clientId: currentClient.id, clientName: currentClient.name)
        }
        }
        .onAppear {
            viewModel.loadClientData(currentClient)
            refreshClientData()
            loadProgressData()
        }
        .sheet(isPresented: $showingAddNoteSheet) {
            AddNoteSheet(client: currentClient)
                .environmentObject(viewModel)
                .onDisappear {
                    // Refresh notes when sheet is dismissed
                    viewModel.loadClientData(currentClient)
                }
        }
        .sheet(isPresented: $showingAssignCurrentPlanSheet) {
            AssignCurrentPlanSheet(client: currentClient) {
                // Refresh immediately when plan is successfully assigned
                Task {
                    refreshClientData()
                    await MainActor.run {
                        viewModel.loadClientData(currentClient)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAssignUpcomingPlanSheet) {
            AssignUpcomingPlanSheet(client: currentClient) {
                // Refresh immediately when plan is successfully assigned
                Task {
                    refreshClientData()
                    await MainActor.run {
                        viewModel.loadClientData(currentClient)
                    }
                }
            }
        }
        .sheet(isPresented: $showingReplaceCurrentPlanSheet) {
            ReplaceCurrentPlanSheet(client: currentClient)
                .onDisappear {
                    // Refresh data when sheet is dismissed to update UI after plan replacement
                    viewModel.loadClientData(currentClient)
                    refreshClientData()
                }
        }
        .sheet(isPresented: $showingRemoveCurrentPlanConfirmation) {
            RemoveCurrentPlanConfirmation(client: currentClient)
                .onDisappear {
                    // Refresh data when sheet is dismissed to update UI after plan removal
                    viewModel.loadClientData(currentClient)
                    refreshClientData()
                }
        }
        .sheet(isPresented: $showingReplaceUpcomingPlanSheet) {
            ReplaceUpcomingPlanSheet(client: currentClient)
                .onDisappear {
                    // Refresh data when sheet is dismissed
                    viewModel.loadClientData(currentClient)
                    refreshClientData()
                }
        }
        .sheet(isPresented: $showingRemoveUpcomingPlanConfirmation) {
            RemoveUpcomingPlanConfirmation(client: currentClient)
                .onDisappear {
                    // Refresh data when sheet is dismissed
                    viewModel.loadClientData(currentClient)
                    refreshClientData()
                }
        }

        .sheet(isPresented: $showingPlanOptionsSheet) {
            PlanOptionsSheet(client: currentClient) { option in
                switch option {
                case .replaceCurrent:
                    showingReplaceCurrentPlanSheet = true
                case .addUpcoming:
                    showingAssignUpcomingPlanSheet = true
                case .removeCurrent:
                    showingRemoveCurrentPlanConfirmation = true
                case .manageUpcoming:
                    // For now, this could show another action sheet or go directly to replace
                    showingReplaceUpcomingPlanSheet = true
                case .removeUpcoming:
                    showingRemoveUpcomingPlanConfirmation = true
                }
            }
        }
        .sheet(isPresented: $showingFullNotesView) {
            FullNotesView(client: currentClient)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingFullProgressHistory) {
            FullProgressHistoryView(client: currentClient)
        }
        .sheet(isPresented: $showingAddProgressSheet) {
            AddProgressSheet(client: currentClient) {
                loadProgressData()
            }
        }
        .sheet(isPresented: $showingAddMilestoneSheet) {
            AddMilestoneSheet(client: currentClient) {
                loadProgressData()
            }
        }
        .sheet(isPresented: $showingEditProfileSheet) {
            EditClientProfileSheet(client: currentClient) { updatedClient in
                currentClient = updatedClient
                viewModel.loadClientData(currentClient)
            }
        }
        .alert("Delete Client", isPresented: $showDeleteClientAlert) {
            Button("Cancel", role: .cancel) { }
            Button("I Understand", role: .destructive) {
                showDeleteClientConfirmation = true
            }
        } message: {
            Text("⚠️ WARNING: This will remove \(currentClient.name) from your client list.\n\nThis action will:\n• Remove all their workout history and progress data\n• Delete all conversations between you and the client\n\nAre you sure?")
        }
        .sheet(isPresented: $showDeleteClientConfirmation) {
            TrainerDeleteClientConfirmationView(
                client: currentClient,
                deletionService: deletionService,
                onCancel: { showDeleteClientConfirmation = false },
                onComplete: { 
                    showDeleteClientConfirmation = false
                    // Navigate back to client list by dismissing this view
                    dismiss()
                }
            )
        }
        .alert("Link Copied!", isPresented: $showingCopyConfirmation) {
            Button("OK") { }
        } message: {
            Text("The invitation link has been copied to your clipboard.")
        }
    }
    
    // MARK: - Navigation Functions
    private func navigateToConversation() {
        navigateToMessages = true
    }
    
    // MARK: - Pending Invitation Section
    private var pendingInvitationSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            Text("Pending Invitation")
                .font(MovefullyTheme.Typography.title3)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            MovefullyCard {
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    HStack {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                
                                Text("Invitation Link")
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            }
                            
                            Text("Client hasn't accepted the invitation yet")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        if !viewModel.invitationLink.isEmpty {
                            Button("Copy Link") {
                                UIPasteboard.general.string = viewModel.invitationLink
                                showingCopyConfirmation = true
                            }
                            .font(MovefullyTheme.Typography.buttonSmall)
                            .foregroundColor(.white)
                            .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                            .padding(.vertical, MovefullyTheme.Layout.paddingS)
                            .background(MovefullyTheme.Colors.primaryTeal)
                            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
                        }
                    }
                    
                    if !viewModel.invitationLink.isEmpty {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            Text("Share this link with your client:")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            
                            Text(viewModel.invitationLink)
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                .padding(MovefullyTheme.Layout.paddingS)
                                .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
                                .lineLimit(2)
                        }
                    }
                    
                    // Show invitation details if available
                    if let invitation = viewModel.invitationDetails {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            HStack {
                                Text("Invitation Details")
                                    .font(MovefullyTheme.Typography.caption)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                
                                Spacer()
                                
                                Text("Expires: \(invitation.expiresAt, formatter: dateFormatter)")
                                    .font(MovefullyTheme.Typography.caption)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            }
                            
                            if let personalNote = invitation.personalNote, !personalNote.isEmpty {
                                Text("Note: \(personalNote)")
                                    .font(MovefullyTheme.Typography.caption)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .italic()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var clientHeaderSection: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Profile Picture with AsyncImage support
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        MovefullyTheme.Colors.primaryTeal,
                                        MovefullyTheme.Colors.secondaryPeach
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        if let profileImageUrl = client.profileImageUrl, !profileImageUrl.isEmpty {
                            AsyncImage(url: URL(string: profileImageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            } placeholder: {
                                Text(initials)
                                    .font(MovefullyTheme.Typography.title1)
                                    .foregroundColor(.white)
                            }
                        } else {
                            Text(initials)
                                .font(MovefullyTheme.Typography.title1)
                                .foregroundColor(.white)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text(client.name)
                            .font(MovefullyTheme.Typography.title3)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        if !client.email.isEmpty {
                            ProfileInfoRow(title: "Email", value: client.email, icon: "envelope")
                        }
                        
                        ClientStatusBadge(status: client.status)
                    }
                    
                    Spacer()
                }
                
                // Joined date and activity
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Client Since")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        Text(joinedDateText)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Last Activity")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        Text(client.lastActivityText)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            Text("Quick Actions")
                .font(MovefullyTheme.Typography.title3)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                SmartPlanActionButton(client: currentClient) { action in
                    switch action {
                    case .assignCurrent:
                        showingAssignCurrentPlanSheet = true
                    case .showPlanOptions:
                        showingPlanOptionsSheet = true
                    }
                }
                
                QuickActionButton(
                    title: "Send Message",
                    icon: "message",
                    color: MovefullyTheme.Colors.secondaryPeach
                ) {
                    // Deep link to conversation with this client
                    navigateToConversation()
                }
                
                QuickActionButton(
                    title: "Add Note",
                    icon: "note.text.badge.plus",
                    color: MovefullyTheme.Colors.success
                ) {
                    showingAddNoteSheet = true
                }
            }
        }
    }
    
    // MARK: - Smart Alerts Section
    private var smartAlertsSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
            ForEach(viewModel.smartAlerts) { alert in
                SmartAlertCard(alert: alert) {
                    viewModel.dismissAlert(alert)
                }
            }
        }
    }
    
    // MARK: - Profile Information Section
    private var profileInformationSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            Text("Profile Information")
                .font(MovefullyTheme.Typography.title3)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                    // Header with Edit button
                    HStack {
                        Text("Profile Details")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Spacer()
                        
                        Button {
                            showingEditProfileSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12, weight: .medium))
                                Text("Edit")
                                .font(MovefullyTheme.Typography.caption)
                            }
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                            .padding(.vertical, 4)
                            .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
                        }
                    }
                    
                    // Profile information rows
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        // Goal - show content or fallback
                        if let goals = currentClient.goals, !goals.isEmpty {
                            ProfileInfoRow(title: "Goal", value: goals, icon: "target", lineLimit: 3)
                        } else {
                            ProfileInfoRow(title: "Goal", value: "No specific goal set", icon: "target", lineLimit: 3)
                }
                
                // Injuries/Notes - show content or fallback
                        if let injuries = currentClient.injuries, !injuries.isEmpty {
                    ProfileInfoRow(title: "Injuries/Notes", value: injuries, icon: "cross.case", lineLimit: 3)
                } else {
                    ProfileInfoRow(title: "Injuries/Notes", value: "No injuries or notes", icon: "cross.case", lineLimit: 3)
                }
                
                // Preferred Style - show content or fallback
                        if let coachingStyle = currentClient.preferredCoachingStyle {
                    ProfileInfoRow(title: "Preferred Style", value: coachingStyle.rawValue, icon: "person.2", lineLimit: 1)
                } else {
                    ProfileInfoRow(title: "Preferred Style", value: "Not specified", icon: "person.2", lineLimit: 1)
                }
            }
                }
            }
        }
    }
    
    // MARK: - Current Plan Section
    private var currentPlanSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingL) {
            // Current Plan Section
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            Text("Current Plan")
                .font(MovefullyTheme.Typography.title3)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
                if let currentPlan = viewModel.currentPlan, currentClient.hasCurrentPlan {
                    currentPlanCard(currentPlan)
                } else {
                    // Show empty state when no current plan
                    MovefullyCard {
                        VStack(spacing: MovefullyTheme.Layout.paddingM) {
                            Image(systemName: "list.clipboard")
                                .font(.system(size: 24))
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            
                            Text("No current plan assigned")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            
                            Button("Assign Current Plan") {
                                showingAssignCurrentPlanSheet = true
                            }
                            .font(MovefullyTheme.Typography.buttonMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MovefullyTheme.Layout.paddingM)
                            .background(MovefullyTheme.Colors.primaryTeal)
                            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                        }
                        .padding(.vertical, MovefullyTheme.Layout.paddingS)
                    }
                }
            }
        
        // Upcoming Plan Section
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            Text("Upcoming Plan")
                .font(MovefullyTheme.Typography.title3)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            if currentClient.hasNextPlan {
                upcomingPlanCard
            } else {
                // Show empty state for upcoming plan
                MovefullyCard {
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 24))
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        
                        if currentClient.hasCurrentPlan {
                            Text("No upcoming plan assigned")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            
                            Button("Assign Upcoming Plan") {
                                showingAssignUpcomingPlanSheet = true
                            }
                            .font(MovefullyTheme.Typography.buttonMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MovefullyTheme.Layout.paddingM)
                            .background(MovefullyTheme.Colors.primaryTeal)
                            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                        } else {
                            Text("Assign a current plan first")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            
                            Text("You need to assign a current plan before you can queue an upcoming plan")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
        }
        }
    }
    
    // MARK: - Current Plan Card
    private func currentPlanCard(_ plan: WorkoutPlan) -> some View {
        MovefullyCard {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                        if !plan.description.isEmpty {
                            Text(plan.description)
                                    .font(MovefullyTheme.Typography.caption)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
                        
                    MovefullyPill(
                        title: "Active",
                        isSelected: false,
                        style: .status,
                        action: { }
                    )
                }
                
                // Plan info with dates
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                    HStack(spacing: MovefullyTheme.Layout.paddingL) {
                        Label("\(plan.duration) weeks", systemImage: "calendar")
                        Label(plan.difficulty.rawValue, systemImage: "chart.line.uptrend.xyaxis")
                        Spacer()
                    }
                    
                    // Add start and end dates if available
                    if let startDate = currentClient.currentPlanStartDate,
                       let endDate = currentClient.currentPlanEndDate {
                        HStack(spacing: MovefullyTheme.Layout.paddingL) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.circle")
                                    .foregroundColor(MovefullyTheme.Colors.softGreen)
                                Text("\(startDate > Date() ? "Starts" : "Started"): \(compactDateFormatter.string(from: startDate))")
                    }
                    
                            HStack(spacing: 4) {
                                Image(systemName: "stop.circle")
                                    .foregroundColor(MovefullyTheme.Colors.warmOrange)
                                Text("Ends: \(compactDateFormatter.string(from: endDate))")
                            }
                            
                        Spacer()
                        }
                    }
                    }
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                
                // Action Buttons
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Button("Replace") {
                        showingReplaceCurrentPlanSheet = true
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MovefullyTheme.Layout.paddingS)
                    .background(MovefullyTheme.Colors.warmOrange)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    
                    Button("Remove") {
                        showingRemoveCurrentPlanConfirmation = true
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MovefullyTheme.Layout.paddingS)
                    .background(MovefullyTheme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                }
            }
        }
    }
    

    
    private var mediumDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private var compactDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    // MARK: - Empty Current Plan Card
    private var emptyCurrentPlanCard: some View {
        MovefullyCard {
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Image(systemName: "list.clipboard")
                        .font(.system(size: 40))
                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                    
                    Text("No plan assigned")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                Text("Assign a plan to begin training next Sunday")
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    
                    Button("Assign Plan") {
                    showingAssignCurrentPlanSheet = true
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    .background(MovefullyTheme.Colors.primaryTeal)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                }
                .frame(maxWidth: .infinity)
            .padding(.vertical, MovefullyTheme.Layout.paddingL)
        }
    }
    
    // MARK: - Upcoming Plan Card
    private var upcomingPlanCard: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if let upcomingPlan = viewModel.upcomingPlan {
                            Text(upcomingPlan.name)
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            if !upcomingPlan.description.isEmpty {
                                Text(upcomingPlan.description)
                                    .font(MovefullyTheme.Typography.caption)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .lineLimit(2)
                            }
                        } else {
                            Text("Upcoming Plan")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Text("Will start when current plan ends")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    MovefullyPill(
                        title: "Queued",
                        isSelected: false,
                        style: .status,
                        action: { }
                    )
                }
                
                // Plan info with dates
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                    if let upcomingPlan = viewModel.upcomingPlan {
                        HStack(spacing: MovefullyTheme.Layout.paddingL) {
                            Label("\(upcomingPlan.duration) weeks", systemImage: "calendar")
                            Label(upcomingPlan.difficulty.rawValue, systemImage: "chart.line.uptrend.xyaxis")
                            Spacer()
                        }
                    }
                    
                    // Add start and end dates if available
                    if let startDate = currentClient.nextPlanStartDate,
                       let endDate = currentClient.nextPlanEndDate {
                        HStack(spacing: MovefullyTheme.Layout.paddingL) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.circle")
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                Text("Starts: \(compactDateFormatter.string(from: startDate))")
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "stop.circle")
                                    .foregroundColor(MovefullyTheme.Colors.warmOrange)
                                Text("Ends: \(compactDateFormatter.string(from: endDate))")
                            }
                            
                            Spacer()
                        }
                    }
                }
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                
                // Action Buttons
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Button("Replace") {
                        showingReplaceUpcomingPlanSheet = true
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MovefullyTheme.Layout.paddingS)
                    .background(MovefullyTheme.Colors.warmOrange)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    
                    Button("Remove") {
                        showingRemoveUpcomingPlanConfirmation = true
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MovefullyTheme.Layout.paddingS)
                    .background(MovefullyTheme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                }
            }
        }
    }
    
    // MARK: - Empty Upcoming Plan Card
    private var emptyUpcomingPlanCard: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
                
                Text("No upcoming plan")
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                
                if currentClient.hasCurrentPlan {
                    Text("Queue a plan to start when the current plan ends")
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Assign a current plan first, then you can queue an upcoming plan")
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                
                Button("Assign Upcoming") {
                    if currentClient.hasCurrentPlan {
                        showingAssignUpcomingPlanSheet = true
                    }
                }
                .font(MovefullyTheme.Typography.buttonMedium)
                .foregroundColor(.white)
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.vertical, MovefullyTheme.Layout.paddingM)
                .background(currentClient.hasCurrentPlan ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.textTertiary)
                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                .disabled(!currentClient.hasCurrentPlan)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MovefullyTheme.Layout.paddingL)
        }
    }
    
    // MARK: - Progress History Section
    private var progressHistorySection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                Text("Progress History")
                .font(MovefullyTheme.Typography.title3)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
                Spacer()
                
                Button("View Full") {
                    showingFullProgressHistory = true
                }
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            }
            
            if recentProgressEntries.isEmpty && recentMilestones.isEmpty {
                // Empty state with action buttons
                MovefullyCard {
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        VStack(spacing: MovefullyTheme.Layout.paddingM) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 40))
                                .foregroundColor(MovefullyTheme.Colors.textTertiary)
                            
                            Text("No progress data yet")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            
                            Text("Start tracking your client's progress with updates and milestones")
                                .font(MovefullyTheme.Typography.callout)
                                .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Action buttons
                        HStack(spacing: MovefullyTheme.Layout.paddingS) {
                            Button {
                                showingAddProgressSheet = true
                            } label: {
                                HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Add Update")
                                        .font(MovefullyTheme.Typography.caption)
                                }
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                                .padding(.vertical, MovefullyTheme.Layout.paddingXS)
                                .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
                            }
                            
                            Button {
                                showingAddMilestoneSheet = true
                            } label: {
                                HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                                    Image(systemName: "trophy")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Add Milestone")
                                        .font(MovefullyTheme.Typography.caption)
                                }
                                .foregroundColor(MovefullyTheme.Colors.warmOrange)
                                .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                                .padding(.vertical, MovefullyTheme.Layout.paddingXS)
                                .background(MovefullyTheme.Colors.warmOrange.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MovefullyTheme.Layout.paddingL)
                }
            } else {
                // Progress Summary Card
                MovefullyCard {
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        // Quick Stats
                HStack(spacing: MovefullyTheme.Layout.paddingL) {
                    ProgressStatView(
                                title: "Updates",
                                value: "\(recentProgressEntries.count)",
                                icon: "chart.line.uptrend.xyaxis"
                    )
                    
                    ProgressStatView(
                                title: "Milestones",
                                value: "\(recentMilestones.count)",
                                icon: "trophy"
                    )
                    
                    ProgressStatView(
                                title: "Last Update",
                                value: lastUpdateText,
                                icon: "clock"
                            )
                        }
                        
                        Divider()
                            .background(MovefullyTheme.Colors.divider)
                        
                        // Recent Changes
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            Text("Recent Changes")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            if recentProgressEntries.isEmpty {
                                Text("No recent progress updates")
                                    .font(MovefullyTheme.Typography.callout)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .italic()
                            } else {
                                VStack(spacing: MovefullyTheme.Layout.paddingXS) {
                                    ForEach(Array(recentProgressEntries.prefix(3))) { entry in
                                        HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                            Image(systemName: entry.field.icon)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                            
                                            Text("\(entry.field.displayName): \(entry.newValue)\(entry.field.unit.isEmpty ? "" : " \(entry.field.unit)")")
                                                .font(MovefullyTheme.Typography.callout)
                                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                            
                                            Spacer()
                                            
                                            Text(formatRelativeTime(entry.timestamp))
                                                .font(MovefullyTheme.Typography.caption)
                                                .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Quick Actions
                        HStack(spacing: MovefullyTheme.Layout.paddingM) {
                            Button {
                                showingAddProgressSheet = true
                            } label: {
                                HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Add Update")
                                        .font(MovefullyTheme.Typography.callout)
                                }
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            }
                            
                            Spacer()
                            
                            Button {
                                showingAddMilestoneSheet = true
                            } label: {
                                HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                    Image(systemName: "trophy")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Add Milestone")
                                        .font(MovefullyTheme.Typography.callout)
                                }
                                .foregroundColor(MovefullyTheme.Colors.warmOrange)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Notes Section
    private var recentNotesSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                Text("Recent Notes")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Spacer()
                
                if !viewModel.allNotes.isEmpty {
                Button("View All") {
                        showingFullNotesView = true
                }
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
            
            if viewModel.recentNotes.isEmpty {
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Image(systemName: "note.text")
                        .font(.system(size: 40))
                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                    
                    Text("No notes yet")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    Button("Add First Note") {
                        showingAddNoteSheet = true
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    .background(MovefullyTheme.Colors.warmOrange)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, MovefullyTheme.Layout.paddingXL)
                .background(MovefullyTheme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 2, x: 0, y: 1)
            } else {
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    ForEach(viewModel.recentNotes.prefix(3)) { note in
                        NoteRowView(note: note, onDelete: nil)
                    }
                    HStack {
                        Spacer()
                        Button {
                            showingAddNoteSheet = true
                        } label: {
                            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Add Note")
                                    .font(MovefullyTheme.Typography.callout)
                            }
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        }
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingS)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var initials: String {
        let components = currentClient.name.components(separatedBy: " ")
        let firstInitial = components.first?.first?.uppercased() ?? ""
        let lastInitial = components.count > 1 ? (components.last?.first?.uppercased() ?? "") : ""
        return firstInitial + lastInitial
    }
    
    private var joinedDateText: String {
        guard let joinedDate = currentClient.joinedDate else {
            return "Invited"
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(joinedDate)
        let days = Int(timeInterval / 86400)
        
        if days < 1 {
            return "Today"
        } else if days < 7 {
            return "\(days)d ago"
        } else if days < 30 {
            let weeks = days / 7
            return "\(weeks)w ago"
        } else if days < 365 {
            let months = days / 30
            return "\(months)mo ago"
        } else {
            let years = days / 365
            return "\(years)y ago"
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
    
    private var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
    
    // Helper for better time formatting
    private func formatRelativeTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let daysDiff = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if daysDiff < 7 {
                return "\(daysDiff) days ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: date)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var lastUpdateText: String {
        guard let latestEntry = recentProgressEntries.first else {
            return "None"
        }
        
        let daysAgo = Calendar.current.dateComponents([.day], from: latestEntry.timestamp, to: Date()).day ?? 0
        
        if daysAgo == 0 {
            return "Today"
        } else if daysAgo == 1 {
            return "Yesterday"
        } else {
            return "\(daysAgo)d ago"
        }
    }
    
    // MARK: - Data Loading
    private func loadProgressData() {
        Task {
            do {
                print("📊 Loading progress data for client: \(currentClient.id)")
                async let progressData = progressService.fetchRecentProgressSummary(for: currentClient.id, days: 30)
                async let milestoneData = progressService.fetchMilestones(for: currentClient.id, limit: 5)
                
                let (entries, achievements) = try await (progressData, milestoneData)
                
                print("✅ Loaded \(entries.count) progress entries and \(achievements.count) milestones")
                
                await MainActor.run {
                    self.recentProgressEntries = entries
                    self.recentMilestones = achievements
                }
            } catch {
                print("❌ Error loading progress data: \(error)")
            }
        }
    }
    
    // MARK: - Refresh Methods
    
    private func refreshClientData() {
        print("🔄 ClientDetailView: Starting refreshClientData for client \(currentClient.id)")
        
        Task {
            do {
                isRefreshing = true
                print("🔍 ClientDetailView: Fetching latest client data from Firestore...")
                
                // First fetch client data
                let fetchedClient = try await assignmentService.fetchClient(currentClient.id)
                print("✅ ClientDetailView: Successfully fetched client - hasCurrentPlan: \(fetchedClient.hasCurrentPlan)")
                print("📋 ClientDetailView: Current plan ID: \(fetchedClient.currentPlanId ?? "nil")")
                
                // Check if we need to promote next plan to current plan automatically
                var refreshedClient = fetchedClient
                if fetchedClient.shouldPromoteNextPlan {
                    print("🔄 ClientDetailView: Plan promotion needed - promoting next plan to current")
                    refreshedClient = try await assignmentService.promoteNextPlanToCurrent(fetchedClient)
                    print("✅ ClientDetailView: Plan promotion completed")
                }
                
                await MainActor.run {
                    print("🔄 ClientDetailView: Updating currentClient on main thread")
                    currentClient = refreshedClient
                    print("🎯 ClientDetailView: Updated currentClient - hasCurrentPlan: \(currentClient.hasCurrentPlan)")
                    
                    // Also refresh the view model with the new client data
                    print("🔄 ClientDetailView: Loading client data in view model...")
                    viewModel.loadClientData(currentClient)
                    print("✅ ClientDetailView: View model refresh completed")
                    
                    isRefreshing = false
                }
            } catch {
                await MainActor.run {
                    print("❌ ClientDetailView: Error refreshing client data: \(error)")
                    isRefreshing = false
                }
            }
        }
    }
}

// MARK: - Supporting Views

// MARK: - Smart Plan Action Button
struct SmartPlanActionButton: View {
    let client: Client
    let action: (PlanAction) -> Void
    
    enum PlanAction {
        case assignCurrent
        case showPlanOptions
    }
    
    var body: some View {
        if client.hasCurrentPlan {
            // Client has a plan - show plan options
            QuickActionButton(
                title: "Plan Options",
                icon: "gearshape",
                color: MovefullyTheme.Colors.textSecondary
            ) {
                action(.showPlanOptions)
            }
        } else {
            // Client has no plan - show assign plan
            QuickActionButton(
                title: "Assign Plan",
                icon: "list.clipboard",
                color: MovefullyTheme.Colors.primaryTeal
            ) {
                action(.assignCurrent)
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(MovefullyTheme.Layout.paddingM)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 2, x: 0, y: 1)
        }
    }
}

struct ProfileInfoRow: View {
    let title: String
    let value: String
    let icon: String
    let lineLimit: Int?
    
    init(title: String, value: String, icon: String, lineLimit: Int? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.lineLimit = lineLimit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                
                Text(title)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            
            Text(value)
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                .lineLimit(lineLimit)
        }
    }
}



struct ProgressStatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingS) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            
            Text(value)
                .font(MovefullyTheme.Typography.title3)
                .fontWeight(.semibold)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            Text(title)
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct NoteRowView: View {
    let note: ClientNote
    let onDelete: ((ClientNote) -> Void)?
    
    init(note: ClientNote, onDelete: ((ClientNote) -> Void)? = nil) {
        self.note = note
        self.onDelete = onDelete
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
            HStack {
                Image(systemName: note.type.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                
                Text(note.type.displayName)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                
                Spacer()
                
                Text(RelativeDateTimeFormatter().localizedString(for: note.createdAt, relativeTo: Date()))
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
            }
            
            Text(note.content)
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 1, x: 0, y: 1)
    }
}

// MARK: - Edit Client Profile Sheet
struct EditClientProfileSheet: View {
    let client: Client
    let onSave: (Client) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var clientDataService = ClientDataService()
    
    @State private var goals: String
    @State private var injuries: String
    @State private var preferredCoachingStyle: CoachingStyle?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    init(client: Client, onSave: @escaping (Client) -> Void) {
        self.client = client
        self.onSave = onSave
        self._goals = State(initialValue: client.goals ?? "")
        self._injuries = State(initialValue: client.injuries ?? "")
        self._preferredCoachingStyle = State(initialValue: client.preferredCoachingStyle)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    MovefullyCard {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingL) {
                            // Goals Section
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                                HStack(spacing: 6) {
                                    Image(systemName: "target")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                    
                                    Text("Goals")
                                        .font(MovefullyTheme.Typography.bodyMedium)
                                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                }
                                
                                MovefullyTextEditor(
                                    placeholder: "Enter client's fitness goals and objectives...",
                                    text: $goals,
                                    minLines: 4,
                                    maxLines: 8
                                )
                            }
                            
                            // Injuries/Notes Section
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                                HStack(spacing: 6) {
                                    Image(systemName: "cross.case")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                    
                                    Text("Injuries & Medical Notes")
                                        .font(MovefullyTheme.Typography.bodyMedium)
                                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                }
                                
                                MovefullyTextEditor(
                                    placeholder: "Enter any injuries, medical conditions, or important notes...",
                                    text: $injuries,
                                    minLines: 4,
                                    maxLines: 8
                                )
                            }
                            
                            // Preferred Coaching Style Section
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.2")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                    
                                    Text("Preferred Coaching Style")
                                        .font(MovefullyTheme.Typography.bodyMedium)
                                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                }
                                
                                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                                    ForEach(CoachingStyle.allCases, id: \.self) { style in
                                        Button {
                                            preferredCoachingStyle = style
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(style.rawValue)
                                                        .font(MovefullyTheme.Typography.body)
                                                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                                    
                                                    Text(style.description)
                                                        .font(MovefullyTheme.Typography.caption)
                                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: preferredCoachingStyle == style ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(preferredCoachingStyle == style ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.textTertiary)
                                            }
                                            .padding(MovefullyTheme.Layout.paddingM)
                                            .background(
                                                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                                                    .fill(preferredCoachingStyle == style ? MovefullyTheme.Colors.primaryTeal.opacity(0.1) : MovefullyTheme.Colors.backgroundSecondary)
                                                    .stroke(preferredCoachingStyle == style ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.divider, lineWidth: 1)
                                            )
                                        }
                                    }
                                    
                                    // Option to clear selection
                                    Button {
                                        preferredCoachingStyle = nil
                                    } label: {
                                        HStack {
                                            Text("No Preference")
                                                .font(MovefullyTheme.Typography.body)
                                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                            
                                            Spacer()
                                            
                                            Image(systemName: preferredCoachingStyle == nil ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 20))
                                                .foregroundColor(preferredCoachingStyle == nil ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.textTertiary)
                                        }
                                        .padding(MovefullyTheme.Layout.paddingM)
                                        .background(
                                            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                                                .fill(preferredCoachingStyle == nil ? MovefullyTheme.Colors.primaryTeal.opacity(0.1) : MovefullyTheme.Colors.backgroundSecondary)
                                                .stroke(preferredCoachingStyle == nil ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.divider, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(MovefullyTheme.Layout.paddingL)
            }
            .movefullyBackground()
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { 
                        dismiss() 
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(isLoading)
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private func saveChanges() {
        isLoading = true
        
        var updatedClient = client
        updatedClient.goals = goals.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : goals.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedClient.injuries = injuries.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : injuries.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedClient.preferredCoachingStyle = preferredCoachingStyle
        updatedClient.updatedAt = Date()
        
        Task {
            do {
                try await clientDataService.updateClientProfile(updatedClient, trainerId: updatedClient.trainerId)
                
                await MainActor.run {
                    isLoading = false
                    onSave(updatedClient)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to save changes: \(error.localizedDescription)"
                }
            }
        }
    }
}



struct AssignCurrentPlanSheet: View {
    let client: Client
    let onCompletion: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assignmentService = ClientPlanAssignmentService()
    @StateObject private var programsViewModel = ProgramsViewModel()
    
    @State private var selectedProgram: Program?
    @State private var selectedStartDate: Date = Date()
    @State private var selectedStartOption: MovefullyPlanStartSelector.PlanStartOption = .nextSunday
    @State private var availableSundays: [Date] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    
    init(client: Client, onCompletion: (() -> Void)? = nil) {
        self.client = client
        self.onCompletion = onCompletion
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: MovefullyTheme.Layout.paddingL) {
                    if isLoading {
                        MovefullyLoadingState(message: "Loading plans...")
                    } else {
                        planStartSelectionSection
                        availablePlansSection
                    }
                }
                .padding(MovefullyTheme.Layout.paddingL)
            }
            .movefullyBackground()
            .navigationTitle("Assign Current Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Assign") {
                        assignCurrentPlan()
                    }
                    .disabled(selectedProgram == nil || isLoading)
                }
            }
        }
        .onAppear {
            loadData()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    

    
    private var planStartSelectionSection: some View {
        MovefullyCard {
            MovefullyPlanStartSelector(selectedOption: $selectedStartOption)
                .onChange(of: selectedStartOption) { newOption in
                    switch newOption {
                    case .nextSunday:
                        selectedStartDate = assignmentService.nextSunday()
                    case .startToday:
                        selectedStartDate = Date()
                    }
                }
        }
    }
    
    private var availablePlansSection: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                HStack {
                    Text("Available Plans")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(filteredPrograms.count) plans")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                MovefullySearchField(
                    placeholder: "Search plans...",
                    text: $searchText
                )
                
                if filteredPrograms.isEmpty {
                    MovefullyEmptyState(
                        icon: "magnifyingglass",
                        title: "No plans found",
                        description: "Try adjusting your search terms to find the plan you're looking for.",
                        actionButton: nil
                    )
                } else {
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        ForEach(filteredPrograms) { program in
                            ProgramSelectionCard(
                                program: program,
                                isSelected: selectedProgram?.id == program.id,
                                programsViewModel: programsViewModel
                            ) {
                                selectedProgram = program
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var filteredPrograms: [Program] {
        if searchText.isEmpty {
            return programsViewModel.programs.filter { !$0.isDraft }
        } else {
            return programsViewModel.programs.filter { program in
                !program.isDraft && (
                    program.name.localizedCaseInsensitiveContains(searchText) ||
                    program.description.localizedCaseInsensitiveContains(searchText) ||
                    program.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
                )
            }
        }
    }
    
    private func loadData() {
        selectedStartDate = assignmentService.nextSunday()
        selectedStartOption = .nextSunday // Default to traditional Sunday start
    }
    
    private func assignCurrentPlan() {
        guard let program = selectedProgram else { return }
        
        isLoading = true
        
        Task {
            do {
                let startOnProgramDay = selectedStartOption == .startToday 
                    ? assignmentService.calculateProgramDayForToday(date: selectedStartDate)
                    : 1
                
                let options = PlanAssignmentOptions(
                    replaceCurrentPlan: false,
                    startDate: selectedStartDate,
                    autoCalculateEndDate: true,
                    startOnProgramDay: startOnProgramDay
                )
                
                try await assignmentService.assignPlan(
                    programId: program.id.uuidString,
                    to: client.id,
                    options: options
                )
                
                // Refresh live counts after successful assignment
                programsViewModel.refreshProgramAssignedCounts()
                
                await MainActor.run {
                    onCompletion?()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
}

struct AssignUpcomingPlanSheet: View {
    let client: Client
    let onCompletion: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assignmentService = ClientPlanAssignmentService()
    @StateObject private var programsViewModel = ProgramsViewModel()
    
    @State private var selectedProgram: Program?
    @State private var selectedStartDate: Date = Date()
    @State private var availableSundays: [Date] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    
    init(client: Client, onCompletion: (() -> Void)? = nil) {
        self.client = client
        self.onCompletion = onCompletion
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: MovefullyTheme.Layout.paddingL) {
                    if isLoading {
                        MovefullyLoadingState(message: "Loading plans...")
                    } else {
                        upcomingPlanDateCard
                        availablePlansSection
                    }
                }
                .padding(MovefullyTheme.Layout.paddingL)
            }
            .movefullyBackground()
            .navigationTitle("Assign Upcoming Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Assign") {
                        assignUpcomingPlan()
                    }
                    .disabled(selectedProgram == nil || isLoading)
                }
            }
        }
        .onAppear {
            loadData()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Upcoming Plan Date Card
    private var upcomingPlanDateCard: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                Text("Plan Start Date")
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                if let currentEndDate = client.currentPlanEndDate {
                    HStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Image(systemName: "calendar")
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Will start on \(nextSundayAfter(currentEndDate), formatter: mediumDateFormatter)")
                                .font(MovefullyTheme.Typography.body)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Text("Automatically begins when current plan ends")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(MovefullyTheme.Layout.paddingM)
                    .background(MovefullyTheme.Colors.primaryTeal.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                } else {
                    HStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(MovefullyTheme.Colors.warmOrange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No current plan assigned")
                                .font(MovefullyTheme.Typography.body)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Text("Assign a current plan first to queue an upcoming plan")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(MovefullyTheme.Layout.paddingM)
                    .background(MovefullyTheme.Colors.warmOrange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                }
            }
        }
    }
    
    // MARK: - Available Plans Section
    private var availablePlansSection: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                HStack {
                    Text("Available Plans")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(filteredPrograms.count) plans")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                MovefullySearchField(
                    placeholder: "Search plans...",
                    text: $searchText
                )
                
                if filteredPrograms.isEmpty {
                    MovefullyEmptyState(
                        icon: "magnifyingglass",
                        title: "No plans found",
                        description: "Try adjusting your search terms to find the plan you're looking for.",
                        actionButton: nil
                    )
                } else {
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        ForEach(filteredPrograms) { program in
                            ProgramSelectionCard(
                                program: program,
                                isSelected: selectedProgram?.id == program.id,
                                programsViewModel: programsViewModel
                            ) {
                                selectedProgram = program
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredPrograms: [Program] {
        programsViewModel.programs.filter { program in
            searchText.isEmpty ||
            program.name.localizedCaseInsensitiveContains(searchText) ||
            program.description.localizedCaseInsensitiveContains(searchText) ||
            program.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // MARK: - Helper Methods
    
    private func nextSundayAfter(_ date: Date) -> Date {
        let calendar = Calendar.current
        
        // If the end date is already a Sunday, start the next plan on that same Sunday
        if calendar.component(.weekday, from: date) == 1 {
            return calendar.startOfDay(for: date)
        }
        
        // Otherwise, find the next Sunday after the end date
        return assignmentService.nextSunday(from: date)
    }
    
    private func loadData() {
        isLoading = true
        Task {
            // Programs are automatically loaded by ProgramsViewModel
            await MainActor.run {
                if let currentEndDate = client.currentPlanEndDate {
                    selectedStartDate = nextSundayAfter(currentEndDate)
                } else {
                    // If no current plan, default to next Sunday
                    selectedStartDate = assignmentService.nextSunday()
                }
                isLoading = false
            }
        }
    }
    
    private func assignUpcomingPlan() {
        guard let program = selectedProgram else { return }
        
        isLoading = true
        Task {
            do {
                let options = PlanAssignmentOptions(
                    replaceCurrentPlan: false,
                    startDate: selectedStartDate
                )
                
                try await assignmentService.assignPlan(
                    programId: program.id.uuidString,
                    to: client.id,
                    options: options
                )
                
                // Refresh live counts after successful assignment
                programsViewModel.refreshProgramAssignedCounts()
                
                await MainActor.run {
                    onCompletion?()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private var mediumDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

struct ReplaceCurrentPlanSheet: View {
    let client: Client
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assignmentService = ClientPlanAssignmentService()
    @StateObject private var programsViewModel = ProgramsViewModel()
    
    @State private var selectedProgram: Program?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                replaceCurrentHeader
                
                // Content
                ScrollView {
                    LazyVStack(spacing: MovefullyTheme.Layout.paddingL) {
                        if isLoading {
                            MovefullyLoadingState(message: "Loading plans...")
                        } else {
                            availablePlansSection
                        }
                    }
                    .padding(MovefullyTheme.Layout.paddingL)
                }
            }
            .movefullyBackground()
            .navigationTitle("Replace Current Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Replace") {
                        replaceCurrentPlan()
                    }
                    .disabled(selectedProgram == nil || isLoading)
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Header
    private var replaceCurrentHeader: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                Text("Replace Current Plan")
                    .font(MovefullyTheme.Typography.title2)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                HStack {
                    Text("The current plan will be removed and the new plan will start this Sunday.")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(MovefullyTheme.Colors.gentleBlue)
                    
                    Text("The new plan will start this Sunday")
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.gentleBlue)
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
        .padding(.vertical, MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.backgroundSecondary)
    }
    
    // MARK: - Available Plans Section  
    private var availablePlansSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                Text("Available Plans")
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            // Search field
            MovefullySearchField(
                placeholder: "Search plans...",
                text: $searchText
            )
            
            // Plans list
            if filteredPrograms.isEmpty {
                MovefullyEmptyState(
                    icon: "calendar.badge.plus",
                    title: "No plans found",
                    description: "Try adjusting your search terms to find the plan you're looking for.",
                    actionButton: nil
                )
            } else {
                ForEach(filteredPrograms) { program in
                    ProgramSelectionCard(
                        program: program,
                        isSelected: selectedProgram?.id == program.id,
                        programsViewModel: programsViewModel
                    ) {
                        selectedProgram = program
                    }
                }
            }
        }
    }
    
    private var filteredPrograms: [Program] {
        programsViewModel.programs.filter { program in
            searchText.isEmpty ||
            program.name.localizedCaseInsensitiveContains(searchText) ||
            program.description.localizedCaseInsensitiveContains(searchText) ||
            program.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // MARK: - Actions
    private func replaceCurrentPlan() {
        guard let program = selectedProgram else { return }
        
        isLoading = true
        Task {
            do {
                let options = PlanAssignmentOptions(
                    replaceCurrentPlan: true,
                    startDate: assignmentService.nextSunday(),
                    startOnProgramDay: 1  // Plan replacements always start at Day 1 (traditional)
                )
                
                try await assignmentService.assignPlan(
                    programId: program.id.uuidString,
                    to: client.id,
                    options: options
                )
                
                // Refresh live counts after successful assignment
                programsViewModel.refreshProgramAssignedCounts()
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct ReplaceUpcomingPlanSheet: View {
    let client: Client
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assignmentService = ClientPlanAssignmentService()
    @StateObject private var programsViewModel = ProgramsViewModel()
    
    @State private var selectedProgram: Program?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                replaceHeader
                
                // Content
                ScrollView {
                    LazyVStack(spacing: MovefullyTheme.Layout.paddingL) {
                        if isLoading {
                            MovefullyLoadingState(message: "Loading plans...")
                        } else {
                            currentUpcomingPlanCard
                            availablePlansSection
                        }
                    }
                    .padding(MovefullyTheme.Layout.paddingL)
                }
            }
            .movefullyBackground()
            .navigationTitle("Replace Upcoming Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Replace") {
                        replaceUpcomingPlan()
                    }
                    .disabled(selectedProgram == nil || isLoading)
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Header
    private var replaceHeader: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                Text("Replace Upcoming Plan")
                    .font(MovefullyTheme.Typography.title2)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            HStack {
                Text("Choose a new plan to replace the currently queued plan")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                
                Spacer()
            }
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
        .padding(.vertical, MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.backgroundSecondary)
    }
    
    // MARK: - Current Upcoming Plan Card
    private var currentUpcomingPlanCard: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                HStack {
                    Text("Current Upcoming Plan")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    MovefullyPill(
                        title: "Queued",
                        isSelected: false,
                        style: .status,
                        action: { }
                    )
                }
                
                if let startDate = client.nextPlanStartDate {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(MovefullyTheme.Colors.warmOrange)
                        
                        Text("Will start on \(startDate, formatter: mediumDateFormatter)")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Available Plans Section  
    private var availablePlansSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                Text("Choose Replacement Plan")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(filteredPrograms.count) plans")
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            
            MovefullySearchField(
                placeholder: "Search plans...",
                text: $searchText
            )
            
            if filteredPrograms.isEmpty {
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                    
                    Text("No plans found")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, MovefullyTheme.Layout.paddingXL)
            } else {
                ForEach(filteredPrograms) { program in
                    ProgramSelectionCard(
                        program: program,
                        isSelected: selectedProgram?.id == program.id,
                        programsViewModel: programsViewModel
                    ) {
                        selectedProgram = program
                    }
                }
            }
        }
        .padding(MovefullyTheme.Layout.paddingL)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
    }
    
    // MARK: - Computed Properties
    private var filteredPrograms: [Program] {
        programsViewModel.programs.filter { program in
            searchText.isEmpty ||
            program.name.localizedCaseInsensitiveContains(searchText) ||
            program.description.localizedCaseInsensitiveContains(searchText) ||
            program.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // MARK: - Actions
    private func replaceUpcomingPlan() {
        guard let program = selectedProgram,
              let startDate = client.nextPlanStartDate else { return }
        
        isLoading = true
        Task {
            do {
                // Remove current upcoming plan first
                try await assignmentService.removeUpcomingPlan(for: client.id)
                
                // Assign new upcoming plan
                let options = PlanAssignmentOptions(
                    replaceCurrentPlan: false,
                    startDate: startDate,
                    startOnProgramDay: client.nextPlanStartOnProgramDay ?? 1  // Preserve original program day offset
                )
                
                try await assignmentService.assignPlan(
                    programId: program.id.uuidString,
                    to: client.id,
                    options: options
                )
                
                // Refresh live counts after successful assignment
                programsViewModel.refreshProgramAssignedCounts()
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private var mediumDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

struct RemoveCurrentPlanConfirmation: View {
    let client: Client
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assignmentService = ClientPlanAssignmentService()
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                // Header icon
                ZStack {
                    Circle()
                        .fill(MovefullyTheme.Colors.warmOrange.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.warmOrange)
                }
                .padding(.top, MovefullyTheme.Layout.paddingL)
                
                // Title and description
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Text("Remove Current Plan")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    if client.hasNextPlan {
                        Text("The current plan will be removed. What would you like to do with the upcoming plan?")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("This will permanently delete the client's current plan and all associated workout data.")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Options
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    if client.hasNextPlan {
                        // Option 1: Start upcoming plan today
                        PlanDeletionOption(
                            title: "Start Immediately",
                            subtitle: assignmentService.getTodayProgramDayDescription(),
                            icon: "play.circle.fill",
                            color: MovefullyTheme.Colors.primaryTeal
                        ) {
                            handlePromoteUpcomingPlanToday()
                        }
                        
                        // Option 2: Start upcoming plan on Sunday
                        PlanDeletionOption(
                            title: "Start Next Sunday",
                            subtitle: formatSundayDateOnly(),
                            icon: "calendar",
                            color: MovefullyTheme.Colors.gentleBlue
                        ) {
                            handlePromoteUpcomingPlanSunday()
                        }
                        
                        // Option 3: Delete both plans
                        PlanDeletionOption(
                            title: "Delete Both Plans",
                            subtitle: "",
                            icon: "trash",
                            color: MovefullyTheme.Colors.warmOrange
                        ) {
                            handleDeleteBothPlans()
                        }
                    } else {
                        // No upcoming plan - just delete current
                        PlanDeletionOption(
                            title: "Delete Current Plan",
                            subtitle: "This action cannot be undone",
                            icon: "trash",
                            color: MovefullyTheme.Colors.warmOrange
                        ) {
                            handleDeleteCurrentPlanOnly()
                        }
                    }
                    
                    // Option 4: Cancel
                    PlanDeletionOption(
                        title: "Cancel",
                        subtitle: "",
                        icon: "xmark.circle",
                        color: MovefullyTheme.Colors.textSecondary
                    ) {
                        dismiss()
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
            .movefullyBackground()
            .navigationTitle("Remove Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func formatSundayDateOnly() -> String {
        // Always use the actual next Sunday date, not the stored upcoming plan date
        // This ensures that if today is Sunday, we show next week's Sunday
        let nextSundayDate = assignmentService.nextSunday()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: nextSundayDate)
    }
    
    // MARK: - Action Handlers
    private func handlePromoteUpcomingPlanToday() {
        guard let upcomingPlanId = client.nextPlanId else { return }
        
        isLoading = true
        Task {
            do {
                // First remove current plan
                try await assignmentService.removeCurrentPlan(for: client.id)
                
                // Then promote upcoming plan to start today at appropriate program day
                let startOnProgramDay = assignmentService.calculateProgramDayForToday()
                let options = PlanAssignmentOptions(
                    replaceCurrentPlan: true,
                    startDate: Date(),
                    startOnProgramDay: startOnProgramDay
                )
                
                try await assignmentService.assignPlan(
                    programId: upcomingPlanId,
                    to: client.id,
                    options: options
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func handlePromoteUpcomingPlanSunday() {
        guard let upcomingPlanId = client.nextPlanId else { return }
        
        isLoading = true
        Task {
            do {
                // Remove current plan - upcoming will auto-promote with original schedule
                try await assignmentService.removeCurrentPlan(for: client.id)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func handleDeleteBothPlans() {
        isLoading = true
        Task {
            do {
                // Remove upcoming plan first
                try await assignmentService.removeUpcomingPlan(for: client.id)
                
                // Then remove current plan
                try await assignmentService.removeCurrentPlan(for: client.id)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func handleDeleteCurrentPlanOnly() {
        isLoading = true
        Task {
            do {
                try await assignmentService.removeCurrentPlan(for: client.id)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct PlanDeletionOption: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MovefullyTheme.Layout.paddingL) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 45, height: 45)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text(title)
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
            }
            .padding(MovefullyTheme.Layout.paddingL)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RemoveUpcomingPlanConfirmation: View {
    let client: Client
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assignmentService = ClientPlanAssignmentService()
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(MovefullyTheme.Colors.warmOrange)
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Text("Remove Upcoming Plan")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("Are you sure you want to remove the upcoming plan? This action cannot be undone.")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                if let startDate = client.nextPlanStartDate {
                    MovefullyCard {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            Text("Plan to be removed:")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(MovefullyTheme.Colors.warmOrange)
                                
                                Text("Scheduled to start \(startDate, formatter: mediumDateFormatter)")
                                    .font(MovefullyTheme.Typography.body)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Button(isLoading ? "Removing..." : "Remove Plan") {
                        removeUpcomingPlan()
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    .background(MovefullyTheme.Colors.warmOrange)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    .disabled(isLoading)
                    
                    Button("Keep Plan") {
                        dismiss()
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    .background(MovefullyTheme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                }
            }
            .padding(MovefullyTheme.Layout.paddingL)
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Actions
    private func removeUpcomingPlan() {
        isLoading = true
        Task {
            do {
                try await assignmentService.removeUpcomingPlan(for: client.id)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private var mediumDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

// MARK: - Program Selection Card
struct ProgramSelectionCard: View {
    let program: Program
    let isSelected: Bool
    let programsViewModel: ProgramsViewModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(program.name)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        Text(program.description)
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    }
                }
                
                // Stats
                HStack(spacing: MovefullyTheme.Layout.paddingL) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                        
                        Text(program.durationText)
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.system(size: 12))
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                        
                        Text("\(programsViewModel.getAssignedCount(for: program.id)) assigned")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
                
                // Tags section (always present)
                if program.tags.isEmpty {
                    HStack {
                        Text("No tags assigned")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                            .italic()
                        Spacer()
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: MovefullyTheme.Layout.paddingS) {
                            ForEach(program.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(MovefullyTheme.Typography.caption)
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                    .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                                    .padding(.vertical, 4)
                                    .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(MovefullyTheme.Layout.paddingL)
            .background(isSelected ? MovefullyTheme.Colors.primaryTeal.opacity(0.05) : MovefullyTheme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
            .overlay(
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                    .stroke(isSelected ? MovefullyTheme.Colors.primaryTeal : Color.clear, lineWidth: 2)
            )
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: isSelected ? 4 : 2, x: 0, y: isSelected ? 2 : 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddNoteSheet: View {
    let client: Client
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ClientDetailViewModel
    
    @State private var noteContent: String = ""
    @State private var isLoading = false
    
    private var canSave: Bool {
        !noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Content
                ScrollView {
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        noteContentSection
                    }
                    .padding(MovefullyTheme.Layout.paddingL)
                }
            }
            .movefullyBackground()
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveNote() }
                        .disabled(!canSave)
                        .opacity(canSave ? 1.0 : 0.6)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                Text("Add Note for \(client.name)")
                    .font(MovefullyTheme.Typography.title2)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            HStack {
                Text("Add a note to track progress, observations, or important information")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                
                Spacer()
            }
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
        .padding(.vertical, MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.backgroundSecondary)
    }
    
    // Note: Note type section removed - we only create trainer notes
    
    // MARK: - Note Content Section
    private var noteContentSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            Text("Note Content")
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                MovefullyTextEditor(
                    placeholder: "Enter your note here... Share observations, progress updates, or important information about \(client.name)'s training.",
                    text: $noteContent,
                    maxCharacters: 2000
                )
                .frame(minHeight: 120)
                
                // Character counter
                HStack {
                    Spacer()
                    Text("\(noteContent.count)/2000")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(characterCountColor)
                }
            }
        }
    }
    
    // MARK: - Character Count Color
    private var characterCountColor: Color {
        let count = noteContent.count
        if count >= 2000 {
            return Color.red
        } else if count >= 1800 {
            return MovefullyTheme.Colors.warmOrange
        } else {
            return MovefullyTheme.Colors.textTertiary
        }
    }
    
    // MARK: - Actions
    private func saveNote() {
        let content = noteContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        isLoading = true
        
        // Always create trainer notes (no type selection needed)
        viewModel.addNote(content: content, type: .trainerNote)
        
        // Close the sheet after a short delay to show the loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

// MARK: - Plan Options Sheet
struct PlanOptionsSheet: View {
    let client: Client
    let onSelection: (PlanOption) -> Void
    @Environment(\.dismiss) private var dismiss
    
    enum PlanOption {
        case replaceCurrent
        case addUpcoming
        case removeCurrent
        case manageUpcoming
        case removeUpcoming
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Header section
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text("Plan Management")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Choose an action to manage \(client.name)'s plans")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, MovefullyTheme.Layout.paddingM)
                    
                    // Action options
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        // Current plan actions
                        MovefullyActionRow(
                            title: "Replace Current Plan",
                            icon: "arrow.triangle.2.circlepath"
                        ) {
                            dismiss()
                            onSelection(.replaceCurrent)
                        }
                        
                        if !client.hasNextPlan {
                            MovefullyActionRow(
                                title: "Add Upcoming Plan",
                                icon: "calendar.badge.plus"
                            ) {
                                dismiss()
                                onSelection(.addUpcoming)
                            }
                        }
                        
                        // Upcoming plan actions (if exists)
                        if client.hasNextPlan {
                            MovefullyActionRow(
                                title: "Manage Upcoming Plan",
                                icon: "calendar.badge.exclamationmark"
                            ) {
                                dismiss()
                                onSelection(.manageUpcoming)
                            }
                        }
                        
                        // Destructive actions section
                        VStack(spacing: MovefullyTheme.Layout.paddingS) {
                            // Divider
                            Rectangle()
                                .fill(MovefullyTheme.Colors.divider)
                                .frame(height: 1)
                                .padding(.vertical, MovefullyTheme.Layout.paddingS)
                            
                            Button {
                                dismiss()
                                onSelection(.removeCurrent)
                            } label: {
                                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                                    Image(systemName: "trash")
                                        .font(MovefullyTheme.Typography.buttonSmall)
                                        .foregroundColor(MovefullyTheme.Colors.warmOrange)
                                        .frame(width: 24)
                                    
                                    Text("Remove Current Plan")
                                        .font(MovefullyTheme.Typography.bodyMedium)
                                        .foregroundColor(MovefullyTheme.Colors.warmOrange)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(MovefullyTheme.Typography.caption)
                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                }
                                .padding(MovefullyTheme.Layout.paddingM)
                                .background(MovefullyTheme.Colors.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(MovefullyTheme.Layout.paddingL)
            }
            .movefullyBackground()
            .navigationTitle("Plan Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Full Notes View
struct FullNotesView: View {
    let client: Client
    @EnvironmentObject private var viewModel: ClientDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddNoteSheet = false
    @State private var selectedNoteFilter: ClientNote.NoteType? = nil
    
    // Computed property for filtered notes
    private var filteredNotes: [ClientNote] {
        if let filter = selectedNoteFilter {
            return viewModel.allNotes.filter { $0.type == filter }
        }
        return viewModel.allNotes
    }
    
    // Computed property for note counts by type
    private var noteCounts: [ClientNote.NoteType: Int] {
        var counts: [ClientNote.NoteType: Int] = [:]
        for noteType in ClientNote.NoteType.allCases {
            counts[noteType] = viewModel.allNotes.filter { $0.type == noteType }.count
        }
        return counts
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Filter pills section
                    noteFiltersSection
                    
                    // Content
                    if filteredNotes.isEmpty {
                        emptyState
                    } else {
                        notesContent
                    }
                }
                .padding(MovefullyTheme.Layout.paddingL)
            }
            .movefullyBackground()
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddNoteSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(MovefullyTheme.Typography.buttonMedium)
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddNoteSheet) {
            AddNoteSheet(client: client)
                .environmentObject(viewModel)
                .onDisappear {
                    // Refresh notes when sheet is dismissed
                    viewModel.loadClientData(client)
                }
        }
    }

    
    // MARK: - Note Filters Section
    private var noteFiltersSection: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                Text("Browse by Type")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // "All" filter pill
                    NoteFilterPill(
                        noteType: nil,
                        count: viewModel.allNotes.count,
                        isSelected: selectedNoteFilter == nil
                    ) {
                        selectedNoteFilter = nil
                    }
                    
                    // Individual note type filter pills
                    ForEach(ClientNote.NoteType.allCases, id: \.self) { noteType in
                        let count = noteCounts[noteType] ?? 0
                        if count > 0 {
                            NoteFilterPill(
                                noteType: noteType,
                                count: count,
                                isSelected: selectedNoteFilter == noteType
                            ) {
                                selectedNoteFilter = selectedNoteFilter == noteType ? nil : noteType
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .contentMargins(.leading, MovefullyTheme.Layout.paddingL)
        }
    }
    
    // MARK: - Notes Content
    private var notesContent: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            ForEach(filteredNotes) { note in
                FullNoteCard(note: note, onDelete: nil)
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            Spacer()
            
            Image(systemName: selectedNoteFilter != nil ? "line.3.horizontal.decrease.circle" : "note.text")
                .font(.system(size: 60))
                .foregroundColor(MovefullyTheme.Colors.textTertiary)
            
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                Text(selectedNoteFilter != nil ? "No \(selectedNoteFilter!.displayName)" : "No Notes Yet")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text(selectedNoteFilter != nil ? 
                     "No notes of this type found. Try selecting a different filter or add a new note." :
                     "Start documenting \(client.name)'s progress and observations")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            if selectedNoteFilter != nil {
                Button {
                    selectedNoteFilter = nil
                } label: {
                    HStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Image(systemName: "arrow.clockwise")
                            .font(MovefullyTheme.Typography.buttonMedium)
                        
                        Text("Show All Notes")
                            .font(MovefullyTheme.Typography.buttonMedium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    .background(
                        LinearGradient(
                            colors: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.primaryTeal.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    .shadow(color: MovefullyTheme.Colors.primaryTeal.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button {
                    showingAddNoteSheet = true
                } label: {
                    HStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Image(systemName: "plus.circle.fill")
                            .font(MovefullyTheme.Typography.buttonMedium)
                        
                        Text("Add First Note")
                            .font(MovefullyTheme.Typography.buttonMedium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    .background(
                        LinearGradient(
                            colors: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.primaryTeal.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    .shadow(color: MovefullyTheme.Colors.primaryTeal.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .padding(MovefullyTheme.Layout.paddingL)
    }
}

// MARK: - Note Filter Pill
struct NoteFilterPill: View {
    let noteType: ClientNote.NoteType?
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                Image(systemName: noteType?.icon ?? "list.bullet")
                    .font(MovefullyTheme.Typography.callout)
                
                Text(noteType?.displayName ?? "All")
                    .font(MovefullyTheme.Typography.callout)
                
                if count > 0 {
                    Text("(\(count))")
                        .font(MovefullyTheme.Typography.caption)
                }
            }
            .foregroundColor(isSelected ? .white : MovefullyTheme.Colors.primaryTeal)
            .padding(.horizontal, MovefullyTheme.Layout.paddingM)
            .padding(.vertical, MovefullyTheme.Layout.paddingS)
            .background(
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                    .fill(isSelected ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.primaryTeal.opacity(0.1))
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Full Note Card
struct FullNoteCard: View {
    let note: ClientNote
    let onDelete: ((ClientNote) -> Void)?
    @State private var isExpanded = false
    
    init(note: ClientNote, onDelete: ((ClientNote) -> Void)? = nil) {
        self.note = note
        self.onDelete = onDelete
    }
    
    // Check if note content is long (more than 3 lines approximately)
    private var isLongNote: Bool {
        note.content.count > 150 // Rough estimate for 3 lines
    }
    
    var body: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                // Header with date and type
                HStack {
                    MovefullyStatusBadge(
                        text: note.type.displayName,
                        color: MovefullyTheme.Colors.primaryTeal,
                        showDot: true
                    )
                    
                    Spacer()
                    
                    Text(note.createdAt, style: .date)
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                }
                
                // Note content with truncation
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                    Text(note.content)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        .lineLimit(isExpanded ? nil : (isLongNote ? 3 : nil))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Show expand/collapse button for long notes
                    if isLongNote {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        } label: {
                            HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                                Text(isExpanded ? "Show less" : "Show more")
                                    .font(MovefullyTheme.Typography.caption)
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    } 
}

// MARK: - Progress History Views
struct FullProgressHistoryView: View {
    let client: Client
    @Environment(\.dismiss) private var dismiss
    @StateObject private var progressService = ProgressHistoryService()
    @State private var progressEntries: [ProgressEntry] = []
    @State private var milestones: [Milestone] = []
    @State private var selectedCategory: ProgressCategory? = nil
    @State private var isLoading = true
    @State private var showingAddProgressSheet = false
    @State private var showingAddMilestoneSheet = false
    @State private var showingExport = false
    @State private var showingAllProgressEntries = false
    
    // Filter out muscleMass for UI display
    private var availableProgressFields: [ProgressField] {
        ProgressField.allCases.filter { $0 != .muscleMass }
    }
    
    // Helper for better time formatting
    private func formatRelativeTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let daysDiff = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if daysDiff < 7 {
                return "\(daysDiff) days ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: date)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Stats Header
                    progressStatsHeader
                    
                    // Progress Chart
                    if !progressEntries.isEmpty {
                        ProgressChartView(entries: progressEntries)
                    }
                    
                    // Category Filter
                    categoryFilter
                    
                    // Progress Entries
                    progressEntriesSection
                    
                    // Milestones
                    milestonesSection
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.top, MovefullyTheme.Layout.paddingM)
            }
            .movefullyBackground()
            .navigationTitle("Progress History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: MovefullyTheme.Layout.paddingM) {
                        if !progressEntries.isEmpty || !milestones.isEmpty {
                            Button {
                                showingExport = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            }
                        }
                        
                        Menu {
                            Button {
                                showingAddProgressSheet = true
                            } label: {
                                Label("Add Update", systemImage: "plus.circle")
                            }
                            
                            Button {
                                showingAddMilestoneSheet = true
                            } label: {
                                Label("Add Milestone", systemImage: "trophy")
                            }
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        }
                    }
                }
            }
        }
        .task {
            await loadData()
        }
        .sheet(isPresented: $showingAddProgressSheet) {
            AddProgressSheet(client: client) {
                Task { await loadData() }
            }
        }
        .sheet(isPresented: $showingAddMilestoneSheet) {
            AddMilestoneSheet(client: client) {
                Task { await loadData() }
            }
        }
        .sheet(isPresented: $showingExport) {
            ExportProgressView(client: client, progressService: progressService)
        }
    }
    
    // MARK: - Progress Stats Header
    private var progressStatsHeader: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                HStack {
                    Text("Progress Overview")
                        .font(MovefullyTheme.Typography.title3)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Spacer()
                }
                
                HStack(spacing: MovefullyTheme.Layout.paddingL) {
                    ProgressStatView(
                        title: "Total Updates",
                        value: "\(progressEntries.count)",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                    
                    ProgressStatView(
                        title: "This Month",
                        value: "\(entriesThisMonth)",
                        icon: "calendar.badge.checkmark"
                    )
                    
                    ProgressStatView(
                        title: "Milestones",
                        value: "\(milestones.count)",
                        icon: "trophy"
                    )
                }
            }
        }
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                // All Categories
                categoryFilterButton(
                    title: "All",
                    icon: "list.bullet",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                // Individual Categories
                ForEach(ProgressCategory.allCases, id: \.self) { category in
                    categoryFilterButton(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
        }
    }
    
    private func categoryFilterButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(title)
                    .font(MovefullyTheme.Typography.callout)
            }
            .foregroundColor(isSelected ? .white : MovefullyTheme.Colors.textSecondary)
            .padding(.horizontal, MovefullyTheme.Layout.paddingM)
            .padding(.vertical, MovefullyTheme.Layout.paddingS)
            .background(
                isSelected 
                    ? MovefullyTheme.Colors.primaryTeal
                    : MovefullyTheme.Colors.cardBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            .shadow(color: isSelected ? MovefullyTheme.Colors.primaryTeal.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Progress Entries Section
    private var progressEntriesSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                Text("Progress Updates")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            if filteredProgressEntries.isEmpty {
                MovefullyEmptyState(
                    icon: "chart.line.uptrend.xyaxis",
                    title: selectedCategory == nil ? "No Progress Updates" : "No Updates in \(selectedCategory?.displayName ?? "")",
                    description: "Use the + button to start tracking progress measurements and changes",
                    actionButton: nil
                )
            } else {
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    let entriesToShow = showingAllProgressEntries ? filteredProgressEntries : Array(filteredProgressEntries.prefix(3))
                    
                    List {
                        ForEach(entriesToShow) { entry in
                            ProgressEntryCard(entry: entry)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: MovefullyTheme.Layout.paddingS, leading: 0, bottom: MovefullyTheme.Layout.paddingS, trailing: 0))
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let entryToDelete = entriesToShow[index]
                                deleteProgressEntry(entryToDelete)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .frame(height: CGFloat(entriesToShow.count) * 120) // Approximate height per entry
                    .scrollDisabled(true)
                    
                    if filteredProgressEntries.count > 3 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingAllProgressEntries.toggle()
                            }
                        } label: {
                            HStack {
                                Text(showingAllProgressEntries ? "Show less" : "Show \(filteredProgressEntries.count - 3) more updates")
                                    .font(MovefullyTheme.Typography.callout)
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                
                                Image(systemName: showingAllProgressEntries ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            }
                            .padding(.vertical, MovefullyTheme.Layout.paddingS)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Milestones Section
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                Text("Milestones")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            if milestones.isEmpty {
                MovefullyEmptyState(
                    icon: "trophy",
                    title: "No Milestones Yet",
                    description: "Celebrate achievements and progress markers",
                    actionButton: nil
                )
            } else {
                List {
                    ForEach(milestones) { milestone in
                        MilestoneCard(milestone: milestone)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let milestoneToDelete = milestones[index]
                            deleteMilestone(milestoneToDelete)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .frame(height: CGFloat(milestones.count) * 120) // Proper height for title + category + description + date
                .scrollDisabled(true)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var entriesThisMonth: Int {
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        return progressEntries.filter { $0.timestamp >= startOfMonth }.count
    }
    
    private var filteredProgressEntries: [ProgressEntry] {
        if let selectedCategory = selectedCategory {
            return progressEntries.filter { $0.field.category == selectedCategory }
        }
        return progressEntries
    }
    
    // MARK: - Data Loading
    private func loadData() async {
        isLoading = true
        
        do {
            async let progressData = progressService.fetchProgressEntries(for: client.id)
            async let milestoneData = progressService.fetchMilestones(for: client.id)
            
            let (entries, achievements) = try await (progressData, milestoneData)
            
            await MainActor.run {
                self.progressEntries = entries
                self.milestones = achievements
                self.isLoading = false
            }
        } catch {
            print("❌ Error loading progress data: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Delete Methods
    private func deleteProgressEntry(_ entry: ProgressEntry) {
        Task {
            do {
                try await progressService.deleteProgressEntry(entry.id)
                await loadData()
            } catch {
                print("❌ Error deleting progress entry: \(error)")
            }
        }
    }
    
    private func deleteMilestone(_ milestone: Milestone) {
        Task {
            do {
                try await progressService.deleteMilestone(milestone.id)
                await loadData()
            } catch {
                print("❌ Error deleting milestone: \(error)")
            }
        }
    }
}

// MARK: - Progress Entry Card
struct ProgressEntryCard: View {
    let entry: ProgressEntry
    
    var body: some View {
        MovefullyCard {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                // Field Icon
            VStack {
                    Image(systemName: entry.field.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        .frame(width: 36, height: 36)
                        .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                        .clipShape(Circle())
                    
                    Spacer()
                }
                
                // Content
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                    // Field name and change
                    HStack {
                        Text(entry.field.displayName)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Spacer()
                        
                        Text(entry.timestamp, style: .date)
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                    }
                    
                    // Value change
                    HStack(spacing: MovefullyTheme.Layout.paddingS) {
                        if let oldValue = entry.oldValue {
                            Text(oldValue + (entry.field.unit.isEmpty ? "" : " \(entry.field.unit)"))
                                .font(MovefullyTheme.Typography.callout)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .strikethrough()
                            
                            Image(systemName: "arrow.forward")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(MovefullyTheme.Colors.textTertiary)
                        }
                        
                        Text(entry.newValue + (entry.field.unit.isEmpty ? "" : " \(entry.field.unit)"))
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    }
                    
                    // Note if available
                    if let note = entry.note, !note.isEmpty {
                        Text(note)
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(2)
                    }
                    

                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Milestone Card
struct MilestoneCard: View {
    let milestone: Milestone
    
    var body: some View {
        MovefullyCard {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                // Trophy Icon
                VStack {
                    Image(systemName: milestone.category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            LinearGradient(
                                colors: [MovefullyTheme.Colors.warmOrange, MovefullyTheme.Colors.warmOrange.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                    
                    Spacer()
                }
                
                // Content
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                    // Title and date
                    HStack {
                        Text(milestone.title)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Spacer()
                        
                        Text(milestone.achievedDate, style: .date)
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                    }
                    
                    // Category badge
                    MovefullyPill(
                        title: milestone.category.displayName,
                        isSelected: false,
                        style: .tag,
                        action: {}
                    )
                    
                    // Description if available
                    if let description = milestone.description, !description.isEmpty {
                        Text(description)
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                    

                }
                
                Spacer()
            }
        }
    }
}

struct AddProgressSheet: View {
    let client: Client
    let onComplete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var progressService = ProgressHistoryService()
    
    @State private var selectedField: ProgressField = .weight
    @State private var newValue: String = ""
    @State private var isLoading = false
    
    // Filter out muscleMass for UI display
    private var availableProgressFields: [ProgressField] {
        ProgressField.allCases.filter { $0 != .muscleMass }
    }
    
    init(client: Client, onComplete: (() -> Void)? = nil) {
        self.client = client
        self.onComplete = onComplete
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Header
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text("Add Progress Update")
                    .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                        Text("Track changes in measurements and goals")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Field Selection
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Measurement Type")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: MovefullyTheme.Layout.paddingM) {
                            ForEach(availableProgressFields, id: \.self) { field in
                                fieldSelectionButton(field: field)
                            }
                        }
                    }
                    
                    // Value Input
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("New Value")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        HStack {
                            MovefullyTextField(
                                placeholder: selectedField.isNumeric ? "Enter number" : "Enter value",
                                text: $newValue
                            )
                            .keyboardType(selectedField.isNumeric ? .decimalPad : .default)
                            
                            if !selectedField.unit.isEmpty {
                                Text(selectedField.unit)
                                    .font(MovefullyTheme.Typography.body)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .padding(.leading, MovefullyTheme.Layout.paddingS)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.top, MovefullyTheme.Layout.paddingL)
            }
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await saveProgress() }
                    }
                    .disabled(newValue.isEmpty || isLoading)
                }
            }
        }
    }
    
    private func fieldSelectionButton(field: ProgressField) -> some View {
        Button {
            selectedField = field
        } label: {
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                Image(systemName: field.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(selectedField == field ? .white : MovefullyTheme.Colors.primaryTeal)
                
                Text(field.displayName)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(selectedField == field ? .white : MovefullyTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MovefullyTheme.Layout.paddingM)
            .background(
                selectedField == field 
                    ? MovefullyTheme.Colors.primaryTeal
                    : MovefullyTheme.Colors.cardBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            .shadow(color: selectedField == field ? MovefullyTheme.Colors.primaryTeal.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func saveProgress() async {
        isLoading = true
        
        // Get current value for comparison (placeholder implementation)
        let currentValue: String? = nil // This would come from client data
        
        let entry = ProgressEntry(
            clientId: client.id,
            field: selectedField,
            oldValue: currentValue,
            newValue: newValue,
            changedBy: "trainer", // This would come from current user
            changedByName: "Trainer", // This would come from current user
            note: nil
        )
        
        do {
            try await progressService.addProgressEntry(entry)
            
            // Invalidate progress cache so it refreshes with new data
            await ProgressDataCacheService.shared.invalidateCache()
            
            await MainActor.run {
                onComplete?()
                dismiss()
            }
        } catch {
            print("❌ Error saving progress: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct AddMilestoneSheet: View {
    let client: Client
    let onComplete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var progressService = ProgressHistoryService()
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedCategory: MilestoneCategory = .custom
    @State private var achievedDate: Date = Date()
    @State private var isLoading = false
    
    init(client: Client, onComplete: (() -> Void)? = nil) {
        self.client = client
        self.onComplete = onComplete
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Header
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text("Add Milestone")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Celebrate achievements and progress markers")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Title Input
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Title")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        MovefullyTextField(
                            placeholder: "Enter milestone title...",
                            text: $title
                        )
                    }
                    
                    // Category Selection
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Category")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: MovefullyTheme.Layout.paddingM) {
                            ForEach(MilestoneCategory.allCases, id: \.self) { category in
                                categorySelectionButton(category: category)
                            }
                        }
                    }
                    
                    // Date Selection
                    HStack {
                        Text("Achievement Date")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Spacer()
                        
                        DatePicker("", selection: $achievedDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .accentColor(MovefullyTheme.Colors.primaryTeal)
                    }
                    
                    // Description Input
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Description (Required)")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        MovefullyTextEditor(
                            placeholder: "Describe this milestone (required)...",
                            text: $description
                        )
                        .frame(height: 80)
                        .onChange(of: description) { newValue in
                            if newValue.count > 70 {
                                description = String(newValue.prefix(70))
                            }
                        }
                        
                        // Character count
                        HStack {
                            Spacer()
                            Text("\(description.count)/70")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(description.count > 60 ? MovefullyTheme.Colors.warmOrange : MovefullyTheme.Colors.textTertiary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.top, MovefullyTheme.Layout.paddingL)
            }
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await saveMilestone() }
                    }
                    .disabled(title.isEmpty || description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
        }
    }
    
    private func categorySelectionButton(category: MilestoneCategory) -> some View {
        Button {
            selectedCategory = category
        } label: {
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                Image(systemName: category.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(selectedCategory == category ? .white : MovefullyTheme.Colors.warmOrange)
                
                Text(category.displayName)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(selectedCategory == category ? .white : MovefullyTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MovefullyTheme.Layout.paddingM)
            .background(
                selectedCategory == category 
                    ? MovefullyTheme.Colors.warmOrange
                    : MovefullyTheme.Colors.cardBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            .shadow(color: selectedCategory == category ? MovefullyTheme.Colors.warmOrange.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func saveMilestone() async {
        isLoading = true
        
        let milestone = Milestone(
            clientId: client.id,
            title: title,
            description: description,
            achievedDate: achievedDate,
            createdBy: "trainer", // This would come from current user
            createdByName: "Trainer", // This would come from current user
            category: selectedCategory,
            isAutomatic: false
        )
        
        do {
            try await progressService.addMilestone(milestone)
            
            await MainActor.run {
                onComplete?()
                dismiss()
            }
        } catch {
            print("❌ Error saving milestone: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Export Progress View
struct ExportProgressView: View {
    let client: Client
    let progressService: ProgressHistoryService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .csv
    @State private var isExporting = false
    @State private var exportCompleted = false
    @State private var exportedData: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                // Header
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                    Text("Export Progress Data")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("Export all progress entries and milestones for \(client.name)")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Format Selection
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                    Text("Export Format")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        formatSelectionButton(
                            format: .csv,
                            title: "CSV (Comma-Separated Values)",
                            subtitle: "Best for Excel and spreadsheet apps",
                            icon: "tablecells"
                        )
                        
                        formatSelectionButton(
                            format: .json,
                            title: "JSON (JavaScript Object Notation)",
                            subtitle: "Best for technical use and data analysis",
                            icon: "doc.text"
                        )
                    }
                }
                
                if exportCompleted {
                    // Export Preview
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Export Preview")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        ScrollView {
                            Text(exportedData)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(MovefullyTheme.Layout.paddingM)
                                .background(MovefullyTheme.Colors.backgroundSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
                        }
                        .frame(maxHeight: 200)
                        
                        // Share Button
                        Button {
                            shareExportedData()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Export")
                            }
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MovefullyTheme.Layout.paddingM)
                            .background(MovefullyTheme.Colors.primaryTeal)
                            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                        }
                    }
                } else {
                    // Export Button
                    Button {
                        Task { await exportData() }
                    } label: {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            
                            Text(isExporting ? "Exporting..." : "Export Data")
                        }
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MovefullyTheme.Layout.paddingM)
                        .background(isExporting ? MovefullyTheme.Colors.textSecondary : MovefullyTheme.Colors.primaryTeal)
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    }
                    .disabled(isExporting)
                }
                
                Spacer()
            }
            .padding(MovefullyTheme.Layout.paddingL)
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func formatSelectionButton(format: ExportFormat, title: String, subtitle: String, icon: String) -> some View {
        Button {
            selectedFormat = format
        } label: {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(selectedFormat == format ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.textSecondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: selectedFormat == format ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(selectedFormat == format ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.textTertiary)
            }
            .padding(MovefullyTheme.Layout.paddingM)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            .overlay(
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                    .stroke(selectedFormat == format ? MovefullyTheme.Colors.primaryTeal : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func exportData() async {
        isExporting = true
        
        do {
            let data = try await progressService.exportProgressData(for: client.id, format: selectedFormat)
            
            await MainActor.run {
                self.exportedData = data
                self.exportCompleted = true
                self.isExporting = false
            }
        } catch {
            print("❌ Error exporting data: \(error)")
            await MainActor.run {
                self.isExporting = false
            }
        }
    }
    
    private func shareExportedData() {
        let fileName = "progress_export_\(client.name.replacingOccurrences(of: " ", with: "_")).\(selectedFormat == .csv ? "csv" : "json")"
        
        guard let data = exportedData.data(using: .utf8) else { return }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            
            let activityController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                
                // Handle iPad presentation
                if let popover = activityController.popoverPresentationController {
                    popover.sourceView = rootViewController.view
                    popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                rootViewController.present(activityController, animated: true)
            }
        } catch {
            print("❌ Error sharing export: \(error)")
        }
    }
}

// MARK: - Progress Chart View
struct ProgressChartView: View {
    let entries: [ProgressEntry]
    @State private var selectedField: ProgressField = .weight
    @State private var selectedPeriod: ChartPeriod = .oneMonth
    
    enum ChartPeriod: String, CaseIterable {
        case oneMonth = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"
        case max = "Max"
        
        var days: Int {
            switch self {
            case .oneMonth: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .oneYear: return 365
            case .max: return Int.max
            }
        }
        
        var displayName: String {
            switch self {
            case .oneMonth: return "1 Month"
            case .threeMonths: return "3 Months"
            case .sixMonths: return "6 Months"  
            case .oneYear: return "1 Year"
            case .max: return "All Time"
            }
        }
    }
    
    // Filter out muscleMass for chart display
    private var availableFields: [ProgressField] {
        let fieldsWithData = Set(entries.map { $0.field })
        return ProgressField.allCases.filter { field in
            field != .muscleMass && fieldsWithData.contains(field)
        }
    }
    
    private var filteredEntries: [ProgressEntry] {
        let calendar = Calendar.current
        let cutoffDate = selectedPeriod == .max ? Date.distantPast : calendar.date(byAdding: .day, value: -selectedPeriod.days, to: Date()) ?? Date()
        
        return entries
            .filter { $0.field == selectedField && $0.timestamp >= cutoffDate }
            .sorted { $0.timestamp < $1.timestamp }
    }
    
    var body: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                // Header
                Text("Progress Trend")
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                if availableFields.isEmpty {
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2)
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                        
                        Text("No data to display")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 80)
                } else {
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        // Field Filter Pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                ForEach(availableFields, id: \.self) { field in
                                    MovefullyPill(
                                        title: field.displayName,
                                        isSelected: selectedField == field,
                                        style: .filter
                                    ) {
                                        selectedField = field
                                    }
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                        
                        // Time Period Pills  
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                ForEach(ChartPeriod.allCases, id: \.self) { period in
                                    MovefullyPill(
                                        title: period.rawValue,
                                        isSelected: selectedPeriod == period,
                                        style: .tag
                                    ) {
                                        selectedPeriod = period
                                    }
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                        
                        // Chart Area
                        chartContent
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var chartContent: some View {
        if filteredEntries.isEmpty {
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
                
                Text("No \(selectedField.displayName.lowercased()) data for \(selectedPeriod.displayName.lowercased())")
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
        } else {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                // Chart visualization
                chartVisualization
                
                // Chart info
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(selectedField.displayName) (\(selectedPeriod.displayName))")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        if let latest = filteredEntries.last, let first = filteredEntries.first, filteredEntries.count > 1 {
                            let change = calculateChange(from: first.newValue, to: latest.newValue)
                            Text(change)
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(change.contains("+") ? MovefullyTheme.Colors.softGreen : change.contains("-") ? MovefullyTheme.Colors.warmOrange : MovefullyTheme.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(filteredEntries.count) data points")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private var chartVisualization: some View {
        let maxEntries = min(filteredEntries.count, 20) // Show up to 20 points
        let displayEntries = Array(filteredEntries.suffix(maxEntries))
        
        if displayEntries.count == 1 {
            // Single data point
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                Circle()
                    .fill(MovefullyTheme.Colors.primaryTeal)
                    .frame(width: 8, height: 8)
                
                Text("\(displayEntries[0].newValue)\(selectedField.unit.isEmpty ? "" : " \(selectedField.unit)")")
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
        } else {
            // Multiple data points - simple line chart representation
            let values = displayEntries.compactMap { Double($0.newValue) }
            if values.isEmpty {
                EmptyView()
            } else {
                let minValue = values.min() ?? 0
                let maxValue = values.max() ?? 0
                let range = maxValue - minValue
            
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(displayEntries.indices, id: \.self) { index in
                        let entry = displayEntries[index]
                        let value = Double(entry.newValue) ?? 0
                        let normalizedHeight = range > 0 ? (value - minValue) / range : 0.5
                        let barHeight = max(8, normalizedHeight * 80)
                        
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(MovefullyTheme.Colors.primaryTeal)
                                .frame(width: max(8, 120 / CGFloat(displayEntries.count)), height: barHeight)
                            
                            if displayEntries.count <= 10 {
                                Text(formatShortDate(entry.timestamp))
                                    .font(.system(size: 6))
                                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                    .rotationEffect(.degrees(-45))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .padding(.horizontal, MovefullyTheme.Layout.paddingS)
            }
        }
    }
    
    private func calculateChange(from first: String, to last: String) -> String {
        guard let firstValue = Double(first), let lastValue = Double(last) else {
            return "No change"
        }
        
        let change = lastValue - firstValue
        let sign = change > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", change))\(selectedField.unit.isEmpty ? "" : " \(selectedField.unit)")"
    }
        
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

// MARK: - Progress Analytics View
struct ProgressAnalyticsView: View {
    let client: Client
    let progressService: ProgressHistoryService
    @Environment(\.dismiss) private var dismiss
    @State private var analytics: ProgressAnalytics?
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    if isLoading {
                        ProgressView("Loading analytics...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let analytics = analytics {
                        analyticsContent(analytics)
                    } else {
                        MovefullyEmptyState(
                            icon: "chart.bar",
                            title: "No Analytics Available",
                            description: "Add some progress entries to see analytics",
                            actionButton: nil
                        )
                    }
                }
                .padding(MovefullyTheme.Layout.paddingL)
            }
            .movefullyBackground()
            .navigationTitle("Progress Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            await loadAnalytics()
        }
    }
    
    @ViewBuilder
    private func analyticsContent(_ analytics: ProgressAnalytics) -> some View {
        // Summary Stats
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            Text("Summary")
                .font(MovefullyTheme.Typography.title3)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: MovefullyTheme.Layout.paddingM) {
                analyticsCard(
                    title: "Total Entries",
                    value: "\(analytics.totalEntries)",
                    icon: "chart.line.uptrend.xyaxis",
                    color: MovefullyTheme.Colors.primaryTeal
                )
                
                analyticsCard(
                    title: "Weekly Average",
                    value: String(format: "%.1f", analytics.averageEntriesPerWeek),
                    icon: "calendar.badge.checkmark",
                    color: MovefullyTheme.Colors.gentleBlue
                )
                
                analyticsCard(
                    title: "Most Tracked",
                    value: analytics.mostTrackedField?.displayName ?? "None",
                    icon: "target",
                    color: MovefullyTheme.Colors.softGreen
                )
                
                analyticsCard(
                    title: "Active Days",
                    value: "\(analytics.weeklyActivity.count)",
                    icon: "flame",
                    color: MovefullyTheme.Colors.warmOrange
                )
            }
        }
        
        // Field Breakdown
        if !analytics.fieldBreakdown.isEmpty {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                Text("Tracking Breakdown")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                MovefullyCard {
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        ForEach(analytics.fieldBreakdown.sorted(by: { $0.value > $1.value }), id: \.key) { field, count in
                            HStack {
                                Image(systemName: field.icon)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                    .frame(width: 20)
                                
                                Text(field.displayName)
                                    .font(MovefullyTheme.Typography.body)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Spacer()
                                
                                Text("\(count)")
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                
                                // Progress bar
                                let percentage = Double(count) / Double(analytics.totalEntries)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(MovefullyTheme.Colors.primaryTeal.opacity(0.3))
                                    .frame(width: 40, height: 4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(MovefullyTheme.Colors.primaryTeal)
                                            .frame(width: 40 * percentage, height: 4),
                                        alignment: .leading
                                    )
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func analyticsCard(title: String, value: String, icon: String, color: Color) -> some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(title)
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    private func loadAnalytics() async {
        do {
            let analyticsData = try await progressService.getProgressAnalytics(for: client.id, days: 90)
            
            await MainActor.run {
                self.analytics = analyticsData
                self.isLoading = false
            }
        } catch {
            print("❌ Error loading analytics: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

// MARK: - Messages Navigation Wrapper
struct MessagesNavigationWrapper: View {
    let clientId: String
    let clientName: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var messagesService = MessagesService()
    @State private var conversation: Conversation?
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(MovefullyTheme.Colors.primaryTeal)
                        
                        Text("Opening conversation...")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .movefullyBackground()
                } else if let conversation = conversation {
                    TrainerConversationDetailView(conversation: conversation)
                } else {
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(MovefullyTheme.Colors.warmOrange)
                        
                        Text("Unable to open conversation")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Please try again from the Messages tab")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Close") {
                            dismiss()
                        }
                        .font(MovefullyTheme.Typography.buttonMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                        .padding(.vertical, MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.primaryTeal)
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .movefullyBackground()
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            createOrFindConversation()
        }
    }
    
    private func createOrFindConversation() {
        Task {
            do {
                guard let trainerId = Auth.auth().currentUser?.uid else {
                    throw NSError(domain: "MessagesNavigationWrapper", code: 401, 
                                 userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                }
                
                print("🔍 MessagesNavigationWrapper: Creating/finding conversation for client: \(clientName)")
                
                // Get or create the conversation
                let conversationId = try await messagesService.getOrCreateConversation(
                    trainerId: trainerId,
                    clientId: clientId,
                    clientName: clientName
                )
                
                // Create the conversation object
                let newConversation = Conversation(
                    id: conversationId,
                    trainerId: trainerId,
                    clientId: clientId,
                    clientName: clientName,
                    lastMessage: "",
                    lastMessageTime: Date(),
                    unreadCount: 0
                )
                
                await MainActor.run {
                    self.conversation = newConversation
                    self.isLoading = false
                    print("✅ MessagesNavigationWrapper: Successfully created conversation: \(conversationId)")
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("❌ MessagesNavigationWrapper: Error creating conversation: \(error)")
                }
            }
        }
    }
}

// MARK: - Trainer Delete Client Confirmation View

struct TrainerDeleteClientConfirmationView: View {
    let client: Client
    @ObservedObject var deletionService: ClientDeletionService
    let onCancel: () -> Void
    let onComplete: () -> Void
    
    @State private var confirmationText = ""
    @State private var showError = false
    @Environment(\.dismiss) private var dismiss
    
    private var requiredText: String {
        "DELETE \(client.name.uppercased())"
    }
    
    private var isConfirmationValid: Bool {
        confirmationText.uppercased() == requiredText
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                // Warning header
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(MovefullyTheme.Colors.warning)
                    
                    Text("Delete Client")
                        .font(MovefullyTheme.Typography.title1)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("This action cannot be undone")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, MovefullyTheme.Layout.paddingXL)
                
                // Consequences list
                MovefullyCard {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("What will be deleted:")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            TrainerDeleteConsequenceRow(text: "All workout history and progress")
                            TrainerDeleteConsequenceRow(text: "All messages and conversations")
                            TrainerDeleteConsequenceRow(text: "All body measurements and milestones")
                            TrainerDeleteConsequenceRow(text: "All notes and plan assignments")
                            TrainerDeleteConsequenceRow(text: "Client will be removed from your list")
                        }
                        
                        Text("Note: This will NOT delete their authentication account - they can still sign in and connect to a different trainer.")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .padding(.top, MovefullyTheme.Layout.paddingS)
                            .italic()
                    }
                }
                
                // Confirmation input
                MovefullyCard {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Type '\(requiredText)' to confirm:")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        MovefullyTextField(
                            placeholder: "Type here to confirm...",
                            text: $confirmationText
                        )
                        
                        if !confirmationText.isEmpty && !isConfirmationValid {
                            Text("Text doesn't match. Please type exactly: \(requiredText)")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.warning)
                        }
                    }
                }
                
                // Progress indicator
                if deletionService.isDeleting {
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(MovefullyTheme.Colors.warning)
                        
                        Text(deletionService.deletionProgress)
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(MovefullyTheme.Layout.paddingL)
                }
                
                Spacer()
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            .movefullyBackground()
            .navigationTitle("Delete Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .disabled(deletionService.isDeleting)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete") {
                        deleteClient()
                    }
                    .foregroundColor(MovefullyTheme.Colors.warning)
                    .disabled(!isConfirmationValid || deletionService.isDeleting)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(deletionService.errorMessage ?? "An error occurred while deleting the client.")
        }
    }
    
    private func deleteClient() {
        Task {
            do {
                guard let trainerId = Auth.auth().currentUser?.uid else {
                    throw NSError(domain: "TrainerDeleteClient", code: 401, userInfo: [NSLocalizedDescriptionKey: "Trainer not authenticated"])
                }
                try await deletionService.deleteClientFromTrainer(clientId: client.id, trainerId: trainerId)
                await MainActor.run {
                    deletionService.cleanup()
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    deletionService.errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct TrainerDeleteConsequenceRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingS) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(MovefullyTheme.Colors.warning)
            
            Text(text)
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
            
            Spacer()
        }
    }
} 

// MARK: - Plan Promotion Timing Modal
struct PlanPromotionTimingModal: View {
    let client: Client
    let onStartNow: () -> Void
    let onKeepSchedule: () -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assignmentService = ClientPlanAssignmentService()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                // Header icon
                ZStack {
                    Circle()
                        .fill(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
                .padding(.top, MovefullyTheme.Layout.paddingL)
                
                // Title and description
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Text("Plan Promoted!")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("The upcoming plan has been promoted to current. When would you like it to start?")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                // Options
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Start Now option
                    PromotionTimingOption(
                        title: "Start Today",
                        subtitle: assignmentService.getTodayProgramDayDescription(),
                        icon: "play.circle.fill",
                        color: MovefullyTheme.Colors.primaryTeal,
                        isRecommended: true
                    ) {
                        onStartNow()
                        dismiss()
                    }
                    
                    // Keep schedule option  
                    PromotionTimingOption(
                        title: "Keep Original Schedule",
                        subtitle: formatScheduleDescription(),
                        icon: "calendar",
                        color: MovefullyTheme.Colors.gentleBlue,
                        isRecommended: false
                    ) {
                        onKeepSchedule()
                        dismiss()
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
            .movefullyBackground()
            .navigationTitle("Plan Timing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
    }
    
    private func formatScheduleDescription() -> String {
        guard let startDate = client.nextPlanStartDate else {
            return "Will start as originally scheduled"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Will start \(formatter.string(from: startDate)) at Day 1"
    }
}

struct PromotionTimingOption: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isRecommended: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MovefullyTheme.Layout.paddingL) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    HStack {
                        Text(title)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        if isRecommended {
                            Text("RECOMMENDED")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                                .padding(.vertical, 2)
                                .background(MovefullyTheme.Colors.primaryTeal)
                                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
                        }
                        
                        Spacer()
                    }
                    
                    Text(subtitle)
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
            }
            .padding(MovefullyTheme.Layout.paddingL)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}