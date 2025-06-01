import Foundation
import SwiftUI

// MARK: - Messages View Model
class MessagesViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var availableClients: [Client] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        conversations = [
            Conversation(
                clientName: "Sarah Johnson",
                lastMessage: "Thanks for the workout plan! I'm excited to start.",
                lastMessageTime: Date().addingTimeInterval(-3600),
                unreadCount: 2
            ),
            Conversation(
                clientName: "Marcus Chen",
                lastMessage: "Can we adjust the intensity for next week?",
                lastMessageTime: Date().addingTimeInterval(-7200),
                unreadCount: 1
            ),
            Conversation(
                clientName: "Emma Rodriguez",
                lastMessage: "Perfect! See you tomorrow.",
                lastMessageTime: Date().addingTimeInterval(-86400),
                unreadCount: 0
            )
        ]
    }
    
    func loadConversations() {
        isLoading = true
        
        // Simulate loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.loadSampleData()
            self.isLoading = false
        }
    }
    
    func refreshConversations() {
        loadConversations()
    }
    
    func sendMessage(to client: Client, text: String, completion: @escaping () -> Void) {
        // Simulate sending message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion()
        }
    }
} 