import Foundation
import SwiftUI
import FirebaseAuth
import Combine

// MARK: - Messages View Model
@MainActor
class MessagesViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var availableClients: [Client] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var searchText: String = ""
    
    private let messagesService = MessagesService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupRealtimeListeners()
    }
    
    // MARK: - Authentication Helper
    private func getCurrentTrainerId() throws -> String {
        guard let trainerId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "MessagesViewModel", code: 401, 
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        return trainerId
    }
    
    // MARK: - Setup Real-time Listeners
    private func setupRealtimeListeners() {
        do {
            let trainerId = try getCurrentTrainerId()
            
            // First, load conversations immediately (including auto-generated ones)
            loadConversations()
            
            // Then set up real-time listener for updates to existing conversations
            messagesService.listenToTrainerConversations(trainerId) { [weak self] existingConversations in
                Task { @MainActor in
                    // Refresh the full conversation list (existing + auto-generated) when Firebase updates
                    self?.loadConversations()
                }
            }
        } catch {
            print("❌ MessagesViewModel: Error setting up listeners: \(error)")
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Public Methods
    func loadConversations() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let trainerId = try getCurrentTrainerId()
                let fetchedConversations = try await messagesService.fetchTrainerConversations(trainerId)
                
                await MainActor.run {
                    self.conversations = fetchedConversations
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                print("❌ MessagesViewModel: Error loading conversations: \(error)")
            }
        }
    }
    
    func refreshConversations() {
        loadConversations()
    }
    
    func sendMessage(to client: Client, text: String, completion: @escaping () -> Void) {
        Task {
            do {
                let trainerId = try getCurrentTrainerId()
                
                // Get or create conversation
                let conversationId = try await messagesService.getOrCreateConversation(
                    trainerId: trainerId,
                    clientId: client.id,
                    clientName: client.name
                )
                
                // Send the message
                try await messagesService.sendMessage(
                    conversationId: conversationId,
                    trainerId: trainerId,
                    clientId: client.id,
                    clientName: client.name,
                    text: text,
                    senderId: trainerId,
                    senderType: "trainer"
                )
                
                await MainActor.run {
                    completion()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    completion()
                }
                print("❌ MessagesViewModel: Error sending message: \(error)")
            }
        }
    }
    
    // MARK: - Conversation-specific Methods
    func markConversationAsRead(_ conversation: Conversation) {
        Task {
            do {
                try await messagesService.markConversationAsRead(conversationId: conversation.id)
            } catch {
                print("❌ MessagesViewModel: Error marking conversation as read: \(error)")
            }
        }
    }
    
    // MARK: - Filtered Conversations for Search
    var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return conversations
        } else {
            return conversations.filter { conversation in
                conversation.clientName.localizedCaseInsensitiveContains(searchText) ||
                conversation.lastMessage.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    deinit {
        messagesService.stopListeners()
    }
} 