import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Workout Completion Data Model
struct WorkoutCompletionData {
    let skippedExercises: [Int]
    let completedExercises: [Int]
    let rating: Int
    let notes: String
    let actualDuration: Int
    let completedDate: Date
    
    init(data: [String: Any]) {
        self.skippedExercises = data["skippedExercises"] as? [Int] ?? []
        self.completedExercises = data["completedExercises"] as? [Int] ?? []
        self.rating = data["rating"] as? Int ?? 3
        self.notes = data["notes"] as? String ?? ""
        self.actualDuration = data["duration"] as? Int ?? 0
        
        if let timestamp = data["completedDate"] as? Timestamp {
            self.completedDate = timestamp.dateValue()
        } else {
            self.completedDate = Date()
        }
    }
}

// MARK: - Workout Review View
struct WorkoutReviewView: View {
    let assignment: WorkoutAssignment
    @ObservedObject var viewModel: ClientViewModel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var completionData: WorkoutCompletionData?
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Header Section
                    headerSection
                    
                    // Session Feedback (moved up, right after header)
                    if let completion = completionData {
                        sessionFeedbackSection(completion)
                    }
                    
                    // Workout Summary
                    workoutSummarySection
                    
                    // Exercises List
                    exercisesSection
                }
                .padding(MovefullyTheme.Layout.paddingL)
            }
            .movefullyBackground()
            .navigationTitle("Workout Review")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
        .onAppear {
            loadCompletionData()
        }
    }
    
    // MARK: - Data Loading
    private func loadCompletionData() {
        Task {
            await fetchCompletionData()
        }
    }
    
    private func fetchCompletionData() async {
        guard let clientId = Auth.auth().currentUser?.uid else {
            print("❌ WorkoutReviewView: No authenticated user")
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        let consistentWorkoutId = "\(assignment.title)_\(Calendar.current.startOfDay(for: assignment.date).timeIntervalSince1970)"
        
        do {
            let db = Firestore.firestore()
            let doc = try await db.collection("clients")
                .document(clientId)
                .collection("workoutCompletions")
                .document(consistentWorkoutId)
                .getDocument()
            
            await MainActor.run {
                if doc.exists, let data = doc.data() {
                    self.completionData = WorkoutCompletionData(data: data)
                    print("✅ WorkoutReviewView: Loaded completion data with \(self.completionData?.skippedExercises.count ?? 0) skipped exercises")
                } else {
                    print("⚠️ WorkoutReviewView: No completion data found for workout")
                }
                self.isLoading = false
            }
        } catch {
            print("❌ WorkoutReviewView: Error fetching completion data: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingL) {
                HStack {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text("Completed Workout")
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                        
                        Text(assignment.title)
                            .font(MovefullyTheme.Typography.title1)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        MovefullyStatusBadge(
                            text: "Completed",
                            color: MovefullyTheme.Colors.softGreen,
                            showDot: true
                        )
                        
                        MovefullyStatusBadge(
                            text: "\(completionData?.actualDuration ?? assignment.estimatedDuration) min",
                            color: MovefullyTheme.Colors.primaryTeal,
                            showDot: false
                        )
                    }
                }
                
                // Workout description
                if let description = assignment.description, !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(description)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .padding(MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.primaryTeal.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                }
            }
        }
    }
    
    // MARK: - Workout Summary Section
    private var workoutSummarySection: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingL) {
                HStack {
                    Text("Workout Summary")
                        .font(MovefullyTheme.Typography.title3)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Spacer()
                }
                
                // Summary stats
                HStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Total exercises
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Text("\(assignment.exercises.count)")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        
                        Text("Total")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 40)
                    
                    // Estimated duration
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Text("\(completionData?.actualDuration ?? assignment.estimatedDuration)")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        
                        Text("Minutes")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 40)
                    
                    // Date completed
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Text(DateFormatter.shortDate.string(from: completionData?.completedDate ?? assignment.date))
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text("Date")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    // MARK: - Exercises Section
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingL) {
            HStack {
                Text("Exercises")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Spacer()
                
                if let completion = completionData {
                    let completedCount = completion.completedExercises.count
                    let skippedCount = completion.skippedExercises.count
                    
                    Text("\(completedCount) completed, \(skippedCount) skipped")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.2)
                } else {
                    Text("\(assignment.exercises.count) total")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.2)
                }
            }
            
            LazyVStack(spacing: MovefullyTheme.Layout.paddingM) {
                ForEach(Array(assignment.exercises.enumerated()), id: \.offset) { index, exercise in
                    exerciseCard(exercise: exercise, index: index)
                }
            }
        }
    }
    
    // MARK: - Exercise Card
    private func exerciseCard(exercise: AssignedExercise, index: Int) -> some View {
        let isCompleted = completionData?.completedExercises.contains(index) ?? true
        let isSkipped = completionData?.skippedExercises.contains(index) ?? false
        
        return MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                // Exercise header
                HStack {
                    HStack(spacing: MovefullyTheme.Layout.paddingS) {
                        // Exercise number
                        Text("\(index + 1)")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(MovefullyTheme.Colors.primaryTeal)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                            Text(exercise.title)
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Text(exercise.category.rawValue)
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1.2)
                        }
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    if isSkipped {
                        HStack(spacing: MovefullyTheme.Layout.paddingS) {
                            Image(systemName: "xmark.circle.fill")
                                .font(MovefullyTheme.Typography.title3)
                                .foregroundColor(MovefullyTheme.Colors.mediumGray)
                            
                            Text("Skipped")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.mediumGray)
                                .textCase(.uppercase)
                                .tracking(1.2)
                        }
                    } else if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(MovefullyTheme.Typography.title3)
                            .foregroundColor(MovefullyTheme.Colors.softGreen)
                    }
                }
                
                // Exercise description
                if !exercise.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(exercise.description)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(nil)
                }
                
                // Exercise parameters
                HStack(spacing: MovefullyTheme.Layout.paddingL) {
                    if let sets = exercise.sets {
                        exerciseParam(icon: "repeat", text: "\(sets) sets")
                    }
                    
                    // Show reps or duration based on exerciseType
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
                    
                    if let restTime = exercise.restTime, restTime > 0 {
                        exerciseParam(icon: "pause.circle", text: "\(restTime)s rest")
                    }
                    
                    Spacer()
                }
            }
        }
        .opacity(isSkipped ? 0.6 : 1.0)
    }
    
    // MARK: - Exercise Parameter Helper
    private func exerciseParam(icon: String, text: String) -> some View {
        HStack(spacing: MovefullyTheme.Layout.paddingS) {
            Image(systemName: icon)
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            
            Text(text)
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
        }
    }
    
    // MARK: - Session Feedback Section
    private func sessionFeedbackSection(_ completion: WorkoutCompletionData) -> some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingL) {
                HStack {
                    Text("Session Feedback")
                        .font(MovefullyTheme.Typography.title3)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Spacer()
                }
                
                // Completion stats
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                    let completionPercentage = assignment.exercises.count > 0 ? 
                        Int((Double(completion.completedExercises.count) / Double(assignment.exercises.count)) * 100) : 100
                    
                    HStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Image(systemName: "star.fill")
                            .font(MovefullyTheme.Typography.title3)
                            .foregroundColor(MovefullyTheme.Colors.warmOrange)
                        
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            Text("Session Complete!")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            if completion.skippedExercises.isEmpty {
                                Text("You completed all exercises successfully. Excellent work!")
                                    .font(MovefullyTheme.Typography.body)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            } else {
                                Text("You completed \(completion.completedExercises.count) out of \(assignment.exercises.count) exercises. Keep up the great work!")
                                    .font(MovefullyTheme.Typography.body)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            }
                        }
                    }
                    
                    // Progress indicator
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        HStack {
                            Text("Completion Rate")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1.2)
                            
                            Spacer()
                            
                            Text("\(completionPercentage)%")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(completionPercentage == 100 ? MovefullyTheme.Colors.softGreen : MovefullyTheme.Colors.primaryTeal)
                        }
                        
                        ProgressView(value: Double(completionPercentage) / 100.0)
                            .tint(completionPercentage == 100 ? MovefullyTheme.Colors.softGreen : MovefullyTheme.Colors.primaryTeal)
                            .scaleEffect(y: 1.5)
                    }
                    
                    // Your Notes - Full Width within the card
                    if !completion.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            Text("Your Notes")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1.2)
                            
                            Text("\"\(completion.notes)\"")
                                .font(MovefullyTheme.Typography.body)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                .italic()
                                .lineLimit(nil)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.primaryTeal.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleExercises = [
        AssignedExercise(
            title: "Push-ups",
            description: "Classic upper body exercise for building chest, shoulder, and tricep strength",
            sets: 3,
            reps: "10",
            duration: nil,
            restTime: 60,
            trainerTips: nil,
            mediaUrl: nil,
            category: .strength,
            exerciseType: .reps
        ),
        AssignedExercise(
            title: "Plank",
            description: "Core strengthening exercise for stability and endurance",
            sets: 3,
            reps: nil,
            duration: 30,
            restTime: 60,
            trainerTips: nil,
            mediaUrl: nil,
            category: .strength,
            exerciseType: .duration
        )
    ]
    
    let sampleWorkout = WorkoutAssignment(
        title: "Morning Strength",
        description: "A balanced strength workout to start your day",
        date: Date(),
        status: .completed,
        exercises: sampleExercises,
        trainerNotes: "Focus on form over speed",
        estimatedDuration: 30
    )
    
    return WorkoutReviewView(assignment: sampleWorkout, viewModel: ClientViewModel())
} 