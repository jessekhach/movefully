import SwiftUI

// MARK: - Client Messages View
struct ClientMessagesView: View {
    @ObservedObject var viewModel: ClientViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var messageText = ""
    @State private var showingTrainerProfile = false
    @State private var previousMessageCount = 0
    @State private var isLoadingMoreMessages = false
    @State private var scrollAnchorMessageId: String? = nil
    @FocusState private var isMessageFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom header with trainer info and profile button
                customHeaderSection
                
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: MovefullyTheme.Layout.paddingM) {
                            // Load More button at the top
                            if viewModel.clientMessagesService.hasMoreMessages && !viewModel.messages.isEmpty {
                                Button(action: {
                                    print("🔄 CLIENT LOAD MORE: Starting load more process")
                                    print("🔄 CLIENT LOAD MORE: Current message count: \(viewModel.messages.count)")
                                    
                                    // Find a stable anchor message (not the first one, but one that's more likely to stay visible)
                                    if viewModel.messages.count > 5 {
                                        scrollAnchorMessageId = viewModel.messages[5].id // Use 6th message as anchor
                                        print("🔄 CLIENT LOAD MORE: Using anchor message: \(scrollAnchorMessageId!)")
                                    } else if let firstMessage = viewModel.messages.first {
                                        scrollAnchorMessageId = firstMessage.id
                                        print("🔄 CLIENT LOAD MORE: Using first message as anchor: \(scrollAnchorMessageId!)")
                                    }
                                    
                                    isLoadingMoreMessages = true
                                    print("🔄 CLIENT LOAD MORE: Calling viewModel.loadMoreMessages()")
                                    viewModel.loadMoreMessages()
                                }) {
                                    HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                        if viewModel.clientMessagesService.isLoadingMore {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .tint(MovefullyTheme.Colors.primaryTeal)
                                        } else {
                                            Image(systemName: "arrow.up.circle")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                        }
                                        
                                        Text(viewModel.clientMessagesService.isLoadingMore ? "Loading..." : "Load More Messages")
                                            .font(MovefullyTheme.Typography.body)
                                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                    }
                                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                                    .background(MovefullyTheme.Colors.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                                    .shadow(color: MovefullyTheme.Effects.cardShadow.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                                .disabled(viewModel.clientMessagesService.isLoadingMore)
                                .padding(.bottom, MovefullyTheme.Layout.paddingM)
                            }
                            
                            ForEach(viewModel.messages) { message in
                                MessageBubble(
                                    message: message,
                                    isFromCurrentUser: !message.isFromTrainer
                                )
                                .id(message.id)
                            }
                            
                            // Invisible spacer at the very bottom for scroll targeting
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                        }
                        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                        .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    }
                    .onTapGesture {
                        // Dismiss keyboard when tapping outside of text field
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
                        
                        print("📊 CLIENT MESSAGE COUNT CHANGE: \(previousMessageCount) -> \(newMessageCount)")
                        print("📊 CLIENT MESSAGE COUNT CHANGE: isLoadingMoreMessages = \(isLoadingMoreMessages)")
                        
                        if isLoadingMoreMessages {
                            // We're loading more messages - immediately scroll to anchor without animation
                            print("📊 CLIENT MESSAGE COUNT CHANGE: Loading more messages - restoring to anchor")
                            
                            if let anchorId = scrollAnchorMessageId {
                                print("🔄 CLIENT LOAD MORE: Immediately scrolling to anchor: \(anchorId)")
                                
                                // Scroll immediately without animation to prevent visible jump
                                proxy.scrollTo(anchorId, anchor: .center)
                                print("🔄 CLIENT LOAD MORE: Instant scroll command executed")
                            }
                            
                            // Reset flags
                            isLoadingMoreMessages = false
                            scrollAnchorMessageId = nil
                            previousMessageCount = newMessageCount
                            
                            print("📊 CLIENT MESSAGE COUNT CHANGE: Flags reset, instant scroll restoration complete")
                            
                        } else if newMessageCount > previousMessageCount {
                            // New messages were added (not loaded from history), auto-scroll to bottom
                            print("📊 CLIENT MESSAGE COUNT CHANGE: New messages detected - auto-scrolling to bottom")
                            if !viewModel.messages.isEmpty {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                            previousMessageCount = newMessageCount
                        } else {
                            print("📊 CLIENT MESSAGE COUNT CHANGE: Message count decreased or stayed same - no action")
                            previousMessageCount = newMessageCount
                        }
                    }
                }
                
                // Message input
                messageInputSection
            }
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingTrainerProfile) {
            if let trainer = viewModel.clientMessagesService.trainerProfile {
                ClientViewTrainerProfileView(trainer: trainer)
            } else {
                // Fallback view while trainer profile is loading
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading trainer profile...")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(MovefullyTheme.Colors.backgroundPrimary)
            }
        }
    }
    
    // MARK: - Custom Header Section
    private var customHeaderSection: some View {
        VStack(spacing: 0) {
            Button(action: {
                // Dismiss keyboard and show trainer profile
                isMessageFieldFocused = false
                showingTrainerProfile = true
            }) {
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Trainer avatar
                    if let trainer = viewModel.clientMessagesService.trainerProfile {
                        AsyncImage(url: URL(string: trainer.profileImageUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            // Show trainer initials if no profile image
                            ZStack {
                                Circle()
                                    .fill(MovefullyTheme.Colors.primaryTeal.opacity(0.8))
                                
                                Text(trainerInitials(for: trainer.name))
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(MovefullyTheme.Colors.primaryTeal.opacity(0.2), lineWidth: 2)
                        )
                    } else {
                        // Loading placeholder
                        Circle()
                            .fill(MovefullyTheme.Colors.backgroundSecondary)
                            .frame(width: 50, height: 50)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    }
                    
                    // Trainer info
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                        Text(viewModel.clientMessagesService.trainerProfile?.name ?? "Loading...")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            
                            Text(viewModel.clientMessagesService.trainerProfile?.location ?? "Loading location...")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Profile access indicator
                    Image(systemName: "chevron.right")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.vertical, MovefullyTheme.Layout.paddingM)
                .background(MovefullyTheme.Colors.cardBackground)
                .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 2, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
                .background(MovefullyTheme.Colors.divider)
        }
    }
    
    // MARK: - Message Input Section
    private var messageInputSection: some View {
        VStack(spacing: 0) {
            Divider()
                .background(MovefullyTheme.Colors.divider)
            
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                // Message text field
                TextField("Type your message...", text: $messageText, axis: .vertical)
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
                    Image(systemName: "arrow.up.circle.fill")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                                       ? MovefullyTheme.Colors.mediumGray 
                                       : MovefullyTheme.Colors.primaryTeal)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            .padding(.vertical, MovefullyTheme.Layout.paddingM)
            .background(MovefullyTheme.Colors.cardBackground)
        }
    }
    
    // MARK: - Actions
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        viewModel.sendMessage(trimmedText)
        messageText = ""
        isMessageFieldFocused = false
    }
    
    // MARK: - Helper Functions
    
    /// Generates initials from trainer name
    private func trainerInitials(for name: String) -> String {
        let components = name.split(separator: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }
        return initials.prefix(2).joined().uppercased()
    }
}

// MARK: - Message Bubble Component
struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                // Message content
                Text(message.text)
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(isFromCurrentUser ? .white : MovefullyTheme.Colors.textPrimary)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                    .padding(.vertical, MovefullyTheme.Layout.paddingS)
                    .background(
                        RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                            .fill(isFromCurrentUser 
                                  ? MovefullyTheme.Colors.primaryTeal 
                                  : MovefullyTheme.Colors.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                            .stroke(
                                isFromCurrentUser 
                                ? Color.clear 
                                : MovefullyTheme.Colors.divider,
                                lineWidth: 1
                            )
                    )
                
                // Timestamp
                Text(formatTimestamp(message.timestamp))
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingS)
            }
            
            if !isFromCurrentUser {
                Spacer(minLength: 50)
            }
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Conversation Starter Component
struct ConversationStarter: View {
    let suggestions = [
        "How did today's workout feel?",
        "I have a question about form",
        "Can we adjust this week's plan?",
        "I'm feeling sore, is that normal?"
    ]
    
    let onSuggestionTapped: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            Text("Quick questions:")
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: MovefullyTheme.Layout.paddingS) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(suggestion) {
                        onSuggestionTapped(suggestion)
                    }
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                    .padding(.vertical, MovefullyTheme.Layout.paddingS)
                    .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
        }
    }
}

// MARK: - Empty Messages State
struct EmptyMessagesState: View {
    let onStartConversation: () -> Void
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingXL) {
            Spacer()
            
            Image(systemName: "message.circle")
                .font(MovefullyTheme.Typography.largeTitle)
                .foregroundColor(MovefullyTheme.Colors.primaryTeal.opacity(0.6))
            
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                Text("Start a conversation")
                    .font(MovefullyTheme.Typography.title2)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text("Your trainer is here to support you on your movement journey. Feel free to ask questions, share how you're feeling, or just say hello!")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            }
            
            ConversationStarter { suggestion in
                onStartConversation()
            }
            
            Spacer()
        }
    }
}

#Preview {
    ClientMessagesView(viewModel: ClientViewModel())
} 