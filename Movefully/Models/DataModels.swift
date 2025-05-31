import Foundation

// MARK: - Client Status Enum
enum ClientStatus: String, CaseIterable, Codable {
    case new = "New"
    case active = "Active" 
    case needsAttention = "Needs Attention"
    case paused = "Paused"
    case pending = "Pending Invite"
    
    var color: String {
        switch self {
        case .new:
            return "primaryTeal"
        case .active:
            return "success"
        case .needsAttention:
            return "warning"
        case .paused:
            return "textSecondary"
        case .pending:
            return "secondaryPeach"
        }
    }
    
    var icon: String {
        switch self {
        case .new:
            return "star.fill"
        case .active:
            return "checkmark.circle.fill"
        case .needsAttention:
            return "exclamationmark.triangle.fill"
        case .paused:
            return "pause.circle.fill"
        case .pending:
            return "clock.fill"
        }
    }
}

// MARK: - Coaching Style Enum
enum CoachingStyle: String, CaseIterable, Codable {
    case synchronous = "Live Sessions"
    case asynchronous = "Self-Paced"
    case hybrid = "Hybrid"
    
    var description: String {
        switch self {
        case .synchronous:
            return "Real-time coaching sessions"
        case .asynchronous:
            return "Flexible, on-your-own-time approach"
        case .hybrid:
            return "Mix of live and self-paced"
        }
    }
}

// MARK: - Workout Difficulty Enum
enum WorkoutDifficulty: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var starRating: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        }
    }
}

// MARK: - Client Invitation Status
enum InvitationStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case accepted = "Accepted"
    case expired = "Expired"
    case declined = "Declined"
}

// MARK: - Client Data Model
struct Client: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var trainerId: String
    var status: ClientStatus
    var joinedDate: Date?
    var profileImageUrl: String?
    
    // Profile Information
    var height: String?
    var weight: String?
    var goals: String?
    var injuries: String?
    var preferredCoachingStyle: CoachingStyle?
    
    // Activity Tracking
    var lastWorkoutDate: Date?
    var lastActivityDate: Date?
    var currentPlanId: String?
    var totalWorkoutsCompleted: Int
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString, 
         name: String, 
         email: String, 
         trainerId: String, 
         status: ClientStatus = .pending,
         joinedDate: Date? = nil,
         profileImageUrl: String? = nil,
         height: String? = nil,
         weight: String? = nil,
         goal: String? = nil,
         injuries: String? = nil,
         preferredCoachingStyle: CoachingStyle? = nil,
         lastWorkoutDate: Date? = nil,
         lastActivityDate: Date? = nil,
         currentPlanId: String? = nil,
         totalWorkoutsCompleted: Int = 0) {
        
        self.id = id
        self.name = name
        self.email = email
        self.trainerId = trainerId
        self.status = status
        self.joinedDate = joinedDate
        self.profileImageUrl = profileImageUrl
        self.height = height
        self.weight = weight
        self.goals = goal
        self.injuries = injuries
        self.preferredCoachingStyle = preferredCoachingStyle
        self.lastWorkoutDate = lastWorkoutDate
        self.lastActivityDate = lastActivityDate
        self.currentPlanId = currentPlanId
        self.totalWorkoutsCompleted = totalWorkoutsCompleted
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var lastActivityText: String {
        guard let lastActivityDate = lastActivityDate else {
            return "No activity yet"
        }
        
        let daysAgo = Calendar.current.dateComponents([.day], from: lastActivityDate, to: Date()).day ?? 0
        
        if daysAgo == 0 {
            return "Active today"
        } else if daysAgo == 1 {
            return "Last active yesterday"
        } else {
            return "Last active \(daysAgo) days ago"
        }
    }
    
    var needsAttention: Bool {
        // Check if client needs attention based on various criteria
        if currentPlanId == nil { return true }
        if let lastActivity = lastActivityDate, 
           Calendar.current.dateComponents([.day], from: lastActivity, to: Date()).day ?? 0 > 7 {
            return true
        }
        return false
    }
    
    // Sample clients for testing
    static let sampleClients = [
        Client(
            id: "1", 
            name: "Sarah Johnson", 
            email: "sarah.johnson@example.com", 
            trainerId: "trainer1",
            status: .active,
            joinedDate: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
            height: "5'6\"",
            weight: "145 lbs",
            goal: "Improve overall flexibility and build core strength for better posture at work",
            injuries: "Previous knee injury (2019) - cleared by PT",
            preferredCoachingStyle: .hybrid,
            lastWorkoutDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            lastActivityDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            currentPlanId: "plan1",
            totalWorkoutsCompleted: 24
        ),
        Client(
            id: "2", 
            name: "Marcus Chen", 
            email: "marcus.chen@example.com", 
            trainerId: "trainer1",
            status: .needsAttention,
            joinedDate: Calendar.current.date(byAdding: .day, value: -45, to: Date()),
            height: "5'10\"",
            weight: "180 lbs",
            goal: "Train for upcoming marathon while maintaining strength",
            preferredCoachingStyle: .asynchronous,
            lastWorkoutDate: Calendar.current.date(byAdding: .day, value: -8, to: Date()),
            lastActivityDate: Calendar.current.date(byAdding: .day, value: -8, to: Date()),
            currentPlanId: "plan2",
            totalWorkoutsCompleted: 18
        ),
        Client(
            id: "3", 
            name: "Emma Rodriguez", 
            email: "emma.rodriguez@example.com", 
            trainerId: "trainer1",
            status: .new,
            joinedDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
            height: "5'4\"",
            weight: "130 lbs",
            goal: "Get back into fitness after having a baby",
            injuries: "Diastasis recti - working with pelvic floor PT",
            preferredCoachingStyle: .synchronous,
            lastActivityDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            totalWorkoutsCompleted: 2
        ),
        Client(
            id: "4", 
            name: "David Kim", 
            email: "david.kim@example.com", 
            trainerId: "trainer1",
            status: .paused,
            joinedDate: Calendar.current.date(byAdding: .day, value: -60, to: Date()),
            height: "6'1\"",
            weight: "200 lbs",
            goal: "Rehab shoulder injury and return to rock climbing",
            injuries: "Rotator cuff strain - in PT",
            preferredCoachingStyle: .hybrid,
            lastWorkoutDate: Calendar.current.date(byAdding: .day, value: -14, to: Date()),
            lastActivityDate: Calendar.current.date(byAdding: .day, value: -14, to: Date()),
            currentPlanId: "plan3",
            totalWorkoutsCompleted: 15
        ),
        Client(
            id: "5", 
            name: "Alex Thompson", 
            email: "alex.thompson@example.com", 
            trainerId: "trainer1",
            status: .pending,
            joinedDate: nil,
            goal: "Improve strength and mobility for aging gracefully",
            preferredCoachingStyle: .asynchronous,
            totalWorkoutsCompleted: 0
        )
    ]
}

// MARK: - Client Invitation Model
struct ClientInvitation: Identifiable, Codable {
    let id: String
    let trainerId: String
    let trainerName: String
    let clientEmail: String
    let clientName: String?
    let goal: String?
    let injuries: String?
    let preferredCoachingStyle: CoachingStyle?
    let status: InvitationStatus
    let createdAt: Date
    let expiresAt: Date
    
    init(id: String = UUID().uuidString,
         trainerId: String,
         trainerName: String,
         clientEmail: String,
         clientName: String? = nil,
         goal: String? = nil,
         injuries: String? = nil,
         preferredCoachingStyle: CoachingStyle? = nil,
         status: InvitationStatus = .pending,
         createdAt: Date = Date(),
         expiresAt: Date) {
        self.id = id
        self.trainerId = trainerId
        self.trainerName = trainerName
        self.clientEmail = clientEmail
        self.clientName = clientName
        self.goal = goal
        self.injuries = injuries
        self.preferredCoachingStyle = preferredCoachingStyle
        self.status = status
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
    
    static let sampleInvitations = [
        ClientInvitation(
            id: "inv1",
            trainerId: "trainer1",
            trainerName: "Your Trainer",
            clientEmail: "jessica.martin@example.com",
            clientName: "Jessica Martin",
            goal: "Build strength for hiking adventures",
            preferredCoachingStyle: .hybrid,
            status: .pending,
            createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            expiresAt: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
        )
    ]
}

// MARK: - Client Notes Model
struct ClientNote: Identifiable, Codable {
    var id: String
    var clientId: String
    var trainerId: String
    var content: String
    var type: NoteType
    var createdAt: Date
    var updatedAt: Date
    
    enum NoteType: String, Codable, CaseIterable {
        case trainerNote = "trainer_note"
        case clientJournal = "client_journal"
        case progressUpdate = "progress_update"
        case injuryUpdate = "injury_update"
        
        var displayName: String {
            switch self {
            case .trainerNote:
                return "Trainer Note"
            case .clientJournal:
                return "Client Journal"
            case .progressUpdate:
                return "Progress Update"
            case .injuryUpdate:
                return "Injury Update"
            }
        }
        
        var icon: String {
            switch self {
            case .trainerNote:
                return "note.text"
            case .clientJournal:
                return "book.fill"
            case .progressUpdate:
                return "chart.line.uptrend.xyaxis"
            case .injuryUpdate:
                return "cross.case.fill"
            }
        }
    }
    
    static let sampleNotes = [
        ClientNote(
            id: "note1",
            clientId: "1",
            trainerId: "trainer1",
            content: "Sarah showed excellent form today during our virtual session. She's really embracing the mind-body connection and asking great questions about breathing techniques.",
            type: .trainerNote,
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        ),
        ClientNote(
            id: "note2",
            clientId: "1",
            trainerId: "trainer1",
            content: "Feeling much stronger this week! The morning stretches are really helping with my back pain at work. Looking forward to adding some core work next week.",
            type: .clientJournal,
            createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            updatedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        )
    ]
}

// MARK: - Conversation Model
struct Conversation: Identifiable, Codable {
    let id = UUID()
    let clientName: String
    let lastMessage: String
    let lastMessageTime: Date
    let unreadCount: Int
    
    static let sampleConversations = [
        Conversation(clientName: "Sarah Johnson", lastMessage: "Thanks for the workout plan! I'm excited to get started.", lastMessageTime: Date().addingTimeInterval(-3600), unreadCount: 2),
        Conversation(clientName: "Mike Chen", lastMessage: "My knee is feeling much better after those mobility exercises.", lastMessageTime: Date().addingTimeInterval(-7200), unreadCount: 0),
        Conversation(clientName: "Emma Wilson", lastMessage: "Can we schedule a call this week?", lastMessageTime: Date().addingTimeInterval(-86400), unreadCount: 1)
    ]
}

// MARK: - Message Model
struct Message: Identifiable, Codable {
    let id: String
    let text: String
    let isFromTrainer: Bool
    let timestamp: Date
    
    static let sampleMessages = [
        Message(id: "1", text: "Hi! I'm excited to start working with you on your movement journey.", isFromTrainer: true, timestamp: Date().addingTimeInterval(-3600)),
        Message(id: "2", text: "Thank you! I'm looking forward to it too. When should we start?", isFromTrainer: false, timestamp: Date().addingTimeInterval(-3500)),
        Message(id: "3", text: "Let's begin with some basic mobility work. I'll send you a plan shortly.", isFromTrainer: true, timestamp: Date().addingTimeInterval(-3400)),
        Message(id: "4", text: "Sounds perfect! I really appreciate your approach to movement.", isFromTrainer: false, timestamp: Date().addingTimeInterval(-3300))
    ]
}

// MARK: - Workout Plan Model
struct WorkoutPlan: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let difficulty: WorkoutDifficulty
    let duration: Int // weeks
    let exercisesPerWeek: Int
    let sessionDuration: Int // minutes
    let tags: [String]
    let exercises: [String]
    let assignedClients: Int
    
    static let samplePlans = [
        WorkoutPlan(
            name: "Beginner Strength Foundation",
            description: "A gentle introduction to strength training focusing on form and basic movements.",
            difficulty: .beginner,
            duration: 6,
            exercisesPerWeek: 3,
            sessionDuration: 45,
            tags: ["Strength", "Beginner", "Foundation"],
            exercises: ["Bodyweight Squats", "Push-ups", "Planks", "Lunges", "Dead Bug"],
            assignedClients: 4
        ),
        WorkoutPlan(
            name: "Mobility & Recovery",
            description: "Focus on improving flexibility, mobility, and recovery for all fitness levels.",
            difficulty: .beginner,
            duration: 4,
            exercisesPerWeek: 4,
            sessionDuration: 30,
            tags: ["Mobility", "Recovery", "Flexibility", "Wellness"],
            exercises: ["Cat-Cow Stretch", "Hip Circles", "Shoulder Rolls", "Leg Swings"],
            assignedClients: 7
        ),
        WorkoutPlan(
            name: "Intermediate HIIT",
            description: "High-intensity interval training for improved cardiovascular fitness and strength.",
            difficulty: .intermediate,
            duration: 8,
            exercisesPerWeek: 4,
            sessionDuration: 60,
            tags: ["HIIT", "Cardio", "Strength", "Intermediate"],
            exercises: ["Burpees", "Mountain Climbers", "Jump Squats", "Battle Ropes"],
            assignedClients: 2
        )
    ]
}

// MARK: - Exercise Data Model
struct Exercise: Identifiable, Codable {
    var id: String
    var title: String
    var description: String?
    var mediaUrl: String? // For GIF/video later
    var category: ExerciseCategory?
    var duration: Int? // in minutes
    var difficulty: DifficultyLevel?
    var createdByTrainerId: String? // If trainers can add their own
    
    // Sample exercises for testing
    static let sampleExercises = [
        Exercise(
            id: "ex1",
            title: "Morning Stretch Routine",
            description: "Gentle stretches to start your day with intention and grace.",
            category: .flexibility,
            duration: 10,
            difficulty: .beginner
        ),
        Exercise(
            id: "ex2",
            title: "Mindful Walking",
            description: "Focus on breath and movement in a peaceful, meditative way.",
            category: .cardio,
            duration: 20,
            difficulty: .beginner
        ),
        Exercise(
            id: "ex3",
            title: "Core Strengthening Flow",
            description: "Build strength from your center with flowing, connected movements.",
            category: .strength,
            duration: 15,
            difficulty: .intermediate
        ),
        Exercise(
            id: "ex4",
            title: "Evening Wind Down",
            description: "Gentle movements to release tension and prepare for rest.",
            category: .flexibility,
            duration: 12,
            difficulty: .beginner
        )
    ]
}

// MARK: - Supporting Enums
enum ExerciseCategory: String, CaseIterable, Codable {
    case strength = "Strength"
    case cardio = "Cardio"
    case flexibility = "Flexibility"
    case balance = "Balance"
    case mindfulness = "Mindfulness"
    
    var icon: String {
        switch self {
        case .strength:
            return "dumbbell.fill"
        case .cardio:
            return "heart.fill"
        case .flexibility:
            return "figure.flexibility"
        case .balance:
            return "figure.yoga"
        case .mindfulness:
            return "leaf.fill"
        }
    }
}

enum DifficultyLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var color: String {
        switch self {
        case .beginner:
            return "success"
        case .intermediate:
            return "primaryTeal"
        case .advanced:
            return "secondaryPeach"
        }
    }
}

// MARK: - Trainer Profile Data Model
struct TrainerProfile: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var bio: String?
    var profileImageUrl: String?
    var specialties: [String]?
    var yearsOfExperience: Int?
    var createdAt: Date?
    var updatedAt: Date?
} 