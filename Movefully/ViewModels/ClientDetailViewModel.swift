import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class ClientDetailViewModel: ObservableObject {
    @Published var alerts: [String] = []
    @Published var currentPlan: WorkoutPlan?
    @Published var recentNotes: [ClientNote] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var successMessage: String = ""
    
    private let db = Firestore.firestore()
    private var client: Client?
    
    func loadClientData(_ client: Client) {
        self.client = client
        generateSmartAlerts(for: client)
        loadCurrentPlan(for: client)
        loadRecentNotes(for: client)
    }
    
    private func generateSmartAlerts(for client: Client) {
        alerts.removeAll()
        
        // Check for no assigned plan
        if client.currentPlanId == nil {
            alerts.append("No workout plan assigned")
        }
        
        // Check for inactivity
        if let lastActivity = client.lastActivityDate {
            let daysInactive = Calendar.current.dateComponents([.day], from: lastActivity, to: Date()).day ?? 0
            if daysInactive >= 7 {
                alerts.append("No activity logged in \(daysInactive) days")
            }
        } else {
            alerts.append("No activity logged yet")
        }
        
        // Check for new clients without initial assessment
        if client.status == .new && client.totalWorkoutsCompleted == 0 {
            alerts.append("New client - consider scheduling initial assessment")
        }
        
        // Check for paused clients
        if client.status == .paused {
            alerts.append("Client is currently paused - follow up when ready to resume")
        }
    }
    
    private func loadCurrentPlan(for client: Client) {
        // For demo purposes, use sample data
        // In production, this would query Firestore
        if let planId = client.currentPlanId {
            currentPlan = WorkoutPlan.samplePlans.first { $0.id == planId }
        }
        
        /*
        // Real Firestore implementation:
        guard let planId = client.currentPlanId else {
            currentPlan = nil
            return
        }
        
        db.collection("workoutPlans").document(planId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error loading plan: \(error.localizedDescription)")
                    return
                }
                
                if let document = document, document.exists {
                    self?.currentPlan = try? document.data(as: WorkoutPlan.self)
                }
            }
        }
        */
    }
    
    private func loadRecentNotes(for client: Client) {
        // For demo purposes, use sample data filtered by client ID
        recentNotes = ClientNote.sampleNotes.filter { $0.clientId == client.id }
            .sorted { $0.createdAt > $1.createdAt }
        
        /*
        // Real Firestore implementation:
        db.collection("clientNotes")
            .whereField("clientId", isEqualTo: client.id)
            .order(by: "createdAt", descending: true)
            .limit(to: 5)
            .getDocuments { [weak self] querySnapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error loading notes: \(error.localizedDescription)")
                        return
                    }
                    
                    self?.recentNotes = querySnapshot?.documents.compactMap { document in
                        try? document.data(as: ClientNote.self)
                    } ?? []
                }
            }
        */
    }
    
    func pauseClient() {
        guard let client = client else { return }
        
        // For demo purposes, just show a message
        let action = client.status == .paused ? "resumed" : "paused"
        successMessage = "Client \(action) successfully"
        
        // Clear message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.successMessage = ""
        }
        
        /*
        // Real implementation would update Firestore:
        let newStatus: ClientStatus = client.status == .paused ? .active : .paused
        
        db.collection("clients").document(client.id).updateData([
            "status": newStatus.rawValue,
            "updatedAt": Timestamp()
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to update client status"
                    print("❌ Error updating client: \(error.localizedDescription)")
                } else {
                    let action = newStatus == .paused ? "paused" : "resumed"
                    self?.successMessage = "Client \(action) successfully"
                }
            }
        }
        */
    }
    
    func archiveClient() {
        guard let client = client else { return }
        
        // For demo purposes, just show a message
        successMessage = "Client archived successfully"
        
        // Clear message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.successMessage = ""
        }
        
        /*
        // Real implementation would update Firestore:
        db.collection("clients").document(client.id).updateData([
            "status": "archived",
            "archivedAt": Timestamp(),
            "updatedAt": Timestamp()
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to archive client"
                    print("❌ Error archiving client: \(error.localizedDescription)")
                } else {
                    self?.successMessage = "Client archived successfully"
                }
            }
        }
        */
    }
    
    func addNote(content: String, type: ClientNote.NoteType) {
        guard let client = client,
              let currentUser = Auth.auth().currentUser else { return }
        
        // For demo purposes, just add to local array
        let newNote = ClientNote(
            id: UUID().uuidString,
            clientId: client.id,
            trainerId: currentUser.uid,
            content: content,
            type: type,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        recentNotes.insert(newNote, at: 0)
        successMessage = "Note added successfully"
        
        /*
        // Real implementation would save to Firestore:
        let noteData: [String: Any] = [
            "clientId": client.id,
            "trainerId": currentUser.uid,
            "content": content,
            "type": type.rawValue,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp()
        ]
        
        db.collection("clientNotes").addDocument(data: noteData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to add note"
                    print("❌ Error adding note: \(error.localizedDescription)")
                } else {
                    self?.successMessage = "Note added successfully"
                    self?.loadRecentNotes(for: client)
                }
            }
        }
        */
    }
    
    func assignPlan(_ plan: WorkoutPlan) {
        guard let client = client else { return }
        
        // For demo purposes, just update local state
        currentPlan = plan
        successMessage = "Plan assigned successfully"
        
        // Clear message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.successMessage = ""
        }
        
        /*
        // Real implementation would update Firestore:
        db.collection("clients").document(client.id).updateData([
            "currentPlanId": plan.id,
            "updatedAt": Timestamp()
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to assign plan"
                    print("❌ Error assigning plan: \(error.localizedDescription)")
                } else {
                    self?.successMessage = "Plan assigned successfully"
                    self?.currentPlan = plan
                }
            }
        }
        */
    }
    
    func clearMessages() {
        errorMessage = ""
        successMessage = ""
    }
} 