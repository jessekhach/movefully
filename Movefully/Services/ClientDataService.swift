import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Client Data Service
@MainActor
class ClientDataService: ObservableObject {
    private let db = Firestore.firestore()
    private var clientsListener: ListenerRegistration?
    
    // MARK: - Core CRUD Operations
    
    /// Fetches all clients for a specific trainer
    func fetchTrainerClients(_ trainerId: String) async throws -> [Client] {
        let snapshot = try await db.collection("trainers")
            .document(trainerId)
            .collection("clients")
            .getDocuments()
        
        var clients: [Client] = []
        
        for document in snapshot.documents {
            do {
                var client = try document.data(as: Client.self)
                client.id = document.documentID
                clients.append(client)
            } catch {
                print("Error decoding client: \(error)")
                continue
            }
        }
        
        return clients.sorted { client1, client2 in
            // Sort by needs attention first, then by last activity
            if client1.needsAttention && !client2.needsAttention {
                return true
            } else if !client1.needsAttention && client2.needsAttention {
                return false
            } else {
                return (client1.lastActivityDate ?? Date.distantPast) > (client2.lastActivityDate ?? Date.distantPast)
            }
        }
    }
    
    /// Updates client status
    func updateClientStatus(_ clientId: String, status: ClientStatus, trainerId: String) async throws {
        try await db.collection("trainers")
            .document(trainerId)
            .collection("clients")
            .document(clientId)
            .updateData([
                "status": status.rawValue,
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }
    
    /// Updates client profile information
    func updateClientProfile(_ client: Client, trainerId: String) async throws {
        try await db.collection("trainers")
            .document(trainerId)
            .collection("clients")
            .document(client.id)
            .setData(from: client, merge: true)
    }
    
    /// Deletes a client from trainer's roster
    func deleteClient(_ clientId: String, trainerId: String) async throws {
        // Delete from trainer's client collection
        try await db.collection("trainers")
            .document(trainerId)
            .collection("clients")
            .document(clientId)
            .delete()
        
        // Update the relationship status in the main clients collection
        try await db.collection("clients")
            .document(clientId)
            .updateData([
                "trainerId": FieldValue.delete(),
                "status": ClientStatus.pending.rawValue,
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }
    
    /// Adds a new client to trainer's roster
    func addClient(_ client: Client, trainerId: String) async throws {
        var clientData = client
        clientData.trainerId = trainerId
        clientData.createdAt = Date()
        clientData.updatedAt = Date()
        
        try await db.collection("trainers")
            .document(trainerId)
            .collection("clients")
            .document(client.id)
            .setData(from: clientData)
        
        // Also update the main clients collection
        try await db.collection("clients")
            .document(client.id)
            .setData(from: clientData, merge: true)
    }
    
    // MARK: - Real-time Listeners
    
    /// Sets up real-time listener for trainer's clients
    func listenForClientUpdates(_ trainerId: String, completion: @escaping ([Client]) -> Void) {
        clientsListener?.remove()
        
        clientsListener = db.collection("trainers")
            .document(trainerId)
            .collection("clients")
            .addSnapshotListener { snapshot, error in
                Task { @MainActor in
                    if let error = error {
                        print("Error listening for client updates: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    var clients: [Client] = []
                    
                    for document in documents {
                        do {
                            var client = try document.data(as: Client.self)
                            client.id = document.documentID
                            clients.append(client)
                        } catch {
                            print("Error decoding client in listener: \(error)")
                            continue
                        }
                    }
                    
                    // Sort clients by priority
                    let sortedClients = clients.sorted { client1, client2 in
                        if client1.needsAttention && !client2.needsAttention {
                            return true
                        } else if !client1.needsAttention && client2.needsAttention {
                            return false
                        } else {
                            return (client1.lastActivityDate ?? Date.distantPast) > (client2.lastActivityDate ?? Date.distantPast)
                        }
                    }
                    
                    completion(sortedClients)
                }
            }
    }
    
    /// Stops listening for client updates
    func stopListening() {
        clientsListener?.remove()
        clientsListener = nil
    }
    
    // MARK: - Activity Tracking
    
    /// Updates client's last activity timestamp
    func updateClientLastActivity(_ clientId: String, trainerId: String) async throws {
        let now = Date()
        
        try await db.collection("trainers")
            .document(trainerId)
            .collection("clients")
            .document(clientId)
            .updateData([
                "lastActivityDate": Timestamp(date: now),
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }
    
    /// Gets detailed client progress data
    func getClientProgress(_ clientId: String) async throws -> ClientProgress {
        let snapshot = try await db.collection("clients")
            .document(clientId)
            .collection("progress")
            .order(by: "date", descending: true)
            .limit(to: 30)
            .getDocuments()
        
        var workoutsCompleted = 0
        var totalWorkouts = 0
        var lastWorkoutDate: Date?
        
        for document in snapshot.documents {
            let data = document.data()
            if let date = (data["date"] as? Timestamp)?.dateValue() {
                if lastWorkoutDate == nil {
                    lastWorkoutDate = date
                }
                
                totalWorkouts += 1
                if data["completed"] as? Bool == true {
                    workoutsCompleted += 1
                }
            }
        }
        
        let completionRate = totalWorkouts > 0 ? Double(workoutsCompleted) / Double(totalWorkouts) : 0.0
        
        return ClientProgress(
            clientId: clientId,
            workoutsCompleted: workoutsCompleted,
            totalWorkouts: totalWorkouts,
            completionRate: completionRate,
            lastWorkoutDate: lastWorkoutDate
        )
    }
    
    deinit {
        Task { @MainActor in
            stopListening()
        }
    }
}

// MARK: - Client Progress Model
struct ClientProgress: Codable {
    let clientId: String
    let workoutsCompleted: Int
    let totalWorkouts: Int
    let completionRate: Double
    let lastWorkoutDate: Date?
} 