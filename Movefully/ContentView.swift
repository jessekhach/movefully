import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var clientViewModel = ClientViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack {
            if authViewModel.isAuthenticated {
                if authViewModel.userRole == nil {
                    RoleSelectionView()
                        .environmentObject(authViewModel)
                        .environmentObject(themeManager)
                } else if authViewModel.userRole == "trainer" {
                    TrainerDashboardView()
                        .environmentObject(authViewModel)
                        .environmentObject(themeManager)
                } else {
                    ClientMainView()
                        .environmentObject(authViewModel)
                        .environmentObject(themeManager)
                }
            } else {
                AuthenticationView()
                    .environmentObject(authViewModel)
                    .environmentObject(themeManager)
            }
        }
        .onAppear {
            authViewModel.checkAuthenticationState()
        }
    }
} 