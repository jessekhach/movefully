import SwiftUI

struct WorkoutPlansView: View {
    @StateObject private var viewModel = WorkoutPlansViewModel()
    @State private var showingCreatePlan = false
    @State private var selectedPlan: WorkoutPlan? = nil
    @State private var showingPlanDetail = false
    @State private var showingEditPlan = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with improved spacing
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        HStack {
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
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
                            
                            // Create Plan Button
                            Button(action: {
                                showingCreatePlan = true
                            }) {
                                HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Create")
                                        .font(MovefullyTheme.Typography.buttonSmall)
                                }
                            }
                            .movefullyButtonStyle(.primary)
                            .frame(width: 110)
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
                    
                    // Content
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
                    } else if viewModel.workoutPlans.isEmpty {
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
                                showingCreatePlan = true
                            }
                            .movefullyButtonStyle(.primary)
                            .frame(maxWidth: 280)
                            
                            Spacer(minLength: 100)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                    } else {
                        // Plans List
                        LazyVStack(spacing: MovefullyTheme.Layout.paddingM) {
                            ForEach(viewModel.workoutPlans) { plan in
                                WorkoutPlanRowView(plan: plan) {
                                    selectedPlan = plan
                                    showingPlanDetail = true
                                }
                            }
                        }
                        .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                        .padding(.vertical, MovefullyTheme.Layout.paddingL)
                    }
                }
            }
            .movefullyBackground()
        }
        .sheet(isPresented: $showingCreatePlan) {
            CreatePlanSheet()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingPlanDetail) {
            if let plan = selectedPlan {
                PlanDetailView(plan: plan) {
                    selectedPlan = plan
                    showingEditPlan = true
                }
                .environmentObject(viewModel)
            }
        }
        .sheet(isPresented: $showingEditPlan) {
            if let plan = selectedPlan {
                EditPlanSheet(plan: plan)
                    .environmentObject(viewModel)
            }
        }
        .onAppear {
            // Load plans is not needed as they're loaded in init
        }
    }
}

// MARK: - Workout Plan Row View
struct WorkoutPlanRowView: View {
    let plan: WorkoutPlan
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                        Text(plan.name)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        Text(plan.description)
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: MovefullyTheme.Layout.paddingXS) {
                        Text("\(plan.duration) weeks")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                }
                
                // Stats
                HStack(spacing: MovefullyTheme.Layout.paddingL) {
                    PlanStatView(icon: "clock", value: "\(plan.sessionDuration)", label: "min/session")
                    PlanStatView(icon: "person.2", value: "\(plan.assignedClients)", label: "clients")
                    
                    Spacer()
                }
                
                // Tags
                if !plan.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: MovefullyTheme.Layout.paddingS) {
                            ForEach(plan.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(MovefullyTheme.Typography.caption)
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                    .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                                    .padding(.vertical, MovefullyTheme.Layout.paddingXS)
                                    .background(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
                            }
                        }
                    }
                }
            }
            .padding(MovefullyTheme.Layout.paddingL)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Plan Stat View
struct PlanStatView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingXS) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            
            Text(value)
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            Text(label)
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Plan Detail View
struct PlanDetailView: View {
    @EnvironmentObject var viewModel: WorkoutPlansViewModel
    @Environment(\.dismiss) private var dismiss
    let plan: WorkoutPlan
    let onEdit: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    planHeader
                    planInfo
                }
            }
            .movefullyBackground()
            .navigationBarHidden(true)
        }
    }
    
    private var planHeader: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                
                Spacer()
                
                Text("Plan Details")
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Spacer()
                
                Button("Edit") {
                    onEdit()
                }
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            .padding(.top, MovefullyTheme.Layout.paddingM)
        }
    }
    
    private var planInfo: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            planBasicInfo
            planStatsGrid
            planTags
            planExercises
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
    }
    
    private var planBasicInfo: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            Text(plan.name)
                .font(MovefullyTheme.Typography.title2)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            Text(plan.description)
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                .lineLimit(nil)
        }
    }
    
    private var planStatsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: MovefullyTheme.Layout.paddingM) {
            PlanDetailStatView(title: "Duration", value: "\(plan.duration) weeks", icon: "calendar")
            PlanDetailStatView(title: "Sessions/Week", value: "\(plan.exercisesPerWeek)", icon: "repeat")
            PlanDetailStatView(title: "Session Length", value: "\(plan.sessionDuration) min", icon: "clock")
            PlanDetailStatView(title: "Assigned Clients", value: "\(plan.assignedClients)", icon: "person.2")
        }
    }
    

    
    @ViewBuilder
    private var planTags: some View {
        if !plan.tags.isEmpty {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                Text("Tags:")
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                FlowLayout(spacing: MovefullyTheme.Layout.paddingS) {
                    ForEach(plan.tags, id: \.self) { tag in
                        Text(tag)
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                            .padding(.vertical, MovefullyTheme.Layout.paddingS)
                            .background(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var planExercises: some View {
        if !plan.exercises.isEmpty {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                Text("Exercises:")
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                    ForEach(Array(plan.exercises.enumerated()), id: \.offset) { index, exercise in
                        HStack {
                            Text("\(index + 1).")
                                .font(MovefullyTheme.Typography.callout)
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                .frame(width: 30, alignment: .leading)
                            
                            Text(exercise)
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Spacer()
                        }
                        .padding(.vertical, MovefullyTheme.Layout.paddingXS)
                    }
                }
                .padding(MovefullyTheme.Layout.paddingM)
                .background(MovefullyTheme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            }
        }
    }
}

// MARK: - Plan Detail Stat View
struct PlanDetailStatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingS) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            
            Text(value)
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            Text(title)
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
    }
}

// MARK: - Create Plan Sheet
struct CreatePlanSheet: View {
    @EnvironmentObject var viewModel: WorkoutPlansViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var planName: String = ""
    @State private var planDescription: String = ""
    @State private var selectedDifficulty: WorkoutDifficulty = .beginner
    @State private var duration: Int = 4
    @State private var exercisesPerWeek: Int = 3
    @State private var sessionDuration: Int = 45
    @State private var tags: String = ""
    @State private var clientNotes: String = ""
    @State private var coachingTips: String = ""
    @State private var prerequisites: String = ""
    @State private var selectedExercises: [Exercise] = []
    @State private var showingExerciseLibrary = false
    @State private var selectedCategory: ExerciseCategory? = nil
    @State private var isLoading = false
    @State private var currentStep = 1
    
    // Use the master exercise repository
    private let availableExercises = Exercise.sampleExercises
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Progress Indicator
                    HStack {
                        ForEach(1...3, id: \.self) { step in
                            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                Circle()
                                    .fill(step <= currentStep ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.inactive)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text("\(step)")
                                            .font(MovefullyTheme.Typography.caption)
                                            .foregroundColor(.white)
                                    )
                                
                                if step < 3 {
                                    Rectangle()
                                        .fill(step < currentStep ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.inactive)
                                        .frame(height: 2)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                    
                    // Step Content
                    Group {
                        switch currentStep {
                        case 1:
                            PlanBasicsStep(
                                planName: $planName,
                                planDescription: $planDescription,
                                selectedDifficulty: $selectedDifficulty,
                                duration: $duration,
                                exercisesPerWeek: $exercisesPerWeek,
                                sessionDuration: $sessionDuration
                            )
                        case 2:
                            ExerciseSelectionStep(
                                selectedExercises: $selectedExercises,
                                availableExercises: availableExercises,
                                selectedCategory: $selectedCategory
                            )
                        case 3:
                            ClientGuidanceStep(
                                clientNotes: $clientNotes,
                                coachingTips: $coachingTips,
                                prerequisites: $prerequisites,
                                tags: $tags
                            )
                        default:
                            EmptyView()
                        }
                    }
                    
                    // Navigation Buttons
                    HStack(spacing: MovefullyTheme.Layout.paddingM) {
                        if currentStep > 1 {
                            Button("Previous") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep -= 1
                                }
                            }
                            .movefullyButtonStyle(.tertiary)
                        }
                        
                        Spacer()
                        
                        if currentStep < 3 {
                            Button("Next") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep += 1
                                }
                            }
                            .movefullyButtonStyle(.primary)
                            .disabled(currentStep == 1 && (planName.isEmpty || planDescription.isEmpty))
                        } else {
                            Button("Create Plan") {
                                createPlan()
                            }
                            .movefullyButtonStyle(.primary)
                            .disabled(selectedExercises.isEmpty || isLoading)
                        }
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                    .padding(.bottom, MovefullyTheme.Layout.paddingXL)
                }
            }
            .movefullyBackground()
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
    
    private func createPlan() {
        isLoading = true
        
        // Simulate creating
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            dismiss()
        }
    }
}

// MARK: - Plan Creation Steps

struct PlanBasicsStep: View {
    @Binding var planName: String
    @Binding var planDescription: String
    @Binding var selectedDifficulty: WorkoutDifficulty
    @Binding var duration: Int
    @Binding var exercisesPerWeek: Int
    @Binding var sessionDuration: Int
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            // Header
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                Text("Plan Basics")
                    .font(MovefullyTheme.Typography.title2)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text("Set the foundation for your wellness plan")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Form Fields
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                // Plan Name
                MovefullyFormField(title: "Plan Name") {
                    MovefullyTextField(
                        placeholder: "Plan name",
                        text: $planName
                    )
                }
                
                // Description
                MovefullyFormField(title: "Description") {
                    MovefullyTextEditor(
                        placeholder: "Description",
                        text: $planDescription,
                        minLines: 3,
                        maxLines: 6
                    )
                }
                
                // Settings Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: MovefullyTheme.Layout.paddingM) {
                    // Difficulty
                    MovefullyFormField(title: "Difficulty") {
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
                                    .font(.system(size: 14))
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
                    
                    // Duration
                    MovefullyFormField(title: "Duration (weeks)") {
                        Menu {
                            ForEach(1...12, id: \.self) { week in
                                Button("\(week) week\(week == 1 ? "" : "s")") {
                                    duration = week
                                }
                            }
                        } label: {
                            HStack {
                                Text("\(duration) week\(duration == 1 ? "" : "s")")
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .font(.system(size: 14))
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
                    
                    // Sessions per week
                    MovefullyFormField(title: "Sessions/Week") {
                        Menu {
                            ForEach(1...7, id: \.self) { sessions in
                                Button("\(sessions) session\(sessions == 1 ? "" : "s")") {
                                    exercisesPerWeek = sessions
                                }
                            }
                        } label: {
                            HStack {
                                Text("\(exercisesPerWeek) session\(exercisesPerWeek == 1 ? "" : "s")")
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .font(.system(size: 14))
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
                    
                    // Session Duration
                    MovefullyFormField(title: "Session Length") {
                        Menu {
                            ForEach([15, 30, 45, 60, 75, 90], id: \.self) { minutes in
                                Button("\(minutes) minutes") {
                                    sessionDuration = minutes
                                }
                            }
                        } label: {
                            HStack {
                                Text("\(sessionDuration) min")
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .font(.system(size: 14))
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
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
    }
}

struct ExerciseSelectionStep: View {
    @Binding var selectedExercises: [Exercise]
    let availableExercises: [Exercise]
    @Binding var selectedCategory: ExerciseCategory?
    
    var filteredExercises: [Exercise] {
        if let category = selectedCategory {
            return availableExercises.filter { $0.category == category }
        }
        return availableExercises
    }
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            // Header
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                Text("Select Exercises")
                    .font(MovefullyTheme.Typography.title2)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text("Choose movements that align with your plan goals")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Selected Count
            HStack {
                Text("\(selectedExercises.count) exercise\(selectedExercises.count == 1 ? "" : "s") selected")
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                
                Spacer()
                
                if !selectedExercises.isEmpty {
                    Button("Clear All") {
                        selectedExercises.removeAll()
                    }
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.warmOrange)
                }
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    ExerciseCategoryPill(
                        title: "All",
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }
                    
                    ForEach(ExerciseCategory.allCases, id: \.self) { category in
                        ExerciseCategoryPill(
                            title: category.rawValue,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
            }
            
            // Exercise List
            LazyVStack(spacing: MovefullyTheme.Layout.paddingM) {
                ForEach(filteredExercises) { exercise in
                    ExerciseSelectionRow(
                        exercise: exercise,
                        isSelected: selectedExercises.contains { $0.id == exercise.id }
                    ) {
                        if let index = selectedExercises.firstIndex(where: { $0.id == exercise.id }) {
                            selectedExercises.remove(at: index)
                        } else {
                            selectedExercises.append(exercise)
                        }
                    }
                }
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
        }
    }
}

struct ClientGuidanceStep: View {
    @Binding var clientNotes: String
    @Binding var coachingTips: String
    @Binding var prerequisites: String
    @Binding var tags: String
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            // Header
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                Text("Client Guidance")
                    .font(MovefullyTheme.Typography.title2)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text("Add helpful information to guide your clients through this plan")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Form Fields
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                MovefullyFormField(title: "Client Notes", subtitle: "What should clients know before starting?") {
                    MovefullyTextEditor(
                        placeholder: "e.g. This plan focuses on building fundamental movement patterns. Listen to your body and progress at your own pace.",
                        text: $clientNotes,
                        minLines: 3,
                        maxLines: 6
                    )
                }
                
                MovefullyFormField(title: "Coaching Tips", subtitle: "Helpful guidance from you as their coach") {
                    MovefullyTextEditor(
                        placeholder: "e.g. Focus on form over speed. Remember to breathe deeply throughout each movement.",
                        text: $coachingTips,
                        minLines: 3,
                        maxLines: 6
                    )
                }
                
                MovefullyFormField(title: "Prerequisites", subtitle: "Any requirements or prior experience needed") {
                    MovefullyTextEditor(
                        placeholder: "e.g. No prior experience required. Basic mobility recommended.",
                        text: $prerequisites,
                        minLines: 2,
                        maxLines: 4
                    )
                }
                
                MovefullyFormField(title: "Tags", subtitle: "Keywords to help organize and find this plan") {
                    MovefullyTextField(
                        placeholder: "e.g. beginner, strength, bodyweight, foundation",
                        text: $tags
                    )
                }
            }
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
    }
}

// MARK: - Supporting Components

struct PlanFormField<Content: View>: View {
    let title: String
    let subtitle: String?
    let isRequired: Bool
    let content: Content
    
    init(title: String, subtitle: String? = nil, isRequired: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.isRequired = isRequired
        self.content = content()
    }
    
    var body: some View {
        MovefullyFormField(title: title, subtitle: subtitle, isRequired: isRequired) {
            content
        }
    }
}

struct ExerciseCategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        MovefullyPill(
            title: title,
            isSelected: isSelected,
            style: .tag,
            action: action
        )
    }
}

struct ExerciseSelectionRow: View {
    let exercise: Exercise
    let isSelected: Bool
    let onToggle: () -> Void
    
    private var difficultyColor: Color {
        guard let difficulty = exercise.difficulty else { return MovefullyTheme.Colors.primaryTeal }
        
        switch difficulty.color {
        case "success":
            return MovefullyTheme.Colors.success
        case "primaryTeal":
            return MovefullyTheme.Colors.primaryTeal
        case "secondaryPeach":
            return MovefullyTheme.Colors.secondaryPeach
        default:
            return MovefullyTheme.Colors.primaryTeal
        }
    }
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.cardBackground)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.divider, lineWidth: 2)
                        )
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Exercise info
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    HStack {
                        Text(exercise.title)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Spacer()
                        
                        if let difficulty = exercise.difficulty {
                            Text(difficulty.rawValue)
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(difficultyColor)
                                .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                                .padding(.vertical, MovefullyTheme.Layout.paddingXS)
                                .background(difficultyColor.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
                        }
                    }
                    
                    if let description = exercise.description {
                        Text(description)
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
            }
            .padding(MovefullyTheme.Layout.paddingM)
            .background(isSelected ? MovefullyTheme.Colors.primaryTeal.opacity(0.05) : MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            .overlay(
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                    .stroke(isSelected ? MovefullyTheme.Colors.primaryTeal.opacity(0.3) : MovefullyTheme.Colors.divider, lineWidth: 1)
            )
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: isSelected ? 4 : 2, x: 0, y: isSelected ? 2 : 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Plan Sheet
struct EditPlanSheet: View {
    @EnvironmentObject var viewModel: WorkoutPlansViewModel
    @Environment(\.dismiss) private var dismiss
    let plan: WorkoutPlan
    @State private var planName: String = ""
    @State private var planDescription: String = ""
    @State private var selectedDifficulty: WorkoutDifficulty = .beginner
    @State private var duration: Int = 4
    @State private var exercisesPerWeek: Int = 3
    @State private var sessionDuration: Int = 45
    @State private var tags: String = ""
    @State private var exercises: String = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Header
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Edit Plan")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Make changes to \"\(plan.name)\"")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                    
                    // Form Fields (same as create)
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        // Plan Name
                        MovefullyFormField(title: "Plan Name") {
                            MovefullyTextField(
                                placeholder: "Plan name",
                                text: $planName
                                )
                        }
                        
                        // Description
                        MovefullyFormField(title: "Description") {
                            MovefullyTextEditor(
                                placeholder: "Description",
                                text: $planDescription,
                                minLines: 3,
                                maxLines: 6
                            )
                        }
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    HStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(MovefullyTheme.Typography.buttonMedium)
                        .frame(maxWidth: .infinity)
                        .frame(height: MovefullyTheme.Layout.buttonHeightM)
                        .background(MovefullyTheme.Colors.cardBackground)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                        .overlay(
                            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                                .stroke(MovefullyTheme.Colors.textSecondary.opacity(0.3), lineWidth: 1)
                        )
                        
                        Button("Save Changes") {
                            savePlan()
                        }
                        .movefullyButtonStyle(.primary)
                        .disabled(planName.isEmpty || planDescription.isEmpty || isLoading)
                    }
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.bottom, MovefullyTheme.Layout.paddingL)
            }
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadPlanData()
        }
    }
    
    private func loadPlanData() {
        planName = plan.name
        planDescription = plan.description
        selectedDifficulty = plan.difficulty
        duration = plan.duration
        exercisesPerWeek = plan.exercisesPerWeek
        sessionDuration = plan.sessionDuration
        tags = plan.tags.joined(separator: ", ")
        exercises = plan.exercises.joined(separator: "\n")
    }
    
    private func savePlan() {
        isLoading = true
        
        // Simulate saving
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            dismiss()
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.bounds
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
}

struct FlowResult {
    var bounds = CGSize.zero
    var frames: [CGRect] = []
    
    init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
        var currentPosition = CGPoint.zero
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentPosition.x + subviewSize.width > maxWidth && currentPosition.x > 0 {
                // Move to next line
                currentPosition.x = 0
                currentPosition.y += lineHeight + spacing
                lineHeight = 0
            }
            
            frames.append(CGRect(origin: currentPosition, size: subviewSize))
            
            currentPosition.x += subviewSize.width + spacing
            lineHeight = max(lineHeight, subviewSize.height)
            maxX = max(maxX, currentPosition.x - spacing)
        }
        
        bounds = CGSize(width: maxX, height: currentPosition.y + lineHeight)
    }
} 