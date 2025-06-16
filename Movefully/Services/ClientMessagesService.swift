import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

    // MARK: - Client Messages Service
@MainActor
class ClientMessagesService: ObservableObject {
    @Published var conversation: Conversation?
    @Published var messages: [Message] = []
    @Published var trainerProfile: TrainerProfile?
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMoreMessages = true
    @Published var errorMessage = ""
    
    private let messagesService = MessagesService()
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private let messagesPerPage = 30
    
    // MARK: - Authentication Helper
    private func getCurrentClientId() throws -> String {
        guard let clientId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ClientMessagesService", code: 401, 
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        return clientId
    }
    
    // MARK: - Trainer Profile Operations
    
    /// Fetches trainer profile by trainer ID
    func fetchTrainerProfile(trainerId: String) async throws {
        print("🔍 ClientMessagesService: Fetching trainer profile for ID: \(trainerId)")
        
        do {
            let document = try await db.collection("trainers").document(trainerId).getDocument()
            
            guard document.exists else {
                print("❌ ClientMessagesService: Trainer profile not found for ID: \(trainerId)")
                throw NSError(domain: "ClientMessagesService", code: 404, 
                             userInfo: [NSLocalizedDescriptionKey: "Trainer profile not found"])
            }
            
            var profile = try document.data(as: TrainerProfile.self)
            profile.id = document.documentID
            
            await MainActor.run {
                self.trainerProfile = profile
                print("✅ ClientMessagesService: Trainer profile loaded: \(profile.name)")
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load trainer profile: \(error.localizedDescription)"
                print("❌ ClientMessagesService: Error fetching trainer profile: \(error)")
            }
            throw error
        }
    }
    
    // MARK: - Conversation Management
    
    /// Sets up conversation with the client's trainer
    func setupConversation(clientId: String, trainerId: String, clientName: String) async throws {
        print("🔍 ClientMessagesService: Setting up conversation for client: \(clientName)")
        
        isLoading = true
        errorMessage = ""
        
        do {
            // Get or create conversation
            let conversationId = try await messagesService.getOrCreateConversation(
                trainerId: trainerId,
                clientId: clientId,
                clientName: clientName
            )
            
            // Create conversation object
            let newConversation = Conversation(
                id: conversationId,
                trainerId: trainerId,
                clientId: clientId,
                clientName: clientName,
                lastMessage: "",
                lastMessageTime: Date(),
                unreadCount: 0
            )
            
            await MainActor.run {
                self.conversation = newConversation
                print("✅ ClientMessagesService: Conversation setup complete: \(conversationId)")
            }
            
            // Start listening for messages
            startMessageListener()
            
            // Load existing messages
            try await loadMessages()
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                print("❌ ClientMessagesService: Error setting up conversation: \(error)")
            }
            throw error
        }
    }
    
    // MARK: - Message Operations
    
    /// Loads existing messages for the conversation
    private func loadMessages() async throws {
        guard let conversation = conversation else {
            print("❌ ClientMessagesService: No conversation available for loading messages")
            return
        }
        
        print("🔍 ClientMessagesService: Loading messages for conversation: \(conversation.id)")
        
        do {
            let fetchedMessages = try await messagesService.fetchMessages(conversationId: conversation.id, limit: messagesPerPage, lastMessageId: nil)
            
            await MainActor.run {
                self.messages = fetchedMessages
                self.isLoading = false
                self.hasMoreMessages = fetchedMessages.count >= self.messagesPerPage
                print("✅ ClientMessagesService: Loaded \(fetchedMessages.count) messages")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                print("❌ ClientMessagesService: Error loading messages: \(error)")
            }
            throw error
        }
    }
    
    /// Loads more messages for pagination
    func loadMoreMessages() async throws {
        guard let conversation = conversation else {
            print("❌ ClientMessagesService: No conversation available for loading more messages")
            return
        }
        
        guard !isLoadingMore && hasMoreMessages && !messages.isEmpty else { return }
        
        isLoadingMore = true
        
        do {
            let oldestMessageId = messages.first?.id
            let olderMessages = try await messagesService.fetchMessages(
                conversationId: conversation.id, 
                limit: messagesPerPage, 
                lastMessageId: oldestMessageId
            )
            
            await MainActor.run {
                // Prepend older messages to the beginning of the array
                self.messages = olderMessages + self.messages
                self.isLoadingMore = false
                self.hasMoreMessages = olderMessages.count >= self.messagesPerPage
                print("✅ ClientMessagesService: Loaded \(olderMessages.count) more messages")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoadingMore = false
                print("❌ ClientMessagesService: Error loading more messages: \(error)")
            }
            throw error
        }
    }
    
    /// Sends a message as the client
    func sendMessage(text: String) async throws {
        guard let conversation = conversation else {
            throw NSError(domain: "ClientMessagesService", code: 400, 
                         userInfo: [NSLocalizedDescriptionKey: "No conversation available"])
        }
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw NSError(domain: "ClientMessagesService", code: 400, 
                         userInfo: [NSLocalizedDescriptionKey: "Message cannot be empty"])
        }
        
        print("🔍 ClientMessagesService: Sending message: \(trimmedText)")
        
        do {
            let clientId = try getCurrentClientId()
            
            try await messagesService.sendMessage(
                conversationId: conversation.id,
                trainerId: conversation.trainerId,
                clientId: clientId,
                clientName: conversation.clientName,
                text: trimmedText,
                senderId: clientId,
                senderType: "client"
            )
            
            print("✅ ClientMessagesService: Message sent successfully")
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                print("❌ ClientMessagesService: Error sending message: \(error)")
            }
            throw error
        }
    }
    
    /// Marks conversation as read
    func markAsRead() {
        guard let conversation = conversation else { return }
        
        Task {
            do {
                try await messagesService.markConversationAsRead(conversationId: conversation.id)
                print("✅ ClientMessagesService: Conversation marked as read")
            } catch {
                print("❌ ClientMessagesService: Error marking conversation as read: \(error)")
            }
        }
    }
    
    // MARK: - Real-time Listeners
    
    /// Starts listening for real-time message updates
    private func startMessageListener() {
        guard let conversation = conversation else {
            print("❌ ClientMessagesService: No conversation available for listener")
            return
        }
        
        print("🔍 ClientMessagesService: Starting message listener for conversation: \(conversation.id)")
        
        messagesService.listenToMessages(conversationId: conversation.id, limit: messagesPerPage) { [weak self] messages in
            Task { @MainActor in
                self?.messages = messages
                self?.isLoading = false
                self?.hasMoreMessages = messages.count >= self?.messagesPerPage ?? 30
                print("✅ ClientMessagesService: Real-time messages updated - \(messages.count) messages")
            }
        }
    }
    
    /// Stops all listeners
    func stopListeners() {
        messagesService.stopListeners()
        print("🛑 ClientMessagesService: All listeners stopped")
    }
    
    deinit {
        Task { @MainActor in
            stopListeners()
        }
    }
} 