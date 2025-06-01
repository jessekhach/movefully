import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var clientViewModel = ClientViewModel()
    
    var body: some View {
        VStack {
            if authViewModel.isAuthenticated {
                if authViewModel.userRole == nil {
                    RoleSelectionView()
                        .environmentObject(authViewModel)
                } else if authViewModel.userRole == "trainer" {
                    TrainerDashboardView()
                        .environmentObject(authViewModel)
                } else {
                    ClientMainView()
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