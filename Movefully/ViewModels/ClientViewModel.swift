import SwiftUI
import UIKit
import Foundation
import Combine
import FirebaseAuth
import FirebaseStorage

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
    let description: String?
    let date: Date
    var status: WorkoutStatus
    let exercises: [AssignedExercise]
    let trainerNotes: String?
    let estimatedDuration: Int // minutes
    
    static let sampleAssignments = [
        WorkoutAssignment(
            title: "Morning Flow",
            description: "A gentle morning routine to wake up your body and mind",
            date: Date(),
            status: .pending,
            exercises: AssignedExercise.sampleExercises,
            trainerNotes: "Focus on your breath and move at your own pace. Listen to your body today.",
            estimatedDuration: 30
        ),
        WorkoutAssignment(
            title: "Core Strength",
            description: "Targeted core strengthening exercises to build stability",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            status: .completed,
            exercises: AssignedExercise.sampleExercises,
            trainerNotes: "Great work yesterday! I loved seeing your progress in the plank hold.",
            estimatedDuration: 25
        ),
        WorkoutAssignment(
            title: "Gentle Mobility",
            description: "Restorative movements to improve flexibility and reduce tension",
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            status: .completed,
            exercises: AssignedExercise.sampleExercises,
            trainerNotes: "Perfect timing for recovery work. How did your back feel afterward?",
            estimatedDuration: 20
        ),
        WorkoutAssignment(
            title: "Lower Body Strength",
            description: "Build strength and power in your legs and glutes",
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
    let exerciseType: ExerciseType // New field to determine display logic
    
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
            category: .flexibility,
            exerciseType: .reps
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
            category: .strength,
            exerciseType: .duration
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
            category: .flexibility,
            exerciseType: .duration
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

// MARK: - Inspirational Quote Model
struct InspirationalQuote: Identifiable {
    let id = UUID()
    let text: String
    let author: String
    let category: QuoteCategory
    
    enum QuoteCategory: String, CaseIterable {
        case movement = "Movement"
        case wellness = "Wellness"
        case mindfulness = "Mindfulness"
        case strength = "Strength"
        case motivation = "Motivation"
        
        var icon: String {
            switch self {
            case .movement: return "figure.walk"
            case .wellness: return "heart.fill"
            case .mindfulness: return "brain.head.profile"
            case .strength: return "dumbbell.fill"
            case .motivation: return "flame.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .movement: return MovefullyTheme.Colors.primaryTeal
            case .wellness: return MovefullyTheme.Colors.softGreen
            case .mindfulness: return MovefullyTheme.Colors.lavender
            case .strength: return MovefullyTheme.Colors.warmOrange
            case .motivation: return MovefullyTheme.Colors.gentleBlue
            }
        }
    }
    
    static let sampleQuotes = [
        InspirationalQuote(
            text: "Movement is medicine for creating change in a person's physical, emotional, and mental states.",
            author: "Carol Welch",
            category: .movement
        ),
        InspirationalQuote(
            text: "Take care of your body. It's the only place you have to live.",
            author: "Jim Rohn",
            category: .wellness
        ),
        InspirationalQuote(
            text: "The groundwork for all happiness is good health.",
            author: "Leigh Hunt",
            category: .wellness
        ),
        InspirationalQuote(
            text: "Mindfulness is about being fully awake in our lives. It is about perceiving the exquisite vividness of each moment.",
            author: "Jon Kabat-Zinn",
            category: .mindfulness
        ),
        InspirationalQuote(
            text: "Strength doesn't come from what you can do. It comes from overcoming the things you once thought you couldn't.",
            author: "Rikki Rogers",
            category: .strength
        ),
        InspirationalQuote(
            text: "Your body can do it. It's your mind you have to convince.",
            author: "Unknown",
            category: .motivation
        ),
        InspirationalQuote(
            text: "Progress, not perfection, is the goal.",
            author: "Unknown",
            category: .motivation
        ),
        InspirationalQuote(
            text: "Every small step forward is a victory worth celebrating.",
            author: "Unknown",
            category: .movement
        ),
        InspirationalQuote(
            text: "Wellness is not a destination, but a journey of small, consistent choices.",
            author: "Unknown",
            category: .wellness
        ),
        InspirationalQuote(
            text: "Be present in all things and thankful for all things.",
            author: "Maya Angelou",
            category: .mindfulness
        ),
        InspirationalQuote(
            text: "You are stronger than you think and more capable than you imagine.",
            author: "Unknown",
            category: .strength
        ),
        InspirationalQuote(
            text: "The only bad workout is the one that didn't happen.",
            author: "Unknown",
            category: .motivation
        ),
        InspirationalQuote(
            text: "Listen to your body. It knows what it needs.",
            author: "Unknown",
            category: .movement
        ),
        InspirationalQuote(
            text: "Wellness is the complete integration of body, mind, and spirit.",
            author: "Greg Anderson",
            category: .wellness
        ),
        InspirationalQuote(
            text: "Peace comes from within. Do not seek it without.",
            author: "Buddha",
            category: .mindfulness
        )
    ]
}

// MARK: - Client View Model
@MainActor
class ClientViewModel: ObservableObject {
    @Published var currentClient: Client?
    @Published var todayWorkout: WorkoutAssignment?
    @Published var weeklyAssignments: [WorkoutAssignment] = []
    @Published var totalAssignments: Int = 0
    @Published var completedAssignments: Int = 0
    @Published var currentStreak: Int = 0
    @Published var availableExercises: [Exercise] = []
    @Published var messages: [Message] = []
    @Published var selectedExerciseCategory: ExerciseCategory? = nil // nil means "All"
    @Published var isLoading = false
    @Published var hasNoPlan = false
    @Published var errorMessage: String? = nil
    @Published var assignmentsByWeek: [Int: [WorkoutAssignment]] = [:]
    
    // Notification Settings
    @Published var notificationsEnabled = true
    
    // Services
    private let clientDataService = ClientDataService()
    let clientMessagesService = ClientMessagesService()
    private let workoutAssignmentService = ClientWorkoutAssignmentService()
    
    // Combine cancellables for real-time updates
    private var cancellables = Set<AnyCancellable>()
    
    // Week navigation limits (should match ClientScheduleView)
    private let minWeekOffset = -2
    private let maxWeekOffset = 4
    
    init() {
        // Set loading state instead of showing sample data
        isLoading = true
        loadExerciseLibrary()
        
        // Load real data asynchronously
        loadRealData()
    }
    
    func loadRealData() {
        isLoading = true
        errorMessage = nil
        Task {
            await loadCurrentClient()
            // Detect and notify missed workouts before loading current data
            await workoutAssignmentService.detectAndNotifyMissedWorkouts()
            await loadTodayWorkout()
            // Preload all weeks in range
            await preloadAllWeeks()
            await loadMessages()
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    func loadExerciseLibrary() {
        // Load exercises from the library
        availableExercises = Exercise.sampleExercises
        print("🏋️ ClientViewModel loaded \(availableExercises.count) exercises")
    }
    
    @MainActor
    private func loadCurrentClient() async {
        print("🔍 ClientViewModel: Loading current client data")
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ ClientViewModel: No authenticated user found")
            currentClient = nil
            hasNoPlan = true
            return
        }
        
        do {
            // Fetch the real client data using the authenticated user's ID
            let fetchedClient = try await clientDataService.fetchClient(clientId: currentUserId)
            currentClient = fetchedClient
            loadNotificationSettings() // Load notification settings after client data is loaded
            print("✅ ClientViewModel: Successfully loaded client: \(fetchedClient.name)")
        } catch {
            print("❌ ClientViewModel: Failed to load client data: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load profile data"
                isLoading = false
            }
        }
    }
    
    func loadTodayWorkout() {
        Task {
            await loadTodayWorkoutAsync()
        }
    }
    
    private func loadTodayWorkoutAsync() async {
        print("🔍 ClientViewModel: Loading today's workout")
        do {
            todayWorkout = try await workoutAssignmentService.getTodayWorkoutAssignment()
            if todayWorkout == nil {
                print("🔍 ClientViewModel: No workout assigned for today")
            } else {
                print("✅ ClientViewModel: Today's workout loaded: \(todayWorkout?.title ?? "Unknown")")
            }
        } catch {
            errorMessage = "Failed to load today's workout: \(error.localizedDescription)"
            todayWorkout = nil
            print("❌ ClientViewModel: Failed to load today's workout: \(error)")
        }
    }
    
    @MainActor
    private func preloadAllWeeks() async {
        print("🔄 Preloading all week assignments from \(minWeekOffset) to \(maxWeekOffset)")
        var assignmentsByWeekTemp: [Int: [WorkoutAssignment]] = [:]
        
        await withTaskGroup(of: (Int, [WorkoutAssignment]).self) { group in
            for weekOffset in minWeekOffset...maxWeekOffset {
                group.addTask {
                    let assignments = try? await self.workoutAssignmentService.getWeeklyWorkoutAssignments(weekOffset: weekOffset)
                    return (weekOffset, assignments ?? [])
                }
            }
            
            for await (weekOffset, assignments) in group {
                assignmentsByWeekTemp[weekOffset] = assignments
                if weekOffset == 0 {
                    self.weeklyAssignments = assignments // keep current week for compatibility
                }
            }
        }
        
        // Update the published property after all tasks complete
        self.assignmentsByWeek = assignmentsByWeekTemp
        print("✅ Preloaded all week assignments")
    }
    
    @MainActor
    private func loadMessages() async {
        print("🔍 ClientViewModel: Loading messages")
        
        guard let client = currentClient else {
            print("❌ ClientViewModel: No current client available for loading messages")
            return
        }
        
        // Get trainer ID from client data
        let trainerId = client.trainerId
        let clientId = client.id
        let clientName = client.name
        
        do {
            // Setup conversation with trainer using ClientMessagesService
            try await clientMessagesService.setupConversation(
                clientId: clientId,
                trainerId: trainerId,
                clientName: clientName
            )
            
            // Fetch trainer profile
            try await clientMessagesService.fetchTrainerProfile(trainerId: trainerId)
            
            // Observe messages from the service
            await MainActor.run {
                // Set up binding to update messages when clientMessagesService.messages changes
                self.messages = clientMessagesService.messages
                
                // Set up real-time updates
                clientMessagesService.$messages
                    .receive(on: DispatchQueue.main)
                    .assign(to: \.messages, on: self)
                    .store(in: &cancellables)
                
                print("✅ ClientViewModel: Messages setup complete")
            }
            
        } catch {
            await MainActor.run {
                print("❌ ClientViewModel: Error loading messages: \(error)")
                self.messages = []
            }
        }
    }
    
    private func calculateCurrentStreak() {
        // Calculate current streak based on consecutive completed workouts
        currentStreak = 0
        let sortedAssignments = weeklyAssignments.sorted { $0.date > $1.date }
        
        for assignment in sortedAssignments {
            if assignment.status == .completed {
                currentStreak += 1
            } else {
                break
            }
        }
    }
    
    // MARK: - Workout Actions
    func startWorkout(_ assignment: WorkoutAssignment) {
        // Start workout logic would go here
        print("Starting workout: \(assignment.title)")
    }
    
    func completeWorkout(_ assignment: WorkoutAssignment, rating: Int, notes: String, skippedExercises: Set<Int> = [], completedExercises: Set<Int> = [], actualDuration: Int? = nil) {
        Task {
            do {
                // Complete workout through service with additional session data
                try await workoutAssignmentService.completeWorkout(
                    assignment, 
                    rating: rating, 
                    notes: notes,
                    skippedExercises: skippedExercises,
                    completedExercises: completedExercises,
                    actualDuration: actualDuration
                )
                
                // Update local state
                await MainActor.run {
                    // Update the assignment status to completed
                    if let index = weeklyAssignments.firstIndex(where: { $0.id == assignment.id }) {
                        weeklyAssignments[index].status = .completed
                    }
                    
                    // Also update assignmentsByWeek so Schedule page shows the updated status
                    for weekOffset in assignmentsByWeek.keys {
                        if let weekAssignments = assignmentsByWeek[weekOffset],
                           let index = weekAssignments.firstIndex(where: { $0.id == assignment.id }) {
                            assignmentsByWeek[weekOffset]![index].status = .completed
                            break // Assignment will only be in one week
                        }
                    }
                    
                    // Update today's workout if it's the same assignment
                    if let todayWorkout = todayWorkout, todayWorkout.id == assignment.id {
                        var updatedAssignment = todayWorkout
                        updatedAssignment.status = .completed
                        self.todayWorkout = updatedAssignment
                    }
                    
                    // Update completed count and stats
                    completedAssignments = weeklyAssignments.filter { $0.status == .completed }.count
                    calculateCurrentStreak()
                    
                    // Update client stats if available
                    if var client = currentClient {
                        client.totalWorkoutsCompleted += 1
                        client.lastWorkoutDate = Date()
                        client.lastActivityDate = Date()
                        currentClient = client
                    }
                    
                    print("✅ Completed workout: \(assignment.title), Rating: \(rating)")
                    
                    // Invalidate progress cache so the Progress page shows the latest completion
                    ProgressDataCacheService.shared.invalidateCache()
                }
            } catch {
                await MainActor.run {
                    print("❌ Failed to complete workout: \(error)")
                }
            }
        }
    }
    
    // MARK: - Exercise Library
    func filterExercises(by category: ExerciseCategory?) {
        selectedExerciseCategory = category
    }
    
    var filteredExercises: [Exercise] {
        // If no category is selected (nil), show all exercises
        guard let selectedCategory = selectedExerciseCategory else {
            return availableExercises.sorted { $0.title < $1.title }
        }
        
        // Filter by selected category and sort alphabetically
        return availableExercises.filter { $0.category == selectedCategory }
            .sorted { $0.title < $1.title }
    }
    
    var exerciseCategories: [ExerciseCategory] {
        return ExerciseCategory.allCases
    }
    
    // MARK: - Messages
    func sendMessage(_ text: String) {
        Task {
            do {
                try await clientMessagesService.sendMessage(text: text)
                print("✅ ClientViewModel: Message sent successfully")
            } catch {
                await MainActor.run {
                    print("❌ ClientViewModel: Error sending message: \(error)")
                }
            }
        }
    }
    
    func loadMoreMessages() {
        Task {
            do {
                try await clientMessagesService.loadMoreMessages()
                print("✅ ClientViewModel: More messages loaded successfully")
            } catch {
                print("❌ ClientViewModel: Error loading more messages: \(error)")
            }
        }
    }
    
    // MARK: - Inspirational Quotes
    var dailyInspirationalQuote: InspirationalQuote {
        // Use current date to seed random number generator for consistent daily quotes
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        
        // Use day of year to select quote consistently for the day
        let quoteIndex = (dayOfYear - 1) % InspirationalQuote.sampleQuotes.count
        return InspirationalQuote.sampleQuotes[quoteIndex]
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
                if var client = currentClient {
                    client.totalWorkoutsCompleted += 1
                    currentClient = client
                }
            }
        }
    }
    
    func loadTodayWorkoutFromWeekly() {
        // Load today's workout assignment from weekly assignments
        let today = Calendar.current.startOfDay(for: Date())
        todayWorkout = weeklyAssignments.first { assignment in
            Calendar.current.isDate(assignment.date, inSameDayAs: today)
        }
    }
    
    @MainActor
    func updateClientProfile(_ updatedClient: Client) async throws {
        print("🔄 ClientViewModel: Updating client profile")
        
        // Detect changes between current and updated client
        let changes = detectProfileChanges(current: currentClient, updated: updatedClient)
        
        // Update the client profile in Firestore using the client self-update method
        try await clientDataService.updateClientSelfProfile(updatedClient)
        
        // Create automatic note for trainer if there are changes
        if !changes.isEmpty && !updatedClient.trainerId.isEmpty {
            do {
                try await clientDataService.createProfileUpdateNote(
                    clientId: updatedClient.id,
                    trainerId: updatedClient.trainerId,
                    clientName: updatedClient.name,
                    changes: changes
                )
                print("✅ ClientViewModel: Profile update note created for trainer")
            } catch {
                print("⚠️ ClientViewModel: Failed to create profile update note: \(error.localizedDescription)")
                // Don't throw error here - profile update succeeded, note creation is secondary
            }
        }
        
        // Update local state after successful Firestore update
        currentClient = updatedClient
        
        print("✅ ClientViewModel: Client profile updated successfully")
    }
    
    /// Detects changes between current and updated client profiles
    private func detectProfileChanges(current: Client?, updated: Client) -> [String] {
        guard let current = current else { return [] }
        
        var changes: [String] = []
        
        // Check name changes
        if current.name != updated.name {
            changes.append("Name: \"\(current.name)\" → \"\(updated.name)\"")
        }
        
        // Check goals changes
        let currentGoals = current.goals?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let updatedGoals = updated.goals?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if currentGoals != updatedGoals {
            if currentGoals.isEmpty && !updatedGoals.isEmpty {
                changes.append("Goals: Added \"\(updatedGoals)\"")
            } else if !currentGoals.isEmpty && updatedGoals.isEmpty {
                changes.append("Goals: Removed previous goals")
            } else if !currentGoals.isEmpty && !updatedGoals.isEmpty {
                changes.append("Goals: Updated to \"\(updatedGoals)\"")
            }
        }
        
        // Check height changes
        let currentHeight = current.height?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let updatedHeight = updated.height?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if currentHeight != updatedHeight {
            if currentHeight.isEmpty && !updatedHeight.isEmpty {
                changes.append("Height: Added \(updatedHeight)")
            } else if !currentHeight.isEmpty && updatedHeight.isEmpty {
                changes.append("Height: Removed")
            } else if !currentHeight.isEmpty && !updatedHeight.isEmpty {
                changes.append("Height: \(currentHeight) → \(updatedHeight)")
            }
        }
        
        // Check weight changes
        let currentWeight = current.weight?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let updatedWeight = updated.weight?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if currentWeight != updatedWeight {
            if currentWeight.isEmpty && !updatedWeight.isEmpty {
                changes.append("Weight: Added \(updatedWeight)")
            } else if !currentWeight.isEmpty && updatedWeight.isEmpty {
                changes.append("Weight: Removed")
            } else if !currentWeight.isEmpty && !updatedWeight.isEmpty {
                changes.append("Weight: \(currentWeight) → \(updatedWeight)")
            }
        }
        
        // Check injuries changes
        let currentInjuries = current.injuries?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let updatedInjuries = updated.injuries?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if currentInjuries != updatedInjuries {
            if currentInjuries.isEmpty && !updatedInjuries.isEmpty {
                changes.append("Health Information: Added \"\(updatedInjuries)\"")
            } else if !currentInjuries.isEmpty && updatedInjuries.isEmpty {
                changes.append("Health Information: Removed previous information")
            } else if !currentInjuries.isEmpty && !updatedInjuries.isEmpty {
                changes.append("Health Information: Updated to \"\(updatedInjuries)\"")
            }
        }
        
        return changes
    }
    
    // MARK: - Profile Photo Upload
    
    @MainActor
    func uploadProfilePhoto(_ imageData: Data) async throws {
        guard let clientId = currentClient?.id else {
            throw NSError(domain: "ClientViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No client ID available"])
        }
        
        print("🔄 ClientViewModel: Uploading profile photo for client: \(clientId)")
        
        // Compress the image data to reduce storage costs and upload time
        let compressedImageData = compressImageData(imageData, maxSizeKB: 500) // Max 500KB
        
        // Create a reference to Firebase Storage
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profile_images/clients/\(clientId).jpg")
        
        // Upload the compressed image
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            let _ = try await profileImageRef.putDataAsync(compressedImageData, metadata: metadata)
            
            // Get the download URL
            let downloadURL = try await profileImageRef.downloadURL()
            
            // Update the client profile with the new image URL
            var updatedClient = currentClient
            updatedClient?.profileImageUrl = downloadURL.absoluteString
            
            // Save the updated client profile
            try await updateClientProfile(updatedClient!)
            
            print("✅ ClientViewModel: Profile photo uploaded successfully")
        } catch {
            print("❌ ClientViewModel: Failed to upload profile photo: \(error)")
            // If upload fails, try to create the storage path first
            throw error
        }
    }
    
    /// Compresses image data to reduce file size for storage efficiency
    private func compressImageData(_ imageData: Data, maxSizeKB: Int) -> Data {
        guard let image = UIImage(data: imageData) else {
            print("⚠️ ClientViewModel: Could not create UIImage from data, returning original")
            return imageData
        }
        
        let maxSizeBytes = maxSizeKB * 1024
        var compressionQuality: CGFloat = 0.8
        var compressedData = image.jpegData(compressionQuality: compressionQuality) ?? imageData
        
        // Reduce quality until we're under the size limit
        while compressedData.count > maxSizeBytes && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            compressedData = image.jpegData(compressionQuality: compressionQuality) ?? imageData
        }
        
        // If still too large, resize the image
        if compressedData.count > maxSizeBytes {
            let maxDimension: CGFloat = 800
            let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
            
            if scale < 1.0 {
                let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                compressedData = resizedImage?.jpegData(compressionQuality: 0.8) ?? imageData
            }
        }
        
        let originalSizeKB = imageData.count / 1024
        let compressedSizeKB = compressedData.count / 1024
        print("📸 ClientViewModel: Image compressed from \(originalSizeKB)KB to \(compressedSizeKB)KB")
        
        return compressedData
    }
    
    // MARK: - Notification Settings
    
    func loadNotificationSettings() {
        // Load notification setting from current client profile or default to true
        notificationsEnabled = currentClient?.notificationsEnabled ?? true
    }
    
    func saveNotificationSettings() async {
        guard let clientId = currentClient?.id else {
            print("❌ ClientViewModel: No client ID available for saving notification settings")
            return
        }
        
        do {
            let fcmToken = currentClient?.fcmToken
            try await clientDataService.updateNotificationSettings(
                clientId: clientId,
                enabled: notificationsEnabled,
                fcmToken: fcmToken
            )
            
            // Update local client data
            currentClient?.notificationsEnabled = notificationsEnabled
            
            print("✅ ClientViewModel: Notification settings saved successfully")
        } catch {
            print("❌ ClientViewModel: Error saving notification settings: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
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
        return currentClient?.currentPlanId != nil
    }
} 