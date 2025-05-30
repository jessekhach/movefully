import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if authViewModel.userRole == nil {
                    RoleSelectionView()
                        .environmentObject(authViewModel)
                } else if authViewModel.userRole == "trainer" {
                    TrainerDashboardView()
                        .environmentObject(authViewModel)
                } else {
                    ClientDashboardView()
                        .environmentObject(authViewModel)
                }
            } else {
                AuthenticationView()
                    .environmentObject(authViewModel)
            }
        }
        .onAppear {
            authViewModel.checkAuthenticationState()
        }
    }
} 