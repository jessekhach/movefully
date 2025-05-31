import SwiftUI
import FirebaseAuth

struct TrainerDashboardView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Clients Tab
                ClientManagementView()
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "person.2.fill" : "person.2")
                        Text("Clients")
                    }
                    .tag(0)
                
                // Plans Tab
                PlansManagementView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "calendar.badge.plus" : "calendar")
                        Text("Plans")
                    }
                    .tag(1)
                
                // Resources Tab
                ExerciseLibraryView()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "books.vertical.fill" : "books.vertical")
                        Text("Resources")
                    }
                    .tag(2)
                
                // Messages Tab
                MessagesManagementView()
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "message.fill" : "message")
                        Text("Messages")
                    }
                    .tag(3)
                
                // Profile Tab
                TrainerProfileView()
                    .tabItem {
                        Image(systemName: selectedTab == 4 ? "person.crop.circle.fill" : "person.crop.circle")
                        Text("Profile")
                    }
                    .tag(4)
            }
            .accentColor(MovefullyTheme.Colors.primaryTeal)
            .onAppear {
                // Customize tab bar appearance with soft theme
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0) // #FAFAFA
                
                // Unselected item appearance
                appearance.stackedLayoutAppearance.normal.iconColor = UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1.0)
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                    .foregroundColor: UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1.0),
                    .font: UIFont.systemFont(ofSize: 10, weight: .medium)
                ]
                
                // Selected item appearance - soft teal
                appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.34, green: 0.76, blue: 0.78, alpha: 1.0)
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                    .foregroundColor: UIColor(red: 0.34, green: 0.76, blue: 0.78, alpha: 1.0),
                    .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
                ]
                
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .movefullyBackground()
    }
}

// MARK: - Messages Management View
struct MessagesManagementView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @State private var searchText = ""
    @State private var selectedConversation: Conversation?
    @State private var showingNewMessage = false
    
    var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return viewModel.conversations.sorted { $0.lastMessageDate > $1.lastMessageDate }
        } else {
            return viewModel.conversations.filter { conversation in
                conversation.clientName.localizedCaseInsensitiveContains(searchText) ||
                conversation.lastMessage.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    HStack(spacing: MovefullyTheme.Layout.paddingL) {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            Text("Conversations")
                                .font(MovefullyTheme.Typography.title1)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Text("Stay connected with your wellness community")
                                .font(MovefullyTheme.Typography.callout)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingNewMessage = true
                        }) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                .background(
                                    Circle()
                                        .fill(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                )
                        }
                    }
                    
                    // Search Bar
                    VStack(spacing: 0) {
                        TextField("Search conversations...", text: $searchText)
                            .movefullySearchFieldStyle()
                            .overlay(
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                        .padding(.leading, MovefullyTheme.Layout.paddingL)
                                    
                                    Spacer()
                                }, 
                                alignment: .leading
                            )
                            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                            .padding(.vertical, MovefullyTheme.Layout.paddingL)
                    }
                    .background(MovefullyTheme.Colors.cardBackground)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 8)
                .background(.white)
                
                // Conversations List
                ScrollView {
                    LazyVStack(spacing: MovefullyTheme.Layout.paddingM) {
                        ForEach(filteredConversations) { conversation in
                            ConversationRowView(conversation: conversation) {
                                selectedConversation = conversation
                            }
                        }
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                    .padding(.vertical, MovefullyTheme.Layout.paddingL)
                }
                .background(MovefullyTheme.Colors.backgroundPrimary)
            }
            .movefullyBackground()
            .sheet(isPresented: $showingNewMessage) {
                NewMessageView()
            }
            .sheet(item: $selectedConversation) { conversation in
                ConversationDetailView(conversation: conversation)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ConversationRowView: View {
    let conversation: Conversation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Profile Picture
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [MovefullyTheme.lavender.opacity(0.6), MovefullyTheme.lavender.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Text(String(conversation.clientName.prefix(1)))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                // Conversation Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(conversation.clientName)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Spacer()
                        
                        Text(formatDate(conversation.lastMessageDate))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    
                    HStack {
                        Text(conversation.lastMessage)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        if conversation.unreadCount > 0 {
                            ZStack {
                                Circle()
                                    .fill(MovefullyTheme.Colors.primaryTeal)
                                    .frame(width: 20, height: 20)
                                
                                Text("\(conversation.unreadCount)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.smallCornerRadius))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MM/dd"
        }
        
        return formatter.string(from: date)
    }
}

struct NewMessageView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedClient = ""
    @State private var messageText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                Text("New Message")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .padding(.top, 20)
                
                // Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("To")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        TextField("Select client...", text: $selectedClient)
                            .textFieldStyle(MovefullyTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        TextEditor(text: $messageText)
                            .frame(height: 120)
                            .padding(16)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.smallCornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: MovefullyTheme.smallCornerRadius)
                                    .stroke(MovefullyTheme.Colors.primaryTeal.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Send Button
                Button(action: {
                    // TODO: Send message
                    dismiss()
                }) {
                    Text("Send Message")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.primaryTeal.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.cornerRadius))
                        .shadow(color: MovefullyTheme.Colors.primaryTeal.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .disabled(selectedClient.isEmpty || messageText.isEmpty)
            }
            .background(MovefullyTheme.Colors.backgroundSecondary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
    }
}

struct ConversationDetailView: View {
    let conversation: Conversation
    @Environment(\.dismiss) private var dismiss
    @State private var newMessageText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(conversation.messages) { message in
                            MessageBubbleView(message: message)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                
                // Message Input
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $newMessageText)
                        .textFieldStyle(MovefullyTextFieldStyle())
                        .padding(12)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(MovefullyTheme.Colors.primaryTeal.opacity(0.2), lineWidth: 1)
                        )
                    
                    Button(action: {
                        // TODO: Send message
                        newMessageText = ""
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    }
                    .disabled(newMessageText.isEmpty)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(.white)
            }
            .background(MovefullyTheme.Colors.backgroundSecondary)
            .navigationTitle(conversation.clientName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
    }
}

struct MessageBubbleView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromTrainer {
                Spacer()
            }
            
            VStack(alignment: message.isFromTrainer ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(message.isFromTrainer ? .white : MovefullyTheme.Colors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.isFromTrainer
                            ? MovefullyTheme.Colors.primaryTeal
                            : Color.white
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                
                Text(formatTime(message.timestamp))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .padding(.horizontal, 4)
            }
            
            if !message.isFromTrainer {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Compact Category Pill
struct CompactCategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .white : MovefullyTheme.Colors.primaryTeal)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Exercise Supporting Views
struct ExerciseCategoryPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : MovefullyTheme.Colors.primaryTeal)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? MovefullyTheme.Colors.primaryTeal.opacity(0.8) : .white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(isSelected ? .white : MovefullyTheme.Colors.primaryTeal)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                isSelected ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.primaryTeal.opacity(0.1)
            )
            .clipShape(Capsule())
            .shadow(
                color: isSelected ? MovefullyTheme.Colors.primaryTeal.opacity(0.3) : Color.clear,
                radius: 6,
                x: 0,
                y: 3
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}

struct EquipmentFilterPill: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : color)
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : color)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? color.opacity(0.8) : .white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(isSelected ? .white : color)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ? color : color.opacity(0.1)
            )
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.smallCornerRadius))
            .shadow(
                color: isSelected ? color.opacity(0.3) : Color.clear,
                radius: 4,
                x: 0,
                y: 2
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}

struct DifficultyFilterPill: View {
    let difficulty: ExerciseDifficulty
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(difficulty.rawValue)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : difficultyColor)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? difficultyColor.opacity(0.8) : .white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(isSelected ? .white : difficultyColor)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? difficultyColor : difficultyColor.opacity(0.15)
            )
            .clipShape(Capsule())
            .shadow(
                color: isSelected ? difficultyColor.opacity(0.3) : Color.clear,
                radius: 4,
                x: 0,
                y: 2
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
    
    private var difficultyColor: Color {
        switch difficulty {
        case .beginner: return MovefullyTheme.softGreen
        case .intermediate: return MovefullyTheme.warmOrange
        case .advanced: return MovefullyTheme.gentleBlue
        }
    }
}

struct ExerciseStatView: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                
                Text("\(count)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.smallCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: MovefullyTheme.smallCornerRadius)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Exercise Data Models

#Preview {
    TrainerDashboardView()
        .environmentObject(AuthenticationViewModel())
}

// MARK: - Trainer Profile Placeholder
struct TrainerProfilePlaceholder: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            
            VStack(spacing: 8) {
                Text("Trainer Profile - TESTING")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text("Your professional wellness profile")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MovefullyTheme.Colors.backgroundSecondary)
    }
} 