import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Filter and Sort Enums
enum ClientFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case needsAttention = "Needs Attention"
    case new = "New"
    case paused = "Paused"
    
    var title: String {
        return self.rawValue
    }
}

enum ClientSort: String, CaseIterable {
    case lastActivity = "Last Activity"
    case joinedDate = "Joined Date"
    case status = "Status"
    case name = "Name"
    
    var title: String {
        return self.rawValue
    }
}

// MARK: - Sort Options
enum ClientSortOption {
    case name
    case lastActivity
    case joinedDate
    case needsAttention
}

// MARK: - Client Management View Model
class ClientManagementViewModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var filteredClients: [Client] = []
    @Published var invitedClients: [ClientInvitation] = []
    @Published var selectedFilter: ClientFilter = .all
    @Published var searchText: String = "" {
        didSet {
            filterClients()
        }
    }
    @Published var selectedSort: ClientSort = .lastActivity {
        didSet {
            sortClients()
        }
    }
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    @Published var showingInviteSheet = false
    @Published var showInviteClientSheet: Bool = false
    @Published var newClientEmail: String = ""
    
    private let db = Firestore.firestore()
    private var currentFilter: ClientStatus? = nil
    private var currentSort: ClientSortOption = .name
    private var currentSearchText: String = ""
    
    var alertCount: Int {
        clients.filter { $0.status == .needsAttention }.count
    }
    
    init() {
        loadSampleData()
        filterClients()
    }
    
    private func loadSampleData() {
        // Use sample data from DataModels
        clients = [
            Client(
                id: "1",
                name: "Sarah Johnson",
                email: "sarah.johnson@example.com",
                trainerId: "trainer1",
                status: .active,
                joinedDate: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
                height: "5'6\"",
                weight: "145 lbs",
                goal: "Improve overall flexibility and build core strength",
                injuries: "Previous knee injury (2019) - cleared by PT",
                preferredCoachingStyle: .hybrid,
                lastWorkoutDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
                lastActivityDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
                currentPlanId: "plan1",
                totalWorkoutsCompleted: 24
            ),
            Client(
                id: "2",
                name: "Marcus Chen",
                email: "marcus.chen@example.com",
                trainerId: "trainer1",
                status: .needsAttention,
                joinedDate: Calendar.current.date(byAdding: .day, value: -45, to: Date()),
                height: "5'10\"",
                weight: "180 lbs",
                goal: "Train for upcoming marathon while maintaining strength",
                preferredCoachingStyle: .asynchronous,
                lastWorkoutDate: Calendar.current.date(byAdding: .day, value: -8, to: Date()),
                lastActivityDate: Calendar.current.date(byAdding: .day, value: -8, to: Date()),
                currentPlanId: "plan2",
                totalWorkoutsCompleted: 18
            ),
            Client(
                id: "3",
                name: "Emma Rodriguez",
                email: "emma.rodriguez@example.com",
                trainerId: "trainer1",
                status: .new,
                joinedDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
                height: "5'4\"",
                weight: "130 lbs",
                goal: "Get back into fitness after having a baby",
                injuries: "Diastasis recti - working with pelvic floor PT",
                preferredCoachingStyle: .synchronous,
                lastActivityDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
                totalWorkoutsCompleted: 2
            ),
            Client(
                id: "4",
                name: "David Kim",
                email: "david.kim@example.com",
                trainerId: "trainer1",
                status: .paused,
                joinedDate: Calendar.current.date(byAdding: .day, value: -60, to: Date()),
                height: "5'8\"",
                weight: "165 lbs",
                goal: "Build functional strength for outdoor activities",
                preferredCoachingStyle: .hybrid,
                lastWorkoutDate: Calendar.current.date(byAdding: .day, value: -15, to: Date()),
                lastActivityDate: Calendar.current.date(byAdding: .day, value: -15, to: Date()),
                currentPlanId: "plan3",
                totalWorkoutsCompleted: 35
            ),
            Client(
                id: "5",
                name: "Alex Thompson",
                email: "alex.thompson@example.com",
                trainerId: "trainer1",
                status: .pending,
                joinedDate: nil,
                goal: "General wellness and stress relief through movement",
                preferredCoachingStyle: .hybrid,
                totalWorkoutsCompleted: 0
            )
        ]
    }
    
    func filterClients() {
        var filtered = clients
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { client in
                client.name.localizedCaseInsensitiveContains(searchText) ||
                client.email.localizedCaseInsensitiveContains(searchText) ||
                (client.goals?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .active:
            filtered = filtered.filter { $0.status == .active }
        case .needsAttention:
            filtered = filtered.filter { $0.status == .needsAttention }
        case .new:
            filtered = filtered.filter { $0.status == .new }
        case .paused:
            filtered = filtered.filter { $0.status == .paused }
        }
        
        filteredClients = filtered
        sortClients()
    }
    
    func sortClients() {
        switch selectedSort {
        case .lastActivity:
            filteredClients.sort(by: { ($0.lastActivityDate ?? Date.distantPast) > ($1.lastActivityDate ?? Date.distantPast) })
        case .joinedDate:
            filteredClients.sort(by: { ($0.joinedDate ?? Date.distantPast) > ($1.joinedDate ?? Date.distantPast) })
        case .status:
            filteredClients.sort(by: { first, second in
                if first.status == .needsAttention && second.status != .needsAttention {
                    return true
                }
                if first.status != .needsAttention && second.status == .needsAttention {
                    return false
                }
                return first.name < second.name
            })
        case .name:
            filteredClients.sort { $0.name < $1.name }
        }
    }
    
    func inviteClient() {
        guard !newClientEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        guard isValidEmail(newClientEmail) else {
            errorMessage = "Please enter a valid email format"
            return
        }
        
        guard Auth.auth().currentUser != nil else {
            errorMessage = "Authentication error. Please try again."
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        print("📧 Inviting client: \(newClientEmail)")
        
        // For now, just simulate the invitation process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.successMessage = "Invitation sent to \(self.newClientEmail)!"
            self.newClientEmail = ""
            self.showInviteClientSheet = false
            
            // Clear success message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
                successMessage = ""
            }
            
            print("✅ Invitation sent successfully")
        }
        
        /*
        // Real implementation would create an invitation document
        let invitationData: [String: Any] = [
            "trainerId": currentUser.uid,
            "trainerName": currentUser.displayName ?? "Your Trainer",
            "clientEmail": newClientEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            "status": "pending",
            "createdAt": Timestamp(),
            "expiresAt": Timestamp(date: Date().addingTimeInterval(7 * 24 * 60 * 60)) // 7 days
        ]
        
        db.collection("invitations").addDocument(data: invitationData) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Error sending invitation: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to send invitation"
                } else {
                    print("✅ Invitation sent successfully")
                    self?.successMessage = "Invitation sent to \(self?.newClientEmail ?? "")!"
                    self?.newClientEmail = ""
                    self?.showInviteClientSheet = false
                    
                    // Here you would also trigger an email/notification to the client
                    // This could be done via Cloud Functions
                }
            }
        }
        */
    }
    
    func inviteClientWithDetails(_ invitation: ClientInvitation) {
        isLoading = true
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.successMessage = "Invitation sent successfully!"
            self.isLoading = false
            
            // Add pending client
            let newClient = Client(
                id: UUID().uuidString,
                name: invitation.clientName ?? invitation.clientEmail,
                email: invitation.clientEmail,
                trainerId: "trainer1", // This should come from the current trainer
                status: .pending,
                joinedDate: Date(),
                profileImageUrl: nil,
                height: "N/A",
                weight: "N/A",
                goal: invitation.goal ?? "General fitness",
                injuries: invitation.injuries ?? "None",
                preferredCoachingStyle: invitation.preferredCoachingStyle ?? .hybrid,
                lastWorkoutDate: nil,
                lastActivityDate: Date(),
                currentPlanId: nil,
                totalWorkoutsCompleted: 0
            )
            
            self.clients.append(newClient)
            self.filteredClients = self.clients
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
                successMessage = ""
            }
        }
    }
    
    func generateInviteLink(_ invitation: ClientInvitation) {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.successMessage = "Invite link generated successfully!"
            self.isLoading = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
                successMessage = ""
            }
        }
    }
    
    func removeClient(_ client: Client) {
        clients.removeAll { $0.id == client.id }
        filteredClients.removeAll { $0.id == client.id }
        successMessage = "Client removed successfully"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
            successMessage = ""
        }
    }
    
    func refreshClients() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPred.evaluate(with: email)
    }
    
    func clearMessages() {
        errorMessage = ""
        successMessage = ""
    }
}

// MARK: - Client Sort Type
enum ClientSortType: String, CaseIterable {
    case name = "Name"
    case lastActivity = "Recent Activity"
    case joinedDate = "Newest"
    case needsAttention = "Needs Attention"
} 