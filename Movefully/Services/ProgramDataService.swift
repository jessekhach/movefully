import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class ProgramDataService: ObservableObject {
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var programs: [Program] = []
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
    
    // MARK: - Real-time Program Loading
    
    private func setupRealtimeListener() {
        guard let trainerId = currentTrainerId else {
            print("❌ ProgramDataService: No authenticated trainer found")
            return
        }
        
        print("✅ ProgramDataService: Setting up real-time listener for trainer: \(trainerId)")
        
        listener = db.collection("programs")
            .whereField("trainerId", isEqualTo: trainerId)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    if let error = error {
                        self?.errorMessage = "Failed to load programs: \(error.localizedDescription)"
                        print("❌ ProgramDataService: Error loading programs: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("⚠️ ProgramDataService: No documents found in programs collection")
                        self?.programs = []
                        return
                    }
                    
                    print("✅ ProgramDataService: Found \(documents.count) program documents")
                    
                    let parsedPrograms = documents.compactMap { document in
                        do {
                            let program = try Program(from: document)
                            print("✅ ProgramDataService: Successfully parsed program: \(program.name)")
                            return program
                        } catch {
                            print("❌ ProgramDataService: Error parsing program: \(error)")
                            return nil
                        }
                    }
                    
                    // Sort by lastModified date
                    self?.programs = parsedPrograms.sorted { $0.lastModified > $1.lastModified }
                    
                    print("✅ ProgramDataService: Loaded \(self?.programs.count ?? 0) programs")
                }
            }
    }
    
    // MARK: - Program Creation
    
    func createProgram(_ program: Program) async throws {
        guard let trainerId = currentTrainerId else {
            print("❌ ProgramDataService: User not authenticated")
            throw ProgramError.notAuthenticated
        }
        
        print("✅ ProgramDataService: Creating program '\(program.name)' for trainer: \(trainerId)")
        isLoading = true
        defer { isLoading = false }
        
        // Create the document data
        let data: [String: Any] = [
            "name": program.name,
            "description": program.description,
            "duration": program.duration,
            "difficulty": program.difficulty.rawValue,
            "scheduledWorkouts": program.scheduledWorkouts.map { workout in
                [
                    "id": workout.id.uuidString,
                    "date": Timestamp(date: workout.date),
                    "workoutTemplateId": workout.workoutTemplate?.id.uuidString ?? "",
                    "customWorkout": workout.customWorkout != nil ? [
                        "id": workout.customWorkout!.id.uuidString,
                        "name": workout.customWorkout!.name,
                        "description": workout.customWorkout!.description,
                        "estimatedDuration": workout.customWorkout!.estimatedDuration,
                        "difficulty": workout.customWorkout!.difficulty.rawValue,
                        "exercises": workout.customWorkout!.exercises.map { exercise in
                            [
                                "id": exercise.id,
                                "title": exercise.title,
                                "description": exercise.description ?? "",
                                "category": exercise.category?.rawValue ?? "",
                                "duration": exercise.duration ?? 0,
                                "difficulty": exercise.difficulty?.rawValue ?? "",
                                "exerciseType": exercise.exerciseType.rawValue
                            ]
                        },
                        "createdDate": Timestamp(date: workout.customWorkout!.createdDate)
                    ] : NSNull(),
                    "isCompleted": workout.isCompleted,
                    "completedDate": workout.completedDate != nil ? Timestamp(date: workout.completedDate!) : NSNull()
                ]
            },
            "tags": program.tags,
            "usageCount": program.usageCount,
            "createdDate": Timestamp(date: program.createdDate),
            "lastModified": Timestamp(date: program.lastModified),
            "isDraft": program.isDraft,
            "icon": program.icon,
            "coachingNotes": program.coachingNotes ?? "",
            "trainerId": trainerId
        ]
        
        try await db.collection("programs").document(program.id.uuidString).setData(data)
        print("✅ ProgramDataService: Program saved successfully to Firestore with ID: \(program.id.uuidString)")
    }
    
    // MARK: - Program Updates
    
    func updateProgram(_ program: Program) async throws {
        guard let trainerId = currentTrainerId else {
            print("❌ ProgramDataService: User not authenticated for update")
            throw ProgramError.notAuthenticated
        }
        
        print("✅ ProgramDataService: Updating program '\(program.name)' with ID: \(program.id.uuidString)")
        isLoading = true
        defer { isLoading = false }
        
        let data: [String: Any] = [
            "name": program.name,
            "description": program.description,
            "duration": program.duration,
            "difficulty": program.difficulty.rawValue,
            "scheduledWorkouts": program.scheduledWorkouts.map { workout in
                [
                    "id": workout.id.uuidString,
                    "date": Timestamp(date: workout.date),
                    "workoutTemplateId": workout.workoutTemplate?.id.uuidString ?? "",
                    "customWorkout": workout.customWorkout != nil ? [
                        "id": workout.customWorkout!.id.uuidString,
                        "name": workout.customWorkout!.name,
                        "description": workout.customWorkout!.description,
                        "estimatedDuration": workout.customWorkout!.estimatedDuration,
                        "difficulty": workout.customWorkout!.difficulty.rawValue,
                        "exercises": workout.customWorkout!.exercises.map { exercise in
                            [
                                "id": exercise.id,
                                "title": exercise.title,
                                "description": exercise.description ?? "",
                                "category": exercise.category?.rawValue ?? "",
                                "duration": exercise.duration ?? 0,
                                "difficulty": exercise.difficulty?.rawValue ?? "",
                                "exerciseType": exercise.exerciseType.rawValue
                            ]
                        },
                        "createdDate": Timestamp(date: workout.customWorkout!.createdDate)
                    ] : NSNull(),
                    "isCompleted": workout.isCompleted,
                    "completedDate": workout.completedDate != nil ? Timestamp(date: workout.completedDate!) : NSNull()
                ]
            },
            "tags": program.tags,
            "usageCount": program.usageCount,
            "lastModified": Timestamp(date: Date()),
            "isDraft": program.isDraft,
            "icon": program.icon,
            "coachingNotes": program.coachingNotes ?? "",
            "trainerId": trainerId
        ]
        
        try await db.collection("programs").document(program.id.uuidString).updateData(data)
        print("✅ ProgramDataService: Program updated successfully in Firestore with ID: \(program.id.uuidString)")
    }
    
    // MARK: - Program Deletion
    
    func deleteProgram(_ program: Program) async throws {
        guard currentTrainerId != nil else {
            throw ProgramError.notAuthenticated
        }
        
        print("✅ ProgramDataService: Deleting program '\(program.name)' with ID: \(program.id.uuidString)")
        isLoading = true
        defer { isLoading = false }
        
        try await db.collection("programs").document(program.id.uuidString).delete()
        print("✅ ProgramDataService: Program deleted successfully from Firestore")
    }
    
    // MARK: - Template Dependency Management
    
    /// Checks if a template is used in any programs
    func isTemplateUsedInPrograms(_ templateId: UUID) async throws -> Bool {
        guard let trainerId = currentTrainerId else {
            throw ProgramError.notAuthenticated
        }
        
        let snapshot = try await db.collection("programs")
            .whereField("trainerId", isEqualTo: trainerId)
            .getDocuments()
        
        for document in snapshot.documents {
            let data = document.data()
            if let scheduledWorkouts = data["scheduledWorkouts"] as? [[String: Any]] {
                for workout in scheduledWorkouts {
                    if let workoutTemplateId = workout["workoutTemplateId"] as? String,
                       workoutTemplateId == templateId.uuidString {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    /// Gets all programs that use a specific template
    func getProgramsUsingTemplate(_ templateId: UUID) async throws -> [Program] {
        guard let trainerId = currentTrainerId else {
            throw ProgramError.notAuthenticated
        }
        
        let snapshot = try await db.collection("programs")
            .whereField("trainerId", isEqualTo: trainerId)
            .getDocuments()
        
        var programsUsingTemplate: [Program] = []
        
        for document in snapshot.documents {
            do {
                let program = try Program(from: document)
                let usesTemplate = program.scheduledWorkouts.contains { workout in
                    workout.workoutTemplate?.id == templateId
                }
                
                if usesTemplate {
                    programsUsingTemplate.append(program)
                }
            } catch {
                print("❌ ProgramDataService: Error parsing program while checking template usage: \(error)")
            }
        }
        
        return programsUsingTemplate
    }
    
    /// Updates all programs to replace a template with a new one
    func replaceTemplateInPrograms(oldTemplateId: UUID, newTemplate: WorkoutTemplate?) async throws {
        guard currentTrainerId != nil else {
            throw ProgramError.notAuthenticated
        }
        
        let programsToUpdate = try await getProgramsUsingTemplate(oldTemplateId)
        
        for program in programsToUpdate {
            var updatedProgram = program
            updatedProgram.scheduledWorkouts = program.scheduledWorkouts.map { workout in
                var updatedWorkout = workout
                if workout.workoutTemplate?.id == oldTemplateId {
                    updatedWorkout.workoutTemplate = newTemplate
                }
                return updatedWorkout
            }
            
            try await updateProgram(updatedProgram)
        }
    }
    
    // MARK: - Usage Count Management
    
    func incrementTemplateUsage(_ templateId: UUID) async throws {
        // This will be handled by the TemplateDataService
        // We just need to call it from the TemplateDataService
    }
    
    // MARK: - Utility Functions
    
    func getProgramsByDifficulty(_ difficulty: WorkoutDifficulty) -> [Program] {
        return programs.filter { $0.difficulty == difficulty }
    }
    
    func getPopularPrograms() -> [Program] {
        return programs.sorted { $0.usageCount > $1.usageCount }
    }
    
    func getDraftPrograms() -> [Program] {
        return programs.filter { $0.isDraft }
    }
    
    func getActivePrograms() -> [Program] {
        return programs.filter { !$0.isDraft }
    }
    
    func searchPrograms(query: String) -> [Program] {
        guard !query.isEmpty else { return programs }
        
        return programs.filter { program in
            program.name.localizedCaseInsensitiveContains(query) ||
            program.description.localizedCaseInsensitiveContains(query) ||
            program.tags.joined().localizedCaseInsensitiveContains(query)
        }
    }
}

// MARK: - Program Error Types

enum ProgramError: LocalizedError {
    case notAuthenticated
    case invalidData
    case unauthorized
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .invalidData:
            return "Invalid program data"
        case .unauthorized:
            return "Unauthorized access"
        case .notFound:
            return "Program not found"
        }
    }
}

// MARK: - Program Firebase Extensions

extension Program {
    init(from document: QueryDocumentSnapshot) throws {
        let data = document.data()
        
        // Use the document ID as the program ID
        guard let id = UUID(uuidString: document.documentID),
              let name = data["name"] as? String,
              let description = data["description"] as? String,
              let duration = data["duration"] as? Int,
              let difficultyRaw = data["difficulty"] as? String,
              let difficulty = WorkoutDifficulty(rawValue: difficultyRaw),
              let scheduledWorkoutsData = data["scheduledWorkouts"] as? [[String: Any]],
              let tags = data["tags"] as? [String],
              let usageCount = data["usageCount"] as? Int,
              let createdTimestamp = data["createdDate"] as? Timestamp,
              let lastModifiedTimestamp = data["lastModified"] as? Timestamp,
              let isDraft = data["isDraft"] as? Bool,
              let icon = data["icon"] as? String else {
            throw ProgramError.invalidData
        }
        
        // Parse scheduled workouts (this is simplified for now)
        let scheduledWorkouts: [ScheduledWorkout] = scheduledWorkoutsData.compactMap { workoutData in
            guard let idString = workoutData["id"] as? String,
                  let workoutId = UUID(uuidString: idString),
                  let dateTimestamp = workoutData["date"] as? Timestamp,
                  let isCompleted = workoutData["isCompleted"] as? Bool else {
                return nil
            }
            
            let date = dateTimestamp.dateValue()
            let completedDate = (workoutData["completedDate"] as? Timestamp)?.dateValue()
            
            // For now, we'll create a simple scheduled workout without template details
            // In a full implementation, you'd need to resolve template references
            return ScheduledWorkout(
                id: workoutId,
                date: date,
                workoutTemplate: nil, // This would need to be resolved from the templateId
                isCompleted: isCompleted,
                completedDate: completedDate
            )
        }
        
        let coachingNotes = data["coachingNotes"] as? String
        
        self.init(
            id: id,
            name: name,
            description: description,
            duration: duration,
            difficulty: difficulty,
            scheduledWorkouts: scheduledWorkouts,
            tags: tags,
            usageCount: usageCount,
            createdDate: createdTimestamp.dateValue(),
            lastModified: lastModifiedTimestamp.dateValue(),
            isDraft: isDraft,
            icon: icon,
            coachingNotes: coachingNotes?.isEmpty == false ? coachingNotes : nil
        )
    }
    

} 