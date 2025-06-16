import Foundation

// MARK: - Workout Session State Model
struct WorkoutSessionState: Codable {
    let workoutId: String
    let workoutTitle: String
    let clientId: String
    let sessionStartTime: Date
    var currentExerciseIndex: Int
    var completedExercises: Set<Int>
    var skippedExercises: Set<Int>
    var elapsedTime: Int
    var isPaused: Bool
    var lastUpdated: Date
    
    init(workoutId: String, workoutTitle: String, clientId: String, sessionStartTime: Date = Date()) {
        self.workoutId = workoutId
        self.workoutTitle = workoutTitle
        self.clientId = clientId
        self.sessionStartTime = sessionStartTime
        self.currentExerciseIndex = 0
        self.completedExercises = []
        self.skippedExercises = []
        self.elapsedTime = 0
        self.isPaused = false
        self.lastUpdated = Date()
    }
    
    mutating func updateProgress(
        currentExerciseIndex: Int,
        completedExercises: Set<Int>,
        skippedExercises: Set<Int>,
        elapsedTime: Int,
        isPaused: Bool
    ) {
        self.currentExerciseIndex = currentExerciseIndex
        self.completedExercises = completedExercises
        self.skippedExercises = skippedExercises
        self.elapsedTime = elapsedTime
        self.isPaused = isPaused
        self.lastUpdated = Date()
    }
    
    var isExpired: Bool {
        // Consider session expired after 24 hours
        Date().timeIntervalSince(lastUpdated) > 24 * 60 * 60
    }
    
    var progressPercentage: Double {
        let totalActions = completedExercises.count + skippedExercises.count
        return totalActions > 0 ? Double(totalActions) / Double(max(currentExerciseIndex + 1, 1)) : 0.0
    }
}

// MARK: - Workout Session Persistence Service
@MainActor
class WorkoutSessionPersistenceService: ObservableObject {
    static let shared = WorkoutSessionPersistenceService()
    
    private let userDefaults = UserDefaults.standard
    private let localStorageKey = "MovefullyWorkoutSession"
    
    @Published var currentSession: WorkoutSessionState?
    @Published var hasActiveSession: Bool = false
    
    private init() {
        loadActiveSession()
    }
    
    // MARK: - Session Management
    
    /// Starts a new workout session
    func startSession(for assignment: WorkoutAssignment) {
        print("🎯 Starting new workout session: \(assignment.title)")
        print("🎯 Workout ID: \(assignment.id.uuidString)")
        print("🎯 Exercise count: \(assignment.exercises.count)")
        
        let newSession = WorkoutSessionState(
            workoutId: assignment.id.uuidString,
            workoutTitle: assignment.title,
            clientId: "current_user" // Simplified for now
        )
        
        currentSession = newSession
        hasActiveSession = true
        
        saveSessionLocally()
    }
    
    /// Updates the current session progress
    func updateSessionProgress(
        currentExerciseIndex: Int,
        completedExercises: Set<Int>,
        skippedExercises: Set<Int>,
        elapsedTime: Int,
        isPaused: Bool
    ) {
        guard var session = currentSession else { return }
        
        session.updateProgress(
            currentExerciseIndex: currentExerciseIndex,
            completedExercises: completedExercises,
            skippedExercises: skippedExercises,
            elapsedTime: elapsedTime,
            isPaused: isPaused
        )
        
        currentSession = session
        
        // Save locally immediately for quick recovery
        saveSessionLocally()
    }
    
    /// Completes and clears the current session
    func completeSession() {
        print("✅ Completing workout session")
        clearSession()
    }
    
    /// Cancels and clears the current session
    func cancelSession() {
        print("❌ Cancelling workout session")
        clearSession()
    }
    
    /// Restores a session if one exists
    func restoreSessionIfExists() -> WorkoutSessionState? {
        loadActiveSession()
        
        if let session = currentSession, !session.isExpired {
            print("🔄 Restored active workout session: \(session.workoutTitle)")
            print("🔄 Session workout ID: \(session.workoutId)")
            print("🔄 Session progress: \(session.completedExercises.count) completed, \(session.skippedExercises.count) skipped")
            return session
        } else if let session = currentSession, session.isExpired {
            print("⏰ Found expired session, clearing it")
            clearSession()
        } else {
            print("🔄 No active session found")
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    private func clearSession() {
        currentSession = nil
        hasActiveSession = false
        
        // Clear local storage
        userDefaults.removeObject(forKey: localStorageKey)
    }
    
    private func loadActiveSession() {
        guard let data = userDefaults.data(forKey: localStorageKey),
              let session = try? JSONDecoder().decode(WorkoutSessionState.self, from: data) else {
            hasActiveSession = false
            return
        }
        
        if !session.isExpired {
            currentSession = session
            hasActiveSession = true
        } else {
            // Clean up expired session
            userDefaults.removeObject(forKey: localStorageKey)
            hasActiveSession = false
        }
    }
    
    private func saveSessionLocally() {
        guard let session = currentSession,
              let data = try? JSONEncoder().encode(session) else { return }
        
        userDefaults.set(data, forKey: localStorageKey)
        print("💾 Saved session locally")
    }
    
    // MARK: - Recovery Methods (Placeholder)
    
    /// Placeholder for Firestore recovery - simplified for now
    func recoverSessionFromFirestore() async {
        print("📱 Firestore recovery not implemented in simplified version")
    }
} 