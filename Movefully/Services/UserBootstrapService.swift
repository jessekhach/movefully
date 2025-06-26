import Foundation
import SwiftUI
import FirebaseAuth

@MainActor
class UserBootstrapService: ObservableObject {
    @Published var isBootstrapping: Bool = false
    @Published var bootstrapPhase: BootstrapPhase = .idle
    @Published var progressText: String = ""
    @Published var userContext: UserContext = .returningUser
    
    var authViewModel: AuthenticationViewModel
    private let minimumLoadingDisplayTime: TimeInterval = 0.8
    
    init(authViewModel: AuthenticationViewModel) {
        self.authViewModel = authViewModel
    }
    
    // MARK: - Public Interface
    
    func bootstrap(context: BootstrapContext, profileData: Any? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                let bootstrapStartTime = Date()
                isBootstrapping = true
                userContext = determineUserContext(for: context)
                
                let config = getBootstrapConfig(for: userContext, context: context)
                
                for (index, phase) in config.phases.enumerated() {
                    let startTime = Date()
                    
                    await MainActor.run {
                        self.bootstrapPhase = phase
                        self.progressText = self.getProgressText(for: phase, userContext: userContext, context: context)
                    }
                    
                    // Execute phase work
                    try await executePhase(phase, userContext: userContext, context: context, profileData: profileData)
                    
                    // Ensure minimum time for this phase
                    let elapsed = Date().timeIntervalSince(startTime)
                    let minimumTime = config.phaseMinimums[index]
                    if elapsed < minimumTime {
                        try await Task.sleep(nanoseconds: UInt64((minimumTime - elapsed) * 1_000_000_000))
                    }
                }
                
                // Update last app use for context detection
                UserDefaults.standard.set(Date(), forKey: "lastAppUse")
                
                // Ensure minimum display time for loading screen (prevents flash loading)
                let totalElapsed = Date().timeIntervalSince(bootstrapStartTime)
                let remainingTime = max(0, minimumLoadingDisplayTime - totalElapsed)
                
                if remainingTime > 0 {
                    try await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
                }
                
                await MainActor.run {
                    self.bootstrapPhase = .complete
                    self.isBootstrapping = false
                }
                
                completion(.success(()))
                
            } catch {
                await MainActor.run {
                    self.isBootstrapping = false
                    self.bootstrapPhase = .idle
                }
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Data Types

enum BootstrapPhase {
    case idle
    case authenticating
    case settingUpWorkspace
    case loadingWellnessData
    case complete
}

enum BootstrapContext {
    case signUp(role: String)
    case signIn
}

enum UserContext {
    case firstTimeSignUp
    case firstTimeSignIn
    case returningUser
    case quickRelaunch
}

struct BootstrapConfig {
    let phases: [BootstrapPhase]
    let phaseMinimums: [TimeInterval]
    let messagingStyle: MessagingStyle
}

enum MessagingStyle {
    case onboarding
    case returning
    case welcomeBack
    case minimal
}

// MARK: - Context Detection

private extension UserBootstrapService {
    func determineUserContext(for context: BootstrapContext) -> UserContext {
        switch context {
        case .signUp:
            return .firstTimeSignUp
            
        case .signIn:
            let hasLocalCache = hasValidLocalData()
            let lastAppUse = UserDefaults.standard.object(forKey: "lastAppUse") as? Date
            
            if !hasLocalCache {
                return .firstTimeSignIn
            }
            
            if let lastUse = lastAppUse, Date().timeIntervalSince(lastUse) < 21600 { // 6 hours
                return .quickRelaunch
            }
            
            return .returningUser
        }
    }
    
    func hasValidLocalData() -> Bool {
        // Check if we have any cached data that indicates prior app use
        let workoutCacheValid = WorkoutDataCacheService.shared.isCacheValid()
        let progressCacheValid = ProgressDataCacheService.shared.isCacheValid()
        let hasUsedApp = UserDefaults.standard.object(forKey: "lastAppUse") != nil
        
        return workoutCacheValid || progressCacheValid || hasUsedApp
    }
}

// MARK: - Configuration

private extension UserBootstrapService {
    func getBootstrapConfig(for userContext: UserContext, context: BootstrapContext) -> BootstrapConfig {
        switch userContext {
        case .firstTimeSignUp:
            return BootstrapConfig(
                phases: [.authenticating, .settingUpWorkspace, .loadingWellnessData],
                phaseMinimums: [2.0, 1.5, 1.5],
                messagingStyle: .onboarding
            )
            
        case .firstTimeSignIn:
            return BootstrapConfig(
                phases: [.settingUpWorkspace, .loadingWellnessData],
                phaseMinimums: [1.0, 1.5],
                messagingStyle: .returning
            )
            
        case .returningUser:
            return BootstrapConfig(
                phases: [.loadingWellnessData],
                phaseMinimums: [1.0],
                messagingStyle: .welcomeBack
            )
            
        case .quickRelaunch:
            return BootstrapConfig(
                phases: [.loadingWellnessData],
                phaseMinimums: [0.5],
                messagingStyle: .minimal
            )
        }
    }
    
    func getProgressText(for phase: BootstrapPhase, userContext: UserContext, context: BootstrapContext) -> String {
        let style = getBootstrapConfig(for: userContext, context: context).messagingStyle
        
        switch (phase, style) {
        case (.authenticating, .onboarding):
            if case .signUp(let role) = context {
                return role == "trainer" ? "Creating Your Account" : "Creating Your Account"
            }
            return "Creating Your Account"
            
        case (.settingUpWorkspace, .onboarding):
            return "Setting up your workspace..."
            
        case (.settingUpWorkspace, .returning):
            return "Preparing your profile..."
            
        case (.loadingWellnessData, .onboarding):
            if case .signUp(let role) = context {
                return role == "trainer" ? "Setting up your coaching space..." : "Preparing your wellness journey..."
            }
            return "Loading your wellness journey..."
            
        case (.loadingWellnessData, .returning):
            return "Loading your wellness data..."
            
        case (.loadingWellnessData, .welcomeBack):
            return "Welcome back! Getting your latest updates..."
            
        case (.loadingWellnessData, .minimal):
            return "Loading..."
            
        default:
            return "Loading..."
        }
    }
}

// MARK: - Phase Execution

private extension UserBootstrapService {
    func executePhase(_ phase: BootstrapPhase, userContext: UserContext, context: BootstrapContext, profileData: Any?) async throws {
        switch phase {
        case .authenticating:
            // This phase is handled by AuthenticationViewModel
            // We just wait here since auth is already complete when bootstrap starts
            break
            
        case .settingUpWorkspace:
            try await executeWorkspaceSetup(userContext: userContext, context: context)
            
        case .loadingWellnessData:
            try await executeDataLoading(userContext: userContext, context: context)
            
        case .idle, .complete:
            break
        }
    }
    
    func executeWorkspaceSetup(userContext: UserContext, context: BootstrapContext) async throws {
        print("🔧 Bootstrap: Setting up workspace for \(userContext)")
        
        // Ensure user role is loaded
        if authViewModel.userRole == nil {
            try await fetchUserRole()
        }
        
        // Initialize core services based on role
        if let role = authViewModel.userRole {
            try await initializeCoreServices(for: role, userContext: userContext)
        }
    }
    
    func executeDataLoading(userContext: UserContext, context: BootstrapContext) async throws {
        print("📊 Bootstrap: Loading wellness data for \(userContext)")
        
        guard let role = authViewModel.userRole else {
            throw BootstrapError.missingUserRole
        }
        
        switch userContext {
        case .quickRelaunch:
            try await executeQuickRelaunchStrategy(role: role)
        case .returningUser:
            try await executeReturningUserStrategy(role: role)
        case .firstTimeSignIn, .firstTimeSignUp:
            try await executeFullDataLoadStrategy(role: role)
        }
    }
    
    // MARK: - Role and Service Initialization
    
    func fetchUserRole() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw BootstrapError.notAuthenticated
        }
        
        print("📊 Bootstrap: Fetching user role for \(userId)")
        
        // Add the same recent auth detection as AuthenticationViewModel
        let isRecentAuth = Date().timeIntervalSince(Auth.auth().currentUser?.metadata.lastSignInDate ?? Date.distantPast) < 5.0
        
        if isRecentAuth {
            print("🔄 Bootstrap: Recent authentication detected - waiting for token propagation...")
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        }
        
        try await fetchUserDataAndWait(userId: userId)
    }
    
    func initializeCoreServices(for role: String, userContext: UserContext) async throws {
        if role == "trainer" {
            // Initialize trainer services
            let _ = TrainerDataService.shared
            print("✅ Bootstrap: Trainer services initialized")
        } else {
            // Initialize client services  
            print("✅ Bootstrap: Client services initialized")
        }
    }
    
    // MARK: - Loading Strategies
    
    func executeQuickRelaunchStrategy(role: String) async throws {
        print("⚡ Bootstrap: Quick relaunch strategy")
        
        // Load from cache immediately, refresh in background
        if role == "trainer" {
            try await loadTrainerDataFromCache()
        } else {
            try await loadClientDataFromCache()
        }
        
        // Start background refresh (don't await)
        Task.detached { [weak self] in
            try? await self?.backgroundRefreshData(role: role)
        }
    }
    
    func executeReturningUserStrategy(role: String) async throws {
        print("🔄 Bootstrap: Returning user strategy")
        
        // Quick cache validation + essential refresh
        if role == "trainer" {
            try await loadTrainerDataSmart()
        } else {
            try await loadClientDataSmart()
        }
    }
    
    func executeFullDataLoadStrategy(role: String) async throws {
        print("🔧 Bootstrap: Full data load strategy")
        
        // Complete data loading for new users
        if role == "trainer" {
            try await loadTrainerDataFull()
        } else {
            try await loadClientDataFull()
        }
    }
    
    // MARK: - Data Loading Implementations
    
    func loadTrainerDataFromCache() async throws {
        // Use cached data immediately
        if ProgressDataCacheService.shared.isCacheValid() {
            let _ = ProgressDataCacheService.shared.getCachedProgressData()
        }
    }
    
    func loadTrainerDataSmart() async throws {
        // Load essential trainer data
        let trainerService = TrainerDataService.shared
        async let profile = trainerService.loadStatistics()
        let _ = try await profile
    }
    
    func loadTrainerDataFull() async throws {
        // Full trainer data load
        let trainerService = TrainerDataService.shared
        try await trainerService.loadStatistics()
        
        // Initialize other services
        let _ = TemplateDataService()
        let _ = ProgramDataService()
        let _ = MessagesService()
    }
    
    func loadClientDataFromCache() async throws {
        // Load client document first
        try await loadClientDocument()
        
        // Use cached client data
        if let cachedData = ProgressDataCacheService.shared.getCachedProgressData() {
            print("📦 Bootstrap: Using cached client data")
        }
    }
    
    func loadClientDataSmart() async throws {
        // Load client document first
        try await loadClientDocument()
        
        // Essential client data
        try await ProgressDataCacheService.shared.refreshOnLaunch()
    }
    
    func loadClientDataFull() async throws {
        // Load client document first
        try await loadClientDocument()
        
        // Full client data load
        try await ProgressDataCacheService.shared.refreshOnLaunch()
        try await WorkoutDataCacheService.shared.refreshOnLaunch()
    }
    
    private func loadClientDocument() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw BootstrapError.notAuthenticated
        }
        
        print("📋 Bootstrap: Loading client document for \(userId)")
        
        // Load client document using ClientDataService
        let clientService = ClientDataService()
        let _ = try await clientService.fetchClient(clientId: userId)
        
        print("✅ Bootstrap: Client document loaded successfully")
    }
    
    func backgroundRefreshData(role: String) async throws {
        print("🔄 Bootstrap: Background refresh started")
        
        if role == "trainer" {
            try await TrainerDataService.shared.loadStatistics()
        } else {
            // Load client document first, then refresh cache data
            try await loadClientDocument()
            try await ProgressDataCacheService.shared.refreshOnLaunch()
        }
        
        print("✅ Bootstrap: Background refresh completed")
    }
}

// MARK: - Bootstrap Errors

enum BootstrapError: LocalizedError {
    case notAuthenticated
    case missingUserRole
    case failedToFetchUserData
    case cacheLoadFailed
    case networkTimeout
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .missingUserRole:
            return "User role not found"
        case .failedToFetchUserData:
            return "Failed to fetch user data"
        case .cacheLoadFailed:
            return "Failed to load cached data"
        case .networkTimeout:
            return "Network request timed out"
        }
    }
}

// MARK: - Helper Extensions

private extension UserBootstrapService {
    func fetchUserDataAndWait(userId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            // Start the fetch with retry logic
            authViewModel.fetchUserDataWithRetry(userId: userId)
            
            // Monitor for role change or auth state change (in case of orphaned account cleanup)
            let checkTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
                DispatchQueue.main.async {
                    // Check if user role was loaded successfully
                    if self.authViewModel.userRole != nil && !hasResumed {
                        hasResumed = true
                        timer.invalidate()
                        continuation.resume()
                        return
                    }
                    
                    // Check if user was signed out (orphaned account cleanup)
                    if Auth.auth().currentUser == nil && !hasResumed {
                        hasResumed = true
                        timer.invalidate()
                        continuation.resume(throwing: BootstrapError.notAuthenticated)
                        return
                    }
                    
                    // Check if there's an error message (orphaned account detected)
                    if self.authViewModel.errorMessage != nil && !hasResumed {
                        hasResumed = true
                        timer.invalidate()
                        continuation.resume(throwing: BootstrapError.failedToFetchUserData)
                        return
                    }
                }
            }
            
            // Timeout after 10 seconds (allows for 4 retries with increasing delays + processing time)
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                if !hasResumed {
                    hasResumed = true
                    checkTimer.invalidate()
                    continuation.resume(throwing: BootstrapError.failedToFetchUserData)
                }
            }
        }
    }
} 