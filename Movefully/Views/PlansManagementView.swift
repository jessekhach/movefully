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
            // Search field - only show when there are plans to search
            if !viewModel.programs.isEmpty {
                MovefullySearchField(
                    placeholder: "Search plans...",
                    text: $searchText
                )
            }
            
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
            NavigationLink(destination: PlansDetailView(program: program).environmentObject(viewModel)) {
                ProgramCard(program: program)
                }
            .buttonStyle(PlainButtonStyle())
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
    let onTap: (() -> Void)?
    
    init(program: Program, onTap: (() -> Void)? = nil) {
        self.program = program
        self.onTap = onTap
    }
    
    var body: some View {
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
                            
                    if program.isDraft {
                        MovefullyStatusBadge(
                            text: "Draft",
                            color: MovefullyTheme.Colors.warmOrange,
                            showDot: false
                        )
                    }
                            
                            Spacer()
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
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

// MARK: - Create Plan Flow
struct CreatePlanView: View {
    @EnvironmentObject var viewModel: ProgramsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 1
    @State private var planName = ""
    @State private var planDescription = ""
    @State private var selectedDuration = 1 // weeks
    @State private var selectedDifficulty: WorkoutDifficulty = .beginner

    @State private var selectedTags: Set<String> = []
    @State private var coachingNotes: String = ""
    @State private var scheduledWorkouts: [Int: ScheduledWorkout] = [:] // Day index to workout
    @State private var showingUnsavedChangesAlert = false
    
    private let totalSteps = 4
    private let maxWeeks = 12
    
    // Pre-defined tag options for multi-select
    private let availableTags = [
        "Strength", "Cardio", "HIIT", "Flexibility", "Balance",
        "Core", "Upper Body", "Lower Body", "Full Body", "Recovery",
        "Beginner Friendly", "Advanced", "Quick Workout", "Endurance"
    ]
    
    private var hasUnsavedChanges: Bool {
        !planName.isEmpty || !planDescription.isEmpty || !scheduledWorkouts.isEmpty || !selectedTags.isEmpty || !coachingNotes.isEmpty
    }
    
    // MARK: - Dynamic Icon Logic
    private var dynamicIcon: String {
        // Priority order for icon selection based on tags
        if selectedTags.contains("Strength") || selectedTags.contains("Upper Body") || selectedTags.contains("Lower Body") {
            return "dumbbell.fill"
        } else if selectedTags.contains("Cardio") || selectedTags.contains("HIIT") || selectedTags.contains("Endurance") {
            return "heart.fill"
        } else if selectedTags.contains("Flexibility") || selectedTags.contains("Mobility") {
            return "figure.yoga"
        } else if selectedTags.contains("Core") || selectedTags.contains("Stability") {
            return "circle.grid.3x3.fill"
        } else if selectedTags.contains("Balance") || selectedTags.contains("Functional") {
            return "figure.stand"
        } else if selectedTags.contains("Recovery") {
            return "leaf.fill"
        } else if selectedTags.contains("Quick Workout") || selectedTags.contains("Beginner Friendly") {
            return "timer"
        } else {
            return "calendar.badge.plus"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Progress Indicator
                    progressIndicator
                    
                    // Step Content
                    Group {
                        switch currentStep {
                        case 1:
                            planBasicsStep
                        case 2:
                            scheduleWorkoutsStep
                        case 3:
                            additionalDetailsStep
                        case 4:
                            reviewAndSaveStep
                        default:
                            EmptyView()
                        }
                    }
                    
                    // Navigation Buttons
                    navigationButtons
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            }
            .movefullyBackground()
            .navigationTitle("Create Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasUnsavedChanges {
                            showingUnsavedChangesAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentStep < totalSteps {
                        Button("Save Draft") {
                            saveDraft()
                        }
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        .disabled(planName.isEmpty)
                    }
                }
            }
        }
        .alert("Unsaved Changes", isPresented: $showingUnsavedChangesAlert) {
            Button("Save Draft") { saveDraft() }
            Button("Discard", role: .destructive) { dismiss() }
            Button("Continue Editing", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. Would you like to save them as a draft?")
        }
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        HStack {
            ForEach(1...totalSteps, id: \.self) { step in
                HStack(spacing: MovefullyTheme.Layout.paddingS) {
                    Circle()
                        .fill(step <= currentStep ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.inactive)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("\(step)")
                                .font(MovefullyTheme.Typography.footnote)
                                .foregroundColor(.white)
                        )
                    
                    if step < totalSteps {
                        Rectangle()
                            .fill(step < currentStep ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.inactive)
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.top, MovefullyTheme.Layout.paddingL)
    }
    
    // MARK: - Step 1: Plan Basics
    private var planBasicsStep: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                MovefullyPageHeader(
                    title: "Plan Basics",
                    subtitle: "Set the foundation for your training plan"
                )
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    MovefullyFormField(title: "Plan Name", isRequired: true) {
                        MovefullyTextField(
                            placeholder: "e.g., 4-Week Strength Foundation",
                            text: $planName
                        )
                    }
                    
                    MovefullyFormField(title: "Description", isRequired: true) {
                        MovefullyTextEditor(
                            placeholder: "Describe what this plan aims to achieve and who it's for...",
                            text: $planDescription,
                            minLines: 3,
                            maxLines: 5
                        )
                    }
                    
                    MovefullyFormField(title: "Duration (weeks)") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                                ForEach(1...maxWeeks, id: \.self) { weeks in
                                    MovefullyPill(
                                        title: "\(weeks) \(weeks == 1 ? "week" : "weeks")",
                                        isSelected: selectedDuration == weeks,
                                        style: .filter
                                    ) {
                                        selectedDuration = weeks
                                    }
                                }
                            }
                            .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                        }
                    }
                    
                    MovefullyFormField(title: "Difficulty Level") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                ForEach(WorkoutDifficulty.allCases, id: \.self) { difficulty in
                                    MovefullyPill(
                                        title: difficulty.rawValue,
                                        isSelected: selectedDifficulty == difficulty,
                                        style: .filter
                                    ) {
                                        selectedDifficulty = difficulty
                                    }
                                }
                            }
                            .padding(.horizontal, MovefullyTheme.Layout.paddingXS)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 2: Schedule Workouts
    private var scheduleWorkoutsStep: some View {
        PlanSchedulingView(
            duration: selectedDuration,
            scheduledWorkouts: $scheduledWorkouts,
            viewModel: viewModel
        )
    }
    
    // MARK: - Step 3: Additional Details
    private var additionalDetailsStep: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                MovefullyPageHeader(
                    title: "Additional Details",
                    subtitle: "Add tags and notes to help organize and guide this plan"
                )
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    MovefullyFormField(
                        title: "Tags",
                        subtitle: "Select relevant tags to categorize this plan"
                    ) {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: MovefullyTheme.Layout.paddingS) {
                            ForEach(availableTags, id: \.self) { tag in
                                MovefullyPill(
                                    title: tag,
                                    isSelected: selectedTags.contains(tag),
                                    style: .tag
                                ) {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                }
                            }
                        }
                    }
                    
                    MovefullyFormField(
                        title: "Plan Notes",
                        subtitle: "Optional notes for trainers using this plan"
                    ) {
                        MovefullyTextEditor(
                            placeholder: "Add important information, special instructions, or client guidance...",
                            text: $coachingNotes,
                            minLines: 3,
                            maxLines: 6
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Step 4: Review and Save
    private var reviewAndSaveStep: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                MovefullyPageHeader(
                    title: "Review Plan",
                    subtitle: "Review your plan details before creating"
                )
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    PlanReviewSection(title: "Basic Information") {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            ReviewItem(label: "Name", value: planName)
                            ReviewItem(label: "Description", value: planDescription)
                            ReviewItem(label: "Duration", value: "\(selectedDuration) \(selectedDuration == 1 ? "week" : "weeks")")
                            ReviewItem(label: "Difficulty", value: selectedDifficulty.rawValue)
                            
                            if !selectedTags.isEmpty {
                                ReviewItem(label: "Tags", value: Array(selectedTags).joined(separator: ", "))
                            }
                        }
                    }
                    
                    PlanReviewSection(title: "Workout Schedule") {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            ReviewItem(label: "Total Days", value: "\(selectedDuration * 7) days")
                            ReviewItem(label: "Workout Days", value: "\(scheduledWorkouts.count)")
                            ReviewItem(label: "Rest Days", value: "\((selectedDuration * 7) - scheduledWorkouts.count)")
                            
                            if !scheduledWorkouts.isEmpty {
                                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                                    ForEach(scheduledWorkouts.keys.sorted(), id: \.self) { dayIndex in
                                        if let workout = scheduledWorkouts[dayIndex] {
                                            HStack {
                                                Text("• Day \(dayIndex + 1): \(workout.title)")
                                                    .font(MovefullyTheme.Typography.caption)
                                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                                
                                                Spacer()
                                                
                                                Text("\(workout.estimatedDuration) min")
                                                    .font(MovefullyTheme.Typography.caption)
                                                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
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
            
            if currentStep < totalSteps {
                Button("Next") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                }
                .movefullyButtonStyle(.primary)
                .disabled(!canProceedFromCurrentStep)
            } else {
                Button("Create Plan") {
                    savePlan()
                }
                .movefullyButtonStyle(.primary)
                .disabled(!isFormValid)
            }
        }
    }
    
    private var canProceedFromCurrentStep: Bool {
        switch currentStep {
        case 1:
            return !planName.isEmpty && !planDescription.isEmpty
        case 2:
            return true // Schedule workouts is optional
        case 3:
            return true // Additional details are optional
        case 4:
            return isFormValid
        default:
            return false
        }
    }
    
    private var isFormValid: Bool {
        !planName.isEmpty && !planDescription.isEmpty
    }
    
    // MARK: - Actions
    private func saveDraft() {
        let program = createProgram(isDraft: true)
        viewModel.createProgram(program)
        dismiss()
    }
    
    private func savePlan() {
        let program = createProgram(isDraft: false)
        viewModel.createProgram(program)
        dismiss()
    }
    
    private func createProgram(isDraft: Bool) -> Program {
        let durationInDays = selectedDuration * 7
        let workouts = scheduledWorkouts.values.map { $0 }
        
                 return Program(
             name: planName,
             description: planDescription,
             duration: durationInDays,
             difficulty: selectedDifficulty,
             scheduledWorkouts: workouts,
             tags: Array(selectedTags),
             usageCount: 0,
             createdDate: Date(),
             lastModified: Date(),
             isDraft: isDraft,
             icon: dynamicIcon,
             coachingNotes: coachingNotes.isEmpty ? nil : coachingNotes
         )
     }
}

// MARK: - Supporting Views for Plan Creation
struct PlanReviewSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
            Text(title)
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            content
        }
        .padding(MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
    }
}





// MARK: - Plan Scheduling View
struct PlanSchedulingView: View {
    let duration: Int // weeks
    @Binding var scheduledWorkouts: [Int: ScheduledWorkout]
    let viewModel: ProgramsViewModel
    
    @State private var selectedWeekIndex = 0
    @State private var showingWorkoutSelector = false
    @State private var selectedDayIndex: Int?
    
    private var totalDays: Int { duration * 7 }
    private var currentWeekDays: [Int] {
        let startDay = selectedWeekIndex * 7
        return Array(startDay..<min(startDay + 7, totalDays))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            scheduleHeader
            
            // Week navigation
            weekNavigation
            
            // Week calendar
            ScrollView {
                weekCalendarView
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    .padding(.bottom, MovefullyTheme.Layout.paddingXXL)
            }
        }
        .sheet(isPresented: $showingWorkoutSelector) {
            if let dayIndex = selectedDayIndex {
                WorkoutSelectorView(
                    dayIndex: dayIndex,
                    scheduledWorkouts: $scheduledWorkouts,
                    viewModel: viewModel
                )
            }
        }
    }
    
    private var scheduleHeader: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            Image(systemName: "calendar")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            
            Text("Schedule Workouts")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
            Text("Add workouts to each day or leave blank for rest days")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
        .padding(.vertical, MovefullyTheme.Layout.paddingL)
    }
    
    private var weekNavigation: some View {
        HStack {
            Button(action: { selectedWeekIndex = max(0, selectedWeekIndex - 1) }) {
                Image(systemName: "chevron.left")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(selectedWeekIndex > 0 ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.textTertiary)
            }
            .disabled(selectedWeekIndex <= 0)
            
            Spacer()
            
            Text("Week \(selectedWeekIndex + 1) of \(duration)")
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            Spacer()
            
            Button(action: { selectedWeekIndex = min(duration - 1, selectedWeekIndex + 1) }) {
                Image(systemName: "chevron.right")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(selectedWeekIndex < duration - 1 ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.textTertiary)
            }
            .disabled(selectedWeekIndex >= duration - 1)
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
        .padding(.vertical, MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.cardBackground)
    }
    
    private var weekCalendarView: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            // Day labels
            HStack {
                ForEach(weekDayNames, id: \.self) { dayName in
                    Text(dayName)
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: MovefullyTheme.Layout.paddingS) {
                ForEach(currentWeekDays, id: \.self) { dayIndex in
                    PlanCalendarDayView(
                        dayIndex: dayIndex,
                        workout: scheduledWorkouts[dayIndex]
                    ) {
                        selectedDayIndex = dayIndex
                        showingWorkoutSelector = true
                    }
                }
            }
        }
    }
    
    private let weekDayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
}

// MARK: - Plan Calendar Day View
struct PlanCalendarDayView: View {
    let dayIndex: Int
    let workout: ScheduledWorkout?
    let onTap: () -> Void
    
    private var dayNumber: Int {
        (dayIndex % 7) + 1
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                Text("Day \(dayIndex + 1)")
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                
                if let workout = workout {
                    VStack(spacing: 4) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 16))
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        
                        Text(workout.title)
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "plus.circle.dashed")
                            .font(.system(size: 20))
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                        
                        Text("Add")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .padding(MovefullyTheme.Layout.paddingS)
            .background(workout != nil ? MovefullyTheme.Colors.primaryTeal.opacity(0.1) : MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            .overlay(
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                    .stroke(workout != nil ? MovefullyTheme.Colors.primaryTeal.opacity(0.3) : MovefullyTheme.Colors.divider, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Workout Selector View
struct WorkoutSelectorView: View {
    let dayIndex: Int
    @Binding var scheduledWorkouts: [Int: ScheduledWorkout]
    let viewModel: ProgramsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingTemplateSelector = false
    @State private var showingCustomWorkoutCreator = false
    
    private func currentWorkoutName(_ workout: ScheduledWorkout) -> String {
        if let template = workout.workoutTemplate {
            return template.name
        } else if let customWorkout = workout.customWorkout {
            return customWorkout.name
        } else {
            return "Unknown workout"
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                // Header
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Text("Day \(dayIndex + 1)")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    if let currentWorkout = scheduledWorkouts[dayIndex] {
                        Text("Currently added: \(currentWorkoutName(currentWorkout))")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    } else {
                        Text("Choose how to add your workout")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                }
                
                // Options
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    if scheduledWorkouts[dayIndex] == nil {
                        // Show add options when no workout is scheduled
                        WorkoutOptionCard(
                            icon: "list.clipboard.fill",
                            title: "Choose Template",
                            description: "Select from your existing workout templates"
                        ) {
                            showingTemplateSelector = true
                        }
                        
                        WorkoutOptionCard(
                            icon: "plus.circle.fill",
                            title: "Create Custom Workout",
                            description: "Build a workout from scratch using exercises"
                        ) {
                            showingCustomWorkoutCreator = true
                        }
                    } else {
                        // Show modify options when workout is scheduled
                        WorkoutOptionCard(
                            icon: "list.clipboard.fill",
                            title: "Change Template",
                            description: "Replace with a different template"
                        ) {
                            showingTemplateSelector = true
                        }
                        
                        WorkoutOptionCard(
                            icon: "plus.circle.fill",
                            title: "Edit Custom Workout",
                            description: "Create a new custom workout instead"
                        ) {
                            showingCustomWorkoutCreator = true
                        }
                        
                        WorkoutOptionCard(
                            icon: "trash.fill",
                            title: "Remove Workout",
                            description: "Make this a rest day",
                            color: MovefullyTheme.Colors.warmOrange
                        ) {
                            scheduledWorkouts.removeValue(forKey: dayIndex)
                    dismiss()
                }
                    }
                }
                
                Spacer()
            }
            .padding(MovefullyTheme.Layout.paddingL)
            .navigationTitle("Add Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { 
                        dismiss() 
                    }
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
        .sheet(isPresented: $showingTemplateSelector) {
            TemplatePickerView(
                dayIndex: dayIndex,
                scheduledWorkouts: $scheduledWorkouts,
                viewModel: viewModel,
                onTemplateSelected: {
                    // Dismiss this view after template is selected
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        dismiss()
                    }
                }
            )
        }
        .sheet(isPresented: $showingCustomWorkoutCreator) {
            CustomWorkoutCreatorView(
                dayIndex: dayIndex,
                scheduledWorkouts: $scheduledWorkouts,
                viewModel: viewModel,
                onWorkoutCreated: {
                    // Dismiss this view after workout is created
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        dismiss()
                    }
                }
            )
        }
    }
}

// MARK: - Workout Option Card
struct WorkoutOptionCard: View {
    let icon: String
    let title: String
    let description: String
    var color: Color = MovefullyTheme.Colors.primaryTeal
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text(title)
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text(description)
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
            }
            .padding(MovefullyTheme.Layout.paddingL)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func difficultyColor(for difficulty: WorkoutDifficulty) -> Color {
        switch difficulty {
        case .beginner:
            return MovefullyTheme.Colors.softGreen
        case .intermediate:
            return MovefullyTheme.Colors.primaryTeal
        case .advanced:
            return MovefullyTheme.Colors.warmOrange
        }
    }
}

// MARK: - Template Picker View
struct TemplatePickerView: View {
    let dayIndex: Int
    @Binding var scheduledWorkouts: [Int: ScheduledWorkout]
    let viewModel: ProgramsViewModel
    let onTemplateSelected: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    
    var filteredTemplates: [WorkoutTemplate] {
        if searchText.isEmpty {
            return viewModel.workoutTemplates
        } else {
            return viewModel.workoutTemplates.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText) ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MovefullySearchField(
                    placeholder: "Search templates...",
                    text: $searchText
                )
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.bottom, MovefullyTheme.Layout.paddingM)
                
                ScrollView {
                    LazyVStack(spacing: MovefullyTheme.Layout.paddingM) {
                        ForEach(filteredTemplates) { template in
                            TemplateSelectionCard(template: template) {
                                selectTemplate(template)
                            }
                        }
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    .padding(.bottom, MovefullyTheme.Layout.paddingXL)
                }
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
    }
    
    private func selectTemplate(_ template: WorkoutTemplate) {
        let scheduledDate = Calendar.current.date(byAdding: .day, value: dayIndex, to: Date()) ?? Date()
        let scheduledWorkout = ScheduledWorkout(
            date: scheduledDate,
            workoutTemplate: template
        )
        scheduledWorkouts[dayIndex] = scheduledWorkout
        dismiss()
        onTemplateSelected()
    }
}

// MARK: - Template Selection Card
struct TemplateSelectionCard: View {
    let template: WorkoutTemplate
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                HStack {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                        Text(template.name)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text(template.description)
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: MovefullyTheme.Layout.paddingXS) {
                        Text("\(template.estimatedDuration) min")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        MovefullyStatusBadge(
                            text: template.difficulty.rawValue,
                            color: difficultyColor(for: template.difficulty),
                            showDot: false
                        )
                    }
                }
                
                if !template.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: MovefullyTheme.Layout.paddingS) {
                            ForEach(template.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(MovefullyTheme.Typography.caption)
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                    .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                                    .padding(.vertical, 2)
                                    .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(MovefullyTheme.Layout.paddingL)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func difficultyColor(for difficulty: WorkoutDifficulty) -> Color {
        switch difficulty {
        case .beginner:
            return MovefullyTheme.Colors.softGreen
        case .intermediate:
            return MovefullyTheme.Colors.primaryTeal
        case .advanced:
            return MovefullyTheme.Colors.warmOrange
        }
    }
}

// MARK: - Custom Workout Creator View  
struct CustomWorkoutCreatorView: View {
    let dayIndex: Int
    @Binding var scheduledWorkouts: [Int: ScheduledWorkout]
    let viewModel: ProgramsViewModel
    let onWorkoutCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var workoutName = ""
    @State private var workoutDescription = ""
    @State private var selectedExercises: [ExerciseWithSetsReps] = []
    @State private var estimatedDuration = 30
    @State private var difficulty: WorkoutDifficulty = .beginner
    @State private var showingExerciseSelector = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    MovefullyFormField(title: "Workout Name") {
                        MovefullyTextField(
                            placeholder: "e.g., Upper Body Strength",
                            text: $workoutName
                        )
                    }
                    
                    MovefullyFormField(title: "Description (Optional)") {
                        MovefullyTextField(
                            placeholder: "Brief description...",
                            text: $workoutDescription
                        )
                    }
                    
                    MovefullyFormField(title: "Estimated Duration (minutes)") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                                ForEach([15, 30, 45, 60, 75, 90], id: \.self) { duration in
                                    MovefullyPill(
                                        title: "\(duration) min",
                                        isSelected: estimatedDuration == duration,
                                        style: .filter
                                    ) {
                                        estimatedDuration = duration
                                    }
                                }
                            }
                            .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                        }
                    }
                    
                    MovefullyFormField(title: "Difficulty") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                ForEach(WorkoutDifficulty.allCases, id: \.self) { level in
                                    MovefullyPill(
                                        title: level.rawValue,
                                        isSelected: difficulty == level,
                                        style: .filter
                                    ) {
                                        difficulty = level
                                    }
                                }
                            }
                            .padding(.horizontal, MovefullyTheme.Layout.paddingXS)
                        }
                    }
                    
                    // Exercises section
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        HStack {
                            Text("Exercises")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            Button("Add Exercise") {
                                showingExerciseSelector = true
                            }
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        }
                        
                        if selectedExercises.isEmpty {
                            Text("No exercises added yet")
                                .font(MovefullyTheme.Typography.body)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, MovefullyTheme.Layout.paddingL)
                        } else {
                            ForEach(selectedExercises.indices, id: \.self) { index in
                                CustomExerciseRow(
                                    exercise: $selectedExercises[index],
                                    onRemove: { selectedExercises.remove(at: index) }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXXL)
            }
            .navigationTitle("Create Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCustomWorkout()
                    }
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    .disabled(workoutName.isEmpty || selectedExercises.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingExerciseSelector) {
            ExerciseSelectorView(selectedExercises: $selectedExercises)
        }
    }
    
    private func saveCustomWorkout() {
        let customWorkout = CustomWorkout(
            name: workoutName,
            description: workoutDescription,
            exercises: selectedExercises.map { $0.exercise },
            estimatedDuration: estimatedDuration,
            difficulty: difficulty,
            createdDate: Date()
        )
        
        let scheduledDate = Calendar.current.date(byAdding: .day, value: dayIndex, to: Date()) ?? Date()
        let scheduledWorkout = ScheduledWorkout(
            date: scheduledDate,
            customWorkout: customWorkout
        )
        
        scheduledWorkouts[dayIndex] = scheduledWorkout
        dismiss()
        onWorkoutCreated()
    }
}

// MARK: - Custom Exercise Row
struct CustomExerciseRow: View {
    @Binding var exercise: ExerciseWithSetsReps
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text(exercise.exercise.title)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    if let description = exercise.exercise.description {
                        Text(description)
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                }
            }
            
            // Sets and Reps Input
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text("Sets")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    HStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Button("-") {
                            if exercise.sets > 1 {
                                exercise.sets -= 1
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        .frame(width: 24, height: 24)
                        .background(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                        .clipShape(Circle())
                        
                        Text("\(exercise.sets)")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            .frame(minWidth: 16)
                        
                        Button("+") {
                            if exercise.sets < 10 {
                                exercise.sets += 1
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        .frame(width: 24, height: 24)
                        .background(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                        .clipShape(Circle())
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text(exercise.exercise.exerciseType == .reps ? "Reps" : "Duration (sec)")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    TextField(exercise.exercise.exerciseType == .reps ? "12" : "60", text: $exercise.reps)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                        .keyboardType(exercise.exercise.exerciseType == .duration ? .numberPad : .default)
                }
            }
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingM)
        .padding(.vertical, MovefullyTheme.Layout.paddingS)
        .background(MovefullyTheme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
    }
}

// MARK: - Exercise Selector View
struct ExerciseSelectorView: View {
    @Binding var selectedExercises: [ExerciseWithSetsReps]
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var tempSelectedExercises: Set<String> = []
    
    private var availableExercises: [Exercise] {
        return Exercise.sampleExercises
    }
    
    private var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return availableExercises
        } else {
            return availableExercises.filter { exercise in
                exercise.title.localizedCaseInsensitiveContains(searchText) ||
                exercise.description?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    private func isExerciseSelected(_ exercise: Exercise) -> Bool {
        // Check if already in selectedExercises or temporarily selected
        let alreadyAdded = selectedExercises.contains { $0.exercise.id == exercise.id }
        let tempSelected = tempSelectedExercises.contains(exercise.id)
        return alreadyAdded || tempSelected
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MovefullySearchField(
                    placeholder: "Search exercises...",
                    text: $searchText
                )
                .padding(.top, MovefullyTheme.Layout.paddingL)
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.bottom, MovefullyTheme.Layout.paddingM)
                
                // Selected count
                if !tempSelectedExercises.isEmpty {
                    HStack {
                        Text("\(tempSelectedExercises.count) exercises selected")
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        
                        Spacer()
                        
                        Button("Clear") {
                            tempSelectedExercises.removeAll()
                        }
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    .padding(.bottom, MovefullyTheme.Layout.paddingM)
                }
                
                ScrollView {
                    LazyVStack(spacing: MovefullyTheme.Layout.paddingS) {
                        ForEach(filteredExercises) { exercise in
                            ExerciseSelectionRow(
                                exercise: exercise, 
                                isSelected: isExerciseSelected(exercise)
                            ) {
                                toggleExerciseSelection(exercise)
                            }
                            .disabled(selectedExercises.contains { $0.exercise.id == exercise.id })
                        }
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    .padding(.bottom, MovefullyTheme.Layout.paddingXL)
                }
            }
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add (\(tempSelectedExercises.count))") {
                        addSelectedExercises()
                    }
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    .disabled(tempSelectedExercises.isEmpty)
                }
            }
        }
    }
    
    private func toggleExerciseSelection(_ exercise: Exercise) {
        if tempSelectedExercises.contains(exercise.id) {
            tempSelectedExercises.remove(exercise.id)
        } else {
            tempSelectedExercises.insert(exercise.id)
        }
    }
    
    private func addSelectedExercises() {
        for exerciseId in tempSelectedExercises {
            if let exercise = availableExercises.first(where: { $0.id == exerciseId }) {
                let exerciseWithSetsReps = ExerciseWithSetsReps(exercise: exercise)
                selectedExercises.append(exerciseWithSetsReps)
            }
        }
        dismiss()
    }
}



// MARK: - Plan Review View
struct PlanReviewView: View {
    let planName: String
    let planDescription: String
    let duration: Int
    let difficulty: WorkoutDifficulty
    let tags: [String]
    let scheduledWorkouts: [Int: ScheduledWorkout]
    let onSave: () -> Void
    
    private var workoutDays: Int {
        scheduledWorkouts.count
    }
    
    private var restDays: Int {
        (duration * 7) - workoutDays
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                // Header
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(MovefullyTheme.Colors.softGreen)
                    
                    Text("Review Plan")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("Review your plan details before saving")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, MovefullyTheme.Layout.paddingL)
                
                // Plan details
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Basic info
                    MovefullyCard {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                            Text("Plan Details")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                                ReviewDetailRow(title: "Name", value: planName)
                                ReviewDetailRow(title: "Duration", value: "\(duration) \(duration == 1 ? "Week" : "Weeks")")
                                ReviewDetailRow(title: "Difficulty", value: difficulty.rawValue)
                                
                                if !planDescription.isEmpty {
                                    ReviewDetailRow(title: "Description", value: planDescription)
                                }
                                
                                if !tags.isEmpty {
                                    ReviewDetailRow(title: "Tags", value: tags.joined(separator: ", "))
                                }
                            }
                        }
                    }
                    
                    // Workout summary
                    MovefullyCard {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                            Text("Workout Summary")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            HStack(spacing: MovefullyTheme.Layout.paddingL) {
                                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                                    Text("\(workoutDays)")
                                        .font(MovefullyTheme.Typography.title3)
                                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                    
                                    Text("Workout Days")
                                        .font(MovefullyTheme.Typography.caption)
                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                }
                                
                                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                                    Text("\(restDays)")
                                        .font(MovefullyTheme.Typography.title3)
                                        .foregroundColor(MovefullyTheme.Colors.softGreen)
                                    
                                    Text("Rest Days")
                                        .font(MovefullyTheme.Typography.caption)
                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            .padding(.bottom, MovefullyTheme.Layout.paddingXXL)
        }
    }
}

// MARK: - Review Detail Row
struct ReviewDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title + ":")
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Plans Detail View
struct PlansDetailView: View {
    let program: Program
    @EnvironmentObject private var viewModel: ProgramsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditPlan = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                // Plan Header
                planHeaderSection
                
                // Plan Stats
                planStatsSection
                
                // Workout Schedule
                workoutScheduleSection
                
                // Plan Notes (always show)
                planNotesCard
            }
            .padding(.top, MovefullyTheme.Layout.paddingL)
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            .padding(.bottom, MovefullyTheme.Layout.paddingXXL)
        }
        .movefullyBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit Plan") {
                        showingEditPlan = true
                    }
                    
                    Button("Duplicate Plan") {
                        // Handle duplication
                    }
                    
                    Divider()
                    
                    Button("Delete Plan", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                }
            }
        }
        .alert("Delete Plan", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Handle deletion
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this plan? This action cannot be undone.")
        }
        .sheet(isPresented: $showingEditPlan) {
            EditPlanView(program: program)
                .environmentObject(viewModel)
        }
    }
    
    // MARK: - Plan Header Section
    private var planHeaderSection: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Plan Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                            .fill(planColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: program.icon)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(planColor)
                    }
                    
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text(program.name)
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text(program.description)
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(nil)
                        
                        // Difficulty Badge
                        HStack {
                            Text(program.difficulty.rawValue)
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(planColor)
                                .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                                .padding(.vertical, MovefullyTheme.Layout.paddingS)
                                .background(planColor.opacity(0.15))
                                .clipShape(Capsule())
                            
                            if program.isDraft {
                                MovefullyStatusBadge(
                                    text: "Draft",
                                    color: MovefullyTheme.Colors.warmOrange,
                                    showDot: false
                                )
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                // Tags
                if !program.tags.isEmpty {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        HStack {
                            Text("Tags")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            Spacer()
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                ForEach(program.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(MovefullyTheme.Typography.caption)
                                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                        .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                                        .padding(.vertical, MovefullyTheme.Layout.paddingS)
                                        .background(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Plan Stats Section
    private var planStatsSection: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                HStack {
                    Text("Plan Overview")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    Spacer()
                }
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    HStack(spacing: MovefullyTheme.Layout.paddingM) {
                        PlansStatCard(
                            icon: "calendar",
                            value: "\(program.duration)",
                            label: program.duration == 1 ? "Week" : "Weeks",
                            color: MovefullyTheme.Colors.primaryTeal
                        )
                        
                        PlansStatCard(
                            icon: "dumbbell.fill",
                            value: "\(workoutCount)",
                            label: "Workouts",
                            color: MovefullyTheme.Colors.softGreen
                        )
                    }
                    
                    HStack(spacing: MovefullyTheme.Layout.paddingM) {
                        PlansStatCard(
                            icon: "person.2.fill",
                            value: "\(program.usageCount)",
                            label: "Assigned",
                            color: MovefullyTheme.Colors.warmOrange
                        )
                        
                        PlansStatCard(
                            icon: "chart.line.uptrend.xyaxis",
                            value: "\(program.difficulty.rawValue)",
                            label: "Difficulty",
                            color: difficultyColor(for: program.difficulty)
                        )
                    }
                }
            }
        }
    }
    

    
    // MARK: - Workout Schedule Section
    private var workoutScheduleSection: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                Text("Workout Schedule")
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                if program.scheduledWorkouts.isEmpty {
                    Text("No workouts scheduled")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, MovefullyTheme.Layout.paddingL)
                } else {
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        // Display actual scheduled workouts from the program
                        ForEach(Array(program.scheduledWorkouts.enumerated()), id: \.offset) { index, workout in
                            WorkoutScheduleRow(
                                day: index + 1,
                                workoutName: workout.title,
                                duration: workout.estimatedDuration,
                                difficulty: program.difficulty
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Plan Notes Card
    private var planNotesCard: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.warmOrange)
                    
                    Text("Plan Notes")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Spacer()
                }
                
                if let coachingNotes = program.coachingNotes, !coachingNotes.isEmpty {
                    // Show actual notes
                    HStack {
                        Text(coachingNotes)
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(MovefullyTheme.Layout.paddingM)
                    .background(MovefullyTheme.Colors.warmOrange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    .overlay(
                        RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                            .stroke(MovefullyTheme.Colors.warmOrange.opacity(0.2), lineWidth: 1)
                    )
                } else {
                    // Show placeholder when no notes
                    HStack {
                        Text("No plan notes added")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                            .italic()
                        
                        Spacer()
                    }
                    .padding(MovefullyTheme.Layout.paddingM)
                    .background(MovefullyTheme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    .overlay(
                        RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                            .stroke(MovefullyTheme.Colors.divider, lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var workoutCount: Int {
        return program.scheduledWorkouts.count
    }
    
    private var planColor: Color {
        switch program.difficulty {
        case .beginner:
            return MovefullyTheme.Colors.softGreen
        case .intermediate:
            return MovefullyTheme.Colors.primaryTeal
        case .advanced:
            return MovefullyTheme.Colors.warmOrange
        }
    }
    
    private func difficultyColor(for difficulty: WorkoutDifficulty) -> Color {
        switch difficulty {
        case .beginner:
            return MovefullyTheme.Colors.softGreen
        case .intermediate:
            return MovefullyTheme.Colors.primaryTeal
        case .advanced:
            return MovefullyTheme.Colors.warmOrange
        }
    }
}

// MARK: - Supporting Views for Plans Detail
struct PlansStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingS) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            Text(label)
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(MovefullyTheme.Layout.paddingM)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .overlay(
            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct PlansStatView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingXS) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            Text(label)
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
        }
    }
}

struct PlansDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
        }
    }
}

struct WorkoutScheduleRow: View {
    let day: Int
    let workoutName: String
    let duration: Int
    let difficulty: WorkoutDifficulty
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            // Day number
            Text("Day \(day)")
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                .frame(width: 50, alignment: .leading)
            
            // Workout info
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                Text(workoutName)
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text("\(duration) min")
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            // Difficulty badge
            MovefullyStatusBadge(
                text: difficulty.rawValue,
                color: difficultyColor(for: difficulty),
                showDot: false
            )
        }
        .padding(.vertical, MovefullyTheme.Layout.paddingS)
    }
    
    private func difficultyColor(for difficulty: WorkoutDifficulty) -> Color {
        switch difficulty {
        case .beginner:
            return MovefullyTheme.Colors.softGreen
        case .intermediate:
            return MovefullyTheme.Colors.primaryTeal
        case .advanced:
            return MovefullyTheme.Colors.warmOrange
        }
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let displayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - Edit Plan View
struct EditPlanView: View {
    let program: Program
    @EnvironmentObject var viewModel: ProgramsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 1
    @State private var planName: String
    @State private var planDescription: String
    @State private var selectedDifficulty: WorkoutDifficulty
    @State private var selectedDuration: Int // in weeks

    @State private var selectedTags: Set<String>
    @State private var coachingNotes: String
    @State private var scheduledWorkouts: [Int: ScheduledWorkout]
    @State private var isLoading = false
    @State private var showingExerciseLibrary = false
    @State private var showingUnsavedChangesAlert = false
    
    private let totalSteps = 4
    private let maxWeeks = 12
    
    // Pre-defined tags
    private let availableTags = [
        "Strength", "Cardio", "HIIT", "Flexibility", "Balance", 
        "Core", "Upper Body", "Lower Body", "Full Body", "Recovery",
        "Beginner Friendly", "Advanced", "Quick Workout", "Endurance",
        "4-Week", "8-Week", "12-Week", "Foundation", "Sport Specific"
    ]
    

    
    init(program: Program) {
        self.program = program
        // Initialize state with program data
        self._planName = State(initialValue: program.name)
        self._planDescription = State(initialValue: program.description)
        self._selectedDifficulty = State(initialValue: program.difficulty)
        self._selectedDuration = State(initialValue: program.duration / 7) // Convert days to weeks

        self._selectedTags = State(initialValue: Set(program.tags))
        self._coachingNotes = State(initialValue: program.coachingNotes ?? "")
        
        // Convert program's scheduled workouts to the [Int: ScheduledWorkout] format needed by the UI
        var workoutsDict: [Int: ScheduledWorkout] = [:]
        let programStartDate = program.createdDate
        
        for workout in program.scheduledWorkouts {
            let daysBetween = Calendar.current.dateComponents([.day], from: programStartDate, to: workout.scheduledDate).day ?? 0
            if daysBetween >= 0 && daysBetween < program.duration {
                workoutsDict[daysBetween] = workout
            }
        }
        
        self._scheduledWorkouts = State(initialValue: workoutsDict)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Progress Indicator
                    progressIndicator
                    
                    // Step Content
                    Group {
                        switch currentStep {
                        case 1:
                            planBasicsStep
                        case 2:
                            workoutSchedulingStep
                        case 3:
                            additionalDetailsStep
                        case 4:
                            reviewAndUpdateStep
                        default:
                            EmptyView()
                        }
                    }
                    
                    // Navigation Buttons
                    navigationButtons
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXXL)
            }
            .movefullyBackground()
            .navigationTitle("Edit Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { 
                        if hasUnsavedChanges {
                            showingUnsavedChangesAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
        .alert("Unsaved Changes", isPresented: $showingUnsavedChangesAlert) {
            Button("Save Draft") { saveDraft() }
            Button("Discard", role: .destructive) { dismiss() }
            Button("Continue Editing", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. Would you like to save them as a draft?")
        }
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        HStack {
            ForEach(1...totalSteps, id: \.self) { step in
                HStack(spacing: MovefullyTheme.Layout.paddingS) {
                    Circle()
                        .fill(step <= currentStep ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.inactive)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("\(step)")
                                .font(MovefullyTheme.Typography.footnote)
                                .foregroundColor(.white)
                        )
                    
                    if step < totalSteps {
                        Rectangle()
                            .fill(step < currentStep ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.inactive)
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.top, MovefullyTheme.Layout.paddingL)
    }
    
    // MARK: - Step 1: Plan Basics
    private var planBasicsStep: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                MovefullyPageHeader(
                    title: "Plan Basics",
                    subtitle: "Update the fundamental details of your plan"
                )
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    MovefullyFormField(title: "Plan Name", isRequired: true) {
                        MovefullyTextField(
                            placeholder: "e.g., 4-Week Strength Foundation",
                            text: $planName
                        )
                    }
                    
                    MovefullyFormField(title: "Description", isRequired: true) {
                        MovefullyTextEditor(
                            placeholder: "Describe what this plan focuses on...",
                            text: $planDescription,
                            minLines: 3,
                            maxLines: 5
                        )
                    }
                    
                    MovefullyFormField(title: "Duration (weeks)") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                                ForEach(1...maxWeeks, id: \.self) { weeks in
                                    MovefullyPill(
                                        title: "\(weeks) \(weeks == 1 ? "week" : "weeks")",
                                        isSelected: selectedDuration == weeks,
                                        style: .filter
                                    ) {
                                        selectedDuration = weeks
                                    }
                                }
                            }
                            .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                        }
                    }
                    
                    MovefullyFormField(title: "Difficulty Level") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                ForEach(WorkoutDifficulty.allCases, id: \.self) { difficulty in
                                    MovefullyPill(
                                        title: difficulty.rawValue,
                                        isSelected: selectedDifficulty == difficulty,
                                        style: .filter
                                    ) {
                                        selectedDifficulty = difficulty
                                    }
                                }
                            }
                            .padding(.horizontal, MovefullyTheme.Layout.paddingXS)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 2: Workout Scheduling
    private var workoutSchedulingStep: some View {
        PlanSchedulingView(
            duration: selectedDuration,
            scheduledWorkouts: $scheduledWorkouts,
            viewModel: viewModel
        )
    }
    
    // MARK: - Step 3: Additional Details
    private var additionalDetailsStep: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                MovefullyPageHeader(
                    title: "Additional Details",
                    subtitle: "Update tags and notes for your plan"
                )
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    MovefullyFormField(title: "Tags") {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible()), count: 2),
                            spacing: MovefullyTheme.Layout.paddingS
                        ) {
                            ForEach(availableTags, id: \.self) { tag in
                                MovefullyPill(
                                    title: tag,
                                    isSelected: selectedTags.contains(tag),
                                    style: .filter
                                ) {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                }
                            }
                        }
                    }
                    
                    MovefullyFormField(
                        title: "Plan Notes",
                        subtitle: "Optional notes for trainers using this plan"
                    ) {
                        MovefullyTextEditor(
                            placeholder: "Add important information, special instructions, or client guidance...",
                            text: $coachingNotes,
                            minLines: 3,
                            maxLines: 6
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Step 4: Review and Update
    private var reviewAndUpdateStep: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                MovefullyPageHeader(
                    title: "Review Changes",
                    subtitle: "Review your plan updates before saving"
                )
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Basic Information
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text("Plan Information")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        ReviewDetailRow(title: "Name", value: planName)
                        ReviewDetailRow(title: "Duration", value: "\(selectedDuration) \(selectedDuration == 1 ? "Week" : "Weeks")")
                        ReviewDetailRow(title: "Difficulty", value: selectedDifficulty.rawValue)
                        
                        if !planDescription.isEmpty {
                            ReviewDetailRow(title: "Description", value: planDescription)
                        }
                        
                        if !selectedTags.isEmpty {
                            ReviewDetailRow(title: "Tags", value: Array(selectedTags).sorted().joined(separator: ", "))
                        }
                    }
                    
                    Divider()
                        .background(MovefullyTheme.Colors.divider)
                    
                    // Workout Summary
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text("Workout Summary")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        ReviewDetailRow(title: "Total Days", value: "\(selectedDuration * 7)")
                        ReviewDetailRow(title: "Scheduled Workouts", value: "\(scheduledWorkouts.count)")
                        ReviewDetailRow(title: "Rest Days", value: "\((selectedDuration * 7) - scheduledWorkouts.count)")
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            if currentStep > 1 && currentStep < totalSteps {
                // Previous and Next buttons side by side
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Button("Previous") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep -= 1
                        }
                    }
                    .movefullyButtonStyle(.tertiary)
                    
                    Button("Next") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep += 1
                        }
                    }
                    .movefullyButtonStyle(.primary)
                    .disabled(!canProceedFromCurrentStep)
                }
            } else if currentStep == 1 {
                // Only Next button, full width
                Button("Next") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                }
                .movefullyButtonStyle(.primary)
                .disabled(!canProceedFromCurrentStep)
            } else {
                // Previous and Update buttons on final step
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Button("Previous") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep -= 1
                        }
                    }
                    .movefullyButtonStyle(.tertiary)
                    
                    Button(isLoading ? "Updating..." : "Update Plan") {
                        updatePlan()
                    }
                    .movefullyButtonStyle(.primary)
                    .disabled(isLoading || !canProceedFromCurrentStep)
                }
            }
        }
        .padding(.bottom, MovefullyTheme.Layout.paddingXL)
    }
    
    // MARK: - Helper Properties
    private var canProceedFromCurrentStep: Bool {
        switch currentStep {
        case 1:
            return !planName.isEmpty && !planDescription.isEmpty
        case 2:
            return true // Workout scheduling is optional
        case 3:
            return true // Additional details are optional
        case 4:
            return !planName.isEmpty && !planDescription.isEmpty
        default:
            return false
        }
    }
    
    private var hasUnsavedChanges: Bool {
        planName != program.name ||
        planDescription != program.description ||
        selectedDifficulty != program.difficulty ||
        selectedDuration != (program.duration / 7) ||
        coachingNotes != (program.coachingNotes ?? "") ||
        Set(program.tags) != selectedTags
    }
    
    // MARK: - Dynamic Icon Logic  
    private var dynamicIcon: String {
        // Priority order for icon selection based on tags
        if selectedTags.contains("Strength") || selectedTags.contains("Upper Body") || selectedTags.contains("Lower Body") {
            return "dumbbell.fill"
        } else if selectedTags.contains("Cardio") || selectedTags.contains("HIIT") || selectedTags.contains("Endurance") {
            return "heart.fill"
        } else if selectedTags.contains("Flexibility") || selectedTags.contains("Mobility") {
            return "figure.yoga"
        } else if selectedTags.contains("Core") || selectedTags.contains("Stability") {
            return "circle.grid.3x3.fill"
        } else if selectedTags.contains("Balance") || selectedTags.contains("Functional") {
            return "figure.stand"
        } else if selectedTags.contains("Recovery") {
            return "leaf.fill"
        } else if selectedTags.contains("Quick Workout") || selectedTags.contains("Beginner Friendly") {
            return "timer"
        } else {
            return "calendar.badge.plus"
        }
    }
    
    // MARK: - Actions
    private func updatePlan() {
        isLoading = true
        
        let updatedProgram = Program(
            name: planName,
            description: planDescription,
            duration: selectedDuration * 7, // Convert weeks to days
            difficulty: selectedDifficulty,
            scheduledWorkouts: Array(scheduledWorkouts.values).sorted(by: { $0.date < $1.date }),
            tags: Array(selectedTags).sorted(),
            usageCount: program.usageCount,
            createdDate: program.createdDate,
            lastModified: Date(),
            isDraft: false,
            icon: dynamicIcon,
            coachingNotes: coachingNotes.isEmpty ? nil : coachingNotes
        )
        
        viewModel.updateProgram(updatedProgram)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            dismiss()
        }
    }
    
    private func saveDraft() {
        let draftProgram = Program(
            name: planName,
            description: planDescription,
            duration: selectedDuration * 7, // Convert weeks to days
            difficulty: selectedDifficulty,
            scheduledWorkouts: Array(scheduledWorkouts.values).sorted(by: { $0.date < $1.date }),
            tags: Array(selectedTags).sorted(),
            usageCount: program.usageCount,
            createdDate: program.createdDate,
            lastModified: Date(),
            isDraft: true,
            icon: dynamicIcon,
            coachingNotes: coachingNotes.isEmpty ? nil : coachingNotes
        )
        
        viewModel.updateProgram(draftProgram)
        dismiss()
    }
} 