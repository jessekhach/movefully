import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class ClientDeletionService: ObservableObject {
    private let db = Firestore.firestore()
    
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
    
    /// Checks for and deletes clients who have been trainer_removed for more than 30 days without acknowledging
    func performAutoCleanup() async throws {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let query = db.collection("clients")
            .whereField("status", isEqualTo: ClientStatus.trainer_removed.rawValue)
            .whereField("trainerRemovedAt", isLessThan: Timestamp(date: thirtyDaysAgo))
        
        let snapshot = try await query.getDocuments()
        
        for document in snapshot.documents {
            let clientId = document.documentID
            print("🗑️ Auto-deleting client \(clientId) after 30 days of trainer removal")
            
            do {
                // Perform complete account deletion
                try await deleteAllClientData(clientId: clientId, trainerId: nil)
                
                // Delete Firebase Auth account
                // Note: This would require admin SDK in a cloud function for production
                print("⚠️ Firebase Auth deletion for \(clientId) should be handled by cloud function")
                
            } catch {
                print("❌ Error auto-deleting client \(clientId): \(error)")
            }
        }
    }
    
    // MARK: - Client Self-Deletion
    
    /// Deletes the current client's account and all associated data
    func deleteClientAccount() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw ClientDeletionError.notAuthenticated
        }
        
        // Prevent concurrent deletion operations
        guard !isDeleting else {
            throw ClientDeletionError.deletionFailed("Deletion already in progress")
        }
        
        let clientId = currentUser.uid
        isDeleting = true
        deletionProgress = "Starting account deletion..."
        
        do {
            // Step 1: Get client data to find trainer relationship
            let clientData = try await getClientData(clientId: clientId)
            let trainerId = clientData["trainerId"] as? String
            
            // Step 2: Delete all client data from Firestore
            try await deleteAllClientData(clientId: clientId, trainerId: trainerId)
            
            // Step 3: Delete Firebase Authentication account
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
    
    // MARK: - Trainer-Initiated Client Deletion
    
    /// Removes a client from trainer's perspective (sets status to trainer_removed)
    func deleteClientFromTrainer(clientId: String, trainerId: String) async throws {
        // Prevent concurrent deletion operations
        guard !isDeleting else {
            throw ClientDeletionError.deletionFailed("Deletion already in progress")
        }
        
        isDeleting = true
        deletionProgress = "Starting client removal..."
        
        do {
            // Step 1: Set client status to trainer_removed and add removal timestamp
            deletionProgress = "Updating client status..."
            let removalData: [String: Any] = [
                "status": ClientStatus.trainer_removed.rawValue,
                "trainerRemovedAt": FieldValue.serverTimestamp(),
                "removedByTrainerId": trainerId,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            // Update in main clients collection
            try await db.collection("clients")
                .document(clientId)
                .updateData(removalData)
            
            // Step 2: Remove client from trainer's subcollection
            deletionProgress = "Removing from trainer's client list..."
            try await db.collection("trainers")
                .document(trainerId)
                .collection("clients")
                .document(clientId)
                .delete()
            
            // Step 3: Remove trainer-specific data but preserve client's core profile
            deletionProgress = "Removing trainer-specific data..."
            try await removeTrainerSpecificData(clientId: clientId, trainerId: trainerId)
            
            // Step 4: Clear caches to prevent stale data
            deletionProgress = "Clearing caches..."
            await invalidateCaches()
            
            deletionProgress = "Client successfully removed"
            
            // Reset deletion state
            await MainActor.run {
                isDeleting = false
            }
            
        } catch {
            await MainActor.run {
                isDeleting = false
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Trainer-Specific Data Removal
    
    private func removeTrainerSpecificData(clientId: String, trainerId: String) async throws {
        // Use batch operations for better performance and atomicity
        let batch = db.batch()
        
        // Remove workout completions
        let workoutCompletions = try await db.collection("workoutCompletions")
            .whereField("clientId", isEqualTo: clientId)
            .limit(to: 500) // Limit to prevent timeout
            .getDocuments()
        
        for document in workoutCompletions.documents {
            batch.deleteDocument(document.reference)
        }
        
        // Remove progress entries
        let progressEntries = try await db.collection("progressEntries")
            .whereField("clientId", isEqualTo: clientId)
            .limit(to: 500)
            .getDocuments()
        
        for document in progressEntries.documents {
            batch.deleteDocument(document.reference)
        }
        
        // Remove milestones
        let milestones = try await db.collection("milestones")
            .whereField("clientId", isEqualTo: clientId)
            .limit(to: 500)
            .getDocuments()
        
        for document in milestones.documents {
            batch.deleteDocument(document.reference)
        }
        
        // Remove conversations between trainer and client
        let conversations = try await db.collection("conversations")
            .whereField("participants", arrayContains: clientId)
            .limit(to: 100)
            .getDocuments()
        
        for document in conversations.documents {
            let data = document.data()
            if let participants = data["participants"] as? [String],
               participants.contains(trainerId) {
                batch.deleteDocument(document.reference)
            }
        }
        
        // Remove trainer notes about this client
        let notes = try await db.collection("trainers")
            .document(trainerId)
            .collection("clientNotes")
            .whereField("clientId", isEqualTo: clientId)
            .limit(to: 100)
            .getDocuments()
        
        for document in notes.documents {
            batch.deleteDocument(document.reference)
        }
        
        // Commit batch deletions
        try await batch.commit()
        
        // Remove plan assignments (separate operation as it's an update, not delete)
        // NOTE: We keep trainerId so client data can still be loaded to show trainer_removed status
        let planUpdateData: [String: Any] = [
            "currentPlanId": FieldValue.delete(),
            "currentPlanStartDate": FieldValue.delete(),
            "currentPlanEndDate": FieldValue.delete(),
            "nextPlanId": FieldValue.delete(),
            "nextPlanStartDate": FieldValue.delete(),
            "nextPlanEndDate": FieldValue.delete()
        ]
        
        try await db.collection("clients")
            .document(clientId)
            .updateData(planUpdateData)
    }
    
    // MARK: - Complete Data Deletion
    
    private func deleteAllClientData(clientId: String, trainerId: String?) async throws {
        
        // Step 1: Delete from trainer's client subcollection (if trainer exists)
        if let trainerId = trainerId {
            deletionProgress = "Removing from trainer's client list..."
            try await db.collection("trainers")
                .document(trainerId)
                .collection("clients")
                .document(clientId)
                .delete()
        }
        
        // Step 2: Delete client's workout completions
        deletionProgress = "Deleting workout history..."
        try await deleteCollection(path: "clients/\(clientId)/workoutCompletions")
        
        // Step 3: Delete client's progress entries
        deletionProgress = "Deleting progress data..."
        try await deleteCollection(path: "clients/\(clientId)/progress")
        
        // Step 4: Delete client's exercise progression data
        deletionProgress = "Deleting exercise progression..."
        try await deleteCollection(path: "clients/\(clientId)/exerciseProgression")
        
        // Step 5: Delete client notes (both trainer notes and client notes)
        deletionProgress = "Deleting notes and messages..."
        try await deleteClientNotes(clientId: clientId)
        
        // Step 6: Delete client-trainer conversations
        try await deleteClientConversations(clientId: clientId)
        
        // Step 7: Delete client's plan assignments
        deletionProgress = "Removing plan assignments..."
        try await deleteClientPlanAssignments(clientId: clientId)
        
        // Step 8: Delete client's milestones
        deletionProgress = "Deleting milestones..."
        try await deleteClientMilestones(clientId: clientId)
        
        // Step 9: Delete pending invitations
        deletionProgress = "Cleaning up invitations..."
        try await deletePendingInvitations(clientEmail: nil, clientId: clientId)
        
        // Step 10: Delete main client document
        deletionProgress = "Finalizing deletion..."
        try await db.collection("clients").document(clientId).delete()
        
        // Step 11: Remove from users collection
        try await db.collection("users").document(clientId).delete()
    }
    
    // MARK: - Helper Methods
    
    private func getClientData(clientId: String) async throws -> [String: Any] {
        let document = try await db.collection("clients").document(clientId).getDocument()
        guard let data = document.data() else {
            throw ClientDeletionError.clientNotFound
        }
        return data
    }
    
    private func deleteCollection(path: String) async throws {
        let collectionRef = db.collection(path.replacingOccurrences(of: "/", with: "/"))
        let documents = try await collectionRef.getDocuments()
        
        // Delete in batches to avoid timeout
        let batch = db.batch()
        var operationCount = 0
        
        for document in documents.documents {
            batch.deleteDocument(document.reference)
            operationCount += 1
            
            // Commit batch every 500 operations
            if operationCount >= 500 {
                try await batch.commit()
                operationCount = 0
            }
        }
        
        // Commit remaining operations
        if operationCount > 0 {
            try await batch.commit()
        }
    }
    
    private func deleteClientNotes(clientId: String) async throws {
        let notesQuery = db.collection("clientNotes")
            .whereField("clientId", isEqualTo: clientId)
        
        let documents = try await notesQuery.getDocuments()
        
        for document in documents.documents {
            try await document.reference.delete()
        }
    }
    
    private func deleteClientConversations(clientId: String) async throws {
        // Delete conversations where client is participant
        let conversationsQuery = db.collection("conversations")
            .whereField("clientId", isEqualTo: clientId)
        
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
    
    private func deleteClientPlanAssignments(clientId: String) async throws {
        // Find and update any programs that have this client assigned
        let programsQuery = db.collection("programs")
            .whereField("assignedClients", arrayContains: clientId)
        
        let programs = try await programsQuery.getDocuments()
        
        for program in programs.documents {
            try await program.reference.updateData([
                "assignedClients": FieldValue.arrayRemove([clientId])
            ])
        }
    }
    
    private func deleteClientMilestones(clientId: String) async throws {
        let milestonesQuery = db.collection("milestones")
            .whereField("clientId", isEqualTo: clientId)
        
        let milestones = try await milestonesQuery.getDocuments()
        
        for milestone in milestones.documents {
            try await milestone.reference.delete()
        }
    }
    
    private func deletePendingInvitations(clientEmail: String?, clientId: String) async throws {
        var queries: [Query] = []
        
        // Query by client ID if available
        queries.append(db.collection("invitations").whereField("clientId", isEqualTo: clientId))
        
        // Query by email if available
        if let email = clientEmail {
            queries.append(db.collection("invitations").whereField("clientEmail", isEqualTo: email))
        }
        
        for query in queries {
            let invitations = try await query.getDocuments()
            for invitation in invitations.documents {
                try await invitation.reference.delete()
            }
        }
    }
    
    // MARK: - Cache Invalidation
    
    /// Invalidates all relevant caches after client deletion
    private func invalidateCaches() async {
        await MainActor.run {
            // Clear progress data cache
            ProgressDataCacheService.shared.clearCache()
            
            // Clear workout data cache
            WorkoutDataCacheService.shared.clearCache()
            
            print("✅ ClientDeletionService: All caches cleared after deletion")
        }
        
        // Add a small delay to ensure cache clearing completes before continuing
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
}

// MARK: - Error Types

enum ClientDeletionError: LocalizedError {
    case notAuthenticated
    case clientNotFound
    case deletionFailed(String)
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to delete your account"
        case .clientNotFound:
            return "Client account not found"
        case .deletionFailed(let message):
            return "Failed to delete account: \(message)"
        case .permissionDenied:
            return "You don't have permission to perform this action"
        }
    }
} 