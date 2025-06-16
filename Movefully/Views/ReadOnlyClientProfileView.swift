import SwiftUI
import FirebaseFirestore

struct ReadOnlyClientProfileView: View {
    let client: Client
    @Environment(\.dismiss) private var dismiss
    @State private var currentPlan: WorkoutPlan?
    @State private var isLoadingPlan = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Header Section
                    clientHeaderSection
                    
                    // Profile Information
                    profileInformationSection
                    
                    // Current Plan (Read-Only)
                    currentPlanSection
                    

                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.top, MovefullyTheme.Layout.paddingL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXL)
            }
            .movefullyBackground()
            .navigationTitle("Client Profile")
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
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text(client.email)
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
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
                        Text(lastActivityText)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    }
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
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Goal
                    if let goals = client.goals, !goals.isEmpty {
                        ReadOnlyProfileInfoItem(label: "Goal", value: goals, fullWidth: true)
                    } else {
                        ReadOnlyProfileInfoItem(label: "Goal", value: "No specific goal set", fullWidth: true)
                    }
                    
                    // Injuries/Notes
                    if let injuries = client.injuries, !injuries.isEmpty {
                        ReadOnlyProfileInfoItem(label: "Injuries/Notes", value: injuries, fullWidth: true)
                    } else {
                        ReadOnlyProfileInfoItem(label: "Injuries/Notes", value: "No injuries or notes", fullWidth: true)
                    }
                    
                    // Preferred Style
                    if let coachingStyle = client.preferredCoachingStyle {
                        ReadOnlyProfileInfoItem(label: "Preferred Style", value: coachingStyle.rawValue, fullWidth: true)
                    } else {
                        ReadOnlyProfileInfoItem(label: "Preferred Style", value: "Not specified", fullWidth: true)
                    }
                }
            }
        }
    }
    
    // MARK: - Current Plan Section (Read-Only)
    private var currentPlanSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            Text("Current Plan")
                .font(MovefullyTheme.Typography.title3)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            if client.currentPlanId != nil {
                if isLoadingPlan {
                    MovefullyCard {
                        VStack(spacing: MovefullyTheme.Layout.paddingM) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading plan details...")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    }
                } else if let plan = currentPlan {
                    MovefullyCard {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                            Text(plan.name)
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Text(plan.description)
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .lineLimit(2)
                            
                            HStack {
                                Label("\(plan.duration) weeks", systemImage: "calendar")
                                Spacer()
                                Label("\(plan.exercisesPerWeek) exercises/week", systemImage: "list.bullet")
                            }
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                    }
                } else {
                    MovefullyCard {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                            Text("Plan Assigned")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Text("A plan has been assigned but details are not available.")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                    }
                }
            } else {
                MovefullyCard {
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Image(systemName: "list.clipboard")
                            .font(.system(size: 40))
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                        
                        Text("No plan assigned")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MovefullyTheme.Layout.paddingL)
                }
            }
        }
        .onAppear {
            loadCurrentPlan()
        }
    }
    

    
    // MARK: - Helper Properties
    private var initials: String {
        let components = client.name.components(separatedBy: " ")
        let firstInitial = components.first?.first ?? Character("")
        let lastInitial = components.count > 1 ? components.last?.first ?? Character("") : Character("")
        return String(firstInitial) + String(lastInitial)
    }
    
    private var joinedDateText: String {
        guard let joinedDate = client.joinedDate else { return "Unknown" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: joinedDate)
    }
    
    private var lastActivityText: String {
        guard let lastActivity = client.lastActivityDate else { return "Never" }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastActivity)
        
        if timeInterval < 3600 { // Less than 1 hour
            let minutes = Int(timeInterval / 60)
            return minutes <= 1 ? "Just now" : "\(minutes) minutes ago"
        } else if timeInterval < 86400 { // Less than 1 day
            let hours = Int(timeInterval / 3600)
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else {
            let days = Int(timeInterval / 86400)
            if days < 7 {
                return days == 1 ? "1 day ago" : "\(days) days ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter.string(from: lastActivity)
            }
        }
    }
    
    // MARK: - Load Current Plan
    private func loadCurrentPlan() {
        guard let planId = client.currentPlanId else {
            currentPlan = nil
            return
        }
        
        isLoadingPlan = true
        
        Task {
            await MainActor.run {
                // First try to find in sample data for demo purposes
                if let samplePlan = WorkoutPlan.samplePlans.first(where: { $0.id.uuidString == planId }) {
                    currentPlan = samplePlan
                    isLoadingPlan = false
                    return
                }
            }
            
            // Load from Firestore programs collection
            do {
                let db = Firestore.firestore()
                let document = try await db.collection("programs").document(planId).getDocument()
                
                await MainActor.run {
                    if document.exists, let data = document.data() {
                        if let name = data["name"] as? String,
                           let description = data["description"] as? String,
                           let duration = data["duration"] as? Int,
                           let difficultyString = data["difficulty"] as? String,
                           let difficulty = WorkoutDifficulty(rawValue: difficultyString) {
                            
                            // Create a WorkoutPlan from the Program data
                            currentPlan = WorkoutPlan(
                                name: name,
                                description: description,
                                difficulty: difficulty,
                                duration: max(1, duration / 7), // Convert days to weeks, minimum 1 week
                                exercisesPerWeek: 3, // Default for now
                                sessionDuration: 60, // Default session duration in minutes
                                tags: data["tags"] as? [String] ?? [],
                                exercises: [], // Programs don't have exercises, they have workout templates
                                assignedClients: 1 // Default assigned clients count
                            )
                        } else {
                            currentPlan = nil
                        }
                    } else {
                        currentPlan = nil
                    }
                    isLoadingPlan = false
                }
            } catch {
                await MainActor.run {
                    currentPlan = nil
                    isLoadingPlan = false
                }
            }
        }
    }
}

// MARK: - Support Components

struct ReadOnlyProfileInfoItem: View {
    let label: String
    let value: String
    var fullWidth: Bool = false
    
    var body: some View {
        VStack(alignment: fullWidth ? .leading : .center, spacing: MovefullyTheme.Layout.paddingXS) {
            Text(label)
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
            
            Text(value)
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                .multilineTextAlignment(fullWidth ? .leading : .center)
        }
        .frame(maxWidth: fullWidth ? .infinity : nil, alignment: fullWidth ? .leading : .center)
    }
}



#Preview {
    ReadOnlyClientProfileView(client: Client.sampleClients[0])
} 