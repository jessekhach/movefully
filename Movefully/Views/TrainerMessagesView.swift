import SwiftUI
import Foundation

struct TrainerMessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    
    var body: some View {
        MovefullyTrainerNavigation(
            title: "Conversations",
            showProfileButton: false
        ) {
            // Search field with tighter spacing for trainer views
            MovefullySearchField(
                placeholder: "Search conversations...",
                text: $viewModel.searchText
            )
            
            // Messages content
            messagesContent
        }
    }
    
    // MARK: - Messages Content
    @ViewBuilder
    private var messagesContent: some View {
        if viewModel.conversations.isEmpty {
            MovefullyEmptyState(
                icon: "message.circle",
                title: "No conversations yet",
                description: "Your conversations with clients will appear here once they're created automatically.",
                actionButton: nil
            )
            .frame(maxHeight: .infinity)
        } else {
            ForEach(viewModel.conversations, id: \.id) { conversation in
                NavigationLink(destination: TrainerConversationDetailView(conversation: conversation)) {
                    ConversationRowView(conversation: conversation)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Conversation Row View
struct ConversationRowView: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            // Client Avatar
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            MovefullyTheme.Colors.primaryTeal.opacity(0.3),
                            MovefullyTheme.Colors.primaryTeal.opacity(0.15)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)
                .overlay(
                    Text(String(conversation.clientName.prefix(1)))
                        .font(MovefullyTheme.Typography.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                )
                .overlay(
                    Circle()
                        .stroke(MovefullyTheme.Colors.primaryTeal.opacity(0.2), lineWidth: 2)
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
                        .multilineTextAlignment(.leading)
                    
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
            
            // Navigation Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
        }
        .padding(MovefullyTheme.Layout.paddingL)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .shadow(
            color: MovefullyTheme.Effects.cardShadow.opacity(0.6), 
            radius: 4, 
            x: 0, 
            y: 2
        )
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

// MARK: - Conversation Detail View
struct TrainerConversationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let conversation: Conversation
    @State private var newMessage: String = ""
    @State private var messages: [Message] = []
    @FocusState private var isMessageFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            customHeader
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: MovefullyTheme.Layout.paddingM) {
                        ForEach(messages) { message in
                            TrainerMessageBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    .padding(.vertical, MovefullyTheme.Layout.paddingL)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    isMessageFieldFocused = false
                }
                .onChange(of: messages.count) { _ in
                    if let lastMessage = messages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message Input
            messageInputSection
        }
        .background(MovefullyTheme.Colors.backgroundPrimary.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            loadMessages()
        }
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        VStack(spacing: 0) {
            HStack {
                // Back button
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
                
                Spacer()
                
                // Client name (first name only)
                VStack(spacing: MovefullyTheme.Layout.paddingXS) {
                    Text(clientFirstName)
                        .font(MovefullyTheme.Typography.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    // Status indicator
                    HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                        Circle()
                            .fill(MovefullyTheme.Colors.softGreen)
                            .frame(width: 6, height: 6)
                        
                        Text("Active")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Profile button
                NavigationLink(destination: ReadOnlyClientProfileView(client: clientFromConversation)) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            .padding(.vertical, MovefullyTheme.Layout.paddingM)
            .background(MovefullyTheme.Colors.cardBackground)
            
            Divider()
                .background(MovefullyTheme.Colors.divider)
        }
    }
    
    // Helper to get first name
    private var clientFirstName: String {
        conversation.clientName.components(separatedBy: " ").first ?? conversation.clientName
    }
    
    // Helper to create client object from conversation
    private var clientFromConversation: Client {
        return Client(
            id: UUID().uuidString,
            name: conversation.clientName,
            email: "\(conversation.clientName.lowercased().replacingOccurrences(of: " ", with: "."))@example.com",
            trainerId: "trainer1", // Mock trainer ID
            status: .active,
            joinedDate: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
            profileImageUrl: nil,
            height: "5'6\"", // Mock height data
            weight: "145 lbs", // Mock weight data
            goal: "Improve overall flexibility and build core strength for better posture at work", // Mock goal
            injuries: "Previous knee injury (2019) - cleared by PT", // Mock injuries
            preferredCoachingStyle: .hybrid,
            lastWorkoutDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            lastActivityDate: Date(),
            currentPlanId: "plan1",
            totalWorkoutsCompleted: 24
        )
    }
    
    // MARK: - Message Input Section
    private var messageInputSection: some View {
        VStack(spacing: 0) {
            Divider()
                .background(MovefullyTheme.Colors.divider)
            
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                // Message text field
                TextField("Type your message...", text: $newMessage, axis: .vertical)
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                    .padding(.vertical, MovefullyTheme.Layout.paddingS)
                    .background(MovefullyTheme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                    .lineLimit(1...4)
                    .focused($isMessageFieldFocused)
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(
                                    newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                                    ? MovefullyTheme.Colors.textSecondary.opacity(0.3)
                                    : MovefullyTheme.Colors.primaryTeal
                                )
                        )
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .scaleEffect(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: newMessage.isEmpty)
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            .padding(.vertical, MovefullyTheme.Layout.paddingM)
            .background(MovefullyTheme.Colors.cardBackground)
        }
    }
    
    // MARK: - Actions
    private func loadMessages() {
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
        isMessageFieldFocused = false
    }
}

// MARK: - Message Bubble View
struct TrainerMessageBubbleView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromTrainer {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text(message.text)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                        .padding(.vertical, MovefullyTheme.Layout.paddingS)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MovefullyTheme.Colors.primaryTeal,
                                    MovefullyTheme.Colors.primaryTeal.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(
                            .rect(
                                topLeadingRadius: MovefullyTheme.Layout.cornerRadiusL,
                                bottomLeadingRadius: MovefullyTheme.Layout.cornerRadiusL,
                                bottomTrailingRadius: MovefullyTheme.Layout.cornerRadiusXS,
                                topTrailingRadius: MovefullyTheme.Layout.cornerRadiusL
                            )
                        )
                    
                    HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                        Text(formatTime(message.timestamp))
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(MovefullyTheme.Colors.softGreen)
                    }
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
                                bottomLeadingRadius: MovefullyTheme.Layout.cornerRadiusL,
                                bottomTrailingRadius: MovefullyTheme.Layout.cornerRadiusL,
                                topTrailingRadius: MovefullyTheme.Layout.cornerRadiusL
                            )
                        )
                    
                    Text(formatTime(message.timestamp))
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                Spacer(minLength: 60)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

