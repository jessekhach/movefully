import SwiftUI

// MARK: - Main Client Interface
struct ClientMainView: View {
    @ObservedObject var viewModel: ClientViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        TabView {
            ClientTodayView(viewModel: viewModel)
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "calendar.badge.clock")
                    Text("Today")
                }
            
            ClientDashboardView(viewModel: viewModel)
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Progress")
                }
            
            ClientScheduleView(viewModel: viewModel)
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Schedule")
                }
            
            ClientMessagesView(viewModel: viewModel)
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Messages")
                }
            
            ClientResourcesView(viewModel: viewModel)
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text("Resources")
                }
        }
        .accentColor(MovefullyTheme.Colors.primaryTeal)
        .background(MovefullyTheme.Colors.backgroundPrimary)
    }
}

#Preview {
    ClientMainView(viewModel: ClientViewModel())
} 