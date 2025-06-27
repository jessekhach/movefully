import Foundation
import FirebaseFirestore
import FirebaseAuth
import MessageUI

// MARK: - Invitation Service
@MainActor
class InvitationService: ObservableObject {
    private let db = Firestore.firestore()
    
    // MARK: - Public Methods
    
    /// Generates a shareable invite link that trainers can share manually
    func createInviteLink(
        clientName: String,
        clientEmail: String,
        personalNote: String? = nil
    ) async throws -> InvitationResult {
        guard let currentUser = Auth.auth().currentUser else {
            throw InvitationError.notAuthenticated
        }
        
        // Generate unique invitation ID
        let invitationId = UUID().uuidString
        
        // Create invitation document
        let invitation = ClientInvitation(
            id: invitationId,
            trainerId: currentUser.uid,
            trainerName: currentUser.displayName ?? "Your Trainer",
            clientEmail: clientEmail,
            clientName: clientName,
            personalNote: personalNote,
            status: .pending,
            createdAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        )
        
        // Save to Firestore
        try await saveInvitation(invitation)
        
        // Create shareable link
        let inviteLink = "https://movefully.app/invite/\(invitationId)"
        
        print("📧 InvitationService: Created invite link: \(inviteLink)")
        
        return InvitationResult(
            invitationId: invitationId,
            inviteLink: inviteLink,
            clientEmail: clientEmail,
            clientName: clientName
        )
    }
    
    /// Validates and retrieves invitation details (for unauthenticated users)
    func validateInvitation(invitationId: String) async throws -> ClientInvitation {
        print("🔍 InvitationService: Validating invitation: \(invitationId)")
        
        // Fetch invitation document
        let document = try await db.collection("invitations").document(invitationId).getDocument()
        
        guard document.exists else {
            print("❌ InvitationService: Invitation not found: \(invitationId)")
            throw InvitationError.invalidInvitation
        }
        
        guard let invitation = try? document.data(as: ClientInvitation.self) else {
            print("❌ InvitationService: Failed to decode invitation: \(invitationId)")
            throw InvitationError.invalidInvitation
        }
        
        // Check if invitation is expired
        if invitation.expiresAt < Date() {
            print("❌ InvitationService: Invitation expired: \(invitationId)")
            throw InvitationError.expiredInvitation
        }
        
        // Check if invitation is already used
        if invitation.status != .pending {
            print("❌ InvitationService: Invitation already used: \(invitationId)")
            throw InvitationError.invitationAlreadyProcessed
        }
        
        print("✅ InvitationService: Invitation validated: \(invitationId)")
        return invitation
    }
    
    /// Accepts an invitation and creates client account
    func acceptInvitation(
        invitationId: String,
        clientEmail: String,
        clientPassword: String,
        clientName: String,
        clientPhone: String?
    ) async throws -> InvitationAcceptanceResult {
        print("🎯 InvitationService: Accepting invitation: \(invitationId)")
        
        // First validate the invitation
        let invitation = try await validateInvitation(invitationId: invitationId)
        
        // Verify email matches
        guard invitation.clientEmail.lowercased() == clientEmail.lowercased() else {
            throw InvitationError.emailMismatch
        }
        
        // Create Firebase Auth account
        let authResult = try await Auth.auth().createUser(withEmail: clientEmail, password: clientPassword)
        let userId = authResult.user.uid
        
        print("✅ InvitationService: Created Firebase Auth user: \(userId)")
        
        // Create client document
        let client = Client(
            id: userId,
            name: clientName,
            email: clientEmail,
            trainerId: invitation.trainerId,
            status: .active,
            joinedDate: Date()
        )
        
        // Save client and update invitation
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Save client
            group.addTask {
                try await self.saveClient(client)
            }
            
            // Mark invitation as accepted
            group.addTask {
                try await self.markInvitationAsAccepted(invitationId: invitationId, clientId: userId)
            }
            
            // Wait for all tasks to complete
            try await group.waitForAll()
        }
        
        print("✅ InvitationService: Successfully accepted invitation: \(invitationId)")
        
        return InvitationAcceptanceResult(
            clientId: userId,
            trainerId: invitation.trainerId,
            invitationId: invitationId
        )
    }
    
    /// Saves a client document directly (for already authenticated users)
    func saveClientDirectly(_ client: Client) async throws {
        try await saveClient(client)
    }
    
    /// Marks an invitation as accepted directly (for already authenticated users)
    func markInvitationAsAcceptedDirectly(invitationId: String, clientId: String) async throws {
        try await markInvitationAsAccepted(invitationId: invitationId, clientId: clientId)
    }
    
    // MARK: - Private Methods
    
    private func saveInvitation(_ invitation: ClientInvitation) async throws {
        print("💾 InvitationService: Saving invitation: \(invitation.id)")
        
        // Convert to dictionary and ensure id is included
        var invitationData = try Firestore.Encoder().encode(invitation)
        invitationData["id"] = invitation.id
        
        try await db.collection("invitations").document(invitation.id).setData(invitationData)
        print("✅ InvitationService: Successfully saved invitation")
    }
    
    private func saveClient(_ client: Client) async throws {
        print("🔧 InvitationService: Saving client to main collection - ID: \(client.id), TrainerID: \(client.trainerId)")
        
        // Convert client to dictionary and ensure id is included
        var clientData = try Firestore.Encoder().encode(client)
        clientData["id"] = client.id // Explicitly include the id field
        
        // Save to main clients collection
        try await db.collection("clients").document(client.id).setData(clientData)
        print("✅ InvitationService: Successfully saved to main clients collection")
        
        print("🔧 InvitationService: Saving client to trainer's subcollection")
        // Save to trainer's client subcollection
        try await db.collection("trainers")
            .document(client.trainerId)
            .collection("clients")
            .document(client.id)
            .setData(clientData)
        print("✅ InvitationService: Successfully saved to trainer's clients subcollection")
    }
    
    private func markInvitationAsAccepted(invitationId: String, clientId: String) async throws {
        print("✅ InvitationService: Marking invitation as accepted: \(invitationId)")
        
        try await db.collection("invitations").document(invitationId).updateData([
            "status": "accepted",
            "acceptedAt": Timestamp(date: Date()),
            "clientId": clientId
        ])
        
        print("✅ InvitationService: Successfully marked invitation as accepted")
    }
}

// MARK: - Supporting Types

struct InvitationResult {
    let invitationId: String
    let inviteLink: String
    let clientEmail: String
    let clientName: String
}

enum InvitationError: LocalizedError {
    case notAuthenticated
    case invalidEmail
    case invitationNotFound
    case invitationExpired
    case invitationAlreadyProcessed
    case networkError(String)
    case invalidResponse
    case invalidInvitation
    case expiredInvitation
    case emailMismatch
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to send invitations"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invitationNotFound:
            return "Invitation not found or invalid"
        case .invitationExpired:
            return "This invitation has expired"
        case .invitationAlreadyProcessed:
            return "This invitation has already been accepted or declined"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidInvitation:
            return "Invalid invitation"
        case .expiredInvitation:
            return "Invitation has expired"
        case .emailMismatch:
            return "Email mismatch"
        }
    }
}

struct InvitationAcceptanceResult {
    let clientId: String
    let trainerId: String
    let invitationId: String
}

 