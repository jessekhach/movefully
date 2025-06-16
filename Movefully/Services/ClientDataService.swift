import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Client Data Service
@MainActor
class ClientDataService: ObservableObject {
    private let db = Firestore.firestore()
    nonisolated(unsafe) private var clientsListener: ListenerRegistration?
    nonisolated(unsafe) private var invitationsListener: ListenerRegistration?
    
    // MARK: - Core CRUD Operations
    
    /// Fetches a single client by ID
    func fetchClient(clientId: String) async throws -> Client {
        print("🔍 ClientDataService: Fetching client with ID: \(clientId)")
        
        // Try to find in clients collection first
        let clientDoc = try await db.collection("clients").document(clientId).getDocument()
        
        if clientDoc.exists {
            var client = try clientDoc.data(as: Client.self)
            client.id = clientId
            print("✅ ClientDataService: Found client in main collection - \(client.name)")
            return client
        }
        
        // If not found, check if it's a pending invitation
        let invitationDoc = try await db.collection("invitations").document(clientId).getDocument()
        
        if invitationDoc.exists {
            let invitation = try invitationDoc.data(as: ClientInvitation.self)
            
            let pendingClient = Client(
                id: invitation.id,
                name: invitation.clientName ?? invitation.clientEmail,
                email: invitation.clientEmail,
                trainerId: invitation.trainerId,
                status: .pending,
                joinedDate: nil,
                goal: invitation.goal,
                injuries: invitation.injuries,
                preferredCoachingStyle: invitation.preferredCoachingStyle,
                totalWorkoutsCompleted: 0
            )
            
            print("✅ ClientDataService: Found pending invitation - \(pendingClient.email)")
            return pendingClient
        }
        
        throw NSError(domain: "ClientDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Client not found"])
    }
    
    /// Fetches all clients for a specific trainer, including pending invitations
    func fetchTrainerClients(_ trainerId: String) async throws -> [Client] {
        print("🔍 ClientDataService: Fetching clients for trainer: \(trainerId)")
        
        // Fetch actual clients
        let clientsSnapshot = try await db.collection("trainers")
            .document(trainerId)
            .collection("clients")
            .getDocuments()
        
        var clients: [Client] = []
        
        print("🔍 ClientDataService: Found \(clientsSnapshot.documents.count) documents in trainer's clients subcollection")
        
        for document in clientsSnapshot.documents {
            do {
                var client = try document.data(as: Client.self)
                client.id = document.documentID
                clients.append(client)
                print("✅ ClientDataService: Loaded client - ID: \(client.id), Name: \(client.name), Status: \(client.status)")
            } catch {
                print("❌ ClientDataService: Error decoding client: \(error)")
                continue
            }
        }
        
        // Fetch pending invitations and convert to pending clients
        let invitationsSnapshot = try await db.collection("invitations")
            .whereField("trainerId", isEqualTo: trainerId)
            .whereField("status", isEqualTo: InvitationStatus.pending.rawValue)
            .getDocuments()
        
        print("🔍 ClientDataService: Found \(invitationsSnapshot.documents.count) pending invitations")
        
        for document in invitationsSnapshot.documents {
            do {
                let invitation = try document.data(as: ClientInvitation.self)
                
                // Create a client object from the invitation
                let pendingClient = Client(
                    id: invitation.id, // Use invitation ID as client ID for pending clients
                    name: invitation.clientName ?? invitation.clientEmail,
                    email: invitation.clientEmail,
                    trainerId: trainerId,
                    status: .pending,
                    joinedDate: nil, // No join date until invitation is accepted
                    goal: invitation.goal,
                    injuries: invitation.injuries,
                    preferredCoachingStyle: invitation.preferredCoachingStyle,
                    totalWorkoutsCompleted: 0
                )
                
                clients.append(pendingClient)
                print("✅ ClientDataService: Loaded pending invitation - ID: \(pendingClient.id), Email: \(pendingClient.email)")
            } catch {
                print("❌ ClientDataService: Error decoding invitation: \(error)")
                continue
            }
        }
        
        print("🔍 ClientDataService: Total clients loaded: \(clients.count)")
        
        return clients.sorted { client1, client2 in
            // Sort by needs attention first, then pending invitations, then by last activity
            if client1.needsAttention && !client2.needsAttention {
                return true
            } else if !client1.needsAttention && client2.needsAttention {
                return false
            } else if client1.status == .pending && client2.status != .pending {
                return true
            } else if client1.status != .pending && client2.status == .pending {
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
    
    /// Updates client profile information (trainer-side update)
    func updateClientProfile(_ client: Client, trainerId: String) async throws {
        // Update in trainer's client subcollection
        try await db.collection("trainers")
            .document(trainerId)
            .collection("clients")
            .document(client.id)
            .setData(from: client, merge: true)
        
        // Also update in main clients collection to ensure data persistence
        try await db.collection("clients")
            .document(client.id)
            .setData(from: client, merge: true)
    }
    
    /// Updates client profile information (client self-update)
    /// This method allows clients to update their own profile without requiring trainerId
    func updateClientSelfProfile(_ client: Client) async throws {
        print("🔄 ClientDataService: Updating client self-profile for ID: \(client.id)")
        
        // Update in main clients collection
        try await db.collection("clients")
            .document(client.id)
            .setData(from: client, merge: true)
        
        // Also update in trainer's client subcollection if trainerId is available
        if !client.trainerId.isEmpty {
            try await db.collection("trainers")
                .document(client.trainerId)
                .collection("clients")
                .document(client.id)
                .setData(from: client, merge: true)
        }
        
        print("✅ ClientDataService: Client self-profile updated successfully")
    }
    
    /// Creates an automatic note when client updates their profile
    func createProfileUpdateNote(
        clientId: String,
        trainerId: String,
        clientName: String,
        changes: [String]
    ) async throws {
        guard !changes.isEmpty else { return }
        
        print("📝 ClientDataService: Creating profile update note for client: \(clientId)")
        
        // Create the note content
        let changesText = changes.joined(separator: "\n• ")
        let noteContent = """
        \(clientName) updated their profile:
        
        • \(changesText)
        
        These changes were made by the client and may require your attention for program adjustments.
        """
        
        // Create unique document ID
        let documentRef = db.collection("clientNotes").document()
        
        // Save to Firestore
        let noteData: [String: Any] = [
            "clientId": clientId,
            "trainerId": trainerId,
            "content": noteContent,
            "type": ClientNote.NoteType.profileUpdate.rawValue,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp()
        ]
        
        try await documentRef.setData(noteData)
        print("✅ ClientDataService: Profile update note created successfully")
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
    
    /// Sets up real-time listener for trainer's clients, including pending invitations
    func listenForClientUpdates(_ trainerId: String, completion: @escaping ([Client]) -> Void) {
        clientsListener?.remove()
        invitationsListener?.remove()
        
        // Listen for actual clients
        clientsListener = db.collection("trainers")
            .document(trainerId)
            .collection("clients")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening for client updates: \(error)")
                    return
                }
                
                Task { @MainActor in
                    do {
                        let allClients = try await self?.fetchTrainerClients(trainerId) ?? []
                        completion(allClients)
                    } catch {
                        print("Error fetching combined clients and invitations: \(error)")
                        completion([])
                    }
                }
            }
        
        // Listen for pending invitations
        invitationsListener = db.collection("invitations")
            .whereField("trainerId", isEqualTo: trainerId)
            .whereField("status", isEqualTo: InvitationStatus.pending.rawValue)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening for invitation updates: \(error)")
                    return
                }
                
                Task { @MainActor in
                    do {
                        let allClients = try await self?.fetchTrainerClients(trainerId) ?? []
                        completion(allClients)
                    } catch {
                        print("Error fetching combined clients and invitations: \(error)")
                        completion([])
                    }
                }
            }
    }
    
    /// Stops listening for client updates
    nonisolated func stopListening() {
        clientsListener?.remove()
        clientsListener = nil
        invitationsListener?.remove()
        invitationsListener = nil
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
        stopListening()
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