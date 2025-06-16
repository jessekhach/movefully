import Foundation
import SwiftUI

// MARK: - URL Handling Service
@MainActor
class URLHandlingService: ObservableObject {
    @Published var pendingInvitationId: String?
    @Published var showInvitationAcceptance = false
    @Published var isProcessingInvitation = false
    
    // MARK: - URL Handling Methods
    
    /// Handles incoming URLs from deep links
    func handleIncomingURL(_ url: URL) {
        print("🔗 Handling incoming URL: \(url)")
        
        // Parse the URL to extract invitation information
        if let invitationId = extractInvitationId(from: url) {
            print("🔗 Extracted invitation ID: \(invitationId)")
            pendingInvitationId = invitationId
            showInvitationAcceptance = true
        } else {
            print("❌ Failed to extract invitation ID from URL")
        }
    }
    
    /// Extracts invitation ID from various URL formats
    private func extractInvitationId(from url: URL) -> String? {
        // Handle different URL formats:
        // 1. https://movefully.app/invite/{id}
        // 2. movefully://invite/{id}
        // 3. movefully://invite?id={id}
        
        let urlString = url.absoluteString.lowercased()
        
        // Check for path-based invitation ID
        if urlString.contains("/invite/") {
            let components = url.pathComponents
            if let inviteIndex = components.firstIndex(of: "invite"),
               inviteIndex + 1 < components.count {
                let invitationId = components[inviteIndex + 1]
                return invitationId.isEmpty ? nil : invitationId
            }
        }
        
        // Check for query parameter-based invitation ID
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            if let inviteItem = queryItems.first(where: { $0.name == "id" || $0.name == "invitationId" }) {
                return inviteItem.value
            }
        }
        
        return nil
    }
    
    /// Clears the pending invitation state
    func clearPendingInvitation() {
        pendingInvitationId = nil
        showInvitationAcceptance = false
        isProcessingInvitation = false
    }
    
    /// Generates a test invitation URL for development
    func generateTestInvitationURL() -> URL? {
        let testInvitationId = "test-invitation-123"
        return URL(string: "movefully://invite/\(testInvitationId)")
    }
}

// MARK: - URL Scheme Configuration
extension URLHandlingService {
    /// Returns the supported URL schemes for the app
    static var supportedURLSchemes: [String] {
        return [
            "movefully",
            "https"
        ]
    }
    
    /// Checks if a URL is a supported invitation URL
    static func isInvitationURL(_ url: URL) -> Bool {
        let urlString = url.absoluteString.lowercased()
        return urlString.contains("/invite/") || urlString.contains("/invite?")
    }
} 