import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct MovefullyApp: App {
    init() {
        configureFirebase()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func configureFirebase() {
        // Configure Firebase with the plist file
        FirebaseApp.configure()
    }
} 