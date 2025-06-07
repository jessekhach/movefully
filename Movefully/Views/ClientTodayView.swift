import SwiftUI

// MARK: - Client Today View
struct ClientTodayView: View {
    @ObservedObject var viewModel: ClientViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingWorkoutDetail = false
    @State private var showingWorkoutSession = false
    @State private var showingCompletionDialog = false
    @State private var showingProfile = false
    
    var body: some View {
        MovefullyClientNavigation(
            title: "Today",
            showProfileButton: true,
            profileAction: { showingProfile = true }
        ) {
            // Header with greeting
            headerSection
            
            // Today's workout or rest day message
            if let todayWorkout = viewModel.todayWorkout {
                workoutSection(todayWorkout)
            } else {
                restDaySection
            }
            
            // Quick stats
            quickStatsSection
        }
        .sheet(isPresented: $showingWorkoutDetail) {
            if let todayWorkout = viewModel.todayWorkout {
                WorkoutDetailView(assignment: todayWorkout, viewModel: viewModel, isReadOnly: true)
            }
        }
        .sheet(isPresented: $showingWorkoutSession) {
            if let todayWorkout = viewModel.todayWorkout {
                WorkoutSessionView(assignment: todayWorkout, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingProfile) {
            ClientProfileView(viewModel: viewModel)
                .environmentObject(authViewModel)
        }
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
                            Text("Good \(timeOfDayGreeting), \(viewModel.currentClient.name.components(separatedBy: " ").first ?? "")!")
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
                        Text("Today's Movement")
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                        
                        Text(workout.title)
                            .font(MovefullyTheme.Typography.title1)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    MovefullyStatusBadge(
                        text: "\(workout.estimatedDuration) min",
                        color: MovefullyTheme.Colors.primaryTeal,
                        showDot: false
                    )
                }
                
                // Trainer notes
                if let notes = workout.trainerNotes {
                    Text(notes)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .padding(MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.primaryTeal.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                }
                
                // Exercise count
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Image(systemName: "list.bullet")
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    
                    Text("\(workout.exercises.count) exercises")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    Spacer()
                }
                
                // Action buttons
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
                        showingWorkoutSession = true
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    .background(
                        LinearGradient(
                            colors: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.primaryTeal.opacity(0.8)],
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
    
    // MARK: - Rest Day Section
    private var restDaySection: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                Image(systemName: "leaf.fill")
                    .font(MovefullyTheme.Typography.largeTitle)
                    .foregroundColor(MovefullyTheme.Colors.softGreen)
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Text("Rest & Restore")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("Today is your day to rest and let your body recover. Take a gentle walk, do some light stretching, or simply enjoy some quiet time.")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                
                // Optional gentle activity suggestions
                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                    Text("Gentle activities you might enjoy:")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                        restActivityItem("🚶‍♀️ Peaceful walk")
                        restActivityItem("🧘‍♀️ Light stretching")
                        restActivityItem("📖 Reading time")
                        restActivityItem("☕ Mindful tea/coffee")
                    }
                }
            }
            .padding(.vertical, MovefullyTheme.Layout.paddingL)
        }
    }
    
    private func restActivityItem(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
            Spacer()
        }
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
}

// MARK: - Workout Detail View (Read-Only)
struct WorkoutDetailView: View {
    let assignment: WorkoutAssignment
    @ObservedObject var viewModel: ClientViewModel
    let isReadOnly: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showingCompletionDialog = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                    // Workout header
                    MovefullyCard {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                            Text(assignment.title)
                                .font(MovefullyTheme.Typography.title1)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
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
                            
                            if let notes = assignment.trainerNotes {
                                Text(notes)
                                    .font(MovefullyTheme.Typography.body)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
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
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
            }
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationTitle(isReadOnly ? "Workout Preview" : "Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
        .sheet(isPresented: $showingCompletionDialog) {
            WorkoutCompletionView(assignment: assignment, viewModel: viewModel)
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
                                
                                Text("Tap for detailed instructions")
                                    .font(MovefullyTheme.Typography.caption)
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            }
                        }
                    }
                    
                    // Exercise description
                    Text(exercise.description)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(nil)
                    
                    // Exercise parameters
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        if let sets = exercise.sets {
                            exerciseParam(icon: "repeat", text: "\(sets) sets")
                        }
                        
                        if let reps = exercise.reps {
                            exerciseParam(icon: "number", text: reps)
                        }
                        
                        if let duration = exercise.duration {
                            exerciseParam(icon: "timer", text: "\(duration) seconds")
                        }
                        
                        if let restTime = exercise.restTime {
                            exerciseParam(icon: "pause", text: "\(restTime)s rest")
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
            duration: assignedExercise.duration,
            difficulty: .intermediate, // Could be derived from exercise database
            createdByTrainerId: nil,
            howToPerform: nil, // Would come from exercise database
            trainerTips: assignedExercise.trainerTips.map { [$0] },
            commonMistakes: nil,
            modifications: nil,
            equipmentNeeded: nil,
            targetMuscles: nil,
            breathingCues: nil
        )
    }
}

// MARK: - Workout Completion View
struct WorkoutCompletionView: View {
    let assignment: WorkoutAssignment
    @ObservedObject var viewModel: ClientViewModel
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
        NavigationView {
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
                                
                                // Complete the workout with feedback
                                viewModel.completeWorkout(assignment, rating: feelingLevel, notes: notes)
                                
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
                                viewModel.completeWorkout(assignment, rating: 3, notes: "")
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

// MARK: - Workout Session View (Interactive)
struct WorkoutSessionView: View {
    let assignment: WorkoutAssignment
    @ObservedObject var viewModel: ClientViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentExerciseIndex = 0
    @State private var completedExercises: Set<Int> = []
    @State private var skippedExercises: Set<Int> = []
    @State private var sessionStartTime = Date()
    @State private var elapsedTime = 0
    @State private var timer: Timer?
    @State private var showingExitConfirmation = false
    @State private var showingCompletionDialog = false
    @State private var showingExerciseDetail = false
    @State private var isPaused = false
    
    var currentExercise: AssignedExercise? {
        guard currentExerciseIndex < assignment.exercises.count else { return nil }
        return assignment.exercises[currentExerciseIndex]
    }
    
    var progressPercentage: Double {
        let totalCompleted = completedExercises.count + skippedExercises.count
        return Double(totalCompleted) / Double(assignment.exercises.count)
    }
    
    var isLastExercise: Bool {
        return currentExerciseIndex >= assignment.exercises.count - 1
    }
    
    var canCompleteWorkout: Bool {
        // Only allow completion if the last exercise is completed or skipped
        let lastExerciseIndex = assignment.exercises.count - 1
        return completedExercises.contains(lastExerciseIndex) || skippedExercises.contains(lastExerciseIndex)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress header
                sessionProgressHeader
                
                // Main scrollable content
                ScrollView {
                    VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                        // Current exercise display
                        if let exercise = currentExercise {
                            currentExerciseSection(exercise)
                        }
                        
                        // Exercise list with checkboxes
                        exerciseListSection
                        
                        // Add extra bottom padding for fixed controls
                        Spacer(minLength: 140) // Increased padding for fixed bottom controls
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                }
                .background(MovefullyTheme.Colors.backgroundPrimary)
                
                // Fixed bottom navigation
                fixedBottomControls
            }
            .navigationTitle("Active Workout")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingExitConfirmation = true
                    }
                    .foregroundColor(MovefullyTheme.Colors.warmOrange)
                }
            }
        }
        .onAppear {
            startSession()
        }
        .onDisappear {
            stopTimer()
        }
        .alert("Cancel Workout", isPresented: $showingExitConfirmation) {
            Button("Keep Going", role: .cancel) { }
            Button("Cancel Workout", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Are you sure you want to cancel this workout? Your progress will not be saved.")
        }
        .sheet(isPresented: $showingCompletionDialog) {
            WorkoutCompletionView(assignment: assignment, viewModel: viewModel)
                .onDisappear {
                    // Check if workout was completed and dismiss session view if so
                    if let updatedWorkout = viewModel.todayWorkout,
                       updatedWorkout.id == assignment.id,
                       updatedWorkout.status == .completed {
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
        .onChange(of: viewModel.todayWorkout?.status) { newStatus in
            if newStatus == .completed {
                // Workout was completed, dismiss this session view
                dismiss()
            }
        }
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
                            
                            Text("Tap for detailed instructions")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
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
                
                // Exercise specifications
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                    if let sets = exercise.sets {
                        exerciseSpecRow(icon: "repeat", text: "\(sets) sets")
                    }
                    
                    if let reps = exercise.reps {
                        exerciseSpecRow(icon: "number", text: reps)
                    }
                    
                    if let duration = exercise.duration {
                        exerciseSpecRow(icon: "clock", text: "\(duration) seconds")
                    }
                    
                    if let rest = exercise.restTime {
                        exerciseSpecRow(icon: "pause", text: "\(rest)s rest")
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
    
    // MARK: - Fixed Bottom Controls
    private var fixedBottomControls: some View {
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
    private func startSession() {
        sessionStartTime = Date()
        startTimer()
    }
    
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
    
    private func exerciseSpecRow(icon: String, text: String) -> some View {
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
            duration: assignedExercise.duration,
            difficulty: .intermediate, // Could be derived from exercise database
            createdByTrainerId: nil,
            howToPerform: nil, // Would come from exercise database
            trainerTips: assignedExercise.trainerTips.map { [$0] },
            commonMistakes: nil,
            modifications: nil,
            equipmentNeeded: nil,
            targetMuscles: nil,
            breathingCues: nil
        )
    }
}

#Preview {
    ClientTodayView(viewModel: ClientViewModel())
} 