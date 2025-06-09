import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class ExerciseDataService: ObservableObject {
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var exercises: [Exercise] = []
    @Published var customExercises: [Exercise] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var currentTrainerId: String? {
        Auth.auth().currentUser?.uid
    }
    
    init() {
        Task {
            await loadExercises()
            setupCustomExercisesListener()
        }
    }
    
    deinit {
        listener?.remove()
        cancellables.removeAll()
    }
    
    // MARK: - Exercise Loading
    
    func loadExercises() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load global exercises (created by system/admin)
            let globalSnapshot = try await db.collection("exercises")
                .whereField("isGlobal", isEqualTo: true)
                .getDocuments()
            
            let globalExercises = globalSnapshot.documents.compactMap { document in
                try? document.data(as: Exercise.self)
            }
            
            // If no global exercises exist, seed the database
            if globalExercises.isEmpty {
                print("No exercises found in Firestore. Seeding database with sample exercises...")
                await seedGlobalExercises()
                
                // Reload after seeding
                let reloadSnapshot = try await db.collection("exercises")
                    .whereField("isGlobal", isEqualTo: true)
                    .getDocuments()
                
                let reloadedExercises = reloadSnapshot.documents.compactMap { document in
                    try? document.data(as: Exercise.self)
                }
                
                // Sort by title in code instead of in query to avoid composite index requirement
                self.exercises = reloadedExercises.sorted { $0.title < $1.title }
            } else {
                // Sort by title in code instead of in query to avoid composite index requirement
                self.exercises = globalExercises.sorted { $0.title < $1.title }
            }
            
        } catch {
            self.errorMessage = "Failed to load exercises: \(error.localizedDescription)"
            print("Error loading exercises: \(error)")
            
            // Fallback to sample data if Firebase fails
            self.exercises = Exercise.sampleExercises
        }
    }
    
    // MARK: - Database Seeding
    
    private func seedGlobalExercises() async {
        print("Seeding Firestore with global exercises...")
        
        do {
            let batch = db.batch()
            let sampleExercises = Exercise.sampleExercises
            
            for exercise in sampleExercises {
                let data: [String: Any] = [
                    "id": exercise.id,
                    "title": exercise.title,
                    "description": exercise.description ?? "",
                    "mediaUrl": exercise.mediaUrl ?? "",
                    "category": exercise.category?.rawValue ?? "",
                    "duration": exercise.duration ?? 0,
                    "difficulty": exercise.difficulty?.rawValue ?? "",
                    "exerciseType": exercise.exerciseType.rawValue,
                    "howToPerform": exercise.howToPerform ?? [],
                    "trainerTips": exercise.trainerTips ?? [],
                    "commonMistakes": exercise.commonMistakes ?? [],
                    "modifications": exercise.modifications ?? [],
                    "equipmentNeeded": exercise.equipmentNeeded ?? [],
                    "targetMuscles": exercise.targetMuscles ?? [],
                    "breathingCues": exercise.breathingCues ?? "",
                    "createdByTrainerId": NSNull(), // Global exercises have no trainer ID
                    "isGlobal": true,
                    "createdAt": Timestamp(date: Date()),
                    "updatedAt": Timestamp(date: Date())
                ]
                
                let docRef = db.collection("exercises").document(exercise.id)
                batch.setData(data, forDocument: docRef)
            }
            
            try await batch.commit()
            print("Successfully seeded \(sampleExercises.count) global exercises to Firestore")
            
        } catch {
            print("Failed to seed exercises: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Custom Exercises (Trainer-Specific)
    
    private func setupCustomExercisesListener() {
        guard let trainerId = currentTrainerId else {
            print("No authenticated trainer found")
            return
        }
        
        listener = db.collection("exercises")
            .whereField("createdByTrainerId", isEqualTo: trainerId)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    if let error = error {
                        self?.errorMessage = "Failed to load custom exercises: \(error.localizedDescription)"
                        print("Error loading custom exercises: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.customExercises = []
                        return
                    }
                    
                    let customExercises = documents.compactMap { document in
                        try? document.data(as: Exercise.self)
                    }
                    
                    // Sort by title in code instead of in query to avoid composite index requirement
                    self?.customExercises = customExercises.sorted { $0.title < $1.title }
                }
            }
    }
    
    // MARK: - Combined Exercise Access
    
    var allExercises: [Exercise] {
        return exercises + customExercises
    }
    
    // MARK: - Custom Exercise Creation
    
    func createCustomExercise(_ exercise: Exercise) async throws {
        guard let trainerId = currentTrainerId else {
            throw ExerciseError.notAuthenticated
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let data: [String: Any] = [
            "id": exercise.id,
            "title": exercise.title,
            "description": exercise.description ?? "",
            "mediaUrl": exercise.mediaUrl ?? "",
            "category": exercise.category?.rawValue ?? "",
            "duration": exercise.duration ?? 0,
            "difficulty": exercise.difficulty?.rawValue ?? "",
            "exerciseType": exercise.exerciseType.rawValue,
            "howToPerform": exercise.howToPerform ?? [],
            "trainerTips": exercise.trainerTips ?? [],
            "commonMistakes": exercise.commonMistakes ?? [],
            "modifications": exercise.modifications ?? [],
            "equipmentNeeded": exercise.equipmentNeeded ?? [],
            "targetMuscles": exercise.targetMuscles ?? [],
            "breathingCues": exercise.breathingCues ?? "",
            "createdByTrainerId": trainerId,
            "isGlobal": false,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection("exercises").document(exercise.id).setData(data)
    }
    
    // MARK: - Custom Exercise Updates
    
    func updateCustomExercise(_ exercise: Exercise) async throws {
        guard let trainerId = currentTrainerId else {
            throw ExerciseError.notAuthenticated
        }
        
        // Verify this is a custom exercise created by this trainer
        guard exercise.createdByTrainerId == trainerId else {
            throw ExerciseError.unauthorized
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let data: [String: Any] = [
            "title": exercise.title,
            "description": exercise.description ?? "",
            "mediaUrl": exercise.mediaUrl ?? "",
            "category": exercise.category?.rawValue ?? "",
            "duration": exercise.duration ?? 0,
            "difficulty": exercise.difficulty?.rawValue ?? "",
            "exerciseType": exercise.exerciseType.rawValue,
            "howToPerform": exercise.howToPerform ?? [],
            "trainerTips": exercise.trainerTips ?? [],
            "commonMistakes": exercise.commonMistakes ?? [],
            "modifications": exercise.modifications ?? [],
            "equipmentNeeded": exercise.equipmentNeeded ?? [],
            "targetMuscles": exercise.targetMuscles ?? [],
            "breathingCues": exercise.breathingCues ?? "",
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection("exercises").document(exercise.id).updateData(data)
    }
    
    // MARK: - Custom Exercise Deletion
    
    func deleteCustomExercise(_ exercise: Exercise) async throws {
        guard let trainerId = currentTrainerId else {
            throw ExerciseError.notAuthenticated
        }
        
        // Verify this is a custom exercise created by this trainer
        guard exercise.createdByTrainerId == trainerId else {
            throw ExerciseError.unauthorized
        }
        
        isLoading = true
        defer { isLoading = false }
        
        try await db.collection("exercises").document(exercise.id).delete()
    }
    
    // MARK: - Exercise Search and Filtering
    
    func searchExercises(query: String, category: ExerciseCategory? = nil) -> [Exercise] {
        var filtered = allExercises
        
        // Apply category filter
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply search query
        if !query.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.title.localizedCaseInsensitiveContains(query) ||
                exercise.description?.localizedCaseInsensitiveContains(query) == true ||
                exercise.targetMuscles?.joined().localizedCaseInsensitiveContains(query) == true
            }
        }
        
        return filtered.sorted { $0.title < $1.title }
    }
    
    func getExercisesByCategory(_ category: ExerciseCategory) -> [Exercise] {
        return allExercises.filter { $0.category == category }
    }
    
    func getExercisesByDifficulty(_ difficulty: DifficultyLevel) -> [Exercise] {
        return allExercises.filter { $0.difficulty == difficulty }
    }
    
    func getExercisesByType(_ type: ExerciseType) -> [Exercise] {
        return allExercises.filter { $0.exerciseType == type }
    }
    
    // MARK: - Exercise Statistics
    
    func getExerciseAnalytics() -> ExerciseAnalytics {
        let totalExercises = allExercises.count
        let customExerciseCount = customExercises.count
        
        let categoryBreakdown = Dictionary(grouping: allExercises) { $0.category ?? .strength }
            .mapValues { $0.count }
        
        let difficultyBreakdown = Dictionary(grouping: allExercises) { $0.difficulty ?? .beginner }
            .mapValues { $0.count }
        
        let typeBreakdown = Dictionary(grouping: allExercises) { $0.exerciseType }
            .mapValues { $0.count }
        
        return ExerciseAnalytics(
            totalExercises: totalExercises,
            customExercises: customExerciseCount,
            categoryBreakdown: categoryBreakdown,
            difficultyBreakdown: difficultyBreakdown,
            typeBreakdown: typeBreakdown
        )
    }
    
    // MARK: - Manual Database Management
    
    /// Force re-seed the database with sample exercises (useful for testing or resetting)
    func forceSeedDatabase() async throws {
        await seedGlobalExercises()
        await loadExercises() // Reload after seeding
    }
    
    /// Check if database seeding is needed
    func isDatabaseEmpty() async -> Bool {
        do {
            let snapshot = try await db.collection("exercises")
                .whereField("isGlobal", isEqualTo: true)
                .limit(to: 1)
                .getDocuments()
            return snapshot.documents.isEmpty
        } catch {
            print("Error checking database status: \(error)")
            return true
        }
    }
    
    // MARK: - Batch Operations
    
    func importExercises(_ exercises: [Exercise]) async throws {
        guard let trainerId = currentTrainerId else {
            throw ExerciseError.notAuthenticated
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let batch = db.batch()
        
        for exercise in exercises {
            let data: [String: Any] = [
                "id": exercise.id,
                "title": exercise.title,
                "description": exercise.description ?? "",
                "mediaUrl": exercise.mediaUrl ?? "",
                "category": exercise.category?.rawValue ?? "",
                "duration": exercise.duration ?? 0,
                "difficulty": exercise.difficulty?.rawValue ?? "",
                "exerciseType": exercise.exerciseType.rawValue,
                "howToPerform": exercise.howToPerform ?? [],
                "trainerTips": exercise.trainerTips ?? [],
                "commonMistakes": exercise.commonMistakes ?? [],
                "modifications": exercise.modifications ?? [],
                "equipmentNeeded": exercise.equipmentNeeded ?? [],
                "targetMuscles": exercise.targetMuscles ?? [],
                "breathingCues": exercise.breathingCues ?? "",
                "createdByTrainerId": trainerId,
                "isGlobal": false,
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ]
            
            let docRef = db.collection("exercises").document(exercise.id)
            batch.setData(data, forDocument: docRef)
        }
        
        try await batch.commit()
    }
}

// MARK: - Supporting Types

enum ExerciseError: LocalizedError {
    case notAuthenticated
    case unauthorized
    case exerciseNotFound
    case invalidData
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to manage exercises"
        case .unauthorized:
            return "You can only modify exercises you created"
        case .exerciseNotFound:
            return "Exercise not found"
        case .invalidData:
            return "Invalid exercise data"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

struct ExerciseAnalytics {
    let totalExercises: Int
    let customExercises: Int
    let categoryBreakdown: [ExerciseCategory: Int]
    let difficultyBreakdown: [DifficultyLevel: Int]
    let typeBreakdown: [ExerciseType: Int]
}

// MARK: - Exercise Firestore Extensions

extension Exercise {
    init(from document: QueryDocumentSnapshot) throws {
        let data = document.data()
        
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let exerciseTypeRaw = data["exerciseType"] as? String,
              let exerciseType = ExerciseType(rawValue: exerciseTypeRaw) else {
            throw ExerciseError.invalidData
        }
        
        let description = data["description"] as? String
        let mediaUrl = data["mediaUrl"] as? String
        let categoryRaw = data["category"] as? String
        let category = categoryRaw != nil ? ExerciseCategory(rawValue: categoryRaw!) : nil
        let duration = data["duration"] as? Int
        let difficultyRaw = data["difficulty"] as? String
        let difficulty = difficultyRaw != nil ? DifficultyLevel(rawValue: difficultyRaw!) : nil
        let createdByTrainerId = data["createdByTrainerId"] as? String
        let howToPerform = data["howToPerform"] as? [String]
        let trainerTips = data["trainerTips"] as? [String]
        let commonMistakes = data["commonMistakes"] as? [String]
        let modifications = data["modifications"] as? [String]
        let equipmentNeeded = data["equipmentNeeded"] as? [String]
        let targetMuscles = data["targetMuscles"] as? [String]
        let breathingCues = data["breathingCues"] as? String
        
        self.init(
            id: id,
            title: title,
            description: description,
            mediaUrl: mediaUrl,
            category: category,
            duration: duration,
            difficulty: difficulty,
            createdByTrainerId: createdByTrainerId,
            exerciseType: exerciseType,
            howToPerform: howToPerform,
            trainerTips: trainerTips,
            commonMistakes: commonMistakes,
            modifications: modifications,
            equipmentNeeded: equipmentNeeded,
            targetMuscles: targetMuscles,
            breathingCues: breathingCues
        )
    }
} 