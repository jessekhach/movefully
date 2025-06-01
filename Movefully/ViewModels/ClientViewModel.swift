import SwiftUI
import Foundation
import Combine

// MARK: - Workout Status Enum
enum WorkoutStatus: String, CaseIterable {
    case completed = "Completed"
    case pending = "Pending"
    case skipped = "Skipped"
    
    var color: Color {
        switch self {
        case .completed: return MovefullyTheme.Colors.softGreen
        case .pending: return MovefullyTheme.Colors.warmOrange
        case .skipped: return MovefullyTheme.Colors.mediumGray
        }
    }
    
    var icon: String {
        switch self {
        case .completed: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .skipped: return "xmark.circle.fill"
        }
    }
}

// MARK: - Workout Assignment Model
struct WorkoutAssignment: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    var status: WorkoutStatus
    let exercises: [AssignedExercise]
    let trainerNotes: String?
    let estimatedDuration: Int // minutes
    
    static let sampleAssignments = [
        WorkoutAssignment(
            title: "Morning Flow",
            date: Date(),
            status: .pending,
            exercises: AssignedExercise.sampleExercises,
            trainerNotes: "Focus on your breath and move at your own pace. Listen to your body today.",
            estimatedDuration: 30
        ),
        WorkoutAssignment(
            title: "Core Strength",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            status: .completed,
            exercises: AssignedExercise.sampleExercises,
            trainerNotes: "Great work yesterday! I loved seeing your progress in the plank hold.",
            estimatedDuration: 25
        ),
        WorkoutAssignment(
            title: "Gentle Mobility",
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            status: .completed,
            exercises: AssignedExercise.sampleExercises,
            trainerNotes: "Perfect timing for recovery work. How did your back feel afterward?",
            estimatedDuration: 20
        ),
        WorkoutAssignment(
            title: "Lower Body Strength",
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            status: .skipped,
            exercises: AssignedExercise.sampleExercises,
            trainerNotes: "No worries if you missed this one. We can adjust this week's plan together.",
            estimatedDuration: 40
        )
    ]
}

// MARK: - Assigned Exercise Model
struct AssignedExercise: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let sets: Int?
    let reps: String? // Could be "10-12" or "Hold for 30 seconds"
    let duration: Int? // In seconds for holds
    let restTime: Int? // In seconds
    let trainerTips: String?
    let mediaUrl: String? // For GIF/video demonstration
    let category: ExerciseCategory
    
    static let sampleExercises = [
        AssignedExercise(
            title: "Cat-Cow Stretch",
            description: "A gentle spinal mobility exercise that helps warm up your back and core",
            sets: 1,
            reps: "8-10 slow movements",
            duration: nil,
            restTime: nil,
            trainerTips: "Move slowly and mindfully. Let your breath guide the movement.",
            mediaUrl: nil,
            category: .flexibility
        ),
        AssignedExercise(
            title: "Modified Plank Hold",
            description: "Build core strength while maintaining proper alignment",
            sets: 3,
            reps: nil,
            duration: 20,
            restTime: 30,
            trainerTips: "Start on knees if needed. Focus on keeping a straight line from head to hips.",
            mediaUrl: nil,
            category: .strength
        ),
        AssignedExercise(
            title: "Mindful Walking",
            description: "Gentle movement with focus on breath and awareness",
            sets: 1,
            reps: nil,
            duration: 600, // 10 minutes
            restTime: nil,
            trainerTips: "Find a peaceful space. Feel your feet connecting with the ground.",
            mediaUrl: nil,
            category: .flexibility
        )
    ]
}

// MARK: - Progress Data Model
struct ProgressData {
    let weeklyWorkoutsCompleted: Int
    let weeklyWorkoutsAssigned: Int
    let monthlyWorkoutsCompleted: Int
    let monthlyWorkoutsAssigned: Int
    let completionPercentage: Double
    
    static let sampleProgress = ProgressData(
        weeklyWorkoutsCompleted: 3,
        weeklyWorkoutsAssigned: 4,
        monthlyWorkoutsCompleted: 14,
        monthlyWorkoutsAssigned: 16,
        completionPercentage: 87.5
    )
}

// MARK: - Client View Model
class ClientViewModel: ObservableObject {
    @Published var currentClient: Client = Client(
        id: "client1",
        name: "Sample Client", 
        email: "sample@example.com", 
        trainerId: "trainer1",
        status: .new,
        joinedDate: Date(),
        profileImageUrl: nil,
        height: "5'6\"",
        weight: "140 lbs",
        goal: "Getting started with movement",
        injuries: "None",
        preferredCoachingStyle: .hybrid,
        lastWorkoutDate: nil,
        lastActivityDate: Date(),
        currentPlanId: nil,
        totalWorkoutsCompleted: 0
    )
    @Published var todayWorkout: WorkoutAssignment?
    @Published var weeklyAssignments: [WorkoutAssignment] = []
    @Published var totalAssignments: Int = 0
    @Published var completedAssignments: Int = 0
    @Published var currentStreak: Int = 0
    @Published var availableExercises: [Exercise] = []
    @Published var messages: [Message] = [
        Message(id: "1", text: "Welcome! How are you feeling today?", isFromTrainer: true, timestamp: Date()),
        Message(id: "2", text: "I'm ready to get moving!", isFromTrainer: false, timestamp: Date())
    ]
    @Published var selectedExerciseCategory: ExerciseCategory? = nil // nil means "All"
    @Published var isLoading = false
    
    init() {
        loadData()
        loadSampleData()
    }
    
    private func loadSampleData() {
        // Try to load real sample data if available
        if let sampleClient = Client.sampleClients.first {
            currentClient = sampleClient
        }
        
        if !Message.sampleMessages.isEmpty {
            messages = Message.sampleMessages
        }
        
        // Load sample exercises for the exercise library
        availableExercises = Exercise.sampleExercises
        print("🏋️ ClientViewModel loaded \(availableExercises.count) exercises")
        
        // Debug: Print all exercise titles to verify they're loaded
        print("📋 All exercises loaded:")
        for (index, exercise) in availableExercises.enumerated() {
            print("  \(index + 1). \(exercise.title) [\(exercise.category?.rawValue ?? "No Category")]")
        }
        
        // Debug: Check filtered exercises
        print("🔍 Filtered exercises count: \(filteredExercises.count)")
    }
    
    // MARK: - Data Loading
    private func loadData() {
        // Load today's workout
        let today = Date()
        todayWorkout = WorkoutAssignment.sampleAssignments.first { assignment in
            Calendar.current.isDate(assignment.date, inSameDayAs: today)
        }
        
        // Load this week's assignments
        loadWeeklyAssignments()
    }
    
    private func loadWeeklyAssignments() {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        // Generate assignments for the week
        weeklyAssignments = []
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) ?? startOfWeek
            
            // Find existing assignment or create rest day
            if let existingAssignment = WorkoutAssignment.sampleAssignments.first(where: { assignment in
                calendar.isDate(assignment.date, inSameDayAs: date)
            }) {
                weeklyAssignments.append(existingAssignment)
            } else {
                // Rest day - no assignment
                continue
            }
        }
    }
    
    // MARK: - Workout Actions
    func startWorkout(_ assignment: WorkoutAssignment) {
        // Start workout logic would go here
        print("Starting workout: \(assignment.title)")
    }
    
    func completeWorkout(_ assignment: WorkoutAssignment, rating: Int, notes: String) {
        // Complete workout logic would go here
        print("Completed workout: \(assignment.title), Rating: \(rating), Notes: \(notes)")
    }
    
    // MARK: - Exercise Library
    func filterExercises(by category: ExerciseCategory?) {
        selectedExerciseCategory = category
    }
    
    var filteredExercises: [Exercise] {
        // If no category is selected (nil), show all exercises
        guard let selectedCategory = selectedExerciseCategory else {
            return availableExercises
        }
        
        // Filter by selected category
        return availableExercises.filter { $0.category == selectedCategory }
    }
    
    var exerciseCategories: [ExerciseCategory] {
        return ExerciseCategory.allCases
    }
    
    // MARK: - Messages
    func sendMessage(_ text: String) {
        let newMessage = Message(
            id: UUID().uuidString,
            text: text,
            isFromTrainer: false,
            timestamp: Date()
        )
        messages.append(newMessage)
    }
    
    // MARK: - Public Methods
    
    func updateWorkoutCompletion(for assignment: WorkoutAssignment, isCompleted: Bool) {
        // Update workout completion status
        if let index = weeklyAssignments.firstIndex(where: { $0.id == assignment.id }) {
            weeklyAssignments[index].status = isCompleted ? .completed : .pending
            
            // Update completed count
            completedAssignments = weeklyAssignments.filter { $0.status == .completed }.count
            
            // Update streak if needed
            if isCompleted {
                currentStreak += 1
                currentClient.totalWorkoutsCompleted += 1
            }
        }
    }
    
    func loadTodayWorkout() {
        // Load today's workout assignment
        let today = Calendar.current.startOfDay(for: Date())
        todayWorkout = weeklyAssignments.first { assignment in
            Calendar.current.isDate(assignment.date, inSameDayAs: today)
        }
    }
}

// MARK: - Helper Extensions
extension ClientViewModel {
    var progressPercentage: Double {
        guard totalAssignments > 0 else { return 0 }
        return Double(completedAssignments) / Double(totalAssignments)
    }
    
    var hasActivePlan: Bool {
        return currentClient.currentPlanId != nil
    }
} 