import SwiftUI

struct ReadOnlyClientProfileView: View {
    let client: Client
    @Environment(\.dismiss) private var dismiss
    
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
                    
                    // Progress Overview
                    progressOverviewSection
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
                        
                        HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                            Image(systemName: "envelope")
                                .font(.system(size: 12))
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            
                            Text(client.email)
                                .font(MovefullyTheme.Typography.body)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                        
                        ReadOnlyClientStatusBadge(status: client.status)
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
    
    // MARK: - Profile Information Section
    private var profileInformationSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            Text("Profile Information")
                .font(MovefullyTheme.Typography.title3)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            MovefullyCard {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                    // Goal
                    if let goals = client.goals, !goals.isEmpty {
                        ReadOnlyProfileInfoRow(title: "Goal", value: goals, icon: "target")
                    } else {
                        ReadOnlyProfileInfoRow(title: "Goal", value: "No specific goal set", icon: "target")
                    }
                    
                    // Height and Weight
                    HStack(spacing: 0) {
                        // Height (left column)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "ruler")
                                    .font(.system(size: 12))
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                
                                Text("Height")
                                    .font(MovefullyTheme.Typography.caption)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            }
                            
                            Text(client.height ?? "Not specified")
                                .font(MovefullyTheme.Typography.body)
                                .foregroundColor(client.height != nil ? MovefullyTheme.Colors.textPrimary : MovefullyTheme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Weight (right column)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "scalemass")
                                    .font(.system(size: 12))
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                
                                Text("Weight")
                                    .font(MovefullyTheme.Typography.caption)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            }
                            
                            Text(client.weight ?? "Not specified")
                                .font(MovefullyTheme.Typography.body)
                                .foregroundColor(client.weight != nil ? MovefullyTheme.Colors.textPrimary : MovefullyTheme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Injuries/Notes
                    if let injuries = client.injuries, !injuries.isEmpty {
                        ReadOnlyProfileInfoRow(title: "Injuries/Notes", value: injuries, icon: "cross.case")
                    } else {
                        ReadOnlyProfileInfoRow(title: "Injuries/Notes", value: "No injuries or notes", icon: "cross.case")
                    }
                    
                    // Preferred Style
                    if let coachingStyle = client.preferredCoachingStyle {
                        ReadOnlyProfileInfoRow(title: "Preferred Style", value: coachingStyle.rawValue, icon: "person.2")
                    } else {
                        ReadOnlyProfileInfoRow(title: "Preferred Style", value: "Not specified", icon: "person.2")
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
                // Mock plan data since we don't have the full plan loaded
                MovefullyCard {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Beginner Strength Foundation")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("A gentle introduction to strength training focusing on form and basic movements.")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(2)
                        
                        HStack {
                            Label("6 weeks", systemImage: "calendar")
                            Spacer()
                            Label("5 exercises", systemImage: "list.bullet")
                        }
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
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
    }
    
    // MARK: - Progress Overview Section
    private var progressOverviewSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            Text("Progress Overview")
                .font(MovefullyTheme.Typography.title3)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            MovefullyCard {
                HStack(spacing: MovefullyTheme.Layout.paddingL) {
                    ReadOnlyProgressStatView(
                        title: "Workouts",
                        value: "\(client.totalWorkoutsCompleted)",
                        icon: "figure.strengthtraining.traditional"
                    )
                    
                    ReadOnlyProgressStatView(
                        title: "Streak",
                        value: "5 days",
                        icon: "flame"
                    )
                    
                    ReadOnlyProgressStatView(
                        title: "Completion",
                        value: "85%",
                        icon: "chart.pie"
                    )
                }
            }
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
}

// MARK: - Support Components

struct ReadOnlyProfileInfoRow: View {
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

struct ReadOnlyProgressStatView: View {
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

struct ReadOnlyClientStatusBadge: View {
    let status: ClientStatus
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingXS) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(status.rawValue.capitalized)
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(statusColor)
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .active:
            return MovefullyTheme.Colors.softGreen
        case .needsAttention:
            return MovefullyTheme.Colors.warmOrange
        case .new:
            return MovefullyTheme.Colors.gentleBlue
        case .paused:
            return MovefullyTheme.Colors.mediumGray
        case .pending:
            return MovefullyTheme.Colors.lavender
        }
    }
}

#Preview {
    ReadOnlyClientProfileView(client: Client.sampleClients[0])
} 