import SwiftUI

// MARK: - Client Today View
struct ClientTodayView: View {
    @ObservedObject var viewModel: ClientViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingWorkoutDetail = false
    @State private var showingCompletionDialog = false
    @State private var showingProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingXL) {
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
                    
                    Spacer(minLength: MovefullyTheme.Layout.paddingXXL)
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.top, MovefullyTheme.Layout.paddingM)
            }
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingProfile = true }) {
                        ZStack {
                            Circle()
                                .fill(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        }
                    }
                    .accessibilityLabel("Profile")
                }
            }
        }
        .sheet(isPresented: $showingWorkoutDetail) {
            if let todayWorkout = viewModel.todayWorkout {
                WorkoutDetailView(assignment: todayWorkout, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingProfile) {
            ClientProfileView(viewModel: viewModel)
                .environmentObject(authViewModel)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
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
                    // View Details button
                    Button("View Details") {
                        showingWorkoutDetail = true
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    
                    // Start Workout button
                    Button("Start Workout") {
                        viewModel.startWorkout(workout)
                        showingWorkoutDetail = true
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

// MARK: - Workout Detail View
struct WorkoutDetailView: View {
    let assignment: WorkoutAssignment
    @ObservedObject var viewModel: ClientViewModel
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
                    
                    // Complete workout button
                    if assignment.status != .completed {
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
            .navigationTitle("Workout Details")
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
    
    var body: some View {
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
                        Text(exercise.title)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        MovefullyStatusBadge(
                            text: exercise.category.rawValue,
                            color: MovefullyTheme.Colors.primaryTeal,
                            showDot: false
                        )
                    }
                    
                    Spacer()
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
                            }
                        }
                        
                        // Action buttons
                        VStack(spacing: MovefullyTheme.Layout.paddingM) {
                            // Complete button
                            Button("Complete Session") {
                                viewModel.completeWorkout(assignment, rating: feelingLevel, notes: notes)
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
    }
}

#Preview {
    ClientTodayView(viewModel: ClientViewModel())
} 