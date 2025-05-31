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
                id: "1",
                clientId: "client1",
                clientName: "Sarah Johnson",
                lastMessage: "Thanks for the workout plan! I'm excited to start.",
                lastMessageDate: Date().addingTimeInterval(-3600),
                unreadCount: 2,
                messages: [
                    Message(id: "1", conversationId: "1", content: "Hi Sarah! How did the first week go?", isFromTrainer: true, timestamp: Date().addingTimeInterval(-7200)),
                    Message(id: "2", conversationId: "1", content: "It was challenging but I loved it!", isFromTrainer: false, timestamp: Date().addingTimeInterval(-3600)),
                    Message(id: "3", conversationId: "1", content: "Thanks for the workout plan! I'm excited to start.", isFromTrainer: false, timestamp: Date().addingTimeInterval(-3600))
                ]
            ),
            Conversation(
                id: "2",
                clientId: "client2",
                clientName: "Marcus Chen",
                lastMessage: "Can we adjust the intensity for next week?",
                lastMessageDate: Date().addingTimeInterval(-7200),
                unreadCount: 1,
                messages: [
                    Message(id: "4", conversationId: "2", content: "How are you feeling after today's session?", isFromTrainer: true, timestamp: Date().addingTimeInterval(-14400)),
                    Message(id: "5", conversationId: "2", content: "Can we adjust the intensity for next week?", isFromTrainer: false, timestamp: Date().addingTimeInterval(-7200))
                ]
            ),
            Conversation(
                id: "3",
                clientId: "client3",
                clientName: "Emma Rodriguez",
                lastMessage: "Perfect! See you tomorrow.",
                lastMessageDate: Date().addingTimeInterval(-86400),
                unreadCount: 0,
                messages: [
                    Message(id: "6", conversationId: "3", content: "Ready for tomorrow's session?", isFromTrainer: true, timestamp: Date().addingTimeInterval(-90000)),
                    Message(id: "7", conversationId: "3", content: "Perfect! See you tomorrow.", isFromTrainer: false, timestamp: Date().addingTimeInterval(-86400))
                ]
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

// MARK: - Data Models
struct Conversation: Identifiable {
    let id: String
    let clientId: String
    let clientName: String
    let lastMessage: String
    let lastMessageDate: Date
    let unreadCount: Int
    let messages: [Message]
}

struct Message: Identifiable {
    let id: String
    let conversationId: String
    let content: String
    let isFromTrainer: Bool
    let timestamp: Date
} 