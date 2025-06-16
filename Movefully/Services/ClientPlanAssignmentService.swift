import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Plan Assignment Errors
enum PlanAssignmentError: LocalizedError {
    case notAuthenticated
    case clientNotFound
    case programNotFound
    case invalidStartDate
    case queueLimitReached
    case firebaseError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .clientNotFound:
            return "Client not found"
        case .programNotFound:
            return "Program not found"
        case .invalidStartDate:
            return "Start date must be a Sunday"
        case .queueLimitReached:
            return "Client already has the maximum number of plans (current + next)"
        case .firebaseError(let error):
            return "Database error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Plan Assignment Options
struct PlanAssignmentOptions {
    let replaceCurrentPlan: Bool
    let startDate: Date
    let autoCalculateEndDate: Bool
    
    init(replaceCurrentPlan: Bool = false, startDate: Date, autoCalculateEndDate: Bool = true) {
        self.replaceCurrentPlan = replaceCurrentPlan
        self.startDate = startDate
        self.autoCalculateEndDate = autoCalculateEndDate
    }
}

// MARK: - Client Plan Assignment Service
@MainActor
class ClientPlanAssignmentService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var currentTrainerId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Sunday Date Utilities
    
    /// Returns the next Sunday from the given date (or the same date if it's already Sunday)
    func nextSunday(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // If it's already Sunday (weekday = 1), return the same date
        if weekday == 1 {
            return calendar.startOfDay(for: date)
        }
        
        // Calculate days to add to reach Sunday
        let daysToAdd = 8 - weekday
        return calendar.date(byAdding: .day, value: daysToAdd, to: calendar.startOfDay(for: date)) ?? date
    }
    
    /// Returns all Sundays for the next 12 weeks
    func availableSundays(startingFrom date: Date = Date()) -> [Date] {
        let calendar = Calendar.current
        let firstSunday = nextSunday(from: date)
        
        return (0..<12).compactMap { weekIndex in
            calendar.date(byAdding: .weekOfYear, value: weekIndex, to: firstSunday)
        }
    }
    
    /// Validates that the given date is a Sunday
    func isSunday(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.component(.weekday, from: date) == 1
    }
    
    // MARK: - Plan Assignment Logic
    
    /// Assigns a program to a client with the specified options
    func assignPlan(programId: String, to clientId: String, options: PlanAssignmentOptions) async throws {
        guard currentTrainerId != nil else {
            throw PlanAssignmentError.notAuthenticated
        }
        
        guard isSunday(options.startDate) else {
            throw PlanAssignmentError.invalidStartDate
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch client and program data
            let client = try await fetchClient(clientId)
            let program = try await fetchProgram(programId)
            
            // Check if client can accept a new plan
            try validatePlanAssignment(for: client, options: options)
            
            // Calculate end date
            let endDate = calculateEndDate(from: options.startDate, duration: program.duration)
            
            // Update client with new plan assignment
            try await updateClientWithPlan(
                client: client,
                programId: programId,
                startDate: options.startDate,
                endDate: endDate,
                options: options
            )
            
            // Update program usage count
            try await incrementProgramUsage(programId)
            
        } catch {
            if let assignmentError = error as? PlanAssignmentError {
                throw assignmentError
            } else {
                throw PlanAssignmentError.firebaseError(error)
            }
        }
    }
    
    /// Checks if a client already has plans and handles queue/replacement logic
    func getPlanAssignmentStatus(for clientId: String) async throws -> PlanAssignmentStatus {
        let client = try await fetchClient(clientId)
        
        // Check for expired plans and auto-promote if needed
        var updatedClient = client
        if client.shouldPromoteNextPlan {
            updatedClient = try await promoteNextPlanToCurrent(client)
        }
        
        if !updatedClient.hasCurrentPlan {
            return .noPlan
        } else if updatedClient.canQueuePlan {
            return .canQueue
        } else if updatedClient.hasNextPlan {
            return .queueFull
        } else {
            return .hasCurrentPlan
        }
    }
    
    /// Removes the current plan from a client
    func removeCurrentPlan(for clientId: String) async throws {
        guard currentTrainerId != nil else {
            throw PlanAssignmentError.notAuthenticated
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let updateData: [String: Any] = [
                "currentPlanId": FieldValue.delete(),
                "currentPlanStartDate": FieldValue.delete(),
                "currentPlanEndDate": FieldValue.delete(),
                "updatedAt": Timestamp()
            ]
            
            try await db.collection("clients").document(clientId).updateData(updateData)
        } catch {
            throw PlanAssignmentError.firebaseError(error)
        }
    }
    
    /// Removes the upcoming plan from a client
    func removeUpcomingPlan(for clientId: String) async throws {
        guard currentTrainerId != nil else {
            throw PlanAssignmentError.notAuthenticated
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let updateData: [String: Any] = [
                "nextPlanId": FieldValue.delete(),
                "nextPlanStartDate": FieldValue.delete(),
                "nextPlanEndDate": FieldValue.delete(),
                "updatedAt": Timestamp()
            ]
            
            try await db.collection("clients").document(clientId).updateData(updateData)
        } catch {
            throw PlanAssignmentError.firebaseError(error)
        }
    }
    
    // MARK: - Private Helper Methods
    
    func fetchClient(_ clientId: String) async throws -> Client {
        let document = try await db.collection("clients").document(clientId).getDocument()
        
        guard document.exists, let data = document.data() else {
            throw PlanAssignmentError.clientNotFound
        }
        
        return try Client.from(data, documentId: clientId)
    }
    
    private func fetchProgram(_ programId: String) async throws -> Program {
        let document = try await db.collection("programs").document(programId).getDocument()
        
        guard document.exists else {
            throw PlanAssignmentError.programNotFound
        }
        
        return try Program.from(document)
    }
    
    private func validatePlanAssignment(for client: Client, options: PlanAssignmentOptions) throws {
        if !options.replaceCurrentPlan {
            // Check queue limits
            if client.hasCurrentPlan && client.hasNextPlan {
                throw PlanAssignmentError.queueLimitReached
            }
        }
    }
    
    private func calculateEndDate(from startDate: Date, duration: Int) -> Date {
        let calendar = Calendar.current
        // Duration is in days, subtract 1 because the start day counts
        let endDate = calendar.date(byAdding: .day, value: duration - 1, to: startDate) ?? startDate
        
        // Ensure end date is also a Sunday
        let weekday = calendar.component(.weekday, from: endDate)
        if weekday != 1 {
            let daysToAdd = 7 - (weekday - 1)
            return calendar.date(byAdding: .day, value: daysToAdd, to: endDate) ?? endDate
        }
        
        return endDate
    }
    
    private func updateClientWithPlan(
        client: Client,
        programId: String,
        startDate: Date,
        endDate: Date,
        options: PlanAssignmentOptions
    ) async throws {
        var updateData: [String: Any] = [:]
        
        if options.replaceCurrentPlan || !client.hasCurrentPlan {
            // Assign as current plan
            updateData["currentPlanId"] = programId
            updateData["currentPlanStartDate"] = Timestamp(date: startDate)
            updateData["currentPlanEndDate"] = Timestamp(date: endDate)
            
            // Clear next plan if replacing current
            if options.replaceCurrentPlan {
                updateData["nextPlanId"] = FieldValue.delete()
                updateData["nextPlanStartDate"] = FieldValue.delete()
                updateData["nextPlanEndDate"] = FieldValue.delete()
            }
        } else {
            // Assign as next plan
            updateData["nextPlanId"] = programId
            updateData["nextPlanStartDate"] = Timestamp(date: startDate)
            updateData["nextPlanEndDate"] = Timestamp(date: endDate)
        }
        
        updateData["updatedAt"] = Timestamp()
        
        try await db.collection("clients").document(client.id).updateData(updateData)
    }
    
    private func incrementProgramUsage(_ programId: String) async throws {
        try await db.collection("programs").document(programId).updateData([
            "usageCount": FieldValue.increment(Int64(1))
        ])
    }
    
    func promoteNextPlanToCurrent(_ client: Client) async throws -> Client {
        guard client.hasNextPlan else { return client }
        
        let updateData: [String: Any] = [
            "currentPlanId": client.nextPlanId ?? "",
            "currentPlanStartDate": client.nextPlanStartDate.map { Timestamp(date: $0) } ?? FieldValue.delete(),
            "currentPlanEndDate": client.nextPlanEndDate.map { Timestamp(date: $0) } ?? FieldValue.delete(),
            "nextPlanId": FieldValue.delete(),
            "nextPlanStartDate": FieldValue.delete(),
            "nextPlanEndDate": FieldValue.delete(),
            "updatedAt": Timestamp()
        ]
        
        try await db.collection("clients").document(client.id).updateData(updateData)
        
        // Return updated client
        var updatedClient = client
        updatedClient.currentPlanId = client.nextPlanId
        updatedClient.currentPlanStartDate = client.nextPlanStartDate
        updatedClient.currentPlanEndDate = client.nextPlanEndDate
        updatedClient.nextPlanId = nil
        updatedClient.nextPlanStartDate = nil
        updatedClient.nextPlanEndDate = nil
        
        return updatedClient
    }
}

// MARK: - Plan Assignment Status
enum PlanAssignmentStatus {
    case noPlan
    case hasCurrentPlan
    case canQueue
    case queueFull
    
    var message: String {
        switch self {
        case .noPlan:
            return "No plan assigned"
        case .hasCurrentPlan:
            return "Has current plan"
        case .canQueue:
            return "Can queue next plan"
        case .queueFull:
            return "Queue full (current + next plan)"
        }
    }
}

// MARK: - Data Model Extensions
extension Client {
    static func from(_ data: [String: Any], documentId: String) throws -> Client {
        return Client(
            id: documentId,
            name: data["name"] as? String ?? "",
            email: data["email"] as? String ?? "",
            trainerId: data["trainerId"] as? String ?? "",
            status: {
                let statusString = data["status"] as? String ?? "Active"
                // Handle both "active" and "Active" cases gracefully
                if statusString.lowercased() == "active" {
                    return .active
                } else {
                    return ClientStatus(rawValue: statusString) ?? .active
                }
            }(),
            joinedDate: (data["joinedDate"] as? Timestamp)?.dateValue(),
            profileImageUrl: data["profileImageUrl"] as? String,
            height: data["height"] as? String,
            weight: data["weight"] as? String,
            goal: data["goals"] as? String,
            injuries: data["injuries"] as? String,
            preferredCoachingStyle: CoachingStyle(rawValue: data["preferredCoachingStyle"] as? String ?? "hybrid"),
            lastWorkoutDate: (data["lastWorkoutDate"] as? Timestamp)?.dateValue(),
            lastActivityDate: (data["lastActivityDate"] as? Timestamp)?.dateValue(),
            currentPlanId: data["currentPlanId"] as? String,
            totalWorkoutsCompleted: data["totalWorkoutsCompleted"] as? Int ?? 0,
            currentPlanStartDate: (data["currentPlanStartDate"] as? Timestamp)?.dateValue(),
            currentPlanEndDate: (data["currentPlanEndDate"] as? Timestamp)?.dateValue(),
            nextPlanId: data["nextPlanId"] as? String,
            nextPlanStartDate: (data["nextPlanStartDate"] as? Timestamp)?.dateValue(),
            nextPlanEndDate: (data["nextPlanEndDate"] as? Timestamp)?.dateValue()
        )
    }
}

extension Program {
    static func from(_ document: DocumentSnapshot) throws -> Program {
        guard let data = document.data() else {
            throw PlanAssignmentError.programNotFound
        }
        
        return Program(
            name: data["name"] as? String ?? "",
            description: data["description"] as? String ?? "",
            duration: data["duration"] as? Int ?? 0,
            difficulty: WorkoutDifficulty(rawValue: data["difficulty"] as? String ?? "beginner") ?? .beginner,
            scheduledWorkouts: [], // Would need to be populated separately if needed
            tags: data["tags"] as? [String] ?? [],
            usageCount: data["usageCount"] as? Int ?? 0,
            createdDate: (data["createdDate"] as? Timestamp)?.dateValue() ?? Date(),
            lastModified: (data["lastModified"] as? Timestamp)?.dateValue() ?? Date(),
            isDraft: data["isDraft"] as? Bool ?? false,
            icon: data["icon"] as? String ?? "calendar",
            coachingNotes: data["coachingNotes"] as? String
        )
    }
} 