import SwiftUI

struct ClientPlansManagementView: View {
    @StateObject private var viewModel = ProgramsViewModel()
    @State private var searchText = ""
    @State private var showingCreatePlan = false
    
    var body: some View {
        MovefullyTrainerNavigation(
            title: "Plans", 
            showProfileButton: false,
            trailingButton: MovefullyStandardNavigation<AnyView>.ToolbarButton(
                icon: "plus",
                action: { showingCreatePlan = true },
                accessibilityLabel: "Create Plan"
            )
        ) {
            AnyView(
                VStack(spacing: 0) {
                    // Header Description
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Text("Client Training Plans")
                            .font(MovefullyTheme.Typography.title3)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Create and manage structured training programs for your clients")
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    .padding(.bottom, MovefullyTheme.Layout.paddingL)
                    
                    // Search Bar
                    MovefullySearchField(
                        placeholder: "Search plans...",
                        text: $searchText
                    )
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    .padding(.bottom, MovefullyTheme.Layout.paddingM)
                    
                    // Content
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: MovefullyTheme.Layout.paddingL) {
                            plansContent
                        }
                        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                        .padding(.bottom, MovefullyTheme.Layout.paddingXL)
                    }
                }
                .background(MovefullyTheme.Colors.backgroundPrimary)
            )
        }
        .sheet(isPresented: $showingCreatePlan) {
            CreateClientPlanView()
                .environmentObject(viewModel)
        }
        .onAppear {
            // Data loads automatically in ProgramsViewModel init
        }
    }
    
    // MARK: - Plans Content
    @ViewBuilder
    private var plansContent: some View {
        let filteredPlans = viewModel.programs.filter { plan in
            searchText.isEmpty || plan.name.localizedCaseInsensitiveContains(searchText) ||
            plan.description.localizedCaseInsensitiveContains(searchText) ||
            plan.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
        
        if viewModel.isLoading {
            MovefullyLoadingState(message: "Loading plans...")
        } else if filteredPlans.isEmpty {
            plansEmptyState
        } else {
            ForEach(filteredPlans) { plan in
                PlanCard(plan: plan) {
                    // Handle plan selection
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var plansEmptyState: some View {
        MovefullyEmptyState(
            icon: searchText.isEmpty ? "calendar.badge.plus" : "magnifyingglass",
            title: searchText.isEmpty ? "Start creating client plans" : "No plans found",
            description: searchText.isEmpty ? 
                "Build structured training programs for your clients using your workout templates." : 
                "Try adjusting your search terms to find the plan you're looking for.",
            actionButton: searchText.isEmpty ? 
                MovefullyEmptyState.ActionButton(
                    title: "Create Your First Plan",
                    action: { showingCreatePlan = true }
                ) : nil
        )
    }
}

// MARK: - Plan Card
struct PlanCard: View {
    let plan: Program
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                // Header with plan info
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Plan Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                            .fill(planColor.opacity(0.15))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: planIcon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(planColor)
                    }
                    
                    // Plan Info
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                        HStack {
                            Text(plan.name)
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            DifficultyBadge(difficulty: plan.difficulty)
                        }
                        
                        Text(plan.description)
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                // Plan stats
                HStack(spacing: MovefullyTheme.Layout.paddingL) {
                    PlanStatView(
                        icon: "calendar",
                        value: "\(plan.duration / 7)",
                        label: plan.duration / 7 == 1 ? "week" : "weeks"
                    )
                    
                    PlanStatView(
                        icon: "doc.text.below.ecg",
                        value: "\(plan.workoutCount)",
                        label: "workouts"
                    )
                    
                    PlanStatView(
                        icon: "person.2",
                        value: "\(plan.usageCount)",
                        label: "assigned"
                    )
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                }
                
                // Tags (if any)
                if !plan.tags.isEmpty {
                    HStack {
                        ForEach(plan.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                                .padding(.vertical, 4)
                                .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        
                        if plan.tags.count > 3 {
                            Text("+\(plan.tags.count - 3)")
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
    
    private var planColor: Color {
        switch plan.difficulty {
        case .beginner:
            return MovefullyTheme.Colors.softGreen
        case .intermediate:
            return MovefullyTheme.Colors.primaryTeal
        case .advanced:
            return MovefullyTheme.Colors.warmOrange
        }
    }
    
    private var planIcon: String {
        if plan.tags.contains("Strength") {
            return "dumbbell.fill"
        } else if plan.tags.contains("Cardio") || plan.tags.contains("HIIT") {
            return "heart.fill"
        } else if plan.tags.contains("Flexibility") || plan.tags.contains("Yoga") {
            return "figure.yoga"
        } else if plan.tags.contains("Recovery") {
            return "leaf.fill"
        } else {
            return "calendar.badge.plus"
        }
    }
}

// Note: PlanStatView is defined in WorkoutPlansView.swift

// MARK: - Create Plan View
struct CreateClientPlanView: View {
    @EnvironmentObject var viewModel: ProgramsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Text("Create Client Plan")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("Build a structured training program that can be assigned to clients")
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

#Preview {
    ClientPlansManagementView()
} 