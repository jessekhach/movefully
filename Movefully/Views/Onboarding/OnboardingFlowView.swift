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
                // Check if this is for sign-in or sign-up
                if coordinator.isSignInFlow {
                    if coordinator.showEmailSignIn {
                        EmailSignInView()
                            .environmentObject(authViewModel)
                    } else {
                        SignInView()
                            .environmentObject(authViewModel)
                    }
                } else {
                    // Check if we should show email sign up or account creation
                    if coordinator.showEmailSignUp {
                        EmailSignUpView()
                            .environmentObject(authViewModel)
                    } else {
                        // Use the new, dedicated view for account creation in the onboarding flow
                        AccountCreationView()
                            .environmentObject(authViewModel)
                    }
                }
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