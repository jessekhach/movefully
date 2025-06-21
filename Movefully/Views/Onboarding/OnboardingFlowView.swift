import SwiftUI

struct OnboardingFlowView: View {
    @StateObject private var coordinator = OnboardingCoordinator()
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        NavigationStack {
            switch coordinator.currentStep {
            case .welcome:
                WelcomeView()
            case .features:
                FeatureHighlightsView()
            case .profileSetup:
                ProfileSetupView()
            case .authentication:
                // Use the new, dedicated view for account creation in the onboarding flow
                AccountCreationView()
                    .environmentObject(authViewModel)
            case .complete:
                OnboardingCompleteView()
            }
        }
        .environmentObject(coordinator)
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(AuthenticationViewModel())
} 