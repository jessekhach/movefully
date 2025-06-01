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
            return viewModel.conversations.sorted { $0.lastMessageTime > $1.lastMessageTime }
        } else {
            return viewModel.conversations.filter { conversation in
                conversation.clientName.localizedCaseInsensitiveContains(searchText) ||
                conversation.lastMessage.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        MovefullyNavigationPageLayout {
            VStack(spacing: 0) {
                // Header Section
                MovefullyContentSection {
                    MovefullyPageSection {
                        MovefullyPageHeader(
                            title: "Conversations",
                            subtitle: "Stay connected with your wellness community",
                            actionButton: MovefullyPageHeader.ActionButton(
                                title: "New",
                                icon: "square.and.pencil",
                                action: {
                                    showingNewMessage = true
                                }
                            )
                        )
                        
                        MovefullySearchField(
                            placeholder: "Search conversations...",
                            text: $searchText
                        )
                    }
                }
                
                // Conversations List
                if filteredConversations.isEmpty {
                    MovefullyEmptyState(
                        icon: searchText.isEmpty ? "message.circle" : "magnifyingglass",
                        title: searchText.isEmpty ? "Start a conversation" : "No conversations found",
                        description: searchText.isEmpty ? 
                            "Connect with your clients through meaningful conversations to support their wellness journey." : 
                            "Try adjusting your search terms to find the conversation you're looking for.",
                        actionButton: searchText.isEmpty ? 
                            MovefullyEmptyState.ActionButton(
                                title: "Send First Message",
                                action: { showingNewMessage = true }
                            ) : nil
                    )
                } else {
                    ScrollView {
                        MovefullyListLayout(
                            items: filteredConversations,
                            itemView: { conversation in
                                Button(action: {
                                    selectedConversation = conversation
                                }) {
                                    ConversationRowView(conversation: conversation)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        )
                    }
                    .background(MovefullyTheme.Colors.backgroundPrimary)
                }
            }
        }
        .sheet(isPresented: $showingNewMessage) {
            NewMessageView()
        }
        .sheet(item: $selectedConversation) { conversation in
            ConversationDetailView(conversation: conversation)
        }
    }
}

// MARK: - Exercise Supporting Views
struct EquipmentFilterPill: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        MovefullyPill(
            title: count > 0 ? "\(title) (\(count))" : title,
            isSelected: isSelected,
            style: .filter,
            action: action
        )
    }
}

struct DifficultyFilterPill: View {
    let difficulty: DifficultyLevel
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        MovefullyPill(
            title: count > 0 ? "\(difficulty.rawValue) (\(count))" : difficulty.rawValue,
            isSelected: isSelected,
            style: .filter,
            action: action
        )
    }
}

struct ExerciseStatView: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingS) {
            HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                Image(systemName: icon)
                    .font(MovefullyTheme.Typography.buttonSmall)
                    .foregroundColor(color)
                
                Text("\(count)")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingM)
        .padding(.vertical, MovefullyTheme.Layout.paddingS)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .overlay(
            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    TrainerDashboardView()
        .environmentObject(AuthenticationViewModel())
}

// MARK: - Trainer Profile Placeholder
struct TrainerProfilePlaceholder: View {
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            Image(systemName: "person.circle.fill")
                .font(MovefullyTheme.Typography.largeTitle)
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                Text("Trainer Profile - TESTING")
                    .font(MovefullyTheme.Typography.title2)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text("Your professional wellness profile")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .movefullyBackground()
    }
} 