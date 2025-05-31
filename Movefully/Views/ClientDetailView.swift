import SwiftUI
import MessageUI

struct ClientDetailView: View {
    let client: Client
    @StateObject private var viewModel = ClientDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingAssignPlanSheet = false
    @State private var showingAddNoteSheet = false
    @State private var showingMessageComposer = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Header Section
                    clientHeaderSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Smart Alerts
                    if !viewModel.alerts.isEmpty {
                        smartAlertsSection
                    }
                    
                    // Profile Information
                    profileInformationSection
                    
                    // Current Plan
                    currentPlanSection
                    
                    // Progress Overview
                    progressOverviewSection
                    
                    // Recent Notes
                    recentNotesSection
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXL)
            }
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingEditSheet = true }) {
                            Label("Edit Profile", systemImage: "person.crop.circle")
                        }
                        
                        Button(action: { showingAssignPlanSheet = true }) {
                            Label("Assign Plan", systemImage: "list.clipboard")
                        }
                        
                        Divider()
                        
                        Button(action: { viewModel.pauseClient() }) {
                            Label(client.status == .paused ? "Resume Client" : "Pause Client", 
                                  systemImage: client.status == .paused ? "play.circle" : "pause.circle")
                        }
                        
                        Button(role: .destructive, action: { viewModel.archiveClient() }) {
                            Label("Archive Client", systemImage: "archivebox")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadClientData(client)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditClientProfileSheet(client: client)
        }
        .sheet(isPresented: $showingAssignPlanSheet) {
            AssignPlanSheet(client: client)
        }
        .sheet(isPresented: $showingAddNoteSheet) {
            AddNoteSheet(client: client)
        }
    }
    
    // MARK: - Header Section
    private var clientHeaderSection: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Profile Picture
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
                        .overlay(
                            Text(initials)
                                .font(MovefullyTheme.Typography.title1)
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text(client.name)
                            .font(MovefullyTheme.Typography.title3)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        if let email = client.email {
                            Text(email)
                                .font(MovefullyTheme.Typography.body)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                        
                        StatusBadge(status: client.status)
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
                QuickActionButton(
                    title: "Assign Plan",
                    icon: "list.clipboard",
                    color: MovefullyTheme.Colors.primaryTeal
                ) {
                    showingAssignPlanSheet = true
                }
                
                QuickActionButton(
                    title: "Send Message",
                    icon: "message",
                    color: MovefullyTheme.Colors.secondaryPeach
                ) {
                    showingMessageComposer = true
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
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            Text("Attention Needed")
                .font(MovefullyTheme.Typography.title3)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            ForEach(viewModel.alerts, id: \.self) { alert in
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(MovefullyTheme.Colors.warning)
                    
                    Text(alert)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Spacer()
                }
                .padding(MovefullyTheme.Layout.paddingM)
                .background(MovefullyTheme.Colors.warning.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
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
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    if let goal = client.goal {
                        ProfileInfoRow(title: "Goal", value: goal, icon: "target")
                    }
                    
                    if let height = client.height, let weight = client.weight {
                        HStack(spacing: MovefullyTheme.Layout.paddingL) {
                            ProfileInfoRow(title: "Height", value: height, icon: "ruler")
                            ProfileInfoRow(title: "Weight", value: weight, icon: "scalemass")
                        }
                    }
                    
                    if let injuries = client.injuries {
                        ProfileInfoRow(title: "Injuries/Notes", value: injuries, icon: "cross.case")
                    }
                    
                    if let coachingStyle = client.preferredCoachingStyle {
                        ProfileInfoRow(title: "Preferred Style", value: coachingStyle.rawValue, icon: "person.2")
                    }
                }
            }
        }
    }
    
    // MARK: - Current Plan Section
    private var currentPlanSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            Text("Current Plan")
                .font(MovefullyTheme.Typography.title3)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            MovefullyCard {
                if let currentPlan = viewModel.currentPlan {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currentPlan.name)
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                if let description = currentPlan.description {
                                    Text(description)
                                        .font(MovefullyTheme.Typography.callout)
                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button("Edit") {
                                showingAssignPlanSheet = true
                            }
                            .movefullyButtonStyle(.secondary)
                            .frame(width: 60, height: 32)
                        }
                        
                        HStack {
                            Label("\(currentPlan.duration) weeks", systemImage: "calendar")
                            Spacer()
                            Label("\(currentPlan.exerciseIds.count) exercises", systemImage: "list.bullet")
                        }
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                } else {
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Image(systemName: "list.clipboard")
                            .font(.system(size: 32))
                            .foregroundColor(MovefullyTheme.Colors.inactive)
                        
                        Text("No plan assigned")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Button("Assign Plan") {
                            showingAssignPlanSheet = true
                        }
                        .movefullyButtonStyle(.primary)
                        .frame(maxWidth: 120)
                    }
                    .padding(MovefullyTheme.Layout.paddingL)
                }
            }
        }
    }
    
    // MARK: - Progress Overview Section
    private var progressOverviewSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            Text("Progress Overview")
                .font(MovefullyTheme.Typography.title3)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            MovefullyCard {
                HStack(spacing: MovefullyTheme.Layout.paddingL) {
                    ProgressStatView(
                        title: "Workouts",
                        value: "\(client.totalWorkoutsCompleted)",
                        icon: "figure.strengthtraining.traditional"
                    )
                    
                    ProgressStatView(
                        title: "Streak",
                        value: "5 days",
                        icon: "flame"
                    )
                    
                    ProgressStatView(
                        title: "Completion",
                        value: "85%",
                        icon: "chart.pie"
                    )
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
                
                Button("View All") {
                    // Navigate to full notes view
                }
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            }
            
            if viewModel.recentNotes.isEmpty {
                MovefullyCard {
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Image(systemName: "note.text")
                            .font(.system(size: 32))
                            .foregroundColor(MovefullyTheme.Colors.inactive)
                        
                        Text("No notes yet")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Button("Add First Note") {
                            showingAddNoteSheet = true
                        }
                        .movefullyButtonStyle(.secondary)
                        .frame(maxWidth: 120)
                    }
                    .padding(MovefullyTheme.Layout.paddingM)
                }
            } else {
                ForEach(viewModel.recentNotes.prefix(3)) { note in
                    NoteRowView(note: note)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var initials: String {
        let components = client.name.components(separatedBy: " ")
        let firstInitial = components.first?.first?.uppercased() ?? ""
        let lastInitial = components.count > 1 ? (components.last?.first?.uppercased() ?? "") : ""
        return firstInitial + lastInitial
    }
    
    private var joinedDateText: String {
        guard let joinedDate = client.joinedDate else {
            return "Invited"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: joinedDate)
    }
}

// MARK: - Supporting Views
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
            }
            .frame(maxWidth: .infinity)
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
    
    var body: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                HStack {
                    Image(systemName: note.type.icon)
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    
                    Text(note.type.displayName)
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text(RelativeDateTimeFormatter().localizedString(for: note.createdAt, relativeTo: Date()))
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                Text(note.content)
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .lineLimit(3)
            }
        }
    }
}

// MARK: - Placeholder Sheets
struct EditClientProfileSheet: View {
    let client: Client
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Edit Client Profile")
                    .font(MovefullyTheme.Typography.title2)
                
                Text("Feature coming soon...")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct AssignPlanSheet: View {
    let client: Client
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Assign Workout Plan")
                    .font(MovefullyTheme.Typography.title2)
                
                Text("Feature coming soon...")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct AddNoteSheet: View {
    let client: Client
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Add Note")
                    .font(MovefullyTheme.Typography.title2)
                
                Text("Feature coming soon...")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
} 