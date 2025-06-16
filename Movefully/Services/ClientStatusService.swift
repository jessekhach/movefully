import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Status Change Reason
enum StatusChangeReason: String, CaseIterable, Codable {
    case userRequested = "User Requested"
    case inactivity = "Inactivity"
    case completed = "Program Completed"
    case healthIssue = "Health Issue"
    case scheduling = "Scheduling Conflict"
    case other = "Other"
}

// MARK: - Client Status Service
@MainActor
class ClientStatusService: ObservableObject {
    private let db = Firestore.firestore()
    private let activityService = ClientActivityService()
    
    // MARK: - Status Management
    
    /// Updates a client's status with optional reason
    func updateClientStatus(_ clientId: String, trainerId: String, newStatus: ClientStatus, reason: StatusChangeReason? = nil, notes: String? = nil) async throws {
        var updateData: [String: Any] = [
            "status": newStatus.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if let reason = reason {
            updateData["lastStatusChangeReason"] = reason.rawValue
        }
        
        if let notes = notes {
            updateData["statusChangeNotes"] = notes
        }
        
        // Update in trainer's client collection
        try await db.collection("trainers")
            .document(trainerId)
            .collection("clients")
            .document(clientId)
            .updateData(updateData)
        
        // Update in main clients collection
        try await db.collection("clients")
            .document(clientId)
            .updateData(updateData)
        
        // Log the status change
        try await logStatusChange(
            clientId: clientId,
            trainerId: trainerId,
            oldStatus: nil, // We could fetch this if needed
            newStatus: newStatus,
            reason: reason,
            notes: notes
        )
    }
    
    /// Automatically checks and updates client statuses based on activity
    func performAutomaticStatusUpdates(_ trainerId: String) async throws {
        let snapshot = try await db.collection("trainers")
            .document(trainerId)
            .collection("clients")
            .getDocuments()
        
        for document in snapshot.documents {
            let clientId = document.documentID
            let data = document.data()
            
            guard let currentStatusString = data["status"] as? String,
                  let currentStatus = ClientStatus(rawValue: currentStatusString) else {
                continue
            }
            
            do {
                let summary = try await activityService.getActivitySummary(clientId)
                let shouldNeedAttention = summary.needsAttention
                
                // Update needs attention flag if it's changed
                if shouldNeedAttention && currentStatus != .needsAttention {
                    try await updateClientStatus(
                        clientId,
                        trainerId: trainerId,
                        newStatus: .needsAttention,
                        reason: .inactivity,
                        notes: summary.attentionReason
                    )
                } else if !shouldNeedAttention && currentStatus == .needsAttention {
                    // Only auto-reactivate if they were previously active
                                         if let lastActivity = summary.lastLoginDate,
                       Calendar.current.dateComponents([.day], from: lastActivity, to: Date()).day ?? 0 < 3 {
                        try await updateClientStatus(
                            clientId,
                            trainerId: trainerId,
                            newStatus: .active,
                            reason: .userRequested,
                            notes: "Recent activity detected"
                        )
                    }
                }
            } catch {
                print("Error updating status for client \(clientId): \(error)")
            }
        }
    }
    
    /// Activates a client (moves from pending/paused to active)
    func activateClient(_ clientId: String, trainerId: String) async throws {
        try await updateClientStatus(
            clientId,
            trainerId: trainerId,
            newStatus: .active,
            reason: .userRequested,
            notes: "Activated by trainer"
        )
        
        // Record activation activity
        try await activityService.recordClientLogin(clientId)
    }
    
    /// Pauses a client with reason
    func pauseClient(_ clientId: String, trainerId: String, reason: StatusChangeReason, notes: String? = nil) async throws {
        try await updateClientStatus(
            clientId,
            trainerId: trainerId,
            newStatus: .paused,
            reason: reason,
            notes: notes
        )
    }
    
    /// Reactivates a paused client
    func reactivateClient(_ clientId: String, trainerId: String) async throws {
        try await updateClientStatus(
            clientId,
            trainerId: trainerId,
            newStatus: .active,
            reason: .userRequested,
            notes: "Reactivated by trainer"
        )
    }
    
    /// Marks a new client as having completed onboarding
    func completeClientOnboarding(_ clientId: String, trainerId: String) async throws {
        try await updateClientStatus(
            clientId,
            trainerId: trainerId,
            newStatus: .active,
            reason: .userRequested,
            notes: "Onboarding completed"
        )
    }
    
    /// Checks if status change is valid
    func canChangeStatus(from currentStatus: ClientStatus, to newStatus: ClientStatus) -> Bool {
        switch (currentStatus, newStatus) {
        case (.pending, .active), (.pending, .paused):
            return true
        case (.active, .paused), (.active, .needsAttention):
            return true
        case (.paused, .active), (.paused, .needsAttention):
            return true
        case (.needsAttention, .active), (.needsAttention, .paused):
            return true
        case (.active, .active):
            return true
        default:
            return currentStatus != newStatus
        }
    }
    
    // MARK: - Bulk Operations
    
    /// Updates multiple clients' statuses
    func bulkUpdateStatus(_ clientIds: [String], trainerId: String, newStatus: ClientStatus, reason: StatusChangeReason) async throws {
        for clientId in clientIds {
            do {
                try await updateClientStatus(clientId, trainerId: trainerId, newStatus: newStatus, reason: reason)
            } catch {
                print("Error updating status for client \(clientId): \(error)")
            }
        }
    }
    
    // MARK: - Status History
    
    /// Gets status change history for a client
    func getStatusHistory(_ clientId: String) async throws -> [StatusChangeRecord] {
        let snapshot = try await db.collection("clients")
            .document(clientId)
            .collection("statusHistory")
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
            .getDocuments()
        
        var history: [StatusChangeRecord] = []
        
        for document in snapshot.documents {
            do {
                let record = try document.data(as: StatusChangeRecord.self)
                history.append(record)
            } catch {
                print("Error decoding status change record: \(error)")
            }
        }
        
        return history
    }
    
    // MARK: - Private Methods
    
    private func logStatusChange(
        clientId: String,
        trainerId: String,
        oldStatus: ClientStatus?,
        newStatus: ClientStatus,
        reason: StatusChangeReason?,
        notes: String?
    ) async throws {
        let record = StatusChangeRecord(
            clientId: clientId,
            trainerId: trainerId,
            oldStatus: oldStatus,
            newStatus: newStatus,
            reason: reason,
            notes: notes,
            timestamp: Date()
        )
        
        try await db.collection("clients")
            .document(clientId)
            .collection("statusHistory")
            .addDocument(from: record)
    }
}

// MARK: - Status Change Record Model
struct StatusChangeRecord: Codable, Identifiable {
    var id = UUID()
    let clientId: String
    let trainerId: String
    let oldStatus: ClientStatus?
    let newStatus: ClientStatus
    let reason: StatusChangeReason?
    let notes: String?
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case clientId, trainerId, oldStatus, newStatus, reason, notes, timestamp
    }
    
    init(clientId: String, trainerId: String, oldStatus: ClientStatus?, newStatus: ClientStatus, reason: StatusChangeReason?, notes: String?, timestamp: Date) {
        self.id = UUID()
        self.clientId = clientId
        self.trainerId = trainerId
        self.oldStatus = oldStatus
        self.newStatus = newStatus
        self.reason = reason
        self.notes = notes
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.clientId = try container.decode(String.self, forKey: .clientId)
        self.trainerId = try container.decode(String.self, forKey: .trainerId)
        self.oldStatus = try container.decodeIfPresent(ClientStatus.self, forKey: .oldStatus)
        self.newStatus = try container.decode(ClientStatus.self, forKey: .newStatus)
        if let reasonString = try container.decodeIfPresent(String.self, forKey: .reason) {
            self.reason = StatusChangeReason(rawValue: reasonString)
        } else {
            self.reason = nil
        }
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(clientId, forKey: .clientId)
        try container.encode(trainerId, forKey: .trainerId)
        try container.encodeIfPresent(oldStatus, forKey: .oldStatus)
        try container.encode(newStatus, forKey: .newStatus)
        try container.encodeIfPresent(reason?.rawValue, forKey: .reason)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(timestamp, forKey: .timestamp)
    }
} 