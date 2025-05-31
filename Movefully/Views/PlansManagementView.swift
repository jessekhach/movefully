import SwiftUI

struct PlansManagementView: View {
    @StateObject private var viewModel = WorkoutPlansViewModel()
    @State private var selectedFilter: PlanFilter = .all
    @State private var showingNewPlan = false
    @State private var selectedPlan: WorkoutPlan?
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with improved spacing and layout
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        HStack(spacing: MovefullyTheme.Layout.paddingL) {
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                                Text("Wellness Plans")
                                    .font(MovefullyTheme.Typography.title1)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Text("Craft meaningful movement experiences")
                                    .font(MovefullyTheme.Typography.callout)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showingNewPlan = true
                            }) {
                                HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("Create")
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
                        
                        // Stats Overview - Wellness focused
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MovefullyTheme.Layout.paddingL) {
                                WellnessPlanStatView(
                                    title: "Plans Created",
                                    value: "\(viewModel.workoutPlans.count)",
                                    icon: "heart.text.square",
                                    color: MovefullyTheme.Colors.primaryTeal
                                )
                                
                                WellnessPlanStatView(
                                    title: "Active Journeys",
                                    value: "\(viewModel.workoutPlans.reduce(0) { $0 + $1.clientsAssigned })",
                                    icon: "figure.walk.motion",
                                    color: MovefullyTheme.Colors.softGreen
                                )
                                
                                WellnessPlanStatView(
                                    title: "This Week",
                                    value: "12",
                                    icon: "chart.line.uptrend.xyaxis",
                                    color: MovefullyTheme.Colors.lavender
                                )
                            }
                            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                        }
                        
                        // Filter Tabs - Soft wellness styling
                        HStack(spacing: 0) {
                            ForEach(PlanFilter.allCases, id: \.self) { filter in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedFilter = filter
                                    }
                                }) {
                                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                                        Text(filter.title)
                                            .font(MovefullyTheme.Typography.bodyMedium)
                                            .foregroundColor(selectedFilter == filter ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.textSecondary)
                                        
                                        Rectangle()
                                            .fill(selectedFilter == filter ? MovefullyTheme.Colors.primaryTeal : Color.clear)
                                            .frame(height: 3)
                                            .clipShape(RoundedRectangle(cornerRadius: 2))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                                }
                            }
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
                    
                    // Plans content
                    if viewModel.isLoading {
                        VStack(spacing: MovefullyTheme.Layout.paddingL) {
                            Spacer(minLength: 200)
                            
                            ProgressView("Loading plans...")
                                .font(MovefullyTheme.Typography.body)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .tint(MovefullyTheme.Colors.primaryTeal)
                            
                            Spacer(minLength: 200)
                        }
                        .frame(maxWidth: .infinity)
                    } else if filteredPlans.isEmpty {
                        // Empty State
                        VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                            Spacer(minLength: 100)
                            
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 80, weight: .light))
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal.opacity(0.6))
                            
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                Text("Create your first plan")
                                    .font(MovefullyTheme.Typography.title2)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Text("Design personalized workout plans for your clients. Create structured programs that help them reach their movement goals with confidence.")
                                    .font(MovefullyTheme.Typography.body)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            }
                            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                            
                            Button("Create Your First Plan") {
                                showingNewPlan = true
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
                            
                            Spacer(minLength: 100)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                    } else {
                        // Plans List
                        LazyVStack(spacing: MovefullyTheme.Layout.paddingL) {
                            ForEach(filteredPlans) { plan in
                                PlanCardView(plan: plan) {
                                    selectedPlan = plan
                                }
                            }
                        }
                        .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                        .padding(.vertical, MovefullyTheme.Layout.paddingL)
                    }
                }
            }
            .movefullyBackground()
            .sheet(isPresented: $showingNewPlan) {
                NewPlanView()
            }
            .sheet(item: $selectedPlan) { plan in
                PlanDetailView(plan: plan)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var filteredPlans: [WorkoutPlan] {
        switch selectedFilter {
        case .all:
            return viewModel.workoutPlans
        case .strength:
            return viewModel.workoutPlans.filter { $0.category == .strength }
        case .cardio:
            return viewModel.workoutPlans.filter { $0.category == .cardio }
        case .flexibility:
            return viewModel.workoutPlans.filter { $0.category == .flexibility }
        }
    }
}

enum PlanFilter: CaseIterable {
    case all, strength, cardio, flexibility
    
    var title: String {
        switch self {
        case .all: return "All Plans"
        case .strength: return "Strength"
        case .cardio: return "Cardio"
        case .flexibility: return "Flexibility"
        }
    }
}

struct WellnessPlanStatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            // Icon with soft background
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: MovefullyTheme.Layout.paddingXS) {
                Text(value)
                    .font(MovefullyTheme.Typography.title2)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text(title)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 120)
        .padding(.vertical, MovefullyTheme.Layout.paddingL)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 8, x: 0, y: 4)
    }
}

struct PlanCardView: View {
    let plan: WorkoutPlan
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    // Plan Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(plan.categoryColor.opacity(0.15))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: plan.categoryIcon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(plan.categoryColor)
                    }
                    
                    // Plan Details
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(plan.name)
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            // Difficulty Badge
                            Text(plan.difficulty.rawValue)
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(plan.difficultyColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(plan.difficultyColor.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        
                        Text(plan.description)
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(2)
                        
                        // Quick Stats
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(MovefullyTheme.Typography.caption)
                                Text("\(plan.avgDuration)min")
                                    .font(MovefullyTheme.Typography.caption)
                            }
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "person.2")
                                    .font(MovefullyTheme.Typography.caption)
                                Text("\(plan.clientsAssigned)")
                                    .font(MovefullyTheme.Typography.caption)
                            }
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            
                            Spacer()
                        }
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
            .padding(20)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.cardCornerRadius))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NewPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var planName = ""
    @State private var planDescription = ""
    @State private var selectedCategory: WorkoutCategory = .strength
    @State private var selectedDifficulty: WorkoutDifficulty = .beginner
    @State private var duration = ""
    @State private var workoutsPerWeek = 3
    @State private var avgDuration = 30
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Create New Plan")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Design a personalized movement journey")
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Plan Name")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            TextField("e.g., Foundation Builder", text: $planName)
                                .textFieldStyle(MovefullyTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            TextEditor(text: $planDescription)
                                .frame(height: 80)
                                .padding(16)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.smallCornerRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: MovefullyTheme.smallCornerRadius)
                                        .stroke(MovefullyTheme.Colors.primaryTeal.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category")
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Menu {
                                    ForEach(WorkoutCategory.allCases, id: \.self) { category in
                                        Button(category.rawValue) {
                                            selectedCategory = category
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedCategory.rawValue)
                                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    }
                                    .padding(16)
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.smallCornerRadius))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: MovefullyTheme.smallCornerRadius)
                                            .stroke(MovefullyTheme.Colors.primaryTeal.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Difficulty")
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Menu {
                                    ForEach(WorkoutDifficulty.allCases, id: \.self) { difficulty in
                                        Button(difficulty.rawValue) {
                                            selectedDifficulty = difficulty
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedDifficulty.rawValue)
                                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    }
                                    .padding(16)
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.smallCornerRadius))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: MovefullyTheme.smallCornerRadius)
                                            .stroke(MovefullyTheme.Colors.primaryTeal.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Create Button
                    Button(action: {
                        // TODO: Create plan
                        dismiss()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Create Plan")
                                .font(MovefullyTheme.Typography.buttonMedium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.primaryTeal.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.cornerRadius))
                        .shadow(color: MovefullyTheme.Colors.primaryTeal.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 24)
                    .disabled(planName.isEmpty)
                }
                .padding(.bottom, 32)
            }
            .background(MovefullyTheme.backgroundGray)
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
    }
}

struct PlanDetailView: View {
    let plan: WorkoutPlan
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Plan Header
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(plan.categoryColor.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: plan.categoryIcon)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(plan.categoryColor)
                        }
                        
                        VStack(spacing: 8) {
                            Text(plan.name)
                                .font(MovefullyTheme.Typography.title1)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Text(plan.description)
                                .font(MovefullyTheme.Typography.callout)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        HStack(spacing: 16) {
                            Text(plan.category.rawValue)
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(plan.categoryColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(plan.categoryColor.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Text(plan.difficulty.rawValue)
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(plan.difficultyColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(plan.difficultyColor.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.top, 20)
                    
                    // Plan Stats
                    VStack(spacing: 16) {
                        HStack {
                            PlanDetailStatView(title: "Duration", value: plan.duration, icon: "calendar")
                            Spacer()
                            PlanDetailStatView(title: "Per Week", value: "\(plan.workoutsPerWeek)x", icon: "repeat")
                            Spacer()
                            PlanDetailStatView(title: "Avg Time", value: "\(plan.avgDuration)min", icon: "clock")
                            Spacer()
                            PlanDetailStatView(title: "Clients", value: "\(plan.clientsAssigned)", icon: "person.2")
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)
            }
            .background(MovefullyTheme.backgroundGray)
            .navigationTitle("Plan Details")
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

struct PlanDetailStatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text(title)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.smallCornerRadius))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
} 