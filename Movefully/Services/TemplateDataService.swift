import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class TemplateDataService: ObservableObject {
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var templates: [WorkoutTemplate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var currentTrainerId: String? {
        Auth.auth().currentUser?.uid
    }
    
    init() {
        setupRealtimeListener()
    }
    
    deinit {
        listener?.remove()
        cancellables.removeAll()
    }
    
    // MARK: - Real-time Template Loading
    
    private func setupRealtimeListener() {
        guard let trainerId = currentTrainerId else {
            print("❌ TemplateDataService: No authenticated trainer found")
            return
        }
        
        print("✅ TemplateDataService: Setting up real-time listener for trainer: \(trainerId)")
        
        listener = db.collection("templates")
            .whereField("trainerId", isEqualTo: trainerId)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    if let error = error {
                        self?.errorMessage = "Failed to load templates: \(error.localizedDescription)"
                        print("❌ TemplateDataService: Error loading templates: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("⚠️ TemplateDataService: No documents found in templates collection")
                        self?.templates = []
                        return
                    }
                    
                    print("✅ TemplateDataService: Found \(documents.count) template documents")
                    
                    let parsedTemplates = documents.compactMap { document in
                        do {
                            let template = try WorkoutTemplate(from: document)
                            print("✅ TemplateDataService: Successfully parsed template: \(template.name)")
                            return template
                        } catch {
                            print("❌ TemplateDataService: Error parsing template: \(error)")
                            return nil
                        }
                    }
                    
                    // Sort by updatedDate in code instead of in query to avoid composite index requirement
                    self?.templates = parsedTemplates.sorted { $0.updatedDate > $1.updatedDate }
                    
                    print("✅ TemplateDataService: Loaded \(self?.templates.count ?? 0) templates")
                }
            }
    }
    
    // MARK: - Template Creation
    
    func createTemplate(_ template: WorkoutTemplate, exercisesWithPrescription: [ExerciseWithSetsReps]? = nil) async throws {
        guard let trainerId = currentTrainerId else {
            print("❌ TemplateDataService: User not authenticated")
            throw TemplateError.notAuthenticated
        }
        
        print("✅ TemplateDataService: Creating template '\(template.name)' for trainer: \(trainerId)")
        isLoading = true
        defer { isLoading = false }
        
        // Create the document data
        let data: [String: Any] = [
            "name": template.name,
            "description": template.description,
            "difficulty": template.difficulty.rawValue,
            "estimatedDuration": template.estimatedDuration,
            "exercises": template.exercises.enumerated().map { index, exercise in
                var exerciseData: [String: Any] = [
                    "id": exercise.id,
                    "title": exercise.title,
                    "description": exercise.description ?? "",
                    "category": exercise.category?.rawValue ?? "",
                    "difficulty": exercise.difficulty?.rawValue ?? "",
                    "exerciseType": exercise.exerciseType.rawValue,
                    "howToPerform": exercise.howToPerform ?? [],
                    "trainerTips": exercise.trainerTips ?? [],
                    "commonMistakes": exercise.commonMistakes ?? [],
                    "modifications": exercise.modifications ?? [],
                    "equipmentNeeded": exercise.equipmentNeeded ?? [],
                    "targetMuscles": exercise.targetMuscles ?? [],
                    "breathingCues": exercise.breathingCues ?? "",
                    "mediaUrl": exercise.mediaUrl ?? "",
                    "createdByTrainerId": exercise.createdByTrainerId ?? ""
                ]
                
                // Add workout prescription data if available
                if let exercisesWithPrescription = exercisesWithPrescription,
                   index < exercisesWithPrescription.count {
                    let exerciseWithSetsReps = exercisesWithPrescription[index]
                    exerciseData["sets"] = exerciseWithSetsReps.sets
                    
                    // Handle reps vs duration based on exercise type
                    if exercise.exerciseType == .reps {
                        exerciseData["reps"] = exerciseWithSetsReps.reps
                    } else {
                        // For duration exercises, store the duration value
                        if let durationInt = Int(exerciseWithSetsReps.reps) {
                            exerciseData["duration"] = durationInt
                        }
                    }
                }
                
                return exerciseData
            },
            "tags": template.tags,
            "icon": template.icon,
            "coachingNotes": template.coachingNotes ?? "",
            "usageCount": template.usageCount,
            "createdDate": Timestamp(date: template.createdDate),
            "updatedDate": Timestamp(date: template.updatedDate),
            "trainerId": trainerId
        ]
        
        try await db.collection("templates").document(template.id.uuidString).setData(data)
        print("✅ TemplateDataService: Template saved successfully to Firestore with ID: \(template.id.uuidString)")
    }
    
    // MARK: - Template Updates
    
    func updateTemplate(_ template: WorkoutTemplate, exercisesWithPrescription: [ExerciseWithSetsReps]? = nil) async throws {
        guard let trainerId = currentTrainerId else {
            print("❌ TemplateDataService: User not authenticated for update")
            throw TemplateError.notAuthenticated
        }
        
        print("✅ TemplateDataService: Updating template '\(template.name)' with ID: \(template.id.uuidString)")
        isLoading = true
        defer { isLoading = false }
        
        let data: [String: Any] = [
            "name": template.name,
            "description": template.description,
            "difficulty": template.difficulty.rawValue,
            "estimatedDuration": template.estimatedDuration,
            "exercises": template.exercises.enumerated().map { index, exercise in
                var exerciseData: [String: Any] = [
                    "id": exercise.id,
                    "title": exercise.title,
                    "description": exercise.description ?? "",
                    "category": exercise.category?.rawValue ?? "",
                    "difficulty": exercise.difficulty?.rawValue ?? "",
                    "exerciseType": exercise.exerciseType.rawValue,
                    "howToPerform": exercise.howToPerform ?? [],
                    "trainerTips": exercise.trainerTips ?? [],
                    "commonMistakes": exercise.commonMistakes ?? [],
                    "modifications": exercise.modifications ?? [],
                    "equipmentNeeded": exercise.equipmentNeeded ?? [],
                    "targetMuscles": exercise.targetMuscles ?? [],
                    "breathingCues": exercise.breathingCues ?? "",
                    "mediaUrl": exercise.mediaUrl ?? "",
                    "createdByTrainerId": exercise.createdByTrainerId ?? ""
                ]
                
                // Add workout prescription data if available
                if let exercisesWithPrescription = exercisesWithPrescription,
                   index < exercisesWithPrescription.count {
                    let exerciseWithSetsReps = exercisesWithPrescription[index]
                    exerciseData["sets"] = exerciseWithSetsReps.sets
                    
                    // Handle reps vs duration based on exercise type
                    if exercise.exerciseType == .reps {
                        exerciseData["reps"] = exerciseWithSetsReps.reps
                    } else {
                        // For duration exercises, store the duration value
                        if let durationInt = Int(exerciseWithSetsReps.reps) {
                            exerciseData["duration"] = durationInt
                        }
                    }
                }
                
                return exerciseData
            },
            "tags": template.tags,
            "icon": template.icon,
            "coachingNotes": template.coachingNotes ?? "",
            "usageCount": template.usageCount,
            "updatedDate": Timestamp(date: Date()),
            "trainerId": trainerId
        ]
        
        try await db.collection("templates").document(template.id.uuidString).updateData(data)
        print("✅ TemplateDataService: Template updated successfully in Firestore with ID: \(template.id.uuidString)")
    }
    
    // MARK: - Template Deletion
    
    func deleteTemplate(_ template: WorkoutTemplate) async throws {
        guard currentTrainerId != nil else {
            throw TemplateError.notAuthenticated
        }
        
        isLoading = true
        defer { isLoading = false }
        
        try await db.collection("templates").document(template.id.uuidString).delete()
    }
    
    // MARK: - Usage Tracking
    
    func incrementUsageCount(for templateId: UUID) async throws {
        guard currentTrainerId != nil else {
            throw TemplateError.notAuthenticated
        }
        
        let documentRef = db.collection("templates").document(templateId.uuidString)
        try await documentRef.updateData([
            "usageCount": FieldValue.increment(Int64(1))
        ])
    }
    
    /// Counts how many times this template is used across all programs
    func getLiveUsageCount(for templateId: UUID) async throws -> Int {
        guard let trainerId = currentTrainerId else {
            throw TemplateError.notAuthenticated
        }
        
        // Query all programs for this trainer
        let programsSnapshot = try await db.collection("programs")
            .whereField("trainerId", isEqualTo: trainerId)
            .getDocuments()
        
        var usageCount = 0
        let templateIdString = templateId.uuidString
        
        for document in programsSnapshot.documents {
            let data = document.data()
            
            // Check if this template is used in any scheduled workouts
            if let scheduledWorkouts = data["scheduledWorkouts"] as? [[String: Any]] {
                for workout in scheduledWorkouts {
                    if let workoutTemplateId = workout["workoutTemplateId"] as? String,
                       workoutTemplateId == templateIdString {
                        usageCount += 1
                    }
                }
            }
        }
        
        return usageCount
    }
    
    // MARK: - Template Search and Filtering
    
    func searchTemplates(query: String) -> [WorkoutTemplate] {
        guard !query.isEmpty else { return templates }
        
        return templates.filter { template in
            template.name.localizedCaseInsensitiveContains(query) ||
            template.description.localizedCaseInsensitiveContains(query) ||
            template.tags.joined().localizedCaseInsensitiveContains(query)
        }
    }
    
    func getTemplatesByTag(_ tag: String) -> [WorkoutTemplate] {
        return templates.filter { $0.tags.contains(tag) }
    }
    
    func getTemplatesByDifficulty(_ difficulty: WorkoutDifficulty) -> [WorkoutTemplate] {
        return templates.filter { $0.difficulty == difficulty }
    }
    
    // MARK: - Analytics
    
    func getTemplateUsageAnalytics() -> TemplateAnalytics {
        let totalTemplates = templates.count
        let totalUsages = templates.reduce(0) { $0 + $1.usageCount }
        let averageUsage = totalTemplates > 0 ? Double(totalUsages) / Double(totalTemplates) : 0.0
        
        let difficultyBreakdown = Dictionary(grouping: templates, by: { $0.difficulty })
            .mapValues { $0.count }
        
        let popularTags = templates
            .flatMap { $0.tags }
            .reduce(into: [:]) { counts, tag in
                counts[tag, default: 0] += 1
            }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { ($0.key, $0.value) }
        
        return TemplateAnalytics(
            totalTemplates: totalTemplates,
            totalUsages: totalUsages,
            averageUsage: averageUsage,
            difficultyBreakdown: difficultyBreakdown,
            popularTags: Array(popularTags)
        )
    }
    
    // MARK: - Template Prescription Data
    
    /// Retrieves the prescription data (sets, reps, restTime) for a specific template
    func getTemplatePrescriptionData(for templateId: UUID) async throws -> [ExerciseWithSetsReps] {
        guard let trainerId = currentTrainerId else {
            throw TemplateError.notAuthenticated
        }
        
        let document = try await db.collection("templates").document(templateId.uuidString).getDocument()
        
        guard document.exists,
              let data = document.data(),
              let exercisesData = data["exercises"] as? [[String: Any]] else {
            throw TemplateError.templateNotFound
        }
        
        // Parse exercises with prescription data
        let exercisesWithPrescription = exercisesData.compactMap { exerciseData -> ExerciseWithSetsReps? in
            guard let id = exerciseData["id"] as? String,
                  let title = exerciseData["title"] as? String,
                  let description = exerciseData["description"] as? String,
                  let categoryRaw = exerciseData["category"] as? String,
                  let category = ExerciseCategory(rawValue: categoryRaw),
                  let exerciseTypeRaw = exerciseData["exerciseType"] as? String,
                  let exerciseType = ExerciseType(rawValue: exerciseTypeRaw) else {
                return nil
            }
            
            let mediaUrl = exerciseData["mediaUrl"] as? String
            let difficultyRaw = exerciseData["difficulty"] as? String
            let difficulty = difficultyRaw != nil ? DifficultyLevel(rawValue: difficultyRaw!) : nil
            let exercise = Exercise(id: id, title: title, description: description, mediaUrl: mediaUrl, category: category, difficulty: difficulty, exerciseType: exerciseType)
            
            let sets = exerciseData["sets"] as? Int ?? 3 // Default for existing templates
            
            // Handle reps vs duration based on exercise type
            var reps: String = "10" // Default
            if exercise.exerciseType == .reps {
                if let repsString = exerciseData["reps"] as? String {
                    reps = repsString
                } else if let durationInt = exerciseData["duration"] as? Int {
                    reps = "\(durationInt)" // Convert duration to reps string for reps-based exercises
                }
            } else {
                // For duration exercises, use duration value or default
                if let durationInt = exerciseData["duration"] as? Int {
                    reps = "\(durationInt)"
                } else {
                    reps = "30" // Default duration
                }
            }
            
            var exerciseWithSetsReps = ExerciseWithSetsReps(exercise: exercise)
            exerciseWithSetsReps.sets = sets
            exerciseWithSetsReps.reps = reps
            return exerciseWithSetsReps
        }
        
        return exercisesWithPrescription
    }
    
    /// Creates a temporary template from custom workout data
    /// This enables the unified template-based architecture
    func createTemporaryTemplate(from customWorkout: CustomWorkout, trainerId: String) async throws -> WorkoutTemplate {
        print("🔄 TemplateDataService: Creating temporary template from custom workout: \(customWorkout.name)")
        
        // Create a temporary template with prescription data
        let temporaryTemplate = WorkoutTemplate(
            name: customWorkout.name,
            description: customWorkout.description,
            difficulty: customWorkout.difficulty,
            estimatedDuration: customWorkout.estimatedDuration,
            exercisesWithPrescription: customWorkout.exercisesWithPrescription ?? [],
            tags: ["Custom", "Temporary"],
            icon: "plus.circle.fill",
            coachingNotes: nil,
            usageCount: 0,
            createdDate: customWorkout.createdDate,
            updatedDate: Date(),
            isTemporary: true,
            createdByTrainerId: trainerId
        )
        
        // Save the temporary template to Firestore
        try await saveTemplate(temporaryTemplate)
        
        print("✅ TemplateDataService: Created temporary template with ID: \(temporaryTemplate.id)")
        return temporaryTemplate
    }
    
    /// Cleans up temporary templates when a program is deleted
    func cleanupTemporaryTemplatesForProgram(_ program: Program) async throws {
        print("🧹 TemplateDataService: Cleaning up temporary templates for program: \(program.name)")
        
        guard let trainerId = currentTrainerId else {
            throw TemplateError.notAuthenticated
        }
        
        // Get all template IDs used in this program
        let templateIds = Set(program.scheduledWorkouts.map { $0.workoutTemplateId })
        
        // Check which ones are temporary templates created by this trainer
        for templateId in templateIds {
            do {
                let templateDoc = try await db.collection("templates")
                    .document(templateId.uuidString)
                    .getDocument()
                
                if let data = templateDoc.data(),
                   let isTemporary = data["isTemporary"] as? Bool,
                   let createdByTrainerId = data["createdByTrainerId"] as? String,
                   isTemporary && createdByTrainerId == trainerId {
                    // Delete the temporary template
                    try await templateDoc.reference.delete()
                    print("✅ TemplateDataService: Deleted temporary template: \(templateId)")
                }
            } catch {
                print("⚠️ TemplateDataService: Failed to check/delete template \(templateId): \(error)")
            }
        }
    }
    
    /// Performs periodic cleanup of orphaned temporary templates
    /// Call this periodically to clean up temporary templates that are no longer referenced
    func cleanupOrphanedTemporaryTemplates() async throws {
        print("🧹 TemplateDataService: Starting cleanup of orphaned temporary templates")
        
        guard let trainerId = currentTrainerId else {
            throw TemplateError.notAuthenticated
        }
        
        // Get all temporary templates created by this trainer
        let temporaryTemplatesSnapshot = try await db.collection("templates")
            .whereField("isTemporary", isEqualTo: true)
            .whereField("createdByTrainerId", isEqualTo: trainerId)
            .getDocuments()
        
        // Get all template IDs currently in use by programs
        let programsSnapshot = try await db.collection("programs")
            .whereField("trainerId", isEqualTo: trainerId)
            .getDocuments()
        
        var usedTemplateIds = Set<String>()
        for programDoc in programsSnapshot.documents {
            if let scheduledWorkoutsData = programDoc.data()["scheduledWorkouts"] as? [[String: Any]] {
                for workoutData in scheduledWorkoutsData {
                    if let templateId = workoutData["workoutTemplateId"] as? String {
                        usedTemplateIds.insert(templateId)
                    }
                }
            }
        }
        
        // Delete orphaned temporary templates
        for templateDoc in temporaryTemplatesSnapshot.documents {
            if !usedTemplateIds.contains(templateDoc.documentID) {
                try await templateDoc.reference.delete()
                print("✅ TemplateDataService: Deleted orphaned temporary template: \(templateDoc.documentID)")
            }
        }
        
        print("🧹 TemplateDataService: Cleanup completed")
    }
    
    func saveTemplate(_ template: WorkoutTemplate) async throws {
        guard let trainerId = currentTrainerId else {
            print("❌ TemplateDataService: User not authenticated for save")
            throw TemplateError.notAuthenticated
        }
        
        print("✅ TemplateDataService: Saving template '\(template.name)' with ID: \(template.id.uuidString)")
        isLoading = true
        defer { isLoading = false }
        
        // Prepare exercises data with prescription information
        let exercisesData = template.exercisesWithPrescription?.map { exerciseWithSetsReps in
            let exercise = exerciseWithSetsReps.exercise
            var exerciseData: [String: Any] = [
                "id": exercise.id,
                "title": exercise.title,
                "description": exercise.description,
                "mediaUrl": exercise.mediaUrl ?? "",
                "category": exercise.category?.rawValue ?? "",
                "difficulty": exercise.difficulty?.rawValue ?? "",
                "exerciseType": exercise.exerciseType.rawValue,
                "sets": exerciseWithSetsReps.sets
            ]
            
            // Handle reps vs duration based on exercise type
            if exercise.exerciseType == .reps {
                exerciseData["reps"] = exerciseWithSetsReps.reps
            } else {
                // For duration exercises, store the duration value
                if let durationInt = Int(exerciseWithSetsReps.reps) {
                    exerciseData["duration"] = durationInt
                }
            }
            
            return exerciseData
        } ?? template.exercises.map { exercise in
            // Fallback for templates without prescription data
            return [
                "id": exercise.id,
                "title": exercise.title,
                "description": exercise.description,
                "mediaUrl": exercise.mediaUrl ?? "",
                "category": exercise.category?.rawValue ?? "",
                "difficulty": exercise.difficulty?.rawValue ?? "",
                "exerciseType": exercise.exerciseType.rawValue
            ]
        }
        
        let data: [String: Any] = [
            "name": template.name,
            "description": template.description,
            "difficulty": template.difficulty.rawValue,
            "estimatedDuration": template.estimatedDuration,
            "exercises": exercisesData,
            "tags": template.tags,
            "icon": template.icon,
            "coachingNotes": template.coachingNotes ?? "",
            "usageCount": template.usageCount,
            "createdDate": Timestamp(date: template.createdDate),
            "updatedDate": Timestamp(date: template.updatedDate),
            "isTemporary": template.isTemporary,
            "createdByTrainerId": template.createdByTrainerId ?? trainerId
        ]
        
        try await db.collection("templates")
            .document(template.id.uuidString)
            .setData(data)
        
        print("✅ TemplateDataService: Template saved successfully")
    }
}

// MARK: - Supporting Types

enum TemplateError: LocalizedError {
    case notAuthenticated
    case templateNotFound
    case invalidData
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to manage templates"
        case .templateNotFound:
            return "Template not found"
        case .invalidData:
            return "Invalid template data"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

struct TemplateAnalytics {
    let totalTemplates: Int
    let totalUsages: Int
    let averageUsage: Double
    let difficultyBreakdown: [WorkoutDifficulty: Int]
    let popularTags: [(String, Int)]
}

// MARK: - WorkoutTemplate Firestore Extensions

extension WorkoutTemplate {
    init(from document: QueryDocumentSnapshot) throws {
        let data = document.data()
        
        // Use the document ID as the template ID
        guard let id = UUID(uuidString: document.documentID),
              let name = data["name"] as? String,
              let description = data["description"] as? String,
              let difficultyRaw = data["difficulty"] as? String,
              let difficulty = WorkoutDifficulty(rawValue: difficultyRaw),
              let estimatedDuration = data["estimatedDuration"] as? Int,
              let exercisesData = data["exercises"] as? [[String: Any]],
              let tags = data["tags"] as? [String],
              let icon = data["icon"] as? String,
              let usageCount = data["usageCount"] as? Int,
              let createdTimestamp = data["createdDate"] as? Timestamp,
              let updatedTimestamp = data["updatedDate"] as? Timestamp else {
            throw TemplateError.invalidData
        }
        
        // Parse exercises with prescription data
        let exercises = exercisesData.compactMap { exerciseData -> Exercise? in
            guard let id = exerciseData["id"] as? String,
                  let title = exerciseData["title"] as? String,
                  let description = exerciseData["description"] as? String,
                  let categoryRaw = exerciseData["category"] as? String,
                  let category = ExerciseCategory(rawValue: categoryRaw),
                  let exerciseTypeRaw = exerciseData["exerciseType"] as? String,
                  let exerciseType = ExerciseType(rawValue: exerciseTypeRaw) else {
                return nil
            }
            
            let mediaUrl = exerciseData["mediaUrl"] as? String
            let difficultyRaw = exerciseData["difficulty"] as? String
            let difficulty = difficultyRaw != nil ? DifficultyLevel(rawValue: difficultyRaw!) : nil
            return Exercise(id: id, title: title, description: description, mediaUrl: mediaUrl, category: category, difficulty: difficulty, exerciseType: exerciseType)
        }
        
        // Parse prescription data if available
        let exercisesWithPrescription = exercisesData.compactMap { exerciseData -> ExerciseWithSetsReps? in
            guard let id = exerciseData["id"] as? String,
                  let title = exerciseData["title"] as? String,
                  let description = exerciseData["description"] as? String,
                  let categoryRaw = exerciseData["category"] as? String,
                  let category = ExerciseCategory(rawValue: categoryRaw),
                  let exerciseTypeRaw = exerciseData["exerciseType"] as? String,
                  let exerciseType = ExerciseType(rawValue: exerciseTypeRaw) else {
                return nil
            }
            
            let mediaUrl = exerciseData["mediaUrl"] as? String
            let difficultyRaw = exerciseData["difficulty"] as? String
            let difficulty = difficultyRaw != nil ? DifficultyLevel(rawValue: difficultyRaw!) : nil
            let exercise = Exercise(id: id, title: title, description: description, mediaUrl: mediaUrl, category: category, difficulty: difficulty, exerciseType: exerciseType)
            
            // Check if prescription data exists
            let sets = exerciseData["sets"] as? Int ?? 3
            
            // Handle reps vs duration based on exercise type
            var reps = "10" // Default
            if exerciseType == .reps {
                reps = exerciseData["reps"] as? String ?? "10"
            } else {
                if let duration = exerciseData["duration"] as? Int {
                    reps = String(duration)
                }
            }
            
            var exerciseWithSetsReps = ExerciseWithSetsReps(exercise: exercise)
            exerciseWithSetsReps.sets = sets
            exerciseWithSetsReps.reps = reps
            
            return exerciseWithSetsReps
        }
        
        let coachingNotes = data["coachingNotes"] as? String
        let isTemporary = data["isTemporary"] as? Bool ?? false
        let createdByTrainerId = data["createdByTrainerId"] as? String
        
        self.init(
            id: id,
            name: name,
            description: description,
            difficulty: difficulty,
            estimatedDuration: estimatedDuration,
            exercises: exercises,
            exercisesWithPrescription: exercisesWithPrescription.isEmpty ? nil : exercisesWithPrescription,
            tags: tags,
            icon: icon,
            coachingNotes: coachingNotes?.isEmpty == false ? coachingNotes : nil,
            usageCount: usageCount,
            createdDate: createdTimestamp.dateValue(),
            updatedDate: updatedTimestamp.dateValue(),
            isTemporary: isTemporary,
            createdByTrainerId: createdByTrainerId
        )
    }
} 