import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var coordinator = OnboardingCoordinator()
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    var body: some View {
        if coordinator.hasCompletedOnboarding {
            AuthenticatedContentView()
                .environmentObject(authViewModel)
        } else {
            OnboardingFlowView()
                .environmentObject(authViewModel)
        }
    }
}

struct AuthenticatedContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var clientViewModel = ClientViewModel()
    
    var body: some View {
        VStack {
            if authViewModel.isAuthenticated {
                if authViewModel.userRole == "trainer" {
                    TrainerDashboardView()
                } else {
                    ClientMainView(viewModel: clientViewModel)
                }
            } else {
                AuthenticationView()
            }
        }
        .onAppear {
            authViewModel.checkAuthenticationState()
        }
        .environmentObject(authViewModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 