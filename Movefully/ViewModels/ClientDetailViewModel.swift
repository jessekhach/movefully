import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class ClientDetailViewModel: ObservableObject {
    @Published var smartAlerts: [SmartAlert] = []
    @Published var currentPlan: WorkoutPlan?
    @Published var upcomingPlan: WorkoutPlan?
    @Published var recentNotes: [ClientNote] = []
    @Published var allNotes: [ClientNote] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var successMessage: String = ""
    @Published var invitationLink: String = ""
    @Published var invitationDetails: ClientInvitation?
    
    private let db = Firestore.firestore()
    private lazy var invitationService = InvitationService()
    private let smartAlertService = SmartAlertService.shared
    private var client: Client?
    
    func loadClientData(_ client: Client) {
        self.client = client
        generateSmartAlerts(for: client)
        loadCurrentPlan(for: client)
        loadUpcomingPlan(for: client)
        loadRecentNotes(for: client)
        
        // Load invitation details for pending clients
        if client.status == .pending {
            loadInvitationDetails(for: client)
        }
    }
    
    /// Dismisses a smart alert
    func dismissAlert(_ alert: SmartAlert) {
        smartAlertService.dismissAlert(alert)
        
        // Remove from local array
        smartAlerts.removeAll { $0.id == alert.id }
    }
    
    private func generateSmartAlerts(for client: Client) {
        // Auto-resolve any dismissed alerts that should be cleared
        smartAlertService.autoResolveAlerts(for: client)
        
        // Generate new alerts (max 2, highest priority)
        smartAlerts = smartAlertService.generateAlerts(for: client)
    }
    
    private func loadCurrentPlan(for client: Client) {
        guard let planId = client.currentPlanId else {
            print("🔍 ClientDetailViewModel: No currentPlanId found for client")
            currentPlan = nil
            return
        }
        
        print("🔍 ClientDetailViewModel: Loading plan with ID: \(planId)")
        print("🔍 ClientDetailViewModel: Available sample plan IDs: \(WorkoutPlan.samplePlans.map { $0.id.uuidString })")
        
        // First try to find in sample data for demo purposes
        if let samplePlan = WorkoutPlan.samplePlans.first(where: { $0.id.uuidString == planId }) {
            print("✅ ClientDetailViewModel: Found plan in sample data: \(samplePlan.name)")
            currentPlan = samplePlan
            return
        }
        
        print("⚠️ ClientDetailViewModel: Plan ID not found in sample data, trying Firestore...")
        
        // Load from Firestore programs collection (not workoutPlans) since we store program IDs
        db.collection("programs").document(planId).getDocument(source: .default) { [weak self] document, error in
            Task { @MainActor in
                if let error = error {
                    print("❌ ClientDetailViewModel: Error loading plan from programs collection: \(error.localizedDescription)")
                    return
                }
                
                if let document = document, document.exists {
                    print("🔍 ClientDetailViewModel: Found Firestore document for plan ID: \(planId)")
                    
                    // Try to parse the document manually first to see what's in it
                    if let data = document.data() {
                        print("📄 ClientDetailViewModel: Document data keys: \(Array(data.keys))")
                        
                        // Extract fields manually to handle any parsing issues
                        if let name = data["name"] as? String,
                           let description = data["description"] as? String,
                           let duration = data["duration"] as? Int,
                           let difficultyString = data["difficulty"] as? String,
                           let difficulty = WorkoutDifficulty(rawValue: difficultyString),
                           let tags = data["tags"] as? [String] {
                            
                            print("✅ ClientDetailViewModel: Successfully parsed program data: \(name)")
                            
                            // Create a WorkoutPlan from the Program data
                            let workoutPlan = WorkoutPlan(
                                name: name,
                                description: description,
                                difficulty: difficulty,
                                duration: max(1, duration / 7), // Convert days to weeks, minimum 1 week
                                exercisesPerWeek: 3, // Default for now
                                sessionDuration: 60, // Default session duration in minutes
                                tags: tags,
                                exercises: [], // Programs don't have exercises, they have workout templates
                                assignedClients: 1 // Default assigned clients count
                            )
                            self?.currentPlan = workoutPlan
                            print("✅ ClientDetailViewModel: Converted program to workout plan successfully")
                        } else {
                            print("❌ ClientDetailViewModel: Failed to parse required fields from document")
                            print("📄 Document data: \(data)")
                            
                            // Try automatic Program decoding as fallback
                            if let program = try? document.data(as: Program.self) {
                                print("✅ ClientDetailViewModel: Fallback Program decoding succeeded: \(program.name)")
                                
                                let workoutPlan = WorkoutPlan(
                                    name: program.name,
                                    description: program.description,
                                    difficulty: program.difficulty,
                                    duration: max(1, program.duration / 7), // Convert days to weeks
                                    exercisesPerWeek: program.workoutCount,
                                    sessionDuration: 60, // Default session duration in minutes
                                    tags: program.tags,
                                    exercises: [], // Programs don't have exercises, they have workout templates
                                    assignedClients: 1 // Default assigned clients count
                                )
                                self?.currentPlan = workoutPlan
                            }
                        }
                    }
                } else {
                    print("❌ ClientDetailViewModel: Program document not found with ID: \(planId)")
                    // Create a fallback plan for assigned but missing plans
                    print("🔧 ClientDetailViewModel: Creating fallback plan for missing plan ID: \(planId)")
                    self?.currentPlan = WorkoutPlan(
                        name: "Assigned Plan",
                        description: "This plan was assigned but the details are not available in the current data source.",
                        difficulty: .intermediate,
                        duration: 8, // 8 weeks default
                        exercisesPerWeek: 3,
                        sessionDuration: 45, // 45 minutes default
                        tags: ["Assigned"],
                        exercises: [],
                        assignedClients: 1
                    )
                }
            }
        }
    }
    
    private func loadUpcomingPlan(for client: Client) {
        guard let planId = client.nextPlanId else {
            print("🔍 ClientDetailViewModel: No nextPlanId found for client")
            upcomingPlan = nil
            return
        }
        
        print("🔍 ClientDetailViewModel: Loading upcoming plan with ID: \(planId)")
        
        // First try to find in sample data for demo purposes
        if let samplePlan = WorkoutPlan.samplePlans.first(where: { $0.id.uuidString == planId }) {
            print("✅ ClientDetailViewModel: Found upcoming plan in sample data: \(samplePlan.name)")
            upcomingPlan = samplePlan
            return
        }
        
        print("⚠️ ClientDetailViewModel: Upcoming plan ID not found in sample data, trying Firestore...")
        
        // Load from Firestore programs collection
        Task {
            do {
                print("🔥 ClientDetailViewModel: Fetching upcoming plan document from Firestore...")
                let document = try await db.collection("programs").document(planId).getDocument(source: .default)
                
                print("🔥 ClientDetailViewModel: Document exists: \(document.exists)")
                print("🔥 ClientDetailViewModel: Document data exists: \(document.data() != nil)")
                
                if document.exists, let data = document.data() {
                    print("🔥 ClientDetailViewModel: Raw upcoming plan document data: \(data)")
                    
                    // Manual field parsing with enhanced debugging
                    await MainActor.run {
                        if let name = data["name"] as? String,
                           let description = data["description"] as? String,
                           let duration = data["duration"] as? Int,
                           let difficultyString = data["difficulty"] as? String,
                           let difficulty = WorkoutDifficulty(rawValue: difficultyString),
                           let tags = data["tags"] as? [String] {
                            
                            print("✅ ClientDetailViewModel: Successfully parsed upcoming plan data: \(name)")
                            
                            // Create a WorkoutPlan from the Program data
                            let workoutPlan = WorkoutPlan(
                                name: name,
                                description: description,
                                difficulty: difficulty,
                                duration: max(1, duration / 7), // Convert days to weeks, minimum 1 week
                                exercisesPerWeek: 3, // Default for now
                                sessionDuration: 60, // Default session duration in minutes
                                tags: tags,
                                exercises: [], // Programs don't have exercises, they have workout templates
                                assignedClients: 1 // Default assigned clients count
                            )
                            self.upcomingPlan = workoutPlan
                            print("✅ ClientDetailViewModel: Converted upcoming plan to workout plan successfully")
                        } else {
                            print("❌ ClientDetailViewModel: Failed to parse required fields from upcoming plan document")
                            print("📄 Upcoming plan document data: \(data)")
                            
                            // Try automatic Program decoding as fallback
                            if let program = try? document.data(as: Program.self) {
                                print("✅ ClientDetailViewModel: Fallback upcoming plan Program decoding succeeded: \(program.name)")
                                
                                let workoutPlan = WorkoutPlan(
                                    name: program.name,
                                    description: program.description,
                                    difficulty: program.difficulty,
                                    duration: max(1, program.duration / 7), // Convert days to weeks
                                    exercisesPerWeek: program.workoutCount,
                                    sessionDuration: 60, // Default session duration in minutes
                                    tags: program.tags,
                                    exercises: [], // Programs don't have exercises, they have workout templates
                                    assignedClients: 1 // Default assigned clients count
                                )
                                self.upcomingPlan = workoutPlan
                            }
                        }
                    }
                } else {
                    print("❌ ClientDetailViewModel: Upcoming plan document not found with ID: \(planId)")
                    await MainActor.run {
                        self.upcomingPlan = nil
                    }
                }
            } catch {
                print("❌ ClientDetailViewModel: Error loading upcoming plan: \(error)")
                await MainActor.run {
                    self.upcomingPlan = nil
                }
            }
        }
    }
    
    private func loadRecentNotes(for client: Client) {
        print("📝 Loading recent notes for client: \(client.id) (trainer-scoped)")
        
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ No authenticated trainer found for loading notes")
            self.recentNotes = []
            self.allNotes = []
            return
        }
        
        print("📝 Filtering notes for trainer: \(currentUser.uid)")
        
        // Load from Firestore with real-time listener
        // Filter by both clientId AND trainerId to ensure proper privacy scoping
        db.collection("clientNotes")
            .whereField("clientId", isEqualTo: client.id)
            .whereField("trainerId", isEqualTo: currentUser.uid)
            .addSnapshotListener { [weak self] querySnapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error loading notes: \(error.localizedDescription)")
                        // Show empty state on error
                        self?.recentNotes = []
                        return
                    }
                    
                    print("📝 Firestore query returned \(querySnapshot?.documents.count ?? 0) documents")
                    
                    let firestoreNotes: [ClientNote] = querySnapshot?.documents.compactMap { document in
                        print("📝 Processing document: \(document.documentID)")
                        let data = document.data()
                        print("📝 Document data: \(data)")
                        
                        // Manually decode since Firestore auto-decoding expects "id" field
                        guard let clientId = data["clientId"] as? String,
                              let trainerId = data["trainerId"] as? String,
                              let content = data["content"] as? String,
                              let typeString = data["type"] as? String,
                              let createdAt = data["createdAt"] as? Timestamp,
                              let updatedAt = data["updatedAt"] as? Timestamp else {
                            print("❌ Missing required fields in document")
                            return nil
                        }
                        
                        let type = ClientNote.NoteType(rawValue: typeString) ?? .trainerNote
                        
                        let note = ClientNote(
                            id: document.documentID, // Use Firestore document ID
                            clientId: clientId,
                            trainerId: trainerId,
                            content: content,
                            type: type,
                            createdAt: createdAt.dateValue(),
                            updatedAt: updatedAt.dateValue()
                        )
                        
                        print("📝 Successfully decoded note: \(note.content) with ID: \(note.id)")
                        return note
                    } ?? []
                    
                    if firestoreNotes.isEmpty {
                        // No notes exist yet - show empty state
                        self?.recentNotes = []
                        self?.allNotes = []
                        print("📝 No notes found for client")
                    } else {
                        // Sort by creation date (newest first)
                        let sortedNotes = firestoreNotes.sorted { $0.createdAt > $1.createdAt }
                        
                        // Store all notes and limit recent notes to 3
                        self?.allNotes = sortedNotes
                        self?.recentNotes = Array(sortedNotes.prefix(3))
                        print("📝 Loaded \(firestoreNotes.count) notes from Firestore")
                        print("📝 Note contents: \(firestoreNotes.map { $0.content })")
                    }
                }
            }
    }
    
    private func loadInvitationDetails(for client: Client) {
        Task {
            do {
                // For pending clients, the client.id is actually the invitation ID
                let invitation = try await invitationService.getInvitationDetails(invitationId: client.id)
                
                await MainActor.run {
                    self.invitationDetails = invitation
                    // Generate the invitation link
                    self.invitationLink = "https://movefully.app/invite/\(invitation.id)"
                }
            } catch {
                await MainActor.run {
                    print("❌ Error loading invitation details: \(error.localizedDescription)")
                    self.errorMessage = "Failed to load invitation details"
                }
            }
        }
    }
    
    func pauseClient() {
        guard let client = client else { return }
        
        let newStatus: ClientStatus = client.status == .paused ? .active : .paused
        
        // Update Firestore
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
                    
                    // Clear message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self?.successMessage = ""
                    }
                }
            }
        }
    }
    
    func archiveClient() {
        guard let client = client else { return }
        
        // Update Firestore
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
                    
                    // Clear message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self?.successMessage = ""
                    }
                }
            }
        }
    }
    
    func addNote(content: String, type: ClientNote.NoteType) {
        guard let client = client,
              let currentUser = Auth.auth().currentUser else { 
            print("❌ AddNote: Missing client or current user")
            return 
        }
        
        print("📝 Adding note for client: \(client.id), trainer: \(currentUser.uid)")
        
        // Create unique document ID
        let documentRef = db.collection("clientNotes").document()
        let documentId = documentRef.documentID
        
        // Save to Firestore with explicit document ID
        let noteData: [String: Any] = [
            "clientId": client.id,
            "trainerId": currentUser.uid,
            "content": content,
            "type": type.rawValue,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp()
        ]
        
        documentRef.setData(noteData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to add note"
                    print("❌ Error adding note: \(error.localizedDescription)")
                } else {
                    print("✅ Note added successfully with ID: \(documentId)")
                    self?.successMessage = "Note added successfully"
                    
                    // The real-time listener should pick up this change automatically
                    // Clear message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self?.successMessage = ""
                    }
                }
            }
        }
    }
    
    func assignPlan(_ plan: WorkoutPlan) {
        guard let client = client else { return }
        
        // Update local state immediately for better UX
        currentPlan = plan
        
        // Update Firestore
        db.collection("clients").document(client.id).updateData([
            "currentPlanId": plan.id.uuidString,
            "updatedAt": Timestamp()
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to assign plan"
                    print("❌ Error assigning plan: \(error.localizedDescription)")
                } else {
                    self?.successMessage = "Plan assigned successfully"
                    
                    // Clear message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self?.successMessage = ""
                    }
                }
            }
        }
    }
    
    func deleteNote(_ note: ClientNote) {
        print("🗑️ Deleting note: \(note.id)")
        
        db.collection("clientNotes").document(note.id).delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to delete note"
                    print("❌ Error deleting note: \(error.localizedDescription)")
                } else {
                    print("✅ Note deleted successfully: \(note.id)")
                    self?.successMessage = "Note deleted"
                    
                    // The real-time listener should pick up this change automatically
                    // Clear message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self?.successMessage = ""
                    }
                }
            }
        }
    }
    
    func clearMessages() {
        errorMessage = ""
        successMessage = ""
    }
} 

