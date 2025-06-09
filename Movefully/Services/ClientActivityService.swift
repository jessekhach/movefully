import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Activity Summary Model
struct ActivitySummary {
    let clientId: String
    let lastActivityDate: Date?
    let lastLoginDate: Date?
    let lastWorkoutDate: Date?
    let lastMessageDate: Date?
    let daysSinceLastActivity: Int
    let needsAttention: Bool
    let attentionReason: String?
}

// MARK: - Client Activity Service
@MainActor
class ClientActivityService: ObservableObject {
    private let db = Firestore.firestore()
    
    // MARK: - Activity Recording
    
    /// Records when a client logs into the app
    func recordClientLogin(_ clientId: String) async throws {
        let now = Date()
        
        try await db.collection("clients")
            .document(clientId)
            .updateData([
                "lastActivityDate": Timestamp(date: now),
                "lastLoginDate": Timestamp(date: now),
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }
    
    /// Records when a client completes a workout
    func recordWorkoutCompletion(_ clientId: String, workoutId: String) async throws {
        let now = Date()
        
        // Update client's last activity
        try await db.collection("clients")
            .document(clientId)
            .updateData([
                "lastActivityDate": Timestamp(date: now),
                "lastWorkoutDate": Timestamp(date: now),
                "totalWorkoutsCompleted": FieldValue.increment(Int64(1)),
                "updatedAt": FieldValue.serverTimestamp()
            ])
        
        // Record specific workout completion
        try await db.collection("clients")
            .document(clientId)
            .collection("workoutHistory")
            .document(workoutId)
            .setData([
                "workoutId": workoutId,
                "completedAt": Timestamp(date: now),
                "status": "completed"
            ], merge: true)
    }
    
    /// Records when a client sends or receives a message
    func recordLastMessageTime(_ clientId: String) async throws {
        let now = Date()
        
        try await db.collection("clients")
            .document(clientId)
            .updateData([
                "lastActivityDate": Timestamp(date: now),
                "lastMessageDate": Timestamp(date: now),
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }
    
    // MARK: - Activity Analysis
    
    /// Gets the last activity date for a client
    func getLastActivityDate(_ clientId: String) async throws -> Date? {
        let document = try await db.collection("clients")
            .document(clientId)
            .getDocument()
        
        guard let data = document.data(),
              let timestamp = data["lastActivityDate"] as? Timestamp else {
            return nil
        }
        
        return timestamp.dateValue()
    }
    
    /// Determines if a client needs attention based on activity
    func calculateAttentionNeeded(_ clientId: String) async throws -> Bool {
        let summary = try await getActivitySummary(clientId)
        
        // Client needs attention if:
        // - No activity in 7+ days
        // - No workout in 10+ days (if they have an active plan)
        // - No login in 14+ days
        
        if summary.daysSinceLastActivity >= 7 {
            return true
        }
        
        if let lastWorkout = summary.lastWorkoutDate {
            let daysSinceWorkout = Calendar.current.dateComponents([.day], from: lastWorkout, to: Date()).day ?? 0
            if daysSinceWorkout >= 10 {
                return true
            }
        }
        
        if let lastLogin = summary.lastLoginDate {
            let daysSinceLogin = Calendar.current.dateComponents([.day], from: lastLogin, to: Date()).day ?? 0
            if daysSinceLogin >= 14 {
                return true
            }
        }
        
        return false
    }
    
    /// Gets a comprehensive activity summary for a client
    func getActivitySummary(_ clientId: String) async throws -> ActivitySummary {
        let document = try await db.collection("clients")
            .document(clientId)
            .getDocument()
        
        guard let data = document.data() else {
            return ActivitySummary(
                clientId: clientId,
                lastActivityDate: nil,
                lastLoginDate: nil,
                lastWorkoutDate: nil,
                lastMessageDate: nil,
                daysSinceLastActivity: Int.max,
                needsAttention: true,
                attentionReason: "No data available"
            )
        }
        
        let lastActivityDate = (data["lastActivityDate"] as? Timestamp)?.dateValue()
        let lastLoginDate = (data["lastLoginDate"] as? Timestamp)?.dateValue()
        let lastWorkoutDate = (data["lastWorkoutDate"] as? Timestamp)?.dateValue()
        let lastMessageDate = (data["lastMessageDate"] as? Timestamp)?.dateValue()
        
        let daysSinceLastActivity: Int
        if let lastActivity = lastActivityDate {
            daysSinceLastActivity = Calendar.current.dateComponents([.day], from: lastActivity, to: Date()).day ?? 0
        } else {
            daysSinceLastActivity = Int.max
        }
        
        let needsAttention = try await calculateAttentionNeeded(clientId)
        let attentionReason = needsAttention ? determineAttentionReason(
            daysSinceLastActivity: daysSinceLastActivity,
            lastWorkoutDate: lastWorkoutDate,
            lastLoginDate: lastLoginDate
        ) : nil
        
        return ActivitySummary(
            clientId: clientId,
            lastActivityDate: lastActivityDate,
            lastLoginDate: lastLoginDate,
            lastWorkoutDate: lastWorkoutDate,
            lastMessageDate: lastMessageDate,
            daysSinceLastActivity: daysSinceLastActivity,
            needsAttention: needsAttention,
            attentionReason: attentionReason
        )
    }
    
    /// Updates activity status for all clients of a trainer
    func updateAllClientActivityStatuses(_ trainerId: String) async throws {
        let snapshot = try await db.collection("trainers")
            .document(trainerId)
            .collection("clients")
            .getDocuments()
        
        for document in snapshot.documents {
            let clientId = document.documentID
            do {
                let needsAttention = try await calculateAttentionNeeded(clientId)
                
                // Update the client's needs attention status
                try await db.collection("trainers")
                    .document(trainerId)
                    .collection("clients")
                    .document(clientId)
                    .updateData([
                        "needsAttention": needsAttention,
                        "updatedAt": FieldValue.serverTimestamp()
                    ])
            } catch {
                print("Error updating attention status for client \(clientId): \(error)")
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func determineAttentionReason(
        daysSinceLastActivity: Int,
        lastWorkoutDate: Date?,
        lastLoginDate: Date?
    ) -> String {
        if daysSinceLastActivity >= 14 {
            return "No activity in 2+ weeks"
        } else if daysSinceLastActivity >= 7 {
            return "No activity in 1+ week"
        }
        
        if let lastWorkout = lastWorkoutDate {
            let daysSinceWorkout = Calendar.current.dateComponents([.day], from: lastWorkout, to: Date()).day ?? 0
            if daysSinceWorkout >= 10 {
                return "No workouts in 10+ days"
            }
        }
        
        if let lastLogin = lastLoginDate {
            let daysSinceLogin = Calendar.current.dateComponents([.day], from: lastLogin, to: Date()).day ?? 0
            if daysSinceLogin >= 14 {
                return "No login in 2+ weeks"
            }
        }
        
        return "Needs check-in"
    }
} 