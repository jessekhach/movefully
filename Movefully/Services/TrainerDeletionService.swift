import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@MainActor
class TrainerDeletionService: ObservableObject {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    @Published var isDeleting = false
    @Published var deletionProgress = ""
    @Published var errorMessage: String?
    
    // MARK: - Cleanup Methods
    
    /// Cleans up the service state after deletion operations
    func cleanup() {
        isDeleting = false
        deletionProgress = ""
        errorMessage = nil
    }
    
    // MARK: - Trainer Self-Deletion
    
    /// Deletes the current trainer's account and all associated data
    func deleteTrainerAccount() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw TrainerDeletionError.notAuthenticated
        }
        
        // Prevent concurrent deletion operations
        guard !isDeleting else {
            throw TrainerDeletionError.deletionFailed("Deletion already in progress")
        }
        
        let trainerId = currentUser.uid
        isDeleting = true
        deletionProgress = "Starting account deletion..."
        
        do {
            // Step 1: Get trainer data to understand relationships
            let trainerData = try await getTrainerData(trainerId: trainerId)
            
            // Step 2: Delete trainer's profile picture from Firebase Storage
            try await deleteTrainerProfilePicture(trainerId: trainerId)
            
            // Step 3: Delete all trainer data from Firestore
            try await deleteAllTrainerData(trainerId: trainerId)
            
            // Step 4: Delete Firebase Authentication account
            deletionProgress = "Removing account authentication..."
            try await currentUser.delete()
            
            deletionProgress = "Account successfully deleted"
            
            // Invalidate caches after successful deletion
            await invalidateCaches()
            
        } catch {
            isDeleting = false
            throw error
        }
    }
    
    // MARK: - Profile Picture Deletion
    
    private func deleteTrainerProfilePicture(trainerId: String) async throws {
        deletionProgress = "Deleting profile picture..."
        
        let storageRef = storage.reference()
        
        // Try to delete from both possible paths
        let possiblePaths = [
            "profile_images/trainers/\(trainerId).jpg",
            "profile_images/\(trainerId).jpg"
        ]
        
        for path in possiblePaths {
            let profileImageRef = storageRef.child(path)
            do {
                try await profileImageRef.delete()
                print("✅ TrainerDeletionService: Profile picture deleted from storage at path: \(path)")
            } catch {
                print("⚠️ TrainerDeletionService: Profile picture may not exist at path \(path): \(error)")
            }
        }
    }
    
    // MARK: - Complete Data Deletion
    
    private func deleteAllTrainerData(trainerId: String) async throws {
        
        // Step 1: Handle all clients associated with this trainer
        deletionProgress = "Managing client relationships..."
        try await handleTrainerClientRelationships(trainerId: trainerId)
        
        // Step 2: Delete trainer's workout programs and templates
        deletionProgress = "Deleting workout programs..."
        try await deleteTrainerPrograms(trainerId: trainerId)
        
        // Step 3: Delete trainer's exercise library
        deletionProgress = "Deleting exercise library..."
        try await deleteTrainerExercises(trainerId: trainerId)
        
        // Step 4: Delete trainer's conversations
        deletionProgress = "Deleting conversations..."
        try await deleteTrainerConversations(trainerId: trainerId)
        
        // Step 5: Delete trainer's client notes
        deletionProgress = "Deleting client notes..."
        try await deleteTrainerClientNotes(trainerId: trainerId)
        
        // Step 6: Delete trainer's progress tracking data
        deletionProgress = "Deleting progress data..."
        try await deleteTrainerProgressData(trainerId: trainerId)
        
        // Step 7: Delete main trainer document
        deletionProgress = "Finalizing deletion..."
        try await db.collection("trainers").document(trainerId).delete()
        
        // Step 8: Remove from users collection
        try await db.collection("users").document(trainerId).delete()
    }
    
    // MARK: - Client Relationship Management
    
    private func handleTrainerClientRelationships(trainerId: String) async throws {
        // Get all clients associated with this trainer
        let clientsQuery = db.collection("clients")
            .whereField("trainerId", isEqualTo: trainerId)
        
        let clients = try await clientsQuery.getDocuments()
        
        for clientDoc in clients.documents {
            let clientId = clientDoc.documentID
            
            // Update client status to indicate trainer is no longer available
            let updateData: [String: Any] = [
                "status": "trainer_unavailable",
                "trainerId": FieldValue.delete(),
                "trainerUnavailableAt": FieldValue.serverTimestamp(),
                "currentPlanId": FieldValue.delete(),
                "currentPlanStartDate": FieldValue.delete(),
                "currentPlanEndDate": FieldValue.delete(),
                "nextPlanId": FieldValue.delete(),
                "nextPlanStartDate": FieldValue.delete(),
                "nextPlanEndDate": FieldValue.delete(),
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            try await clientDoc.reference.updateData(updateData)
            print("✅ TrainerDeletionService: Updated client \(clientId) status to trainer_unavailable")
        }
    }
    
    // MARK: - Program and Template Deletion
    
    private func deleteTrainerPrograms(trainerId: String) async throws {
        // Delete workout programs created by this trainer
        let programsQuery = db.collection("programs")
            .whereField("trainerId", isEqualTo: trainerId)
        
        let programs = try await programsQuery.getDocuments()
        
        for programDoc in programs.documents {
            // Delete program's workouts subcollection
            let workoutsRef = programDoc.reference.collection("workouts")
            let workouts = try await workoutsRef.getDocuments()
            
            for workout in workouts.documents {
                try await workout.reference.delete()
            }
            
            // Delete the program itself
            try await programDoc.reference.delete()
        }
        
        // Delete workout templates
        let templatesQuery = db.collection("workoutTemplates")
            .whereField("trainerId", isEqualTo: trainerId)
        
        let templates = try await templatesQuery.getDocuments()
        
        for template in templates.documents {
            try await template.reference.delete()
        }
    }
    
    // MARK: - Exercise Library Deletion
    
    private func deleteTrainerExercises(trainerId: String) async throws {
        let exercisesQuery = db.collection("exercises")
            .whereField("trainerId", isEqualTo: trainerId)
        
        let exercises = try await exercisesQuery.getDocuments()
        
        for exercise in exercises.documents {
            try await exercise.reference.delete()
        }
    }
    
    // MARK: - Conversation Deletion
    
    private func deleteTrainerConversations(trainerId: String) async throws {
        // Delete conversations where trainer is participant
        let conversationsQuery = db.collection("conversations")
            .whereField("trainerId", isEqualTo: trainerId)
        
        let conversations = try await conversationsQuery.getDocuments()
        
        for conversationDoc in conversations.documents {
            // Delete all messages in conversation
            let messagesRef = conversationDoc.reference.collection("messages")
            let messages = try await messagesRef.getDocuments()
            
            for message in messages.documents {
                try await message.reference.delete()
            }
            
            // Delete conversation document
            try await conversationDoc.reference.delete()
        }
    }
    
    // MARK: - Client Notes Deletion
    
    private func deleteTrainerClientNotes(trainerId: String) async throws {
        let notesQuery = db.collection("clientNotes")
            .whereField("trainerId", isEqualTo: trainerId)
        
        let notes = try await notesQuery.getDocuments()
        
        for note in notes.documents {
            try await note.reference.delete()
        }
        
        // Also delete from trainer's subcollection
        let trainerNotesRef = db.collection("trainers")
            .document(trainerId)
            .collection("clientNotes")
        
        let trainerNotes = try await trainerNotesRef.getDocuments()
        
        for note in trainerNotes.documents {
            try await note.reference.delete()
        }
    }
    
    // MARK: - Progress Data Deletion
    
    private func deleteTrainerProgressData(trainerId: String) async throws {
        // Delete progress entries created by this trainer
        let progressQuery = db.collection("progressEntries")
            .whereField("trainerId", isEqualTo: trainerId)
        
        let progressEntries = try await progressQuery.getDocuments()
        
        for entry in progressEntries.documents {
            try await entry.reference.delete()
        }
        
        // Delete milestones created by this trainer
        let milestonesQuery = db.collection("milestones")
            .whereField("trainerId", isEqualTo: trainerId)
        
        let milestones = try await milestonesQuery.getDocuments()
        
        for milestone in milestones.documents {
            try await milestone.reference.delete()
        }
    }
    
    // MARK: - Helper Methods
    
    private func getTrainerData(trainerId: String) async throws -> [String: Any] {
        let document = try await db.collection("trainers").document(trainerId).getDocument()
        guard let data = document.data() else {
            throw TrainerDeletionError.trainerNotFound
        }
        return data
    }
    
    // MARK: - Cache Invalidation
    
    /// Invalidates all relevant caches after trainer deletion
    private func invalidateCaches() async {
        await MainActor.run {
            // Clear trainer data cache
            TrainerDataService.shared.clearCache()
            
            // Clear any other relevant caches
            print("✅ TrainerDeletionService: Caches invalidated")
        }
    }
}

// MARK: - Error Types

enum TrainerDeletionError: LocalizedError {
    case notAuthenticated
    case trainerNotFound
    case deletionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .trainerNotFound:
            return "Trainer profile not found"
        case .deletionFailed(let message):
            return "Deletion failed: \(message)"
        }
    }
} 