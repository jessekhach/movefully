import Foundation
import SwiftUI
import FirebaseAuth
import Combine

// MARK: - Conversation Detail View Model
@MainActor
class ConversationDetailViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage = ""
    @Published var newMessage = ""
    @Published var hasMoreMessages = true
    
    private let messagesService = MessagesService()
    private let conversation: Conversation
    private var cancellables = Set<AnyCancellable>()
    private let messagesPerPage = 30
    
    init(conversation: Conversation) {
        self.conversation = conversation
        setupRealtimeMessagesListener()
        loadMessages()
    }
    
    // MARK: - Authentication Helper
    private func getCurrentTrainerId() throws -> String {
        guard let trainerId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ConversationDetailViewModel", code: 401, 
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        return trainerId
    }
    
    // MARK: - Setup Real-time Listeners
    private func setupRealtimeMessagesListener() {
        let conversationId = conversation.id
        
        messagesService.listenToMessages(conversationId: conversationId, limit: messagesPerPage) { [weak self] messages in
            DispatchQueue.main.async {
                self?.messages = messages
                self?.isLoading = false
                self?.hasMoreMessages = messages.count >= self?.messagesPerPage ?? 30
            }
        }
    }
    
    // MARK: - Public Methods
    func loadMessages() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let conversationId = conversation.id
                let fetchedMessages = try await messagesService.fetchMessages(conversationId: conversationId, limit: messagesPerPage, lastMessageId: nil)
                
                await MainActor.run {
                    self.messages = fetchedMessages
                    self.isLoading = false
                    self.hasMoreMessages = fetchedMessages.count >= self.messagesPerPage
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                print("❌ ConversationDetailViewModel: Error loading messages: \(error)")
            }
        }
    }
    
    func loadMoreMessages() {
        guard !isLoadingMore && hasMoreMessages && !messages.isEmpty else { return }
        
        isLoadingMore = true
        
        Task {
            do {
                let conversationId = conversation.id
                let oldestMessageId = messages.first?.id
                
                let olderMessages = try await messagesService.fetchMessages(
                    conversationId: conversationId, 
                    limit: messagesPerPage, 
                    lastMessageId: oldestMessageId
                )
                
                await MainActor.run {
                    // Prepend older messages to the beginning of the array
                    self.messages = olderMessages + self.messages
                    self.isLoadingMore = false
                    self.hasMoreMessages = olderMessages.count >= self.messagesPerPage
                }
            } catch {
                await MainActor.run {
                    self.isLoadingMore = false
                    print("❌ ConversationDetailViewModel: Error loading more messages: \(error)")
                }
            }
        }
    }
    
    func sendMessage() {
        let text = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Clear message field immediately for better UX
        let messageToSend = text
        newMessage = ""
        
        Task {
            do {
                let trainerId = try getCurrentTrainerId()
                let conversationId = conversation.id
                
                try await messagesService.sendMessage(
                    conversationId: conversationId,
                    trainerId: conversation.trainerId,
                    clientId: conversation.clientId,
                    clientName: conversation.clientName,
                    text: messageToSend,
                    senderId: trainerId,
                    senderType: "trainer"
                )
                
                print("✅ ConversationDetailViewModel: Message sent successfully")
            } catch {
                await MainActor.run {
                    // Restore message text if sending failed
                    self.newMessage = messageToSend
                    self.errorMessage = error.localizedDescription
                }
                print("❌ ConversationDetailViewModel: Error sending message: \(error)")
            }
        }
    }
    
    func markAsRead() {
        guard conversation.unreadCount > 0 else { return }
        
        Task {
            do {
                try await messagesService.markConversationAsRead(conversationId: conversation.id)
                print("✅ ConversationDetailViewModel: Conversation marked as read")
            } catch {
                print("❌ ConversationDetailViewModel: Error marking conversation as read: \(error)")
            }
        }
    }
    
    deinit {
        messagesService.stopListeners()
    }
} 