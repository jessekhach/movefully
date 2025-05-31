import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Sort Options
enum ClientSortOption {
    case name
    case lastActivity
    case joinedDate
    case needsAttention
}

class ClientManagementViewModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var filteredClients: [Client] = []
    @Published var isLoading: Bool = false
    @Published var showInviteClientSheet: Bool = false
    @Published var newClientEmail: String = ""
    @Published var errorMessage: String = ""
    @Published var successMessage: String = ""
    
    private let db = Firestore.firestore()
    private var currentFilter: ClientStatus? = nil
    private var currentSort: ClientSortOption = .name
    private var currentSearchText: String = ""
    
    var alertCount: Int {
        clients.filter { $0.status == .needsAttention }.count
    }
    
    init() {
        loadSampleData()
        filteredClients = clients
    }
    
    private func loadSampleData() {
        clients = [
            Client(
                id: "1",
                name: "Sarah Johnson",
                email: "sarah.johnson@example.com",
                status: .active,
                joinedDate: Date().addingTimeInterval(-7776000), // 3 months ago
                lastActivity: Date().addingTimeInterval(-172800), // 2 days ago
                profileImageURL: nil,
                workoutPlan: "Foundation Builder",
                notes: "Prefers morning workouts, recovering from knee injury",
                phone: "+1-555-0123",
                goal: "Weight loss & toning",
                injuries: "Previous knee injury",
                height: "5'7\"",
                weight: "145 lbs",
                workoutTimes: "Early morning",
                coachingStyle: .supportive
            ),
            Client(
                id: "2",
                name: "Marcus Chen",
                email: "marcus.chen@example.com",
                status: .needsAttention,
                joinedDate: Date().addingTimeInterval(-3628800), // 6 weeks ago
                lastActivity: Date().addingTimeInterval(-691200), // 8 days ago
                profileImageURL: nil,
                workoutPlan: "Strength Builder",
                notes: "Hasn't checked in for over a week, needs motivation",
                phone: "+1-555-0124",
                goal: "Strength building",
                injuries: "Lower back sensitivity",
                height: "5'10\"",
                weight: "180 lbs",
                workoutTimes: "Evening",
                coachingStyle: .motivational
            ),
            Client(
                id: "3",
                name: "Emma Rodriguez",
                email: "emma.rodriguez@example.com",
                status: .new,
                joinedDate: Date().addingTimeInterval(-604800), // 1 week ago
                lastActivity: Date().addingTimeInterval(-86400), // 1 day ago
                profileImageURL: nil,
                workoutPlan: "Flexibility Focus",
                notes: "New client, very motivated and consistent",
                phone: "+1-555-0125",
                goal: "Flexibility & balance",
                injuries: "None",
                height: "5'4\"",
                weight: "125 lbs",
                workoutTimes: "Afternoon",
                coachingStyle: .gentle
            ),
            Client(
                id: "4",
                name: "David Kim",
                email: "david.kim@example.com",
                status: .paused,
                joinedDate: Date().addingTimeInterval(-5184000), // 2 months ago
                lastActivity: Date().addingTimeInterval(-1209600), // 14 days ago
                profileImageURL: nil,
                workoutPlan: "Athletic Performance",
                notes: "Taking a break due to work schedule",
                phone: "+1-555-0126",
                goal: "Athletic performance",
                injuries: "Shoulder impingement",
                height: "6'0\"",
                weight: "200 lbs",
                workoutTimes: "Morning",
                coachingStyle: .challenging
            ),
            Client(
                id: "5",
                name: "Alex Thompson",
                email: "alex.thompson@example.com",
                status: .pendingInvite,
                joinedDate: Date(),
                lastActivity: Date(),
                profileImageURL: nil,
                workoutPlan: nil,
                notes: "Invitation sent, waiting for acceptance",
                phone: nil,
                goal: "General fitness",
                injuries: "None",
                height: "5'8\"",
                weight: "160 lbs",
                workoutTimes: "Flexible",
                coachingStyle: .hybrid
            )
        ]
        filteredClients = clients
    }
    
    func searchClients(with searchText: String) {
        if searchText.isEmpty {
            filteredClients = clients
        } else {
            filteredClients = clients.filter { client in
                client.name.localizedCaseInsensitiveContains(searchText) ||
                client.email.localizedCaseInsensitiveContains(searchText) ||
                client.goal.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func filterClients(by status: ClientStatus?) {
        if let status = status {
            filteredClients = clients.filter { $0.status == status }
        } else {
            filteredClients = clients
        }
    }
    
    func sortClients(by sortType: ClientSortType) {
        switch sortType {
        case .name:
            filteredClients.sort { $0.name < $1.name }
        case .lastActivity:
            filteredClients.sort { ($0.lastActivity ?? Date.distantPast) > ($1.lastActivity ?? Date.distantPast) }
        case .joinedDate:
            filteredClients.sort { $0.joinedDate > $1.joinedDate }
        case .needsAttention:
            filteredClients.sort { first, second in
                if first.status == .needsAttention && second.status != .needsAttention {
                    return true
                } else if first.status != .needsAttention && second.status == .needsAttention {
                    return false
                } else {
                    return (first.lastActivity ?? Date.distantPast) < (second.lastActivity ?? Date.distantPast)
                }
            }
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
                status: .pendingInvite,
                joinedDate: Date(),
                lastActivity: Date(),
                profileImageURL: nil,
                workoutPlan: nil,
                notes: "",
                phone: nil,
                goal: invitation.goal ?? "General fitness",
                injuries: invitation.injuries ?? "None",
                height: "N/A",
                weight: "N/A",
                workoutTimes: "Flexible",
                coachingStyle: invitation.preferredCoachingStyle
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

// MARK: - Data Models
struct Client: Identifiable, Hashable {
    let id: String
    let name: String
    let email: String
    let status: ClientStatus
    let joinedDate: Date
    let lastActivity: Date?
    let profileImageURL: String?
    let workoutPlan: String?
    let notes: String
    let phone: String?
    let goal: String
    let injuries: String
    let height: String
    let weight: String
    let workoutTimes: String
    let coachingStyle: CoachingStyle
    
    // Additional computed properties for UI
    var goals: [String] {
        goal.components(separatedBy: " & ").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    var workoutsCompleted: Int {
        // Simulate completed workouts based on how long they've been a client
        let daysSinceJoined = Calendar.current.dateComponents([.day], from: joinedDate, to: Date()).day ?? 0
        return max(0, daysSinceJoined / 3) // Roughly 2-3 workouts per week
    }
    
    var currentStreak: Int {
        // Simulate current streak based on status and last activity
        switch status {
        case .active:
            if let lastActivity = lastActivity {
                let daysSinceActivity = Calendar.current.dateComponents([.day], from: lastActivity, to: Date()).day ?? 0
                return max(0, 7 - daysSinceActivity)
            }
            return 0
        case .new:
            return 3
        case .needsAttention, .paused:
            return 0
        case .pendingInvite:
            return 0
        case .inactive:
            return 0
        case .trial:
            return 1
        }
    }
}

enum ClientStatus: String, CaseIterable {
    case active = "Active"
    case new = "New"
    case paused = "Paused"
    case pendingInvite = "Pending Invite"
    case needsAttention = "Needs Attention"
    case inactive = "Inactive"
    case trial = "Trial"
}

enum ClientSortType: String, CaseIterable {
    case name = "Name"
    case lastActivity = "Recent Activity"
    case joinedDate = "Newest"
    case needsAttention = "Needs Attention"
}

enum CoachingStyle: String, CaseIterable {
    case supportive = "Supportive"
    case motivational = "Motivational"
    case challenging = "Challenging"
    case gentle = "Gentle"
    case hybrid = "Hybrid"
    
    var description: String {
        switch self {
        case .supportive: return "Encouraging and patient approach"
        case .motivational: return "High-energy and inspiring"
        case .challenging: return "Push limits and set high goals"
        case .gentle: return "Calm and understanding method"
        case .hybrid: return "Balanced mix of all styles"
        }
    }
}

struct ClientInvitation {
    let id: String
    let trainerId: String
    let trainerName: String
    let clientEmail: String
    let clientName: String?
    let goal: String?
    let injuries: String?
    let preferredCoachingStyle: CoachingStyle
    let status: InvitationStatus
    let createdAt: Date
    let expiresAt: Date
}

enum InvitationStatus: String {
    case pending = "Pending"
    case accepted = "Accepted"
    case expired = "Expired"
    case declined = "Declined"
} 