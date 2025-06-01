import SwiftUI

struct PlansManagementView: View {
    @StateObject private var viewModel = WorkoutPlansViewModel()
    @State private var selectedFilter: PlanFilter = .all
    @State private var searchText = ""
    @State private var showingCreatePlan = false
    
    var body: some View {
        MovefullyTrainerNavigation(
            title: "Wellness Plans",
            showProfileButton: false
        ) {
            MovefullySearchField(
                placeholder: "Search your wellness plans...",
                text: $searchText
            )
            
            MovefullyFilterPillsRow(
                filters: PlanFilter.allCases,
                selectedFilter: selectedFilter,
                filterTitle: { filter in filter.title },
                onFilterSelected: { filter in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedFilter = filter
                    }
                }
            )
            
            // Content Section
            if viewModel.isLoading {
                MovefullyLoadingState(message: "Loading your wellness plans...")
            } else if filteredPlans.isEmpty {
                MovefullyEmptyState(
                    icon: searchText.isEmpty ? "heart.text.square" : "magnifyingglass",
                    title: searchText.isEmpty ? "Your wellness toolkit awaits" : "No plans found",
                    description: searchText.isEmpty ? 
                        "Create your first wellness plan to guide clients on their movement journey with structure and intention." : 
                        "Try adjusting your search terms or filter to find the plan you're looking for.",
                    actionButton: searchText.isEmpty ? 
                        MovefullyEmptyState.ActionButton(
                            title: "Create Your First Plan",
                            action: { showingCreatePlan = true }
                        ) : nil
                )
            } else {
                MovefullyListLayout(
                    items: filteredPlans,
                    itemView: { plan in
                        PlanRowView(plan: plan) {
                            // Handle plan selection
                        }
                    }
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCreatePlan = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
                .accessibilityLabel("Create Plan")
            }
        }
        .sheet(isPresented: $showingCreatePlan) {
            CreatePlanView()
        }
    }
    
    private var filteredPlans: [WorkoutPlan] {
        var plans = viewModel.workoutPlans
        
        if !searchText.isEmpty {
            plans = plans.filter { plan in
                plan.name.localizedCaseInsensitiveContains(searchText) ||
                plan.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        switch selectedFilter {
        case .all:
            return plans
        case .active:
            return plans.filter { $0.assignedClients > 0 } // Consider active if assigned to clients
        case .draft:
            return plans.filter { $0.assignedClients == 0 } // Consider draft if not assigned
        case .archived:
            return plans.filter { $0.assignedClients == 0 } // Same as draft for now
        }
    }
}

// MARK: - Plan Row View
struct PlanRowView: View {
    let plan: WorkoutPlan
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                // Plan Icon
                ZStack {
                    RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                        .fill(categoryColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: categoryIcon)
                        .font(MovefullyTheme.Typography.title3)
                        .foregroundColor(categoryColor)
                }
                
                // Plan Details
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    HStack {
                        Text(plan.name)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Spacer()
                        
                        MovefullyStatusBadge(
                            text: isActive ? "Active" : "Draft",
                            color: isActive ? MovefullyTheme.Colors.success : MovefullyTheme.Colors.warning,
                            showDot: true
                        )
                    }
                    
                    Text(plan.description)
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(2)
                    
                    HStack(spacing: MovefullyTheme.Layout.paddingM) {
                        HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                            Image(systemName: "calendar")
                                .font(MovefullyTheme.Typography.caption)
                            Text("\(plan.duration) weeks")
                                .font(MovefullyTheme.Typography.caption)
                        }
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                            Image(systemName: "figure.walk")
                                .font(MovefullyTheme.Typography.caption)
                            Text("\(plan.exercisesPerWeek)x/week")
                                .font(MovefullyTheme.Typography.caption)
                        }
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                            Image(systemName: "person.2")
                                .font(MovefullyTheme.Typography.caption)
                            Text("\(plan.assignedClients)")
                                .font(MovefullyTheme.Typography.caption)
                        }
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Spacer()
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(MovefullyTheme.Typography.buttonSmall)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            .padding(MovefullyTheme.Layout.paddingM)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties
    private var isActive: Bool {
        return plan.assignedClients > 0
    }
    
    private var categoryColor: Color {
        // Determine color based on plan content or difficulty
        switch plan.difficulty {
        case .beginner:
            return MovefullyTheme.Colors.success
        case .intermediate:
            return MovefullyTheme.Colors.primaryTeal
        case .advanced:
            return MovefullyTheme.Colors.secondaryPeach
        }
    }
    
    private var categoryIcon: String {
        // Determine icon based on tags or content
        if plan.tags.contains("Strength") {
            return "dumbbell.fill"
        } else if plan.tags.contains("Cardio") || plan.tags.contains("HIIT") {
            return "heart.fill"
        } else if plan.tags.contains("Flexibility") || plan.tags.contains("Mobility") {
            return "figure.yoga"
        } else {
            return "heart.text.square"
        }
    }
}

// MARK: - Create Plan View Placeholder
struct CreatePlanView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        MovefullyNavigationPageLayout {
            MovefullyPageLayout {
                MovefullyPageSection {
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        Image(systemName: "plus.circle.fill")
                            .font(MovefullyTheme.Typography.largeTitle)
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        
                        VStack(spacing: MovefullyTheme.Layout.paddingS) {
                            Text("Create Wellness Plan")
                                .font(MovefullyTheme.Typography.title2)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Text("Build a structured movement journey for your clients")
                                .font(MovefullyTheme.Typography.body)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button("Close") {
                            dismiss()
                        }
                        .movefullyButtonStyle(.primary)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Create Plan")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
            }
        }
    }
}

// MARK: - Plan Filter Enum
enum PlanFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case draft = "Draft"
    case archived = "Archived"
    
    var title: String {
        return self.rawValue
    }
} 