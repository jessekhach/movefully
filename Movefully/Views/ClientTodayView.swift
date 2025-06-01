import SwiftUI

// MARK: - Client Today View
struct ClientTodayView: View {
    @ObservedObject var viewModel: ClientViewModel
    @State private var showingWorkoutDetail = false
    @State private var showingCompletionDialog = false
    
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
            }
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingWorkoutDetail) {
            if let todayWorkout = viewModel.todayWorkout {
                WorkoutDetailView(assignment: todayWorkout, viewModel: viewModel)
            }
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
                Text("This Week")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                Spacer()
            }
            
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                // Workouts completed
                MovefullyCard {
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Text("\(viewModel.completedAssignments)")
                            .font(MovefullyTheme.Typography.title1)
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        
                        Text("Completed")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.1)
                    }
                }
                
                // Completion percentage
                MovefullyCard {
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Text("\(Int(viewModel.progressPercentage * 100))%")
                            .font(MovefullyTheme.Typography.title1)
                            .foregroundColor(MovefullyTheme.Colors.softGreen)
                        
                        Text("On Track")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.1)
                    }
                }
            }
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
    @State private var rating = 3
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                // Celebration header
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    Image(systemName: "star.fill")
                        .font(MovefullyTheme.Typography.largeTitle)
                        .foregroundColor(MovefullyTheme.Colors.warmOrange)
                    
                    Text("Workout Complete!")
                        .font(MovefullyTheme.Typography.title1)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("How did it feel?")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                .padding(.top, MovefullyTheme.Layout.paddingXXL)
                
                // Rating selection
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    HStack {
                        Text("Energy Level")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        Spacer()
                    }
                    
                    HStack(spacing: MovefullyTheme.Layout.paddingM) {
                        ForEach(1...5, id: \.self) { level in
                            Button(action: { rating = level }) {
                                Image(systemName: level <= rating ? "star.fill" : "star")
                                    .font(MovefullyTheme.Typography.title2)
                                    .foregroundColor(level <= rating ? MovefullyTheme.Colors.warmOrange : MovefullyTheme.Colors.mediumGray)
                            }
                        }
                        Spacer()
                    }
                }
                
                // Notes
                MovefullyFormField(title: "How did it feel?", subtitle: "Optional notes for your trainer") {
                    MovefullyTextEditor(
                        placeholder: "Share how the workout felt, any challenges, or victories...",
                        text: $notes,
                        minLines: 3,
                        maxLines: 5,
                        maxCharacters: 250
                    )
                }
                
                Spacer()
                
                // Complete button
                Button("Complete Workout") {
                    viewModel.completeWorkout(assignment, rating: rating, notes: notes)
                    dismiss()
                }
                .font(MovefullyTheme.Typography.buttonMedium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MovefullyTheme.Layout.paddingM)
                .background(MovefullyTheme.Colors.softGreen)
                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                .shadow(color: MovefullyTheme.Colors.softGreen.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationTitle("Workout Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
    }
}

#Preview {
    ClientTodayView(viewModel: ClientViewModel())
} 