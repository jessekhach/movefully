import SwiftUI
import FirebaseAuth

struct TrainerDashboardView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Clients Tab
            ClientManagementView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "person.2.fill" : "person.2")
                    Text("Clients")
                }
                .tag(0)
            
            // Plans Tab
            ProgramsManagementView()
                .tabItem {
                    Image(systemName: "calendar.badge.plus")
                    Text("Plans")
                }
                .tag(1)
            
            // Templates Tab
            LibraryManagementView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "books.vertical.fill" : "books.vertical")
                    Text("Templates")
                }
                .tag(2)
            
            // Messages Tab
            TrainerMessagesView()
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
            updateTabBarAppearance()
        }
        .onChange(of: themeManager.isDarkMode) { _ in
            updateTabBarAppearance()
        }
        .onChange(of: themeManager.currentTheme) { _ in
            updateTabBarAppearance()
        }
        .movefullyBackground()
    }
    
    private func updateTabBarAppearance() {
        DispatchQueue.main.async {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            
            // Use theme-aware colors that adapt to light/dark mode
            let backgroundColor = themeManager.isDarkMode 
                ? UIColor(red: 0.110, green: 0.110, blue: 0.118, alpha: 1.0) // Dark mode background
                : UIColor(red: 0.980, green: 0.980, blue: 0.980, alpha: 1.0) // Light mode background
            
            let unselectedColor = themeManager.isDarkMode
                ? UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1.0) // iOS tertiary text dark
                : UIColor(red: 0.620, green: 0.620, blue: 0.620, alpha: 1.0) // Medium gray for light mode
            
            let selectedColor = UIColor(red: 0.337, green: 0.761, blue: 0.776, alpha: 1.0) // Primary teal - same in both modes
            
            appearance.backgroundColor = backgroundColor
            
            // Unselected item appearance
            appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: unselectedColor,
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]
            
            // Selected item appearance
            appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: selectedColor,
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
            ]
            
            // Apply globally - this will affect all tab bars but ensures consistent theming
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
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