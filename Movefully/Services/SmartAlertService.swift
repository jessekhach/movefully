import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Smart Alert Model
struct SmartAlert: Identifiable, Codable {
    let id: String
    let clientId: String
    let type: AlertType
    let title: String
    let message: String
    let priority: AlertPriority
    let createdAt: Date
    let autoResolveCondition: String?
    
    enum AlertType: String, CaseIterable, Codable {
        case noPlan = "no_plan"
        case inactivity = "inactivity"
        case incompleteProfile = "incomplete_profile"
        case newClient = "new_client"
        case pausedClient = "paused_client"
        
        var icon: String {
            switch self {
            case .noPlan: return "calendar.badge.exclamationmark"
            case .inactivity: return "clock.badge.exclamationmark"
            case .incompleteProfile: return "person.crop.circle.badge.exclamationmark"
            case .newClient: return "star.circle"
            case .pausedClient: return "pause.circle"
            }
        }
    }
    
    enum AlertPriority: Int, Codable, Comparable {
        case high = 3
        case medium = 2
        case low = 1
        
        static func < (lhs: AlertPriority, rhs: AlertPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    init(id: String = UUID().uuidString, clientId: String, type: AlertType, title: String, message: String, priority: AlertPriority, createdAt: Date = Date(), autoResolveCondition: String? = nil) {
        self.id = id
        self.clientId = clientId
        self.type = type
        self.title = title
        self.message = message
        self.priority = priority
        self.createdAt = createdAt
        self.autoResolveCondition = autoResolveCondition
    }
}

// MARK: - Dismissed Alert Model
struct DismissedAlert: Codable {
    let alertType: SmartAlert.AlertType
    let clientId: String
    let dismissedAt: Date
    let trainerId: String
    
    init(alertType: SmartAlert.AlertType, clientId: String, trainerId: String, dismissedAt: Date = Date()) {
        self.alertType = alertType
        self.clientId = clientId
        self.trainerId = trainerId
        self.dismissedAt = dismissedAt
    }
}

// MARK: - Smart Alert Service
@MainActor
class SmartAlertService: ObservableObject {
    static let shared = SmartAlertService()
    
    private let db = Firestore.firestore()
    private let userDefaults = UserDefaults.standard
    
    private var currentTrainerId: String? {
        Auth.auth().currentUser?.uid
    }
    
    private init() {} // Private initializer for singleton
    
    // MARK: - Alert Generation
    
    /// Generates smart alerts for a client (max 2, highest priority first)
    func generateAlerts(for client: Client) -> [SmartAlert] {
        guard let trainerId = currentTrainerId else { return [] }
        
        var potentialAlerts: [SmartAlert] = []
        
        // 1. No Plan Alert (HIGH PRIORITY)
        if client.currentPlanId == nil {
            let alert = SmartAlert(
                clientId: client.id,
                type: .noPlan,
                title: "This client doesn't have a workout plan yet",
                message: "Client needs a workout plan to get started with their fitness journey.",
                priority: .high,
                autoResolveCondition: "currentPlanId != nil"
            )
            if !isAlertDismissed(alert, trainerId: trainerId) {
                potentialAlerts.append(alert)
            }
        }
        
        // 2. Inactivity Alert (HIGH PRIORITY)
        if let lastActivity = client.lastActivityDate {
            let daysInactive = Calendar.current.dateComponents([.day], from: lastActivity, to: Date()).day ?? 0
            if daysInactive >= 7 {
                let alert = SmartAlert(
                    clientId: client.id,
                    type: .inactivity,
                    title: "Client has been inactive for \(daysInactive) days - check in with them",
                    message: "Client hasn't logged any activity recently. Consider reaching out to check in.",
                    priority: .high,
                    autoResolveCondition: "lastActivityDate within 7 days"
                )
                if !isAlertDismissed(alert, trainerId: trainerId) {
                    potentialAlerts.append(alert)
                }
            }
        } else if client.status != .pending {
            // Never logged activity (but not pending)
            let alert = SmartAlert(
                clientId: client.id,
                type: .inactivity,
                title: "Client hasn't logged any workouts since joining - help them get started",
                message: "Client hasn't logged any activity since joining. Help them get started.",
                priority: .high,
                autoResolveCondition: "lastActivityDate exists"
            )
            if !isAlertDismissed(alert, trainerId: trainerId) {
                potentialAlerts.append(alert)
            }
        }
        
        // 3. Incomplete Profile Alert (MEDIUM PRIORITY)
        let hasGoals = client.goals?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let hasCoachingStyle = client.preferredCoachingStyle != nil
        
        if !hasGoals || !hasCoachingStyle {
            let missingFields = [
                !hasGoals ? "goals" : nil,
                !hasCoachingStyle ? "coaching style" : nil
            ].compactMap { $0 }.joined(separator: " and ")
            
            let alert = SmartAlert(
                clientId: client.id,
                type: .incompleteProfile,
                title: "Client profile is missing important information for better coaching",
                message: "Missing \(missingFields). Complete profile helps create better programs.",
                priority: .medium,
                autoResolveCondition: "goals and preferredCoachingStyle exist"
            )
            if !isAlertDismissed(alert, trainerId: trainerId) {
                potentialAlerts.append(alert)
            }
        }
        
        // 4. New Client Alert (MEDIUM PRIORITY)
        if client.status == .active && client.totalWorkoutsCompleted == 0 {
            let alert = SmartAlert(
                clientId: client.id,
                type: .newClient,
                title: "New client is ready to start - schedule their first workout session",
                message: "Help \(client.name) get started with their first workout.",
                priority: .medium,
                autoResolveCondition: "totalWorkoutsCompleted > 0"
            )
            if !isAlertDismissed(alert, trainerId: trainerId) {
                potentialAlerts.append(alert)
            }
        }
        
        // 5. Paused Client Alert (LOW PRIORITY)
        if client.status == .paused {
            let alert = SmartAlert(
                clientId: client.id,
                type: .pausedClient,
                title: "Client training is paused - follow up when they're ready to resume",
                message: "Follow up when \(client.name) is ready to resume training.",
                priority: .low,
                autoResolveCondition: "status != paused"
            )
            if !isAlertDismissed(alert, trainerId: trainerId) {
                potentialAlerts.append(alert)
            }
        }
        
        // Sort by priority (highest first) and limit to 2
        return potentialAlerts
            .sorted { $0.priority > $1.priority }
            .prefix(2)
            .map { $0 }
    }
    
    // MARK: - Alert Dismissal
    
    /// Dismisses an alert for a specific client and trainer
    func dismissAlert(_ alert: SmartAlert) {
        guard let trainerId = currentTrainerId else { return }
        
        let dismissedAlert = DismissedAlert(
            alertType: alert.type,
            clientId: alert.clientId,
            trainerId: trainerId
        )
        
        saveDismissedAlert(dismissedAlert)
        
        // Trigger UI update
        objectWillChange.send()
    }
    
    /// Checks if an alert has been dismissed
    private func isAlertDismissed(_ alert: SmartAlert, trainerId: String) -> Bool {
        let dismissedAlerts = getDismissedAlerts()
        return dismissedAlerts.contains { dismissed in
            dismissed.alertType == alert.type &&
            dismissed.clientId == alert.clientId &&
            dismissed.trainerId == trainerId
        }
    }
    
    /// Auto-resolves dismissed alerts when conditions are met
    func autoResolveAlerts(for client: Client) {
        guard let trainerId = currentTrainerId else { return }
        
        var dismissedAlerts = getDismissedAlerts()
        let originalCount = dismissedAlerts.count
        
        // Remove dismissed alerts that should auto-resolve
        dismissedAlerts.removeAll { dismissed in
            guard dismissed.clientId == client.id && dismissed.trainerId == trainerId else {
                return false
            }
            
            switch dismissed.alertType {
            case .noPlan:
                return client.currentPlanId != nil
            case .inactivity:
                if let lastActivity = client.lastActivityDate {
                    let daysInactive = Calendar.current.dateComponents([.day], from: lastActivity, to: Date()).day ?? 0
                    return daysInactive < 7
                }
                return client.lastActivityDate != nil
            case .incompleteProfile:
                let hasGoals = client.goals?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                let hasCoachingStyle = client.preferredCoachingStyle != nil
                return hasGoals && hasCoachingStyle
            case .newClient:
                return client.totalWorkoutsCompleted > 0
            case .pausedClient:
                return client.status != .paused
            }
        }
        
        // Save if any alerts were auto-resolved
        if dismissedAlerts.count != originalCount {
            saveDismissedAlerts(dismissedAlerts)
        }
    }
    
    // MARK: - Persistence
    
    private func getDismissedAlerts() -> [DismissedAlert] {
        guard let data = userDefaults.data(forKey: "DismissedAlerts"),
              let alerts = try? JSONDecoder().decode([DismissedAlert].self, from: data) else {
            return []
        }
        return alerts
    }
    
    private func saveDismissedAlert(_ alert: DismissedAlert) {
        var dismissedAlerts = getDismissedAlerts()
        
        // Remove any existing dismissal for the same alert type and client
        dismissedAlerts.removeAll { existing in
            existing.alertType == alert.alertType &&
            existing.clientId == alert.clientId &&
            existing.trainerId == alert.trainerId
        }
        
        // Add the new dismissal
        dismissedAlerts.append(alert)
        
        saveDismissedAlerts(dismissedAlerts)
    }
    
    private func saveDismissedAlerts(_ alerts: [DismissedAlert]) {
        if let data = try? JSONEncoder().encode(alerts) {
            userDefaults.set(data, forKey: "DismissedAlerts")
        }
    }
    
    // MARK: - Cleanup
    
    /// Removes old dismissed alerts (older than 30 days)
    func cleanupOldDismissedAlerts() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        var dismissedAlerts = getDismissedAlerts()
        
        let originalCount = dismissedAlerts.count
        dismissedAlerts.removeAll { $0.dismissedAt < thirtyDaysAgo }
        
        if dismissedAlerts.count != originalCount {
            saveDismissedAlerts(dismissedAlerts)
        }
    }
} 