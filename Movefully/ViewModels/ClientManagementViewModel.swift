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
@MainActor
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
    @Published var generatedInviteLink: String = ""
    
    private let db = Firestore.firestore()
    private let invitationService = InvitationService()
    private let clientDataService = ClientDataService()
    private let activityService = ClientActivityService()
    private let statusService = ClientStatusService()
    private var currentFilter: ClientStatus? = nil
    private var currentSort: ClientSortOption = .name
    private var currentSearchText: String = ""
    
    var alertCount: Int {
        clients.filter { $0.status == .needsAttention }.count
    }
    
    init() {
        loadClients()
    }
    
    // MARK: - Data Loading Methods
    
    func loadClients() {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "Authentication required"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        // Set up real-time listener for clients
        clientDataService.listenForClientUpdates(currentUser.uid) { [weak self] (updatedClients: [Client]) in
            Task { @MainActor in
                self?.clients = updatedClients
                self?.isLoading = false
                self?.filterClients()
            }
        }
        
        // Also perform periodic automatic status updates
        Task {
            do {
                try await statusService.performAutomaticStatusUpdates(currentUser.uid)
            } catch {
                print("Error updating automatic statuses: \(error)")
            }
        }
    }
    
    func refreshClients() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        do {
            isLoading = true
            let fetchedClients = try await clientDataService.fetchTrainerClients(currentUser.uid)
            clients = fetchedClients
            filterClients()
        } catch {
            errorMessage = "Failed to refresh clients: \(error.localizedDescription)"
        }
        isLoading = false
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
    
    func createInviteLink(clientName: String, clientEmail: String, personalNote: String = "") async {
        isLoading = true
        errorMessage = ""
        
        do {
            let result = try await invitationService.createInviteLink(
                clientName: clientName,
                clientEmail: clientEmail,
                personalNote: personalNote.isEmpty ? nil : personalNote
            )
            
            successMessage = result.message
            generatedInviteLink = result.inviteLink
            
            // Add to invited clients list
            invitedClients.append(result.invitation)
            
            // Copy link to clipboard automatically
            UIPasteboard.general.string = result.inviteLink
            
            // Don't close the sheet - let user see the link and copy it again if needed
            
            // Clear success message after 5 seconds (longer so user can see it)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.successMessage = ""
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
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