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
        
        // Email is optional, so only validate if provided
        if !clientEmail.isEmpty && !isValidEmail(clientEmail) {
            throw InvitationError.invalidEmail
        }
        
        // Generate unique invitation
        let invitationId = UUID().uuidString
        let expirationDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        
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
            expiresAt: expirationDate
        )
        
        // Save to Firestore
        try await saveInvitation(invitation)
        
        // Generate invitation link
        let inviteLink = generateInviteLink(invitationId: invitationId)
        
        return InvitationResult(
            invitation: invitation,
            inviteLink: inviteLink,
            success: true,
            message: "Invite link created successfully! Share this link with your client."
        )
    }
    
    /// Accepts an invitation using the invitation ID
    func acceptInvitation(invitationId: String) async throws -> Client {
        let invitation = try await getInvitation(invitationId: invitationId)
        
        // Check if invitation is still valid
        guard invitation.status == .pending else {
            throw InvitationError.invitationAlreadyProcessed
        }
        
        guard invitation.expiresAt > Date() else {
            throw InvitationError.invitationExpired
        }
        
        guard let currentUser = Auth.auth().currentUser else {
            throw InvitationError.notAuthenticated
        }
        
        // Create client record
        let client = Client(
            id: currentUser.uid,
            name: invitation.clientName ?? currentUser.displayName ?? "Client",
            email: invitation.clientEmail,
            trainerId: invitation.trainerId,
            status: .new,
            joinedDate: Date(),
            goal: invitation.goal,
            injuries: invitation.injuries,
            preferredCoachingStyle: invitation.preferredCoachingStyle
        )
        
        // Save client to Firestore
        try await saveClient(client)
        
        // Update invitation status
        try await updateInvitationStatus(invitationId: invitationId, status: .accepted)
        
        return client
    }
    
    /// Gets pending invitations for a trainer
    func getPendingInvitations(trainerId: String) async throws -> [ClientInvitation] {
        let snapshot = try await db.collection("invitations")
            .whereField("trainerId", isEqualTo: trainerId)
            .whereField("status", isEqualTo: InvitationStatus.pending.rawValue)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: ClientInvitation.self)
        }
    }
    
    // MARK: - Private Methods
    
    private func saveInvitation(_ invitation: ClientInvitation) async throws {
        try db.collection("invitations").document(invitation.id).setData(from: invitation)
    }
    
    private func saveClient(_ client: Client) async throws {
        try db.collection("clients").document(client.id).setData(from: client)
    }
    
    private func getInvitation(invitationId: String) async throws -> ClientInvitation {
        let document = try await db.collection("invitations").document(invitationId).getDocument()
        guard let invitation = try? document.data(as: ClientInvitation.self) else {
            throw InvitationError.invitationNotFound
        }
        return invitation
    }
    
    private func updateInvitationStatus(invitationId: String, status: InvitationStatus) async throws {
        try await db.collection("invitations").document(invitationId).updateData([
            "status": status.rawValue,
            "updatedAt": Timestamp()
        ])
    }
    
    private func generateInviteLink(invitationId: String) -> String {
        // In production, this would be your app's deep link or web URL
        return "https://movefully.app/invite/\(invitationId)"
    }
    

    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}

// MARK: - Supporting Types

struct InvitationResult {
    let invitation: ClientInvitation
    let inviteLink: String
    let success: Bool
    let message: String
}

enum InvitationError: LocalizedError {
    case notAuthenticated
    case invalidEmail
    case invitationNotFound
    case invitationExpired
    case invitationAlreadyProcessed
    case networkError(String)
    
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
        }
    }
}

 