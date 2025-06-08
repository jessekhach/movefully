import SwiftUI

// MARK: - Client Messages View
struct ClientMessagesView: View {
    @ObservedObject var viewModel: ClientViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var messageText = ""
    @State private var showingTrainerProfile = false
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
                            ForEach(viewModel.messages) { message in
                                MessageBubble(
                                    message: message,
                                    isFromCurrentUser: !message.isFromTrainer
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                        .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    }
                    .onTapGesture {
                        // Dismiss keyboard when tapping outside of text field
                        isMessageFieldFocused = false
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        // Auto-scroll to bottom when new message is added
                        if let lastMessage = viewModel.messages.last {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
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
            ClientViewTrainerProfileView(trainer: sampleTrainer)
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
                    AsyncImage(url: URL(string: sampleTrainer.profileImageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(MovefullyTheme.Colors.primaryTeal.opacity(0.2), lineWidth: 2)
                    )
                    
                    // Trainer info
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                        Text(sampleTrainer.name)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                            Circle()
                                .fill(MovefullyTheme.Colors.softGreen)
                                .frame(width: 8, height: 8)
                            
                            Text("Online")
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
    
    // MARK: - Sample Data
    private var sampleTrainer: TrainerProfile {
        TrainerProfile(
            id: "trainer1",
            name: "Alex Martinez",
            email: "alex@movefully.com",
            bio: "Certified movement coach specializing in mindful fitness and injury recovery. I believe every body is capable of beautiful movement.",
            profileImageUrl: nil,
            specialties: ["Mobility", "Recovery", "Mindful Movement"],
            yearsOfExperience: 8
        )
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