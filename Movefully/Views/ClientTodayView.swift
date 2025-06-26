import SwiftUI

// MARK: - Client Today View
struct ClientTodayView: View {
    @ObservedObject var viewModel: ClientViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingWorkoutDetail = false
    @State private var showingWorkoutSession = false
    @State private var showingWorkoutReview = false
    @State private var showingCompletionDialog = false
    @State private var showingProfile = false
    @State private var selectedWorkout: WorkoutAssignment?
    
    // Session persistence
    @StateObject private var persistenceService = WorkoutSessionPersistenceService.shared
    @State private var showingSessionRestoration = false
    
    // Confirmation modal for starting new workout
    @State private var showingNewWorkoutConfirmation = false
    @State private var pendingWorkout: WorkoutAssignment?
    
    var body: some View {
        MovefullyClientNavigation(
            title: "Today",
            showProfileButton: true,
            profileAction: {
                showingProfile = true
            }
        ) {
            // Active session restoration banner
            if persistenceService.hasActiveSession {
                activeSessionBanner
            }
            
            // Header section
            headerSection
            
            // Main content based on loading state and workout availability
            if viewModel.isLoading {
                LoadingStateView()
            } else if let todayWorkout = viewModel.todayWorkout {
                workoutSection(todayWorkout)
            } else {
                NoPlanAssignedCard()
            }
            

            
            // Quick stats
            quickStatsSection
        }
        .onAppear {
            viewModel.loadTodayWorkout()
            checkForActiveSession()
        }
        .onChange(of: showingWorkoutSession) { oldValue, newValue in
            print("🔄 showingWorkoutSession changed to: \(newValue)")
            if newValue {
                print("🔄 selectedWorkout: \(selectedWorkout?.title ?? "nil")")
            }
        }
        .sheet(isPresented: $showingWorkoutDetail) {
            if let workout = viewModel.todayWorkout {
                WorkoutDetailView(assignment: workout, viewModel: viewModel, isReadOnly: true)
            }
        }
        .sheet(isPresented: $showingWorkoutSession) {
            if let workout = selectedWorkout {
                WorkoutSessionView(assignment: workout, viewModel: viewModel)
                    .onAppear {
                        print("📱 Presenting WorkoutSessionView for: \(workout.title)")
                    }
            } else {
                Text("No workout selected")
                    .onAppear {
                        print("❌ No selectedWorkout available for session")
                    }
            }
        }
        .sheet(isPresented: $showingProfile) {
            ClientProfileView(viewModel: viewModel)
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingWorkoutReview) {
            if let workout = selectedWorkout {
                WorkoutReviewView(assignment: workout, viewModel: viewModel)
            }
        }
        .alert("Start New Workout?", isPresented: $showingNewWorkoutConfirmation) {
            Button("Cancel", role: .cancel) {
                pendingWorkout = nil
            }
            Button("Start New", role: .destructive) {
                // Cancel existing session and start new one
                persistenceService.cancelSession()
                if let workout = pendingWorkout {
                    selectedWorkout = workout
                    showingWorkoutSession = true
                }
                pendingWorkout = nil
            }
        } message: {
            Text("You have a workout in progress. Starting a new workout will cancel your current session and you'll lose your progress.")
        }
    }
    
    // MARK: - Active Session Banner
    private var activeSessionBanner: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(MovefullyTheme.Typography.title3)
                        .foregroundColor(MovefullyTheme.Colors.warmOrange)
                    
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                        Text("Workout in Progress")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        if let session = persistenceService.currentSession {
                            Text("Continue \"\(session.workoutTitle)\"")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Resume Workout") {
                        print("🎯 Resume Workout button tapped")
                        resumeActiveSession()
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    .padding(.vertical, MovefullyTheme.Layout.paddingS)
                    .background(MovefullyTheme.Colors.warmOrange)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                }
                
                // Progress indicator
                if let session = persistenceService.currentSession {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        HStack {
                            Text("Progress")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            
                            Spacer()
                            
                            Text("\(session.completedExercises.count + session.skippedExercises.count) exercises completed")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                        
                        ProgressView(value: session.progressPercentage)
                            .tint(MovefullyTheme.Colors.warmOrange)
                            .scaleEffect(y: 1.5)
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                .stroke(MovefullyTheme.Colors.warmOrange.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Add top padding to match trainer views
            Spacer()
                .frame(height: MovefullyTheme.Layout.paddingM)
            
            MovefullyCard {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                    HStack {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            Text("Good \(timeOfDayGreeting), \(viewModel.isLoading ? "" : (viewModel.currentClient?.name.components(separatedBy: " ").first ?? "there"))!")
                                .font(MovefullyTheme.Typography.title2)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Text(todayDateString)
                                .font(MovefullyTheme.Typography.callout)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "sun.max.fill")
                            .font(MovefullyTheme.Typography.title1)
                            .foregroundColor(MovefullyTheme.Colors.warmOrange.opacity(0.7))
                    }
                }
            }
        }
    }
    
    // MARK: - Workout Section
    private func workoutSection(_ workout: WorkoutAssignment) -> some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingL) {
                // Workout header
                HStack {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text("Today's Workout")
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                        
                        Text(workout.title)
                            .font(MovefullyTheme.Typography.title1)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        MovefullyStatusBadge(
                            text: workout.status.rawValue,
                            color: workout.status.color,
                            showDot: true
                        )
                        
                        MovefullyStatusBadge(
                            text: "\(workout.estimatedDuration) min",
                            color: MovefullyTheme.Colors.primaryTeal,
                            showDot: false
                        )
                    }
                }
                
                // Workout description
                if let description = workout.description, !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(description)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .padding(MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.primaryTeal.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                }
                
                // Exercise count
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Image(systemName: workout.status == .completed ? "checkmark.circle.fill" : "list.bullet")
                        .foregroundColor(workout.status == .completed ? MovefullyTheme.Colors.softGreen : MovefullyTheme.Colors.primaryTeal)
                    
                    Text("\(workout.exercises.count) exercises")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    if workout.status == .completed {
                        Text("• Great job!")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.softGreen)
                    }
                    
                    Spacer()
                }
                
                // Action buttons - different based on completion status
                if workout.status == .completed {
                    // Completed workout actions
                    HStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Button("View Details") {
                            showingWorkoutDetail = true
                        }
                        .font(MovefullyTheme.Typography.buttonMedium)
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                        
                        Button("Review Session") {
                            selectedWorkout = workout
                            showingWorkoutReview = true
                        }
                        .font(MovefullyTheme.Typography.buttonMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.softGreen)
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    }
                } else {
                    // Pending workout actions
                    HStack(spacing: MovefullyTheme.Layout.paddingM) {
                        // Details button - shows read-only view
                        Button("Details") {
                            showingWorkoutDetail = true
                        }
                        .font(MovefullyTheme.Typography.buttonMedium)
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                        .padding(.vertical, MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                        .lineLimit(1)
                        
                        // Start Workout button - begins interactive session
                        Button("Start Workout") {
                            if persistenceService.hasActiveSession {
                                // Show confirmation modal
                                pendingWorkout = workout
                                showingNewWorkoutConfirmation = true
                            } else {
                                // Start workout directly
                                selectedWorkout = workout
                                showingWorkoutSession = true
                            }
                        }
                        .font(MovefullyTheme.Typography.buttonMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MovefullyTheme.Layout.paddingM)
                        .background(
                            LinearGradient(
                                colors: [
                                    MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.primaryTeal.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                        .shadow(color: MovefullyTheme.Colors.primaryTeal.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
            }
        }
    }
    
    // MARK: - No Plan Section
    private var noPlanSection: some View {
        NoPlanAssignedCard()
    }
    
    // MARK: - Rest Day Section
    private var restDaySection: some View {
        RestDayCard(date: Date())
    }
    

    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            HStack {
                Text("Daily Inspiration")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                Spacer()
            }
            
            // Daily inspirational quote card
            MovefullyCard {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Quote icon and category
                    HStack {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                Image(systemName: viewModel.dailyInspirationalQuote.category.icon)
                                    .font(MovefullyTheme.Typography.title3)
                                    .foregroundColor(viewModel.dailyInspirationalQuote.category.color)
                                
                                Text(viewModel.dailyInspirationalQuote.category.rawValue)
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(viewModel.dailyInspirationalQuote.category.color)
                            }
                            
                            Text("Today's Inspiration")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1.2)
                        }
                        
                        Spacer()
                    }
                    
                    // Quote text
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("\"\(viewModel.dailyInspirationalQuote.text)\"")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            .italic()
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                        
                        HStack {
                            Spacer()
                            Text("— \(viewModel.dailyInspirationalQuote.author)")
                                .font(MovefullyTheme.Typography.callout)
                                .foregroundColor(viewModel.dailyInspirationalQuote.category.color)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                }
                .padding(.vertical, MovefullyTheme.Layout.paddingS)
            }
            .background(
                LinearGradient(
                    colors: [
                        viewModel.dailyInspirationalQuote.category.color.opacity(0.02),
                        viewModel.dailyInspirationalQuote.category.color.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                    .stroke(
                        LinearGradient(
                            colors: [
                                viewModel.dailyInspirationalQuote.category.color.opacity(0.2),
                                viewModel.dailyInspirationalQuote.category.color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }
    
    // MARK: - Helper Properties
    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }
    
    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
    
    // MARK: - Session Management
    
    private func checkForActiveSession() {
        print("🔍 Checking for active session on app launch")
        
        // First check if there's a local session
        if let session = persistenceService.restoreSessionIfExists() {
            print("✅ Found active session: \(session.workoutTitle)")
            // Session is restored, banner will show automatically
        } else {
            print("🔄 No active session found")
        }
    }
    
    private func resumeActiveSession() {
        guard let session = persistenceService.currentSession else {
            print("❌ No active session to resume")
            return
        }
        
        print("🔄 Resuming session for workout: \(session.workoutTitle)")
        print("🔄 Session workout ID: \(session.workoutId)")
        
        // First, try to find the workout that matches the session by ID
        if let todayWorkout = viewModel.todayWorkout,
           session.workoutId == todayWorkout.id.uuidString {
            // Resume today's workout
            print("✅ Found matching today's workout by ID")
            selectedWorkout = todayWorkout
            showingWorkoutSession = true
            return
        }
        
        // If ID doesn't match, try to match by title (more robust for regenerated workouts)
        if let todayWorkout = viewModel.todayWorkout,
           session.workoutTitle == todayWorkout.title {
            print("✅ Found matching today's workout by title: \(todayWorkout.title)")
            selectedWorkout = todayWorkout
            showingWorkoutSession = true
            return
        }
        
        // Check weekly assignments by ID first
        for weekAssignments in viewModel.assignmentsByWeek.values {
            if let matchingWorkout = weekAssignments.first(where: { $0.id.uuidString == session.workoutId }) {
                print("✅ Found matching workout in weekly assignments by ID")
                selectedWorkout = matchingWorkout
                showingWorkoutSession = true
                return
            }
        }
        
        // Check weekly assignments by title
        for weekAssignments in viewModel.assignmentsByWeek.values {
            if let matchingWorkout = weekAssignments.first(where: { $0.title == session.workoutTitle }) {
                print("✅ Found matching workout in weekly assignments by title: \(matchingWorkout.title)")
                selectedWorkout = matchingWorkout
                showingWorkoutSession = true
                return
            }
        }
        
        // If we can't find the exact workout, try to reload and match by title
        print("⚠️ Could not find matching workout, attempting to reload from service")
        Task {
            // Try to reload today's workout first
            await viewModel.loadTodayWorkout()
            
            // Check if the reloaded workout matches by title
            if let todayWorkout = viewModel.todayWorkout,
               session.workoutTitle == todayWorkout.title {
                print("✅ Found matching workout after reload by title: \(todayWorkout.title)")
                await MainActor.run {
                    selectedWorkout = todayWorkout
                    showingWorkoutSession = true
                }
                return
            }
            
            // If still no match, create a minimal workout from session data
            print("⚠️ Creating minimal workout from session data")
            await MainActor.run {
                let minimalWorkout = WorkoutAssignment(
                    title: session.workoutTitle,
                    description: "Resumed workout session",
                    date: Date(),
                    status: .pending,
                    exercises: [], // Will be populated from session if needed
                    trainerNotes: "This workout was resumed from a previous session",
                    estimatedDuration: 30
                )
                selectedWorkout = minimalWorkout
                showingWorkoutSession = true
            }
        }
    }
}

// MARK: - Workout Detail View (Read-Only)
struct WorkoutDetailView: View {
    let assignment: WorkoutAssignment
    @ObservedObject var viewModel: ClientViewModel
    let isReadOnly: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showingCompletionDialog = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                    // Workout header
                    MovefullyCard {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                            Text(assignment.title)
                                .font(MovefullyTheme.Typography.title1)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack {
                                MovefullyStatusBadge(
                                    text: "\(assignment.estimatedDuration) min",
                                    color: MovefullyTheme.Colors.primaryTeal,
                                    showDot: false
                                )
                                
                                MovefullyStatusBadge(
                                    text: "\(assignment.exercises.count) exercises",
                                    color: MovefullyTheme.Colors.gentleBlue,
                                    showDot: false
                                )
                            }
                            
                            // Workout description
                            if let description = assignment.description, !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(description)
                                    .font(MovefullyTheme.Typography.body)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(MovefullyTheme.Layout.paddingM)
                                    .background(MovefullyTheme.Colors.primaryTeal.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                            }
                        }
                    }
                    
                    // Exercise list
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        HStack {
                            Text("Exercises")
                                .font(MovefullyTheme.Typography.title3)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            Spacer()
                        }
                        
                        ForEach(Array(assignment.exercises.enumerated()), id: \.element.id) { index, exercise in
                            ExerciseDetailCard(exercise: exercise, number: index + 1)
                        }
                    }
                    
                    // Complete workout button (only if not read-only)
                    if !isReadOnly && assignment.status != .completed {
                        Button("Mark as Complete") {
                            showingCompletionDialog = true
                        }
                        .font(MovefullyTheme.Typography.buttonMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.softGreen)
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                        .shadow(color: MovefullyTheme.Colors.softGreen.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    
                    Spacer(minLength: MovefullyTheme.Layout.paddingXXL)
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.top, MovefullyTheme.Layout.paddingM)
            }
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationTitle(isReadOnly ? "Workout Preview" : "Workout Details")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
        .sheet(isPresented: $showingCompletionDialog) {
            WorkoutCompletionView(
                assignment: assignment, 
                viewModel: viewModel,
                skippedExercises: [],
                completedExercises: [],
                actualDuration: 0
            )
                .onDisappear {
                    // Check if workout was completed and dismiss session view if so
                    if let updatedWorkout = viewModel.todayWorkout,
                       updatedWorkout.id == assignment.id,
                       updatedWorkout.status == .completed {
                        dismiss()
                    }
                }
        }
    }
}

// MARK: - Exercise Detail Card
struct ExerciseDetailCard: View {
    let exercise: AssignedExercise
    let number: Int
    @State private var showingExerciseDetail = false
    
    var body: some View {
        Button(action: {
            showingExerciseDetail = true
        }) {
            MovefullyCard {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                    // Exercise header
                    HStack(spacing: MovefullyTheme.Layout.paddingM) {
                        // Exercise number
                        Text("\(number)")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(MovefullyTheme.Colors.primaryTeal)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                            HStack {
                                Text(exercise.title)
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Spacer()
                                
                                // Tap indicator
                                Image(systemName: "info.circle")
                                    .font(MovefullyTheme.Typography.callout)
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            }
                            
                            HStack {
                                MovefullyStatusBadge(
                                    text: exercise.category.rawValue,
                                    color: MovefullyTheme.Colors.primaryTeal,
                                    showDot: false
                                )
                            }
                        }
                    }
                    
                    // Exercise description
                    Text(exercise.description)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(nil)
                    
                    // Exercise parameters - side by side layout without rest time
                    HStack(spacing: MovefullyTheme.Layout.paddingL) {
                        if let sets = exercise.sets {
                            exerciseParam(icon: "repeat", text: "\(sets) sets")
                        }
                        
                        // Show reps or duration based on exerciseType, not both
                        switch exercise.exerciseType {
                        case .reps:
                            if let reps = exercise.reps {
                                exerciseParam(icon: "number", text: "\(reps) reps")
                            }
                        case .duration:
                            if let duration = exercise.duration {
                                exerciseParam(icon: "timer", text: "\(duration) seconds")
                            }
                        }
                        
                        Spacer()
                    }
                    .onAppear {
                        // Debug logging moved outside ViewBuilder
                        if exercise.sets == nil {
                            print("⚠️ [DEBUG] Exercise '\(exercise.title)' has no sets data (detail view)")
                        }
                        if exercise.exerciseType == .reps && exercise.reps == nil {
                            print("⚠️ [DEBUG] Reps exercise '\(exercise.title)' has no reps data (detail view)")
                        }
                        if exercise.exerciseType == .duration && exercise.duration == nil {
                            print("⚠️ [DEBUG] Duration exercise '\(exercise.title)' has no duration data (detail view)")
                        }
                    }
                    
                    // Trainer tips
                    if let tips = exercise.trainerTips {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(MovefullyTheme.Colors.warmOrange)
                                Text("Trainer Tip")
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.warmOrange)
                            }
                            
                            Text(tips)
                                .font(MovefullyTheme.Typography.body)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .italic()
                        }
                        .padding(MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.warmOrange.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingExerciseDetail) {
            if let sourceExercise = findSourceExercise(for: exercise) {
                ExerciseDetailView(exercise: sourceExercise)
            }
        }
    }
    
    private func exerciseParam(icon: String, text: String) -> some View {
        HStack(spacing: MovefullyTheme.Layout.paddingS) {
            Image(systemName: icon)
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                .frame(width: 16)
            
            Text(text)
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
        }
    }
    
    // Link to the source of truth exercise database
    private func findSourceExercise(for assignedExercise: AssignedExercise) -> Exercise? {
        // This would typically query the Exercise database/viewModel
        // For now, create a bridge from AssignedExercise to Exercise
        return Exercise(
            id: assignedExercise.id.uuidString, // Convert UUID to String
            title: assignedExercise.title,
            description: assignedExercise.description,
            mediaUrl: nil, // Could be populated from exercise database
            category: assignedExercise.category,
            difficulty: .intermediate, // Could be derived from exercise database
            createdByTrainerId: nil,
            exerciseType: assignedExercise.exerciseType // Use the actual exercise type
        )
    }
}

// MARK: - Workout Completion View
struct WorkoutCompletionView: View {
    let assignment: WorkoutAssignment
    @ObservedObject var viewModel: ClientViewModel
    let skippedExercises: Set<Int>
    let completedExercises: Set<Int>
    let actualDuration: Int
    @Environment(\.dismiss) private var dismiss
    @State private var feelingLevel = 3 // 1-5, corresponds to emoji faces
    @State private var notes = ""
    @State private var animateSuccess = false
    @State private var showConfetti = false
    @FocusState private var isTextFieldFocused: Bool
    
    // Feeling level data with emojis and descriptions
    private let feelingLevels = [
        (emoji: "😴", title: "Tired", description: "I felt quite tired", color: MovefullyTheme.Colors.mediumGray),
        (emoji: "😐", title: "Okay", description: "I felt okay", color: MovefullyTheme.Colors.primaryTeal.opacity(0.6)),
        (emoji: "🙂", title: "Good", description: "I felt good", color: MovefullyTheme.Colors.primaryTeal),
        (emoji: "😊", title: "Great", description: "I felt great", color: MovefullyTheme.Colors.softGreen),
        (emoji: "🤩", title: "Amazing", description: "I felt amazing", color: MovefullyTheme.Colors.warmOrange)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        feelingLevels[feelingLevel - 1].color.opacity(0.05),
                        MovefullyTheme.Colors.backgroundPrimary,
                        feelingLevels[feelingLevel - 1].color.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                        // Celebration header with animation
                        VStack(spacing: MovefullyTheme.Layout.paddingL) {
                            // Success animation circle
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                MovefullyTheme.Colors.softGreen.opacity(0.2),
                                                MovefullyTheme.Colors.softGreen.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: animateSuccess ? 120 : 100, height: animateSuccess ? 120 : 100)
                                    .scaleEffect(animateSuccess ? 1.0 : 0.8)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateSuccess)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60, weight: .medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [MovefullyTheme.Colors.softGreen, MovefullyTheme.Colors.primaryTeal],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .scaleEffect(animateSuccess ? 1.0 : 0.7)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateSuccess)
                            }
                            
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                Text("Movement Complete! 🎉")
                                    .font(MovefullyTheme.Typography.title1)
                                    .fontWeight(.bold)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [MovefullyTheme.Colors.textPrimary, MovefullyTheme.Colors.primaryTeal],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .multilineTextAlignment(.center)
                                
                                Text("You're building stronger habits with every session")
                                    .font(MovefullyTheme.Typography.body)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            }
                        }
                        .padding(.top, MovefullyTheme.Layout.paddingXL)
                        .onAppear {
                            withAnimation {
                                animateSuccess = true
                            }
                        }
                        
                        // Feeling selection with emojis
                        MovefullyCard {
                            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                                    Text("How did you feel?")
                                        .font(MovefullyTheme.Typography.title3)
                                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                    
                                    Text("Your feedback helps personalize future sessions")
                                        .font(MovefullyTheme.Typography.callout)
                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                
                                // Emoji feeling selector
                                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                                    HStack(spacing: MovefullyTheme.Layout.paddingM) {
                                        ForEach(1...5, id: \.self) { level in
                                            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                                                Button(action: { 
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                        feelingLevel = level 
                                                    }
                                                }) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(
                                                                feelingLevel == level ? 
                                                                feelingLevels[level - 1].color.opacity(0.15) : 
                                                                MovefullyTheme.Colors.cardBackground
                                                            )
                                                            .frame(width: 60, height: 60)
                                                            .overlay(
                                                                Circle()
                                                                    .stroke(
                                                                        feelingLevel == level ? 
                                                                        feelingLevels[level - 1].color : 
                                                                        MovefullyTheme.Colors.divider,
                                                                        lineWidth: feelingLevel == level ? 2 : 1
                                                                    )
                                                            )
                                                        
                                                        Text(feelingLevels[level - 1].emoji)
                                                            .font(.system(size: 32))
                                                            .scaleEffect(feelingLevel == level ? 1.2 : 1.0)
                                                    }
                                                }
                                                .scaleEffect(feelingLevel == level ? 1.1 : 1.0)
                                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: feelingLevel)
                                                
                                                Text(feelingLevels[level - 1].title)
                                                    .font(MovefullyTheme.Typography.caption)
                                                    .foregroundColor(
                                                        feelingLevel == level ? 
                                                        feelingLevels[level - 1].color : 
                                                        MovefullyTheme.Colors.textSecondary
                                                    )
                                                    .fontWeight(feelingLevel == level ? .semibold : .regular)
                                            }
                                        }
                                    }
                                    
                                    // Selected feeling description
                                    Text(feelingLevels[feelingLevel - 1].description)
                                        .font(MovefullyTheme.Typography.body)
                                        .foregroundColor(feelingLevels[feelingLevel - 1].color)
                                        .fontWeight(.medium)
                                        .animation(.easeInOut(duration: 0.2), value: feelingLevel)
                                }
                            }
                        }
                        
                        // Notes section
                        MovefullyCard {
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                                    Text("Share your experience")
                                        .font(MovefullyTheme.Typography.title3)
                                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                    
                                    Text("Optional • Help your trainer understand your journey")
                                        .font(MovefullyTheme.Typography.caption)
                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                }
                                
                                TextField("How did the workout feel? Any highlights or challenges...", text: $notes, axis: .vertical)
                                    .font(MovefullyTheme.Typography.body)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                    .lineLimit(3...6)
                                    .padding(MovefullyTheme.Layout.paddingM)
                                    .background(MovefullyTheme.Colors.backgroundPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                                            .stroke(MovefullyTheme.Colors.divider.opacity(0.5), lineWidth: 1)
                                    )
                                    .focused($isTextFieldFocused)
                            }
                        }
                        
                        // Action buttons
                        VStack(spacing: MovefullyTheme.Layout.paddingM) {
                            // Complete button - now properly completes the session
                            Button("Complete Session") {
                                // Dismiss keyboard first
                                isTextFieldFocused = false
                                
                                // Complete the workout with feedback and session data
                                viewModel.completeWorkout(
                                    assignment, 
                                    rating: feelingLevel, 
                                    notes: notes,
                                    skippedExercises: skippedExercises,
                                    completedExercises: completedExercises,
                                    actualDuration: actualDuration
                                )
                                
                                // Dismiss the completion dialog, which will return to the main view
                                // The workout should now be marked as completed
                                dismiss()
                            }
                            .font(MovefullyTheme.Typography.buttonLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MovefullyTheme.Layout.paddingL)
                            .background(
                                LinearGradient(
                                    colors: [
                                        feelingLevels[feelingLevel - 1].color,
                                        feelingLevels[feelingLevel - 1].color.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                            .shadow(
                                color: feelingLevels[feelingLevel - 1].color.opacity(0.4), 
                                radius: 12, 
                                x: 0, 
                                y: 6
                            )
                            .scaleEffect(0.98)
                            .animation(.easeInOut(duration: 0.2), value: feelingLevel)
                            
                            // Skip button
                            Button("Skip for now") {
                                isTextFieldFocused = false
                                viewModel.completeWorkout(
                                    assignment, 
                                    rating: 3, 
                                    notes: "",
                                    skippedExercises: skippedExercises,
                                    completedExercises: completedExercises,
                                    actualDuration: actualDuration
                                )
                                dismiss()
                            }
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                        
                        Spacer(minLength: MovefullyTheme.Layout.paddingXL)
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                }
                .onTapGesture {
                    // Dismiss keyboard when tapping outside the text field
                    isTextFieldFocused = false
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        isTextFieldFocused = false
                        dismiss()
                    }
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Workout Session View
struct WorkoutSessionView: View {
    let assignment: WorkoutAssignment
    @ObservedObject var viewModel: ClientViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Session persistence
    @StateObject private var persistenceService = WorkoutSessionPersistenceService.shared
    
    // Session state
    @State private var currentExerciseIndex = 0
    @State private var completedExercises: Set<Int> = []
    @State private var skippedExercises: Set<Int> = []
    @State private var sessionStartTime = Date()
    @State private var elapsedTime = 0
    @State private var isPaused = false
    @State private var timer: Timer?
    
    // UI state
    @State private var showingCompletionDialog = false
    @State private var showingCancelAlert = false
    @State private var showingExerciseDetail = false
    
    // Computed properties
    private var currentExercise: AssignedExercise? {
        guard currentExerciseIndex < assignment.exercises.count else { return nil }
        return assignment.exercises[currentExerciseIndex]
    }
    
    private var isLastExercise: Bool {
        currentExerciseIndex >= assignment.exercises.count - 1
    }
    
    private var progressPercentage: Double {
        let totalActions = completedExercises.count + skippedExercises.count
        return assignment.exercises.count > 0 ? Double(totalActions) / Double(assignment.exercises.count) : 0.0
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Session progress header
                sessionProgressHeader
                
                ScrollView {
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        // Current exercise section
                        if let exercise = currentExercise {
                            currentExerciseSection(exercise)
                        }
                        
                        // Exercise list section
                        exerciseListSection
                    }
                    .padding(MovefullyTheme.Layout.paddingL)
                }
                
                // Navigation controls
                navigationControls
            }
            .movefullyBackground()
            .navigationTitle(assignment.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCancelAlert = true
                    }
                }
            }
        }
        .onAppear {
            setupSession()
        }
        .onDisappear {
            saveCurrentProgress()
            stopTimer()
        }
        .onChange(of: currentExerciseIndex) { oldValue, newValue in
            saveCurrentProgress()
        }
        .onChange(of: completedExercises) { oldValue, newValue in
            saveCurrentProgress()
        }
        .onChange(of: skippedExercises) { oldValue, newValue in
            saveCurrentProgress()
        }
        .alert("Cancel Workout", isPresented: $showingCancelAlert) {
            Button("Keep Going", role: .cancel) { }
            Button("Cancel Workout", role: .destructive) {
                persistenceService.cancelSession()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to cancel this workout? Your progress will not be saved.")
        }
        .sheet(isPresented: $showingCompletionDialog) {
            WorkoutCompletionView(
                assignment: assignment, 
                viewModel: viewModel,
                skippedExercises: skippedExercises,
                completedExercises: completedExercises,
                actualDuration: elapsedTime
            )
                .onDisappear {
                    // Check if workout was completed and dismiss session view if so
                    if let updatedWorkout = viewModel.todayWorkout,
                       updatedWorkout.id == assignment.id,
                       updatedWorkout.status == .completed {
                        persistenceService.completeSession()
                        dismiss()
                    }
                }
        }
        .sheet(isPresented: $showingExerciseDetail) {
            if let exercise = currentExercise,
               let sourceExercise = findSourceExercise(for: exercise) {
                ExerciseDetailView(exercise: sourceExercise)
            }
        }
        // Monitor for workout completion status changes
        .onChange(of: viewModel.todayWorkout?.status) { oldValue, newValue in
            if newValue == .completed {
                // Workout was completed, dismiss this session view
                persistenceService.completeSession()
                dismiss()
            }
        }
    }
    
    // MARK: - Session Setup and Management
    
    private func setupSession() {
        // Try to restore existing session first
        if let restoredSession = persistenceService.restoreSessionIfExists() {
            // Check if session matches by ID or title
            let matchesById = restoredSession.workoutId == assignment.id.uuidString
            let matchesByTitle = restoredSession.workoutTitle == assignment.title
            
            if matchesById || matchesByTitle {
                // Restore session state
                currentExerciseIndex = restoredSession.currentExerciseIndex
                completedExercises = restoredSession.completedExercises
                skippedExercises = restoredSession.skippedExercises
                sessionStartTime = restoredSession.sessionStartTime
                elapsedTime = restoredSession.elapsedTime
                isPaused = restoredSession.isPaused
                
                if matchesById {
                    print("🔄 Restored workout session by ID: \(restoredSession.workoutTitle)")
                } else {
                    print("🔄 Restored workout session by title: \(restoredSession.workoutTitle)")
                }
                
                // Resume timer if not paused
                if !isPaused {
                    startTimer()
                }
                return
            } else {
                print("⚠️ Session found but doesn't match current workout (ID: \(restoredSession.workoutId), Title: \(restoredSession.workoutTitle) vs \(assignment.title))")
            }
        }
        
        // Start new session if no matching session found
        startSession()
    }
    
    private func startSession() {
        sessionStartTime = Date()
        persistenceService.startSession(for: assignment)
        startTimer()
    }
    
    private func saveCurrentProgress() {
        persistenceService.updateSessionProgress(
            currentExerciseIndex: currentExerciseIndex,
            completedExercises: completedExercises,
            skippedExercises: skippedExercises,
            elapsedTime: elapsedTime,
            isPaused: isPaused
        )
    }
    
    // MARK: - Session Progress Header
    private var sessionProgressHeader: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            // Timer and progress
            HStack {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text("Elapsed Time")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.2)
                    
                    Text(formattedElapsedTime)
                        .font(MovefullyTheme.Typography.title3)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text("Progress")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.2)
                    
                    Text("\(completedExercises.count + skippedExercises.count)/\(assignment.exercises.count)")
                        .font(MovefullyTheme.Typography.title3)
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        .fontWeight(.semibold)
                }
            }
            
            // Progress bar
            ProgressView(value: progressPercentage)
                .tint(MovefullyTheme.Colors.primaryTeal)
                .scaleEffect(y: 2)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(MovefullyTheme.Layout.paddingL)
        .background(MovefullyTheme.Colors.cardBackground)
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Current Exercise Section
    private func currentExerciseSection(_ exercise: AssignedExercise) -> some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingL) {
                HStack {
                    Text("Current Exercise")
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.2)
                    
                    Spacer()
                    
                    MovefullyStatusBadge(
                        text: exercise.category.rawValue,
                        color: exercise.category.color,
                        showDot: false
                    )
                }
                
                // Clickable exercise title for details
                Button(action: {
                    showingExerciseDetail = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            Text(exercise.title)
                                .font(MovefullyTheme.Typography.title2)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "info.circle")
                            .font(MovefullyTheme.Typography.title3)
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Text(exercise.description)
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .lineLimit(nil)
                
                // Exercise parameters - side by side layout without rest time
                HStack(spacing: MovefullyTheme.Layout.paddingL) {
                    if let sets = exercise.sets {
                        exerciseParam(icon: "repeat", text: "\(sets) sets")
                    }
                    
                    // Show reps or duration based on exerciseType, not both
                    switch exercise.exerciseType {
                    case .reps:
                        if let reps = exercise.reps {
                            exerciseParam(icon: "number", text: "\(reps) reps")
                        }
                    case .duration:
                        if let duration = exercise.duration {
                            exerciseParam(icon: "timer", text: "\(duration) seconds")
                        }
                    }
                    
                    Spacer()
                }
                .onAppear {
                    // Debug logging moved outside ViewBuilder
                    if exercise.sets == nil {
                        print("⚠️ [DEBUG] Exercise '\(exercise.title)' has no sets data")
                    }
                    if exercise.exerciseType == .reps && exercise.reps == nil {
                        print("⚠️ [DEBUG] Reps exercise '\(exercise.title)' has no reps data")
                    }
                    if exercise.exerciseType == .duration && exercise.duration == nil {
                        print("⚠️ [DEBUG] Duration exercise '\(exercise.title)' has no duration data")
                    }
                }
                
                if let tips = exercise.trainerTips {
                    Text("💡 \(tips)")
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        .padding(MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.primaryTeal.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                }
                
                // Exercise action buttons
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Mark as complete button
                    Button(completedExercises.contains(currentExerciseIndex) ? "Completed ✓" : "Mark Complete") {
                        toggleExerciseCompletion(currentExerciseIndex)
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .foregroundColor(completedExercises.contains(currentExerciseIndex) ? .white : MovefullyTheme.Colors.primaryTeal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    .background(
                        completedExercises.contains(currentExerciseIndex) 
                            ? MovefullyTheme.Colors.softGreen 
                            : MovefullyTheme.Colors.primaryTeal.opacity(0.1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    .animation(.easeInOut(duration: 0.2), value: completedExercises.contains(currentExerciseIndex))
                    
                    // Skip button
                    Button(skippedExercises.contains(currentExerciseIndex) ? "Skipped" : "Skip") {
                        toggleExerciseSkip(currentExerciseIndex)
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .foregroundColor(skippedExercises.contains(currentExerciseIndex) ? .white : MovefullyTheme.Colors.textSecondary)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    .background(
                        skippedExercises.contains(currentExerciseIndex)
                            ? MovefullyTheme.Colors.textSecondary
                            : MovefullyTheme.Colors.textSecondary.opacity(0.1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    .animation(.easeInOut(duration: 0.2), value: skippedExercises.contains(currentExerciseIndex))
                }
            }
        }
    }
    
    // MARK: - Exercise List Section
    private var exerciseListSection: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                Text("All Exercises")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                Spacer()
            }
            
            ForEach(Array(assignment.exercises.enumerated()), id: \.element.id) { index, exercise in
                exerciseRowWithStatus(exercise: exercise, index: index)
            }
        }
    }
    
    private func exerciseRowWithStatus(exercise: AssignedExercise, index: Int) -> some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            // Status indicator (completed, skipped, or pending)
            statusIndicator(for: index)
            
            // Exercise info - clickable to switch to this exercise
            Button(action: {
                currentExerciseIndex = index
            }) {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    HStack {
                        Text(exercise.title)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(currentExerciseIndex == index ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.textPrimary)
                            .strikethrough(completedExercises.contains(index) || skippedExercises.contains(index))
                        
                        Spacer()
                        
                        if currentExerciseIndex == index {
                            Text("CURRENT")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                .fontWeight(.semibold)
                                .textCase(.uppercase)
                                .tracking(1.2)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Tap for details icon - clickable to show exercise details
            Button(action: {
                // Set current exercise and show details
                currentExerciseIndex = index
                showingExerciseDetail = true
            }) {
                Image(systemName: "info.circle")
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(MovefullyTheme.Layout.paddingM)
        .background(
            currentExerciseIndex == index 
                ? MovefullyTheme.Colors.primaryTeal.opacity(0.08)
                : MovefullyTheme.Colors.cardBackground
        )
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .overlay(
            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                .stroke(
                    currentExerciseIndex == index 
                        ? MovefullyTheme.Colors.primaryTeal.opacity(0.3)
                        : Color.clear, 
                    lineWidth: 2
                )
        )
    }
    
    private func statusIndicator(for index: Int) -> some View {
        Group {
            if completedExercises.contains(index) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.softGreen)
            } else if skippedExercises.contains(index) {
                Image(systemName: "forward.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            } else {
                Image(systemName: "circle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: completedExercises.contains(index))
        .animation(.easeInOut(duration: 0.2), value: skippedExercises.contains(index))
    }
    
    // MARK: - Navigation Controls
    private var navigationControls: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            Divider()
                .background(MovefullyTheme.Colors.divider)
            
            // Always show navigation buttons (Previous + Complete or Previous + Next)
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                Button("Previous") {
                    if currentExerciseIndex > 0 {
                        currentExerciseIndex -= 1
                    }
                }
                .disabled(currentExerciseIndex <= 0)
                .font(MovefullyTheme.Typography.buttonMedium)
                .foregroundColor(currentExerciseIndex <= 0 ? MovefullyTheme.Colors.textSecondary : MovefullyTheme.Colors.primaryTeal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MovefullyTheme.Layout.paddingM)
                .background(MovefullyTheme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                .overlay(
                    RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                        .stroke(MovefullyTheme.Colors.textSecondary.opacity(0.3), lineWidth: 1)
                )
                
                if isLastExercise {
                    Button("Complete Workout") {
                        showingCompletionDialog = true
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    .background(MovefullyTheme.Colors.softGreen)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    .shadow(color: MovefullyTheme.Colors.softGreen.opacity(0.3), radius: 6, x: 0, y: 3)
                } else {
                    Button("Next") {
                        if currentExerciseIndex < assignment.exercises.count - 1 {
                            currentExerciseIndex += 1
                        }
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    .background(MovefullyTheme.Colors.primaryTeal)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                }
            }
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
        .padding(.bottom, MovefullyTheme.Layout.paddingL)
        .background(MovefullyTheme.Colors.cardBackground)
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 8, x: 0, y: -4)
    }
    
    // MARK: - Helper Functions
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !isPaused {
                elapsedTime = Int(Date().timeIntervalSince(sessionStartTime))
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func toggleExerciseCompletion(_ index: Int) {
        if completedExercises.contains(index) {
            completedExercises.remove(index)
        } else {
            completedExercises.insert(index)
            // Remove from skipped if it was skipped
            skippedExercises.remove(index)
        }
    }
    
    private func toggleExerciseSkip(_ index: Int) {
        if skippedExercises.contains(index) {
            skippedExercises.remove(index)
        } else {
            skippedExercises.insert(index)
            // Remove from completed if it was completed
            completedExercises.remove(index)
        }
    }
    
    private func exerciseParam(icon: String, text: String) -> some View {
        HStack(spacing: MovefullyTheme.Layout.paddingS) {
            Image(systemName: icon)
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                .frame(width: 16)
            
            Text(text)
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
        }
    }
    
    private var formattedElapsedTime: String {
        let minutes = elapsedTime / 60
        let seconds = elapsedTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Link to the source of truth exercise database
    private func findSourceExercise(for assignedExercise: AssignedExercise) -> Exercise? {
        // This would typically query the Exercise database/viewModel
        // For now, create a bridge from AssignedExercise to Exercise
        return Exercise(
            id: assignedExercise.id.uuidString, // Convert UUID to String
            title: assignedExercise.title,
            description: assignedExercise.description,
            mediaUrl: nil, // Could be populated from exercise database
            category: assignedExercise.category,
            difficulty: .intermediate, // Could be derived from exercise database
            createdByTrainerId: nil,
            exerciseType: assignedExercise.exerciseType // Use the actual exercise type
        )
    }
}

// MARK: - No Plan Assigned Card
struct NoPlanAssignedCard: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(MovefullyTheme.Typography.largeTitle)
                    .foregroundColor(MovefullyTheme.Colors.warmOrange)
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Text("No Plan Assigned")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("You don't have a workout plan assigned yet. Your trainer will create a personalized plan for you soon!")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                
                // Gentle suggestions
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Text("In the meantime, you can:")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    HStack(spacing: MovefullyTheme.Layout.paddingL) {
                        VStack(spacing: MovefullyTheme.Layout.paddingS) {
                            Text("💪")
                                .font(MovefullyTheme.Typography.title3)
                            Text("Browse\nexercises")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(spacing: MovefullyTheme.Layout.paddingS) {
                            Text("📱")
                                .font(MovefullyTheme.Typography.title3)
                            Text("Message\ntrainer")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(spacing: MovefullyTheme.Layout.paddingS) {
                            Text("🎯")
                                .font(MovefullyTheme.Typography.title3)
                            Text("Review\ngoals")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Loading State View
struct LoadingStateView: View {
    var body: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(MovefullyTheme.Colors.primaryTeal)
                
                Text("Loading your workout...")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            .padding(.vertical, MovefullyTheme.Layout.paddingXL)
        }
    }
}

#Preview {
    ClientTodayView(viewModel: ClientViewModel())
} 