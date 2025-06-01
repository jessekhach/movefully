import SwiftUI

// MARK: - Main Client Interface
struct ClientMainView: View {
    @StateObject private var viewModel = ClientViewModel()
    
    var body: some View {
        TabView {
            ClientTodayView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "calendar.badge.clock")
                    Text("Today")
                }
            
            ClientDashboardView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Dashboard")
                }
            
            ClientScheduleView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Schedule")
                }
            
            ClientMessagesView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Messages")
                }
            
            ClientResourcesView(viewModel: viewModel)
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
    ClientMainView()
} 