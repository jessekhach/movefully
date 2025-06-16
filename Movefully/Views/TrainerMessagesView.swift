import SwiftUI
import Foundation

struct TrainerMessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    
    var body: some View {
        MovefullyTrainerNavigation(
            title: "Conversations",
            showProfileButton: false
        ) {
            // Search field - only show when there are conversations to search
            if !viewModel.conversations.isEmpty {
                MovefullySearchField(
                    placeholder: "Search conversations...",
                    text: $viewModel.searchText
                )
            }
            
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
            ForEach(viewModel.filteredConversations, id: \.id) { conversation in
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
    @StateObject private var viewModel: ConversationDetailViewModel
    @StateObject private var clientDataService = ClientDataService()
    @FocusState private var isMessageFieldFocused: Bool
    
    // Real client data state
    @State private var clientData: Client?
    @State private var isLoadingClient = false
    @State private var clientLoadError: String?
    @State private var previousMessageCount = 0
    @State private var isLoadingMoreMessages = false
    @State private var scrollAnchorMessageId: String? = nil
    
    init(conversation: Conversation) {
        self.conversation = conversation
        self._viewModel = StateObject(wrappedValue: ConversationDetailViewModel(conversation: conversation))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            customHeader
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: MovefullyTheme.Layout.paddingM) {
                        // Load More button at the top
                        if viewModel.hasMoreMessages && !viewModel.messages.isEmpty {
                            Button(action: {
                                print("🔄 LOAD MORE: Starting load more process")
                                print("🔄 LOAD MORE: Current message count: \(viewModel.messages.count)")
                                
                                // Find a stable anchor message (not the first one, but one that's more likely to stay visible)
                                if viewModel.messages.count > 5 {
                                    scrollAnchorMessageId = viewModel.messages[5].id // Use 6th message as anchor
                                    print("🔄 LOAD MORE: Using anchor message: \(scrollAnchorMessageId!)")
                                } else if let firstMessage = viewModel.messages.first {
                                    scrollAnchorMessageId = firstMessage.id
                                    print("🔄 LOAD MORE: Using first message as anchor: \(scrollAnchorMessageId!)")
                                }
                                
                                isLoadingMoreMessages = true
                                print("🔄 LOAD MORE: Calling viewModel.loadMoreMessages()")
                                viewModel.loadMoreMessages()
                            }) {
                                HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                    if viewModel.isLoadingMore {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(MovefullyTheme.Colors.primaryTeal)
                                    } else {
                                        Image(systemName: "arrow.up.circle")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                    }
                                    
                                    Text(viewModel.isLoadingMore ? "Loading..." : "Load More Messages")
                                        .font(MovefullyTheme.Typography.body)
                                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                }
                                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                                .padding(.vertical, MovefullyTheme.Layout.paddingM)
                                .background(MovefullyTheme.Colors.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                                .shadow(color: MovefullyTheme.Effects.cardShadow.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .disabled(viewModel.isLoadingMore)
                            .padding(.bottom, MovefullyTheme.Layout.paddingM)
                        }
                        
                        ForEach(viewModel.messages) { message in
                            TrainerMessageBubbleView(message: message)
                                .id(message.id)
                        }
                        
                        // Invisible spacer at the very bottom for scroll targeting
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    .padding(.vertical, MovefullyTheme.Layout.paddingL)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    isMessageFieldFocused = false
                }
                .onAppear {
                    // Auto-scroll to bottom when view first appears
                    if !viewModel.messages.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    previousMessageCount = viewModel.messages.count
                }
                .onChange(of: viewModel.messages.count) {
                    // Handle message count changes with immediate scroll preservation
                    let newMessageCount = viewModel.messages.count
                    
                    print("📊 MESSAGE COUNT CHANGE: \(previousMessageCount) -> \(newMessageCount)")
                    print("📊 MESSAGE COUNT CHANGE: isLoadingMoreMessages = \(isLoadingMoreMessages)")
                    
                    if isLoadingMoreMessages {
                        // We're loading more messages - immediately scroll to anchor without animation
                        print("📊 MESSAGE COUNT CHANGE: Loading more messages - restoring to anchor")
                        
                        if let anchorId = scrollAnchorMessageId {
                            print("🔄 LOAD MORE: Immediately scrolling to anchor: \(anchorId)")
                            
                            // Scroll immediately without animation to prevent visible jump
                            proxy.scrollTo(anchorId, anchor: .center)
                            print("🔄 LOAD MORE: Instant scroll command executed")
                        }
                        
                        // Reset flags
                        isLoadingMoreMessages = false
                        scrollAnchorMessageId = nil
                        previousMessageCount = newMessageCount
                        
                        print("📊 MESSAGE COUNT CHANGE: Flags reset, instant scroll restoration complete")
                        
                    } else if newMessageCount > previousMessageCount {
                        // New messages were added (not loaded from history), auto-scroll to bottom
                        print("📊 MESSAGE COUNT CHANGE: New messages detected - auto-scrolling to bottom")
                        if !viewModel.messages.isEmpty {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                        previousMessageCount = newMessageCount
                    } else {
                        print("📊 MESSAGE COUNT CHANGE: Message count decreased or stayed same - no action")
                        previousMessageCount = newMessageCount
                    }
                }
            }
            
            // Message Input
            messageInputSection
        }
        .background(MovefullyTheme.Colors.backgroundPrimary.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            viewModel.markAsRead()
            loadClientData()
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
                            .fill(clientData?.status == .active ? MovefullyTheme.Colors.softGreen : MovefullyTheme.Colors.mediumGray)
                            .frame(width: 6, height: 6)
                        
                        Text(clientData?.status.rawValue.capitalized ?? "Loading...")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Profile button
                if let client = clientData {
                    NavigationLink(destination: ReadOnlyClientProfileView(client: client)) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    }
                } else {
                    // Loading or error state - disabled button
                    Button(action: { }) {
                        Image(systemName: isLoadingClient ? "person.circle" : "person.circle.fill.badge.exclamationmark")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(isLoadingClient ? MovefullyTheme.Colors.textSecondary : MovefullyTheme.Colors.warmOrange)
                    }
                    .disabled(true)
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
    
    // MARK: - Client Data Loading
    private func loadClientData() {
        Task {
            do {
                isLoadingClient = true
                clientLoadError = nil
                print("🔍 TrainerConversationDetailView: Loading client data for ID: \(conversation.clientId)")
                
                let client = try await clientDataService.fetchClient(clientId: conversation.clientId)
                
                await MainActor.run {
                    self.clientData = client
                    self.isLoadingClient = false
                    print("✅ TrainerConversationDetailView: Successfully loaded client: \(client.name)")
                }
            } catch {
                await MainActor.run {
                    self.clientLoadError = error.localizedDescription
                    self.isLoadingClient = false
                    print("❌ TrainerConversationDetailView: Failed to load client: \(error)")
                }
            }
        }
    }
    
    // MARK: - Message Input Section
    private var messageInputSection: some View {
        VStack(spacing: 0) {
            Divider()
                .background(MovefullyTheme.Colors.divider)
            
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                // Message text field
                TextField("Type your message...", text: $viewModel.newMessage, axis: .vertical)
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                    .padding(.vertical, MovefullyTheme.Layout.paddingS)
                    .background(MovefullyTheme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                    .lineLimit(1...4)
                    .focused($isMessageFieldFocused)
                
                // Send button
                Button(action: viewModel.sendMessage) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(
                                    viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                                    ? MovefullyTheme.Colors.textSecondary.opacity(0.3)
                                    : MovefullyTheme.Colors.primaryTeal
                                )
                        )
                }
                .disabled(viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .scaleEffect(viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.newMessage.isEmpty)
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            .padding(.vertical, MovefullyTheme.Layout.paddingM)
            .background(MovefullyTheme.Colors.cardBackground)
        }
    }
    
    // MARK: - Actions
    // All message operations now handled by ConversationDetailViewModel
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

