import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var onboardingCoordinator = OnboardingCoordinator()
    @StateObject private var bootstrapService: UserBootstrapService
    @StateObject private var urlHandler = URLHandlingService()
    @State private var showBootstrapLoading = false
    @State private var hasDetectedAppRelaunch = false
    @State private var shouldShowNotificationPermission = false
    @State private var hasShownNotificationPermission = false
    
    init() {
        let authVM = AuthenticationViewModel()
        _authViewModel = StateObject(wrappedValue: authVM)
        _bootstrapService = StateObject(wrappedValue: UserBootstrapService(authViewModel: authVM))
    }
    
    var body: some View {
        ZStack {
            if authViewModel.isAuthenticated && !authViewModel.isOnboardingInProgress {
                // Show dashboard based on user role
                if let userRole = authViewModel.userRole {
                    if userRole == "trainer" {
                        TrainerDashboardView()
                            .environmentObject(authViewModel)
                            .opacity(showBootstrapLoading ? 0.3 : 1.0)
                            .blur(radius: showBootstrapLoading ? 3 : 0)
                            .animation(.easeInOut(duration: 0.3), value: showBootstrapLoading)
                    } else {
                        ClientMainView(viewModel: ClientViewModel())
                            .environmentObject(authViewModel)
                            .opacity(showBootstrapLoading ? 0.3 : 1.0)
                            .blur(radius: showBootstrapLoading ? 3 : 0)
                            .animation(.easeInOut(duration: 0.3), value: showBootstrapLoading)
                    }
                } else {
                    // Loading user role
                    ProfileLoadingView()
                        .opacity(showBootstrapLoading ? 0.3 : 1.0)
                        .blur(radius: showBootstrapLoading ? 3 : 0)
                        .animation(.easeInOut(duration: 0.3), value: showBootstrapLoading)
                }
            } else {
                // Show onboarding flow (either not authenticated or onboarding in progress)
                OnboardingFlowView()
                    .environmentObject(authViewModel)
                    .environmentObject(onboardingCoordinator)
                    .environmentObject(urlHandler)
                    .opacity(showBootstrapLoading ? 0.3 : 1.0)
                    .blur(radius: showBootstrapLoading ? 3 : 0)
                    .animation(.easeInOut(duration: 0.3), value: showBootstrapLoading)
            }
            
            // Bootstrap Loading Overlay for App Relaunch
            if showBootstrapLoading {
                MovefullyBootstrapLoadingView(bootstrapService: bootstrapService)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .fullScreenCover(isPresented: $shouldShowNotificationPermission) {
            NotificationPermissionView(
                onPermissionGranted: {
                    hasShownNotificationPermission = true
                    UserDefaults.standard.set(true, forKey: "hasSeenNotificationPermission")
                },
                onPermissionDenied: {
                    hasShownNotificationPermission = true
                    UserDefaults.standard.set(true, forKey: "hasSeenNotificationPermission")
                }
            )
            .environmentObject(authViewModel)
        }
        .onAppear {
            handleAppLaunch()
        }
        .onOpenURL { url in
            print("🔗 ContentView: Received URL: \(url)")
            urlHandler.handleIncomingURL(url)
        }
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            print("🔍 ContentView: isAuthenticated changed to \(isAuthenticated)")
            print("🔍 ContentView: userRole = \(authViewModel.userRole ?? "nil")")
            print("🔍 ContentView: isOnboardingInProgress = \(authViewModel.isOnboardingInProgress)")
            print("🔍 ContentView: hasDetectedAppRelaunch = \(hasDetectedAppRelaunch)")
            
            if isAuthenticated && authViewModel.userRole != nil && !authViewModel.isOnboardingInProgress {
                print("🔍 ContentView: Calling handleUserAuthenticated()")
                handleUserAuthenticated()
            }
        }
        .onChange(of: authViewModel.userRole) { userRole in
            print("🔍 ContentView: userRole changed to \(userRole ?? "nil")")
            print("🔍 ContentView: isAuthenticated = \(authViewModel.isAuthenticated)")
            print("🔍 ContentView: isOnboardingInProgress = \(authViewModel.isOnboardingInProgress)")
            print("🔍 ContentView: showBootstrapLoading = \(showBootstrapLoading)")
            print("🔍 ContentView: hasDetectedAppRelaunch = \(hasDetectedAppRelaunch)")
            
            // When user role loads for a returning user (app relaunch), run bootstrap
            // But NOT if this is during onboarding (sign-in flows handle their own bootstrap)
            if authViewModel.isAuthenticated && userRole != nil && !authViewModel.isOnboardingInProgress && !showBootstrapLoading {
                // Only run bootstrap for app relaunch scenarios, not fresh sign-ins
                // Check if this is actually an app relaunch by seeing if we detected it earlier
                if hasDetectedAppRelaunch {
                    print("🔍 ContentView: Conditions met for app relaunch bootstrap - calling handleReturningUserBootstrap()")
                    handleReturningUserBootstrap()
                } else {
                    print("🔍 ContentView: NOT calling bootstrap - this appears to be a fresh sign-in (hasDetectedAppRelaunch = false)")
                }
                
                // Check if we should show notification permission for returning users
                checkAndShowNotificationPermission()
            } else {
                print("🔍 ContentView: NOT calling bootstrap - conditions not met:")
                print("  - isAuthenticated: \(authViewModel.isAuthenticated)")
                print("  - userRole != nil: \(userRole != nil)")
                print("  - !isOnboardingInProgress: \(!authViewModel.isOnboardingInProgress)")
                print("  - !showBootstrapLoading: \(!showBootstrapLoading)")
            }
        }
    }
    
    private func handleAppLaunch() {
        // Check if user has seen notification permission before
        hasShownNotificationPermission = UserDefaults.standard.bool(forKey: "hasSeenNotificationPermission")
        
        // Check if user is already authenticated (app relaunch scenario)
        if Auth.auth().currentUser != nil {
            // User exists in Firebase Auth
            // AuthenticationViewModel will automatically load their profile
            // Bootstrap will be triggered when userRole loads (via onChange)
            print("📱 App relaunch detected - waiting for user role to load")
            hasDetectedAppRelaunch = true
        }
    }
    
    private func handleUserAuthenticated() {
        // User just signed in via onboarding flow
        // Bootstrap was already handled by the auth views, so no need to run it again
        
        // Show notification permission modal if not shown before
        checkAndShowNotificationPermission()
    }
    
    private func checkAndShowNotificationPermission() {
        // Only show if user hasn't seen it before and is fully authenticated
        if !hasShownNotificationPermission && authViewModel.isAuthenticated && authViewModel.userRole != nil && !authViewModel.isOnboardingInProgress {
            // Add a small delay to ensure UI is settled
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                shouldShowNotificationPermission = true
            }
        }
    }
    
    private func handleReturningUserBootstrap() {
        print("📱 Starting bootstrap for returning user")
        showBootstrapLoading = true
        
        bootstrapService.bootstrap(context: .signIn) { result in
            Task { @MainActor in
                showBootstrapLoading = false
                
                switch result {
                case .success():
                    print("✅ App relaunch bootstrap completed successfully")
                    
                case .failure(let error):
                    print("❌ App relaunch bootstrap failed: \(error)")
                    
                    // Check if this is an orphaned account scenario
                    if case BootstrapError.notAuthenticated = error {
                        print("🔄 Orphaned account detected during relaunch - user will see onboarding")
                        // The user will automatically see the onboarding flow since isAuthenticated will be false
                    } else if case BootstrapError.failedToFetchUserData = error {
                        print("🔄 Failed to fetch user data during relaunch - checking auth state")
                        // AuthenticationViewModel may have handled orphaned account cleanup
                        // UI will update automatically based on auth state
                    }
                    
                    // Don't show error to user for relaunch failures - let the auth state handle UI updates
                }
            }
        }
    }
}

// MARK: - Profile Loading View
struct ProfileLoadingView: View {
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 50))
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            
            Text("Loading Profile...")
                .font(MovefullyTheme.Typography.title3)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: MovefullyTheme.Colors.primaryTeal))
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MovefullyTheme.Colors.backgroundPrimary)
    }
}

#Preview {
    ContentView()
} 