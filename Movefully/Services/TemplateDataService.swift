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
    
    func createTemplate(_ template: WorkoutTemplate) async throws {
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
            "exercises": template.exercises.map { exercise in
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
    
    func updateTemplate(_ template: WorkoutTemplate) async throws {
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
            "exercises": template.exercises.map { exercise in
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
        
        // Parse exercises
        let exercises = exercisesData.compactMap { exerciseData -> Exercise? in
            guard let exerciseId = exerciseData["id"] as? String,
                  let title = exerciseData["title"] as? String,
                  let exerciseTypeRaw = exerciseData["exerciseType"] as? String,
                  let exerciseType = ExerciseType(rawValue: exerciseTypeRaw) else {
                return nil
            }
            
            let description = exerciseData["description"] as? String
            let categoryRaw = exerciseData["category"] as? String
            let category = categoryRaw != nil ? ExerciseCategory(rawValue: categoryRaw!) : nil
            let duration = exerciseData["duration"] as? Int
            let difficultyRaw = exerciseData["difficulty"] as? String
            let difficulty = difficultyRaw != nil ? DifficultyLevel(rawValue: difficultyRaw!) : nil
            
            return Exercise(
                id: exerciseId,
                title: title,
                description: description,
                mediaUrl: nil,
                category: category,
                duration: duration,
                difficulty: difficulty,
                createdByTrainerId: nil,
                exerciseType: exerciseType
            )
        }
        
        // Use the specialized initializer with existing ID
        self.init(
            id: id,
            name: name,
            description: description,
            difficulty: difficulty,
            estimatedDuration: estimatedDuration,
            exercises: exercises,
            tags: tags,
            icon: icon,
            coachingNotes: data["coachingNotes"] as? String,
            usageCount: usageCount,
            createdDate: createdTimestamp.dateValue(),
            updatedDate: updatedTimestamp.dateValue()
        )
    }
} 