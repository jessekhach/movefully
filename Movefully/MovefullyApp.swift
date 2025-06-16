import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct MovefullyApp: App {
    @StateObject private var urlHandler = URLHandlingService()
    @StateObject private var planPromotionService = PlanPromotionService()
    
    init() {
        configureFirebase()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(urlHandler)
                .environmentObject(planPromotionService)
                .movefullyThemed()
                .onOpenURL { url in
                    print("🔗 App received URL: \(url)")
                    urlHandler.handleIncomingURL(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    print("📱 App became active - checking for plan promotions")
                    Task {
                        await planPromotionService.checkAllClientsForPromotions()
                    }
                }
        }
    }
    
    private func configureFirebase() {
        // Configure Firebase with the plist file
        FirebaseApp.configure()
    }
} 