import Foundation
import FirebaseMessaging
import UserNotifications
import UIKit
import FirebaseAuth

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var isNotificationPermissionGranted = false
    @Published var fcmToken: String?
    
    private override init() {
        super.init()
        setupNotifications()
    }
    
    // MARK: - Setup
    
    private func setupNotifications() {
        // Set FCM delegate
        Messaging.messaging().delegate = self
        
        // Set UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Check current permission status but don't request automatically
        checkNotificationPermission()
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isNotificationPermissionGranted = granted
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    print("📱 Push notification permission granted")
                    print("📱 Registering for remote notifications - FCM token will be available once APNS token is set")
                } else {
                    print("❌ Push notification permission denied")
                }
            }
        }
    }
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationPermissionGranted = settings.authorizationStatus == .authorized
                
                // If permission is already granted, just log it - don't try to get FCM token immediately
                if settings.authorizationStatus == .authorized {
                    print("📱 Notification permission already granted - FCM token will be retrieved when needed")
                } else {
                    print("📱 Notification permission not granted - status: \(settings.authorizationStatus.rawValue)")
                }
            }
        }
    }
    
    // MARK: - FCM Token Management
    
    func getFCMToken() {
        print("📱 Attempting to get FCM token...")
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Error fetching FCM registration token: \(error)")
            } else if let token = token {
                DispatchQueue.main.async {
                    self.fcmToken = token
                    print("✅ FCM registration token obtained: \(token)")
                    // Save token to user profile
                    self.saveFCMTokenToProfile(token)
                }
            } else {
                print("⚠️ FCM token is nil - this usually means APNS token is not set yet")
            }
        }
    }
    
    func initializeFCMTokenAfterAPNS() {
        // This method should be called after APNS token is confirmed
        print("📱 Initializing FCM token after APNS registration...")
        getFCMToken()
    }
    
    private func saveFCMTokenToProfile(_ token: String) {
        print("📱 Saving FCM token to profile: \(token)")
        
        Task {
            do {
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    print("⚠️ No authenticated user, FCM token not saved")
                    return
                }
                
                // Try both trainer and client data services to save the token
                // This approach works since one will succeed and one will fail silently
                
                // Try trainer first
                do {
                    try await TrainerDataService.shared.updateNotificationSettings(enabled: true, fcmToken: token)
                    print("✅ FCM token saved to trainer profile successfully")
                } catch {
                    // If trainer fails, try client
                    do {
                        let clientDataService = ClientDataService()
                        try await clientDataService.updateNotificationSettings(clientId: currentUserId, enabled: true, fcmToken: token)
                        print("✅ FCM token saved to client profile successfully")
                    } catch {
                        print("❌ Failed to save FCM token to both trainer and client profiles: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Quiet Hours
    
    func isQuietHours() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        // Quiet hours: 10:00 PM (22:00) to 7:00 AM (07:00)
        return hour >= 22 || hour < 7
    }
    
    // MARK: - Notification Scheduling (Local)
    
    func scheduleWorkoutReminder(for clientId: String, workoutTitle: String, at date: Date) {
        guard isNotificationPermissionGranted else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Move!"
        content.body = "Your workout '\(workoutTitle)' is ready"
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "workout_reminder_\(clientId)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling workout reminder: \(error)")
            } else {
                print("📱 Workout reminder scheduled for \(date)")
            }
        }
    }
    
    func cancelAllWorkoutReminders(for clientId: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.contains("workout_reminder_\(clientId)") }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            print("📱 Cancelled \(identifiersToRemove.count) workout reminders for client: \(clientId)")
        }
    }
}

// MARK: - MessagingDelegate

extension NotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("📱 Firebase registration token received: \(String(describing: fcmToken))")
        
        DispatchQueue.main.async {
            self.fcmToken = fcmToken
            if let token = fcmToken {
                print("✅ FCM token successfully obtained: \(token)")
                self.saveFCMTokenToProfile(token)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    // Handle notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("📱 Notification tapped: \(userInfo)")
        
        // Handle notification tap based on type
        handleNotificationTap(userInfo: userInfo)
        
        completionHandler()
    }
    
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // TODO: Handle navigation based on notification type
        // This will be implemented when we add deep linking
        print("📱 Handling notification tap: \(userInfo)")
    }
} 