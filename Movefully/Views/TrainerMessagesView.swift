import SwiftUI

struct TrainerMessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @State private var showingNewMessage = false
    @State private var selectedConversation: Conversation? = nil
    @State private var showingConversationDetail = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    // Header with improved spacing
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        HStack {
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                                Text("Conversations")
                                    .font(MovefullyTheme.Typography.title2)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Text("Stay connected with your wellness community")
                                    .font(MovefullyTheme.Typography.callout)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showingNewMessage = true
                            }) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                    .frame(width: 32, height: 32)
                                    .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                        .padding(.top, MovefullyTheme.Layout.paddingL)
                    }
                    
                    // Soft divider
                    Rectangle()
                        .fill(MovefullyTheme.Colors.divider)
                        .frame(height: 1)
                        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 1, x: 0, y: 1)
                    
                    // Content
                    if viewModel.isLoading {
                        VStack(spacing: MovefullyTheme.Layout.paddingL) {
                            Spacer(minLength: 300)
                            
                            ProgressView("Loading conversations...")
                                .font(MovefullyTheme.Typography.body)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .tint(MovefullyTheme.Colors.primaryTeal)
                            
                            Spacer(minLength: 300)
                        }
                        .frame(maxWidth: .infinity)
                    } else if viewModel.conversations.isEmpty {
                        // Empty State
                        VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                            Spacer(minLength: 150)
                            
                            Image(systemName: "message.circle")
                                .font(MovefullyTheme.Typography.largeTitle)
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal.opacity(0.6))
                            
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                Text("No conversations yet")
                                    .font(MovefullyTheme.Typography.title2)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Text("Start meaningful conversations with your clients to provide ongoing support and guidance on their wellness journey.")
                                    .font(MovefullyTheme.Typography.body)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            }
                            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                            
                            Button("Start Your First Conversation") {
                                showingNewMessage = true
                            }
                            .font(MovefullyTheme.Typography.buttonMedium)
                            .foregroundColor(.white)
                            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                            .padding(.vertical, MovefullyTheme.Layout.paddingL)
                            .background(
                                LinearGradient(
                                    colors: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.primaryTeal.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                            .shadow(color: MovefullyTheme.Colors.primaryTeal.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Spacer(minLength: 150)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                    } else {
                        // Conversations List
                        LazyVStack(spacing: MovefullyTheme.Layout.paddingM) {
                            ForEach(viewModel.conversations) { conversation in
                                ConversationRowView(conversation: conversation)
                                    .onTapGesture {
                                        selectedConversation = conversation
                                        showingConversationDetail = true
                                    }
                            }
                        }
                        .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                        .padding(.vertical, MovefullyTheme.Layout.paddingL)
                        .padding(.bottom, MovefullyTheme.Layout.paddingXXL) // Extra bottom padding for better scrolling
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .movefullyBackground()
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                viewModel.refreshConversations()
            }
        }
        .onAppear {
            viewModel.loadConversations()
        }
        .sheet(isPresented: $showingNewMessage) {
            NewMessageView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingConversationDetail) {
            if let conversation = selectedConversation {
                ConversationDetailView(conversation: conversation)
                    .environmentObject(viewModel)
            }
        }
    }
}

// MARK: - Conversation Row View
struct ConversationRowView: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            // Profile Image
            Circle()
                .fill(MovefullyTheme.Colors.primaryTeal.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(conversation.clientName.prefix(1)))
                        .font(MovefullyTheme.Typography.title3)
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                )
            
            // Content
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                HStack {
                    Text(conversation.clientName)
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text(formatMessageTime(conversation.lastMessageTime))
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                HStack {
                    Text(conversation.lastMessage)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                            .padding(.vertical, MovefullyTheme.Layout.paddingXS)
                            .background(MovefullyTheme.Colors.primaryTeal)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingM)
        .padding(.vertical, MovefullyTheme.Layout.paddingS)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 2, x: 0, y: 1)
    }
    
    private func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDate(date, inSameDayAs: Date()) {
            formatter.timeStyle = .short
        } else if calendar.isDate(date, inSameDayAs: Date().addingTimeInterval(-86400)) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - New Message View
struct NewMessageView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: MessagesViewModel
    @State private var selectedClient: Client? = nil
    @State private var messageText: String = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("New Message")
                        .font(MovefullyTheme.Typography.title3)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Button("Send") {
                        sendMessage()
                    }
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(canSend ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.inactive)
                    .disabled(!canSend || isLoading)
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.vertical, MovefullyTheme.Layout.paddingM)
                
                // Client Selection
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                    Text("To:")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: MovefullyTheme.Layout.paddingS) {
                            ForEach(viewModel.availableClients) { client in
                                ClientSelectionChip(
                                    client: client,
                                    isSelected: selectedClient?.id == client.id
                                ) {
                                    selectedClient = client
                                }
                            }
                        }
                        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    }
                }
                
                // Message Input
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                    Text("Message:")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    TextField("Type your message...", text: $messageText, axis: .vertical)
                        .font(MovefullyTheme.Typography.body)
                        .padding(MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                        .overlay(
                            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                                .stroke(MovefullyTheme.Colors.divider, lineWidth: 1)
                        )
                        .lineLimit(5...10)
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                
                Spacer()
            }
            .movefullyBackground()
            .navigationBarHidden(true)
        }
    }
    
    private var canSend: Bool {
        selectedClient != nil && !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func sendMessage() {
        guard let client = selectedClient else { return }
        
        isLoading = true
        
        viewModel.sendMessage(to: client, text: messageText) {
            isLoading = false
            dismiss()
        }
    }
}

// MARK: - Client Selection Chip
struct ClientSelectionChip: View {
    let client: Client
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                Circle()
                    .fill(isSelected ? .white : MovefullyTheme.Colors.primaryTeal.opacity(0.2))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(String(client.name.prefix(1)))
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(isSelected ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.primaryTeal)
                    )
                
                Text(client.name)
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(isSelected ? .white : MovefullyTheme.Colors.textPrimary)
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            .padding(.vertical, MovefullyTheme.Layout.paddingM)
            .background(isSelected ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
            .overlay(
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                    .stroke(MovefullyTheme.Colors.primaryTeal, lineWidth: isSelected ? 0 : 1)
            )
            .shadow(color: isSelected ? MovefullyTheme.Colors.primaryTeal.opacity(0.3) : MovefullyTheme.Effects.cardShadow, 
                   radius: isSelected ? 6 : 3, x: 0, y: isSelected ? 3 : 2)
        }
    }
}

// MARK: - Conversation Detail View
struct ConversationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: MessagesViewModel
    let conversation: Conversation
    @State private var newMessage: String = ""
    @State private var messages: [Message] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Button("Back") {
                        dismiss()
                    }
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    
                    Spacer()
                    
                    VStack {
                        Text(conversation.clientName)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Online")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.success)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Menu actions
                    }) {
                        Image(systemName: "ellipsis")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    }
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.vertical, MovefullyTheme.Layout.paddingM)
                .background(MovefullyTheme.Colors.cardBackground)
                
                // Messages
                ScrollView {
                    LazyVStack(spacing: MovefullyTheme.Layout.paddingS) {
                        ForEach(messages) { message in
                            MessageBubbleView(message: message)
                        }
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Message Input
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    MovefullyTextEditor(
                        placeholder: "Type a message...",
                        text: $newMessage,
                        minLines: 1,
                        maxLines: 4
                    )
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(MovefullyTheme.Typography.buttonMedium)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(
                                        newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                                        MovefullyTheme.Colors.inactive : 
                                        MovefullyTheme.Colors.primaryTeal
                                    )
                            )
                    }
                    .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.vertical, MovefullyTheme.Layout.paddingM)
                .background(MovefullyTheme.Colors.backgroundPrimary)
            }
            .movefullyBackground()
            .navigationBarHidden(true)
        }
        .onAppear {
            loadMessages()
        }
    }
    
    private func loadMessages() {
        // Load sample messages for demo
        messages = Message.sampleMessages
    }
    
    private func sendMessage() {
        let text = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let message = Message(
            id: UUID().uuidString,
            text: text,
            isFromTrainer: true,
            timestamp: Date()
        )
        
        messages.append(message)
        newMessage = ""
    }
}

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromTrainer {
                Spacer()
                
                VStack(alignment: .trailing, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text(message.text)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                        .padding(.vertical, MovefullyTheme.Layout.paddingS)
                        .background(MovefullyTheme.Colors.primaryTeal)
                        .clipShape(
                            .rect(
                                topLeadingRadius: MovefullyTheme.Layout.cornerRadiusM,
                                bottomLeadingRadius: MovefullyTheme.Layout.cornerRadiusM,
                                bottomTrailingRadius: MovefullyTheme.Layout.cornerRadiusXS,
                                topTrailingRadius: MovefullyTheme.Layout.cornerRadiusM
                            )
                        )
                    
                    Text(formatMessageTime(message.timestamp))
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            } else {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text(message.text)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                        .padding(.vertical, MovefullyTheme.Layout.paddingS)
                        .background(MovefullyTheme.Colors.cardBackground)
                        .clipShape(
                            .rect(
                                topLeadingRadius: MovefullyTheme.Layout.cornerRadiusXS,
                                bottomLeadingRadius: MovefullyTheme.Layout.cornerRadiusM,
                                bottomTrailingRadius: MovefullyTheme.Layout.cornerRadiusM,
                                topTrailingRadius: MovefullyTheme.Layout.cornerRadiusM
                            )
                        )
                    
                    Text(formatMessageTime(message.timestamp))
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
        }
    }
    
    private func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDate(date, inSameDayAs: Date()) {
            formatter.timeStyle = .short
        } else if calendar.isDate(date, inSameDayAs: Date().addingTimeInterval(-86400)) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
        }
        
        return formatter.string(from: date)
    }
} 