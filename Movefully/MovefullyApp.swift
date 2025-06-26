import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import UIKit

// AppDelegate for handling push notifications
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("📱 AppDelegate: didFinishLaunchingWithOptions")
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📱 APNS device token registered successfully")
        print("📱 Device token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        
        // Manually set the APNS token for Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
        print("📱 APNS token set in Firebase Messaging")
        
        // Now try to get FCM token after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NotificationService.shared.initializeFCMTokenAfterAPNS()
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
}

@main
struct MovefullyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
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
        
        // Debug: Print Firebase configuration
        if let app = FirebaseApp.app() {
            print("✅ Firebase configured successfully")
            print("📱 Firebase project ID: \(app.options.projectID ?? "Unknown")")
            print("📱 Firebase app ID: \(app.options.googleAppID)")
        } else {
            print("❌ Firebase configuration failed")
        }
        
        // Initialize notification service
        _ = NotificationService.shared
        print("📱 NotificationService initialized")
    }
} 