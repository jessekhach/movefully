import SwiftUI

struct ProgramsManagementView: View {
    @StateObject private var viewModel = ProgramsViewModel()
    @State private var searchText = ""
    @State private var showingCreatePlan = false
    
    var body: some View {
        MovefullyTrainerNavigation(
            title: "Plans",
            showProfileButton: false,
            trailingButton: MovefullyStandardNavigation.ToolbarButton(
                icon: "plus",
                action: { showingCreatePlan = true },
                accessibilityLabel: "Create Plan"
            )
        ) {
            // Search field inside navigation content
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                MovefullySearchField(
                    placeholder: "Search plans...",
                    text: $searchText
                )
            }
            .padding(.vertical, MovefullyTheme.Layout.paddingS)
            
            // Plans content
            programsContent
        }
        .sheet(isPresented: $showingCreatePlan) {
            CreatePlanView()
                .environmentObject(viewModel)
        }
    }
    
    
    
    // MARK: - Plans Content
    @ViewBuilder
    private var programsContent: some View {
        let filteredPrograms = viewModel.programs.filter { program in
            searchText.isEmpty || program.name.localizedCaseInsensitiveContains(searchText) ||
            program.description.localizedCaseInsensitiveContains(searchText)
        }
        
        if viewModel.isLoading {
            MovefullyLoadingState(message: "Loading programs...")
        } else if filteredPrograms.isEmpty {
            plansEmptyState
        } else {
            ForEach(filteredPrograms) { program in
                ProgramCard(program: program) {
                    // Handle program selection
                }
            }
        }
    }
    
    // MARK: - Empty States
    private var plansEmptyState: some View {
        MovefullyEmptyState(
            icon: searchText.isEmpty ? "calendar.badge.plus" : "magnifyingglass",
            title: searchText.isEmpty ? "Start building plans" : "No plans found",
            description: searchText.isEmpty ? 
                "Create complete plans using your workout templates. These plans can then be assigned to clients." : 
                "Try adjusting your search terms to find the plan you're looking for.",
            actionButton: searchText.isEmpty ? 
                MovefullyEmptyState.ActionButton(
                    title: "Create Your First Plan",
                    action: { showingCreatePlan = true }
                ) : nil
        )
    }
}





// MARK: - Program Card
struct ProgramCard: View {
    let program: Program
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                // Header with program info
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Program Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                            .fill(programColor.opacity(0.15))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: programIcon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(programColor)
                    }
                    
                    // Program Info
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                        HStack {
                            Text(program.name)
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            DifficultyBadge(difficulty: program.difficulty)
                        }
                        
                        Text(program.description)
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                // Program stats
                HStack(spacing: MovefullyTheme.Layout.paddingL) {
                    ProgramStatView(
                        icon: "calendar",
                        value: program.durationText,
                        label: "duration"
                    )
                    
                    ProgramStatView(
                        icon: "dumbbell",
                        value: "\(program.workoutCount)",
                        label: "workouts"
                    )
                    
                    ProgramStatView(
                        icon: "person.2",
                        value: "\(program.usageCount)",
                        label: "assigned"
                    )
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                }
                
                // Tags (if any)
                if !program.tags.isEmpty {
                    HStack {
                        ForEach(program.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                                .padding(.vertical, 4)
                                .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        
                        if program.tags.count > 3 {
                            Text("+\(program.tags.count - 3)")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textTertiary)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(MovefullyTheme.Layout.paddingL)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var programColor: Color {
        switch program.difficulty {
        case .beginner:
            return MovefullyTheme.Colors.softGreen
        case .intermediate:
            return MovefullyTheme.Colors.primaryTeal
        case .advanced:
            return MovefullyTheme.Colors.warmOrange
        }
    }
    
    private var programIcon: String {
        if program.tags.contains("Strength") {
            return "dumbbell.fill"
        } else if program.tags.contains("HIIT") || program.tags.contains("Cardio") {
            return "heart.fill"
        } else if program.tags.contains("Recovery") || program.tags.contains("Mobility") {
            return "leaf.fill"
        } else {
            return "calendar.badge.plus"
        }
    }
}

// MARK: - Supporting Views
struct ProgramStatView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingXS) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(MovefullyTheme.Colors.textTertiary)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
            }
        }
    }
}





// MARK: - Placeholder Views for Sheets
struct CreatePlanView: View {
    @EnvironmentObject var viewModel: ProgramsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Text("Create Plan")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("Build a complete plan using your workout templates that can be assigned to clients")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Button("Close") {
                    dismiss()
                }
                .movefullyButtonStyle(.primary)
            }
            .padding(MovefullyTheme.Layout.paddingXL)
            .navigationTitle("Create Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
    }
} 