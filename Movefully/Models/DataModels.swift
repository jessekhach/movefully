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
    
    // New detailed instruction fields
    var howToPerform: [String]? // Step-by-step instructions
    var trainerTips: [String]? // Professional coaching tips
    var commonMistakes: [String]? // What to avoid
    var modifications: [String]? // Easier/harder variations
    var equipmentNeeded: [String]? // Required equipment
    var targetMuscles: [String]? // Primary muscle groups
    var breathingCues: String? // Breathing instructions
    
    // Comprehensive exercise library shared by both trainers and clients
    static let sampleExercises = [
        // STRENGTH EXERCISES
        Exercise(
            id: "1",
            title: "Push-ups",
            description: "Classic upper body exercise for building chest, shoulder, and tricep strength",
            mediaUrl: nil,
            category: .strength,
            duration: 15,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Start in a plank position with hands placed slightly wider than shoulder-width apart",
                "Keep your body in a straight line from head to heels, engaging your core",
                "Lower your chest toward the floor by bending your elbows, keeping them at a 45-degree angle",
                "Lower until your chest nearly touches the ground or as far as comfortable",
                "Push through your palms to return to the starting position",
                "Maintain control throughout the entire movement"
            ],
            trainerTips: [
                "Focus on quality over quantity - perfect form is more important than speed",
                "Keep your core tight to prevent your hips from sagging or piking up",
                "If you can't maintain proper form, modify to knee push-ups or wall push-ups",
                "Breathe in as you lower down, breathe out as you push up",
                "Start with 3 sets of 5-8 reps and gradually increase as you get stronger"
            ],
            commonMistakes: [
                "Letting hips sag or pike up - maintain a straight line",
                "Flaring elbows too wide - keep them at 45 degrees from your body",
                "Not going through full range of motion",
                "Holding your breath during the movement",
                "Rushing through the exercise without control"
            ],
            modifications: [
                "Easier: Wall push-ups, incline push-ups on a bench, or knee push-ups",
                "Harder: Decline push-ups with feet elevated, single-arm push-ups, or diamond push-ups",
                "For wrist issues: Use push-up handles or perform on fists"
            ],
            equipmentNeeded: ["None (bodyweight only)"],
            targetMuscles: ["Chest", "Shoulders", "Triceps", "Core"],
            breathingCues: "Inhale as you lower down, exhale as you push up"
        ),
        Exercise(
            id: "2",
            title: "Squats",
            description: "Fundamental lower body movement for leg and glute strength",
            mediaUrl: nil,
            category: .strength,
            duration: 20,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Stand with feet shoulder-width apart, toes slightly turned out",
                "Keep your chest up and shoulders back, core engaged",
                "Initiate the movement by pushing your hips back as if sitting in a chair",
                "Bend at the hips and knees, lowering until thighs are parallel to the floor",
                "Keep your knees tracking over your toes, not caving inward",
                "Drive through your heels to return to the starting position",
                "Squeeze your glutes at the top of the movement"
            ],
            trainerTips: [
                "Think 'hips back first' rather than 'knees forward' to initiate the movement",
                "Keep your weight distributed across your whole foot, not just heels or toes",
                "If you can't reach parallel, squat as low as comfortable and gradually improve mobility",
                "Use a chair behind you as a guide when learning proper depth",
                "Focus on controlled movement - 2 seconds down, 1 second pause, 2 seconds up"
            ],
            commonMistakes: [
                "Knees caving inward - focus on pushing knees out over toes",
                "Leaning too far forward - keep chest up and core engaged",
                "Not going deep enough - aim for thighs parallel to floor",
                "Rising up on toes - keep feet flat on the ground",
                "Rounding the back - maintain neutral spine"
            ],
            modifications: [
                "Easier: Chair-assisted squats, partial range of motion, or wall squats",
                "Harder: Jump squats, single-leg pistol squats, or goblet squats with weight",
                "For knee issues: Limit depth to comfortable range"
            ],
            equipmentNeeded: ["None (bodyweight only)"],
            targetMuscles: ["Quadriceps", "Glutes", "Hamstrings", "Calves", "Core"],
            breathingCues: "Inhale as you lower down, exhale as you stand up"
        ),
        Exercise(
            id: "3",
            title: "Plank",
            description: "Core strengthening exercise for stability and endurance",
            mediaUrl: nil,
            category: .strength,
            duration: 10,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Start in a push-up position, then lower onto your forearms",
                "Place elbows directly under your shoulders, forearms parallel",
                "Create a straight line from your head to your heels",
                "Engage your core by pulling your belly button toward your spine",
                "Keep your hips level - don't let them sag or pike up",
                "Hold the position while breathing normally",
                "Keep your neck neutral by looking at the floor"
            ],
            trainerTips: [
                "Start with 15-30 second holds and gradually increase time",
                "Focus on maintaining perfect form rather than holding for a long time",
                "If you feel it mainly in your shoulders, you're likely not engaging your core enough",
                "Squeeze your glutes to help maintain proper hip position",
                "If you start to shake, that's normal - your muscles are working!"
            ],
            commonMistakes: [
                "Hips sagging toward the floor - engage core and glutes",
                "Hips too high in the air - lower to create straight line",
                "Holding breath - remember to breathe normally",
                "Elbows too far forward or back - keep directly under shoulders",
                "Looking up or to the side - maintain neutral neck"
            ],
            modifications: [
                "Easier: Knee plank, wall plank, or incline plank on a bench",
                "Harder: Single-arm plank, single-leg plank, or plank with leg lifts",
                "For wrist issues: Stay on forearms or use push-up handles"
            ],
            equipmentNeeded: ["None (bodyweight only)", "Optional: Exercise mat for comfort"],
            targetMuscles: ["Core", "Shoulders", "Glutes"],
            breathingCues: "Breathe normally and steadily - don't hold your breath"
        ),
        Exercise(
            id: "4",
            title: "Lunges",
            description: "Single-leg strengthening exercise for legs and core stability",
            mediaUrl: nil,
            category: .strength,
            duration: 15,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Stand tall with feet hip-width apart, hands on hips or at sides",
                "Take a large step forward with your right foot",
                "Lower your body by bending both knees to 90-degree angles",
                "Keep your front knee directly over your ankle, not pushed out past your toes",
                "Keep your back knee pointing toward the floor",
                "Push through your front heel to return to starting position",
                "Repeat on the other leg"
            ],
            trainerTips: [
                "Think of dropping your back knee straight down rather than lunging forward",
                "Keep most of your weight on your front leg throughout the movement",
                "Maintain an upright torso - avoid leaning forward",
                "Start with stationary lunges before progressing to walking lunges",
                "Focus on balance and control before adding speed or weight"
            ],
            commonMistakes: [
                "Front knee extending past toes - step out farther",
                "Leaning forward too much - keep chest up and core engaged",
                "Not lowering deep enough - aim for 90-degree angles in both knees",
                "Pushing off the back foot - drive through the front heel",
                "Taking too small a step - ensure adequate distance between feet"
            ],
            modifications: [
                "Easier: Hold onto a wall or chair for balance, or reduce the depth",
                "Harder: Walking lunges, reverse lunges, or add weights",
                "For knee issues: Reduce range of motion or try reverse lunges"
            ],
            equipmentNeeded: ["None (bodyweight only)"],
            targetMuscles: ["Quadriceps", "Glutes", "Hamstrings", "Calves", "Core"],
            breathingCues: "Inhale as you lower down, exhale as you push back up"
        ),
        Exercise(
            id: "5",
            title: "Dead Bug",
            description: "Core stability exercise that strengthens deep abdominal muscles",
            mediaUrl: nil,
            category: .strength,
            duration: 12,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Lie on your back with arms extended toward the ceiling",
                "Bend your hips and knees to 90 degrees, shins parallel to the floor",
                "Press your lower back into the floor and engage your core",
                "Slowly extend your right arm overhead while straightening your left leg",
                "Lower both limbs until they're just above the floor",
                "Return to starting position with control",
                "Repeat with opposite arm and leg"
            ],
            trainerTips: [
                "Keep your lower back pressed into the floor throughout the entire movement",
                "Move slowly and with control - this isn't about speed",
                "If you can't maintain back contact with floor, reduce the range of motion",
                "Focus on breathing steadily - don't hold your breath",
                "Start with just arm movements, then just legs, before combining both"
            ],
            commonMistakes: [
                "Lower back arching off the floor - reduce range of motion",
                "Moving too quickly - slow down and focus on control",
                "Holding breath - maintain steady breathing pattern",
                "Not engaging core before moving - activate abs first",
                "Touching limbs to the floor - stop just above ground"
            ],
            modifications: [
                "Easier: Move only arms or only legs, or reduce range of motion",
                "Harder: Hold light weights in hands or add resistance band",
                "For neck issues: Place a small pillow under your head"
            ],
            equipmentNeeded: ["Exercise mat (recommended)"],
            targetMuscles: ["Deep core muscles", "Hip flexors", "Shoulders"],
            breathingCues: "Exhale as you extend limbs, inhale as you return to start"
        ),
        Exercise(
            id: "6",
            title: "Glute Bridges",
            description: "Hip strengthening exercise targeting glutes and hamstrings",
            mediaUrl: nil,
            category: .strength,
            duration: 15,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Lie on your back with knees bent and feet flat on the floor",
                "Place feet hip-width apart, about 6 inches from your glutes",
                "Keep arms at your sides for stability",
                "Engage your core and squeeze your glutes",
                "Lift your hips up by pushing through your heels",
                "Create a straight line from knees to shoulders",
                "Hold briefly at the top, then lower with control"
            ],
            trainerTips: [
                "Focus on squeezing your glutes at the top of the movement",
                "Don't arch your back excessively - maintain neutral spine",
                "Push through your heels, not your toes",
                "Start with 2-second holds at the top and gradually increase",
                "If you feel it in your hamstrings more than glutes, bring feet closer to your body"
            ],
            commonMistakes: [
                "Arching the back too much - keep core engaged",
                "Not squeezing glutes at the top - focus on glute activation",
                "Feet too far from body - adjust foot position",
                "Rising up on toes - keep feet flat on floor",
                "Not going high enough - lift until hips are fully extended"
            ],
            modifications: [
                "Easier: Reduce range of motion or hold onto something for support",
                "Harder: Single-leg glute bridges, add resistance band, or hold weights",
                "For back issues: Place a pillow under your head and neck"
            ],
            equipmentNeeded: ["Exercise mat (recommended)"],
            targetMuscles: ["Glutes", "Hamstrings", "Core"],
            breathingCues: "Exhale as you lift up, inhale as you lower down"
        ),
        Exercise(
            id: "7",
            title: "Wall Push-ups",
            description: "Modified push-up for beginners or those with limited mobility",
            mediaUrl: nil,
            category: .strength,
            duration: 10,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Stand arm's length away from a wall",
                "Place your palms flat against the wall at shoulder height and width",
                "Keep your body in a straight line from head to heels",
                "Lean toward the wall by bending your elbows",
                "Keep your elbows at a 45-degree angle from your body",
                "Push back to the starting position",
                "Maintain core engagement throughout"
            ],
            trainerTips: [
                "This is perfect for building up to regular push-ups",
                "Focus on the same form cues as regular push-ups",
                "Step farther from the wall to increase difficulty",
                "Keep your body straight - don't let your hips stick out",
                "Progress by gradually stepping farther from the wall"
            ],
            commonMistakes: [
                "Standing too close to the wall - reduces effectiveness",
                "Letting hips stick out - maintain straight body line",
                "Flaring elbows too wide - keep at 45-degree angle",
                "Not engaging core - keep abs tight",
                "Rushing the movement - focus on control"
            ],
            modifications: [
                "Easier: Stand closer to the wall",
                "Harder: Step farther from wall, or progress to incline push-ups",
                "For wrist issues: Use fists instead of flat palms"
            ],
            equipmentNeeded: ["Wall"],
            targetMuscles: ["Chest", "Shoulders", "Triceps", "Core"],
            breathingCues: "Inhale as you lean toward wall, exhale as you push away"
        ),
        Exercise(
            id: "8",
            title: "Bird Dog",
            description: "Core stability exercise that improves balance and coordination",
            mediaUrl: nil,
            category: .strength,
            duration: 10,
            difficulty: .intermediate,
            createdByTrainerId: nil,
            howToPerform: [
                "Start on hands and knees in a tabletop position",
                "Place hands directly under shoulders, knees under hips",
                "Keep your spine in neutral position",
                "Simultaneously extend your right arm forward and left leg back",
                "Keep your hips level and avoid rotating your torso",
                "Hold for 2-5 seconds, then return to starting position",
                "Repeat with opposite arm and leg"
            ],
            trainerTips: [
                "Focus on stability rather than how high you can lift your limbs",
                "Imagine balancing a cup of water on your back",
                "Start by practicing just arm movements, then just legs",
                "Keep your extended leg in line with your torso, not higher",
                "Engage your core before lifting any limbs"
            ],
            commonMistakes: [
                "Lifting limbs too high - keep in line with torso",
                "Rotating hips or shoulders - keep square to the floor",
                "Arching or rounding the back - maintain neutral spine",
                "Moving too quickly - focus on slow, controlled movements",
                "Not engaging core first - activate abs before moving"
            ],
            modifications: [
                "Easier: Practice just arm lifts or just leg lifts separately",
                "Harder: Add resistance band or hold longer",
                "For wrist issues: Perform on forearms instead of hands"
            ],
            equipmentNeeded: ["Exercise mat (recommended)"],
            targetMuscles: ["Core", "Glutes", "Back muscles", "Shoulders"],
            breathingCues: "Breathe normally throughout - don't hold your breath"
        ),
        Exercise(
            id: "9",
            title: "Side Plank",
            description: "Lateral core strengthening exercise for obliques",
            mediaUrl: nil,
            category: .strength,
            duration: 8,
            difficulty: .intermediate,
            createdByTrainerId: nil,
            howToPerform: [
                "Lie on your side with legs extended and stacked",
                "Prop yourself up on your forearm, elbow directly under shoulder",
                "Lift your hips off the ground, creating a straight line from head to feet",
                "Keep your top hand on your hip or extended toward ceiling",
                "Engage your core and hold the position",
                "Keep your head in neutral position",
                "Repeat on the other side"
            ],
            trainerTips: [
                "Start with 10-15 second holds and gradually increase",
                "Focus on keeping your body in one straight line",
                "Don't let your hips sag toward the floor",
                "If too challenging, drop to your knees for modified version",
                "Breathe normally - don't hold your breath"
            ],
            commonMistakes: [
                "Hips sagging toward floor - engage obliques and lift",
                "Rolling forward or backward - stay in side plank plane",
                "Elbow too far from shoulder - keep directly underneath",
                "Holding breath - maintain steady breathing",
                "Looking up or down - keep neck neutral"
            ],
            modifications: [
                "Easier: Modified side plank on knees, or lean against wall",
                "Harder: Top leg lifts, or add rotation movements",
                "For shoulder issues: Perform against wall for support"
            ],
            equipmentNeeded: ["Exercise mat (recommended)"],
            targetMuscles: ["Obliques", "Core", "Shoulders", "Glutes"],
            breathingCues: "Breathe steadily throughout the hold"
        ),
        Exercise(
            id: "10",
            title: "Single-Leg Deadlift",
            description: "Balance and posterior chain strengthening exercise",
            mediaUrl: nil,
            category: .strength,
            duration: 12,
            difficulty: .intermediate,
            createdByTrainerId: nil,
            howToPerform: [
                "Stand on your right leg with a slight bend in the knee",
                "Keep your left leg slightly behind you",
                "Hinge at the hips, lowering your torso toward the floor",
                "Extend your left leg behind you for balance",
                "Keep your back straight and core engaged",
                "Lower until you feel a stretch in your hamstring",
                "Return to standing by driving through your right heel",
                "Complete all reps on one side before switching"
            ],
            trainerTips: [
                "This is a hip hinge movement, not a squat",
                "Focus on balance and control rather than how low you can go",
                "Use a wall or chair for balance support when learning",
                "Keep your hips square to the floor throughout",
                "Start with small range of motion and gradually increase"
            ],
            commonMistakes: [
                "Rounding the back - keep spine neutral",
                "Rotating hips - keep them square to the floor",
                "Bending standing leg too much - maintain slight knee bend",
                "Going too low too fast - build up range of motion gradually",
                "Not engaging core - keep abs tight for stability"
            ],
            modifications: [
                "Easier: Hold onto chair or wall for balance, or reduce range of motion",
                "Harder: Add light weights or close eyes for balance challenge",
                "For balance issues: Keep toe of lifted leg lightly touching ground"
            ],
            equipmentNeeded: ["None (bodyweight only)", "Optional: Chair or wall for balance"],
            targetMuscles: ["Hamstrings", "Glutes", "Core", "Calves"],
            breathingCues: "Inhale as you hinge forward, exhale as you return to standing"
        ),
        
        // CARDIO EXERCISES
        Exercise(
            id: "11",
            title: "Jumping Jacks",
            description: "Full body cardio exercise to elevate heart rate",
            mediaUrl: nil,
            category: .cardio,
            duration: 5,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Stand with feet together and arms at your sides",
                "Jump up and spread your feet to shoulder-width apart",
                "Simultaneously raise your arms overhead",
                "Jump again to return feet together and lower arms to sides",
                "Land softly on the balls of your feet",
                "Maintain a steady rhythm throughout",
                "Keep your core engaged and posture upright"
            ],
            trainerTips: [
                "Start slowly and build up speed as you warm up",
                "Land softly to reduce impact on your joints",
                "If you get winded, slow down rather than stopping completely",
                "Focus on coordination before worrying about speed",
                "This is great for warming up before other exercises"
            ],
            commonMistakes: [
                "Landing too heavily - focus on soft, controlled landings",
                "Arms not reaching overhead - get full range of motion",
                "Feet not coming together completely - touch heels together",
                "Holding breath - maintain steady breathing pattern",
                "Leaning forward - keep upright posture"
            ],
            modifications: [
                "Easier: Step-touch version without jumping, or half jacks (arms only)",
                "Harder: Add squat jacks or increase speed",
                "For joint issues: Low-impact version stepping side to side"
            ],
            equipmentNeeded: ["None (bodyweight only)"],
            targetMuscles: ["Full body", "Cardio", "Calves", "Shoulders"],
            breathingCues: "Breathe rhythmically - don't hold your breath"
        ),
        Exercise(
            id: "12",
            title: "Mountain Climbers",
            description: "Dynamic cardio exercise combining core and cardio work",
            mediaUrl: nil,
            category: .cardio,
            duration: 8,
            difficulty: .intermediate,
            createdByTrainerId: nil,
            howToPerform: [
                "Start in a plank position with hands under shoulders",
                "Keep your body in a straight line from head to heels",
                "Bring your right knee toward your chest",
                "Quickly switch legs, extending right leg back while bringing left knee forward",
                "Continue alternating legs in a running motion",
                "Keep your hips level and core engaged",
                "Maintain steady breathing throughout"
            ],
            trainerTips: [
                "Start slowly to master the form before increasing speed",
                "Keep your hips down - don't let them pike up",
                "Think of running in place while in plank position",
                "If you get tired, slow down rather than compromising form",
                "This exercise should elevate your heart rate quickly"
            ],
            commonMistakes: [
                "Hips too high - keep in plank position",
                "Hands moving or sliding - keep them planted firmly",
                "Not bringing knees close enough to chest",
                "Holding breath - maintain steady breathing",
                "Bouncing up and down - keep smooth, controlled movement"
            ],
            modifications: [
                "Easier: Slow mountain climbers or incline version with hands on bench",
                "Harder: Cross-body mountain climbers or increase speed",
                "For wrist issues: Use push-up handles or perform on forearms"
            ],
            equipmentNeeded: ["None (bodyweight only)", "Optional: Exercise mat"],
            targetMuscles: ["Core", "Shoulders", "Hip flexors", "Cardio"],
            breathingCues: "Quick, rhythmic breathing to match the movement pace"
        ),
        Exercise(
            id: "13",
            title: "Marching in Place",
            description: "Low-impact cardio movement to warm up or maintain fitness",
            mediaUrl: nil,
            category: .cardio,
            duration: 5,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Stand tall with feet hip-width apart",
                "Lift your right knee up toward your chest",
                "Lower right foot and immediately lift left knee",
                "Continue alternating legs in a marching motion",
                "Swing your arms naturally as you march",
                "Keep your core engaged and posture upright",
                "Maintain a steady, comfortable pace"
            ],
            trainerTips: [
                "This is perfect for warming up or active recovery",
                "Focus on lifting knees to a comfortable height",
                "Add arm movements to increase intensity",
                "Great exercise for beginners or those with joint issues",
                "Can be done anywhere with minimal space"
            ],
            commonMistakes: [
                "Leaning forward - keep upright posture",
                "Not lifting knees high enough - aim for hip height if possible",
                "Marching too fast - maintain controlled pace",
                "Forgetting to engage core - keep abs lightly activated",
                "Stiff arm movement - let arms swing naturally"
            ],
            modifications: [
                "Easier: March with smaller knee lifts or while seated",
                "Harder: High knees, add arm circles, or increase pace",
                "For balance issues: Hold onto chair or wall for support"
            ],
            equipmentNeeded: ["None (bodyweight only)"],
            targetMuscles: ["Hip flexors", "Core", "Calves", "Cardio"],
            breathingCues: "Breathe naturally and steadily throughout"
        ),
        Exercise(
            id: "14",
            title: "Step-ups",
            description: "Functional cardio exercise using stairs or platform",
            mediaUrl: nil,
            category: .cardio,
            duration: 10,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Stand in front of a sturdy step, bench, or bottom stair",
                "Place your right foot completely on the step",
                "Push through your right heel to step up",
                "Bring your left foot up to meet your right",
                "Step back down with your left foot first",
                "Follow with your right foot to return to starting position",
                "Repeat, leading with the same leg for all reps, then switch"
            ],
            trainerTips: [
                "Choose a step height that allows your knee to be at 90 degrees or less",
                "Focus on controlled movement rather than speed",
                "Use your leg muscles to step up, not momentum",
                "Keep your torso upright throughout the movement",
                "Start with a lower step and progress to higher surfaces"
            ],
            commonMistakes: [
                "Using momentum to bounce up - control the movement",
                "Not placing full foot on step - ensure complete foot contact",
                "Leaning forward too much - keep upright posture",
                "Step too high - choose appropriate height for your fitness level",
                "Not engaging core - keep abs activated for stability"
            ],
            modifications: [
                "Easier: Use a lower step or hold handrail for balance",
                "Harder: Increase step height, add weights, or increase pace",
                "For knee issues: Use very low step or just practice the motion"
            ],
            equipmentNeeded: ["Sturdy step, bench, or stairs"],
            targetMuscles: ["Quadriceps", "Glutes", "Calves", "Cardio"],
            breathingCues: "Exhale as you step up, inhale as you step down"
        ),
        Exercise(
            id: "15",
            title: "Butt Kicks",
            description: "Dynamic cardio movement for warming up and heart rate elevation",
            mediaUrl: nil,
            category: .cardio,
            duration: 5,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Stand tall with feet hip-width apart",
                "Begin jogging in place, bringing your heels toward your glutes",
                "Alternate legs quickly, kicking your heels up behind you",
                "Keep your thighs pointing down toward the floor",
                "Pump your arms naturally as you would when running",
                "Stay light on your feet and maintain good posture",
                "Keep your core engaged throughout"
            ],
            trainerTips: [
                "Focus on bringing heels to glutes rather than just lifting knees",
                "Start slowly and gradually increase the pace",
                "This is excellent for warming up your hamstrings",
                "Keep your upper body relaxed and natural",
                "Great exercise to do before running or leg workouts"
            ],
            commonMistakes: [
                "Leaning forward - keep upright posture",
                "Not bringing heels high enough - aim for glutes",
                "Landing too heavily - stay light on your feet",
                "Tensing shoulders - keep arms and shoulders relaxed",
                "Going too fast too soon - build up speed gradually"
            ],
            modifications: [
                "Easier: Slower pace or alternate single leg kicks",
                "Harder: Increase speed or add arm movements",
                "For joint issues: Perform while seated, just moving legs"
            ],
            equipmentNeeded: ["None (bodyweight only)"],
            targetMuscles: ["Hamstrings", "Glutes", "Calves", "Cardio"],
            breathingCues: "Breathe rhythmically to match your movement pace"
        ),
        Exercise(
            id: "16",
            title: "Burpees",
            description: "High-intensity full-body exercise combining strength and cardio",
            mediaUrl: nil,
            category: .cardio,
            duration: 8,
            difficulty: .advanced,
            createdByTrainerId: nil,
            howToPerform: [
                "Start standing with feet shoulder-width apart",
                "Squat down and place your hands on the floor",
                "Jump or step your feet back into a plank position",
                "Perform a push-up (optional for beginners)",
                "Jump or step your feet back toward your hands",
                "Explosively jump up with arms overhead",
                "Land softly and immediately begin the next rep"
            ],
            trainerTips: [
                "This is a challenging exercise - modify as needed",
                "Focus on maintaining good form throughout",
                "Start with 3-5 reps and build up gradually",
                "It's okay to step instead of jump when learning",
                "Take breaks as needed - quality over quantity"
            ],
            commonMistakes: [
                "Sagging hips in plank position - maintain straight line",
                "Landing too hard from jump - focus on soft landings",
                "Rushing through movements - maintain control",
                "Skipping the push-up when you're capable",
                "Not fully extending arms overhead on jump"
            ],
            modifications: [
                "Easier: Step back instead of jumping, omit push-up, or step up instead of jump",
                "Harder: Add a tuck jump or do on one leg",
                "For wrist issues: Use push-up handles or skip the push-up"
            ],
            equipmentNeeded: ["None (bodyweight only)", "Optional: Exercise mat"],
            targetMuscles: ["Full body", "Cardio", "Core", "Legs", "Arms"],
            breathingCues: "Exhale during explosive movements, inhale during transitions"
        ),
        Exercise(
            id: "17",
            title: "High Knees",
            description: "Cardio exercise to improve coordination and elevate heart rate",
            mediaUrl: nil,
            category: .cardio,
            duration: 5,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Stand tall with feet hip-width apart",
                "Begin running in place, lifting your knees as high as possible",
                "Aim to bring knees up to hip level or higher",
                "Pump your arms as you would when running",
                "Stay on the balls of your feet",
                "Maintain quick, light steps",
                "Keep your core engaged and posture upright"
            ],
            trainerTips: [
                "Focus on lifting knees high rather than moving forward",
                "Start at a moderate pace and build up speed",
                "Great for warming up before workouts",
                "Think of driving your knees up toward your chest",
                "Keep your steps quick and light"
            ],
            commonMistakes: [
                "Not lifting knees high enough - aim for hip level",
                "Leaning backward - maintain upright posture",
                "Landing too heavily - stay light on your feet",
                "Moving forward instead of staying in place",
                "Tensing shoulders - keep arms relaxed"
            ],
            modifications: [
                "Easier: Lower knee lifts or slower pace",
                "Harder: Increase speed or add arm movements",
                "For balance issues: Hold onto wall or chair for support"
            ],
            equipmentNeeded: ["None (bodyweight only)"],
            targetMuscles: ["Hip flexors", "Core", "Calves", "Cardio"],
            breathingCues: "Quick, rhythmic breathing to match the pace"
        ),
        Exercise(
            id: "18",
            title: "Jump Squats",
            description: "Plyometric exercise combining strength and cardio",
            mediaUrl: nil,
            category: .cardio,
            duration: 8,
            difficulty: .intermediate,
            createdByTrainerId: nil,
            howToPerform: [
                "Start in a squat position with feet shoulder-width apart",
                "Lower into a squat by pushing hips back and bending knees",
                "Explosively jump up, extending through your hips and knees",
                "Reach your arms overhead during the jump",
                "Land softly back into the squat position",
                "Immediately begin the next rep",
                "Keep your core engaged throughout"
            ],
            trainerTips: [
                "Focus on landing softly to protect your joints",
                "Start with regular squats before adding the jump",
                "Quality is more important than speed",
                "Take breaks if you can't maintain good form",
                "This exercise should significantly elevate your heart rate"
            ],
            commonMistakes: [
                "Landing too hard - focus on soft, controlled landings",
                "Not squatting deep enough before jumping",
                "Knees caving inward on landing - keep them aligned",
                "Not using arms for momentum - swing them overhead",
                "Rushing between reps - take a moment to reset if needed"
            ],
            modifications: [
                "Easier: Regular squats without jumping, or smaller jumps",
                "Harder: Single-leg jump squats or add weights",
                "For knee issues: Stick to regular squats or very small hops"
            ],
            equipmentNeeded: ["None (bodyweight only)"],
            targetMuscles: ["Quadriceps", "Glutes", "Calves", "Cardio"],
            breathingCues: "Exhale during the jump, inhale as you land and squat"
        ),
        
        // FLEXIBILITY EXERCISES
        Exercise(
            id: "19",
            title: "Child's Pose",
            description: "Gentle yoga stretch for relaxation and flexibility",
            mediaUrl: nil,
            category: .flexibility,
            duration: 5,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Start on your hands and knees in a tabletop position",
                "Bring your big toes together and separate your knees",
                "Sit back on your heels",
                "Extend your arms forward and lower your forehead to the floor",
                "Let your arms rest comfortably on the floor",
                "Breathe deeply and relax into the stretch",
                "Hold for 30 seconds to several minutes"
            ],
            trainerTips: [
                "This is a resting pose - focus on relaxation and breathing",
                "If your forehead doesn't reach the floor, use a pillow or block",
                "Great pose for stress relief and gentle back stretching",
                "Can be done anytime you need a moment of calm",
                "Listen to your body and adjust as needed for comfort"
            ],
            commonMistakes: [
                "Forcing the stretch - this should be comfortable and relaxing",
                "Holding tension in shoulders - let them relax completely",
                "Shallow breathing - focus on deep, calming breaths",
                "Sitting too far forward - settle back onto your heels",
                "Rushing out of the pose - take your time transitioning"
            ],
            modifications: [
                "Easier: Place a pillow between calves and thighs, or under forehead",
                "For knee issues: Place a cushion under your knees",
                "Alternative: Seated forward fold for similar benefits"
            ],
            equipmentNeeded: ["Exercise mat (recommended)", "Optional: Pillow or block"],
            targetMuscles: ["Lower back", "Hips", "Shoulders", "Mind (stress relief)"],
            breathingCues: "Deep, slow breathing to promote relaxation"
        ),
        Exercise(
            id: "20",
            title: "Cat-Cow Stretch",
            description: "Spinal mobility exercise that helps warm up your back",
            mediaUrl: nil,
            category: .flexibility,
            duration: 5,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Start on hands and knees in tabletop position",
                "Place wrists under shoulders and knees under hips",
                "For Cat pose: Round your spine toward the ceiling",
                "Tuck your chin toward your chest and engage your abs",
                "For Cow pose: Arch your back and lift your chest and tailbone",
                "Look up gently, creating a curve in your spine",
                "Flow smoothly between these two positions"
            ],
            trainerTips: [
                "Move slowly and mindfully between positions",
                "Let your breath guide the movement",
                "This is excellent for spinal mobility and warming up",
                "Focus on moving your entire spine, not just your neck",
                "Great to do first thing in the morning or before workouts"
            ],
            commonMistakes: [
                "Moving too quickly - slow down and focus on control",
                "Only moving the neck - engage your entire spine",
                "Holding breath - coordinate movement with breathing",
                "Forcing the range of motion - work within comfortable limits",
                "Collapsing through the shoulders - maintain arm strength"
            ],
            modifications: [
                "Easier: Perform while seated in a chair",
                "For wrist issues: Perform on forearms or use fists",
                "For knee issues: Place a cushion under knees"
            ],
            equipmentNeeded: ["Exercise mat (recommended)"],
            targetMuscles: ["Entire spine", "Core", "Shoulders", "Neck"],
            breathingCues: "Inhale during Cow pose, exhale during Cat pose"
        ),
        Exercise(
            id: "21",
            title: "Downward Dog",
            description: "Yoga pose that stretches hamstrings, calves, and shoulders",
            mediaUrl: nil,
            category: .flexibility,
            duration: 8,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Start on hands and knees in tabletop position",
                "Tuck your toes under and lift your hips up and back",
                "Straighten your legs as much as comfortable",
                "Create an inverted V-shape with your body",
                "Press your hands firmly into the ground",
                "Lengthen your spine and relax your head between your arms",
                "Pedal your feet to stretch your calves if desired"
            ],
            trainerTips: [
                "It's okay to keep a bend in your knees if hamstrings are tight",
                "Focus on lengthening your spine rather than straightening legs",
                "Press through your hands to take weight off your wrists",
                "This pose builds strength while providing a great stretch",
                "Start with shorter holds and gradually increase time"
            ],
            commonMistakes: [
                "Rounding the back - focus on lengthening the spine",
                "Putting too much weight on wrists - engage your arms",
                "Forcing straight legs - bend knees as needed",
                "Hunching shoulders - draw shoulder blades down your back",
                "Holding breath - maintain steady breathing"
            ],
            modifications: [
                "Easier: Use blocks under hands or bend knees significantly",
                "For wrist issues: Use forearms (dolphin prep) or push-up handles",
                "For tight hamstrings: Keep knees bent and focus on spine length"
            ],
            equipmentNeeded: ["Exercise mat (recommended)", "Optional: Blocks"],
            targetMuscles: ["Hamstrings", "Calves", "Shoulders", "Back", "Arms"],
            breathingCues: "Breathe deeply and steadily throughout the hold"
        ),
        Exercise(
            id: "22",
            title: "Hip Circles",
            description: "Dynamic mobility exercise for hip joint health",
            mediaUrl: nil,
            category: .flexibility,
            duration: 5,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Stand with feet hip-width apart, hands on your hips",
                "Begin making slow, controlled circles with your hips",
                "Start with small circles and gradually make them larger",
                "Complete 5-10 circles in one direction",
                "Reverse direction and repeat",
                "Keep your upper body relatively still",
                "Focus on smooth, fluid movement"
            ],
            trainerTips: [
                "This is great for warming up before exercise",
                "Start small and gradually increase the size of circles",
                "Perfect for people who sit a lot during the day",
                "Can be done anywhere - no equipment needed",
                "Listen to your body and stay within comfortable range"
            ],
            commonMistakes: [
                "Moving too fast - focus on slow, controlled movement",
                "Making circles too large too quickly - build up gradually",
                "Tensing upper body - keep shoulders and arms relaxed",
                "Holding breath - breathe naturally throughout",
                "Forcing the movement - work within your comfortable range"
            ],
            modifications: [
                "Easier: Smaller circles or hold onto chair for support",
                "Harder: Larger circles or single-leg hip circles",
                "For balance issues: Hold onto wall or chair"
            ],
            equipmentNeeded: ["None (bodyweight only)"],
            targetMuscles: ["Hip flexors", "Hip joints", "Core", "Lower back"],
            breathingCues: "Breathe naturally and rhythmically"
        ),
        Exercise(
            id: "23",
            title: "Shoulder Rolls",
            description: "Gentle mobility exercise for shoulder and neck tension",
            mediaUrl: nil,
            category: .flexibility,
            duration: 3,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Stand or sit with your arms relaxed at your sides",
                "Slowly lift your shoulders up toward your ears",
                "Roll them back, squeezing your shoulder blades together",
                "Lower your shoulders down",
                "Complete the circle by rolling them forward",
                "Perform 5-10 slow, controlled circles",
                "Reverse direction and repeat"
            ],
            trainerTips: [
                "Move slowly and focus on the full range of motion",
                "This is perfect for desk workers or anyone with shoulder tension",
                "Can be done anywhere - at work, in the car, or at home",
                "Focus on releasing tension with each roll",
                "Great to do throughout the day to prevent stiffness"
            ],
            commonMistakes: [
                "Moving too quickly - slow down for maximum benefit",
                "Not completing full circles - use the entire range of motion",
                "Tensing other muscles - keep neck and arms relaxed",
                "Holding breath - breathe naturally throughout",
                "Forcing the movement - work within comfortable limits"
            ],
            modifications: [
                "Easier: Smaller range of motion or single shoulder at a time",
                "Alternative: Gentle shoulder shrugs if full circles are uncomfortable",
                "Can be done seated or standing"
            ],
            equipmentNeeded: ["None (bodyweight only)"],
            targetMuscles: ["Shoulders", "Upper back", "Neck"],
            breathingCues: "Breathe naturally and deeply throughout"
        ),
        Exercise(
            id: "24",
            title: "Seated Spinal Twist",
            description: "Gentle spinal rotation to improve mobility and reduce tension",
            mediaUrl: nil,
            category: .flexibility,
            duration: 8,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Sit tall in a chair with feet flat on the floor",
                "Place your hands on your shoulders or cross them over your chest",
                "Keeping your hips facing forward, slowly rotate your torso to the right",
                "Turn as far as comfortable while maintaining good posture",
                "Hold for 15-30 seconds, breathing normally",
                "Return to center and repeat on the left side",
                "Keep your core gently engaged throughout"
            ],
            trainerTips: [
                "Focus on rotating from your spine, not just your shoulders",
                "Keep your hips square and facing forward",
                "This is excellent for people who sit for long periods",
                "Start with gentle rotations and gradually increase range",
                "Great for relieving lower back tension"
            ],
            commonMistakes: [
                "Rotating the hips instead of just the spine",
                "Forcing the twist - work within comfortable range",
                "Slouching or losing good posture",
                "Holding breath during the stretch",
                "Moving too quickly - focus on slow, controlled movement"
            ],
            modifications: [
                "Easier: Smaller range of motion or shorter holds",
                "Can also be done standing with hands on hips",
                "For back issues: Very gentle range of motion only"
            ],
            equipmentNeeded: ["Chair"],
            targetMuscles: ["Spine", "Obliques", "Lower back", "Core"],
            breathingCues: "Breathe deeply and steadily throughout the stretch"
        ),
        Exercise(
            id: "25",
            title: "Pigeon Pose",
            description: "Deep hip flexor stretch for improved mobility",
            mediaUrl: nil,
            category: .flexibility,
            duration: 10,
            difficulty: .intermediate,
            createdByTrainerId: nil,
            howToPerform: [
                "Start in a tabletop position on hands and knees",
                "Bring your right knee forward and place it behind your right wrist",
                "Extend your left leg straight back behind you",
                "Square your hips toward the front of your mat",
                "Lower down onto your forearms or forehead if comfortable",
                "Hold for 30 seconds to 2 minutes",
                "Slowly come out and repeat on the other side"
            ],
            trainerTips: [
                "This is an intense stretch - go slowly and listen to your body",
                "Use props like pillows or blocks under your hip if needed",
                "Focus on breathing deeply to help release tension",
                "It's normal to feel tight - don't force the stretch",
                "This pose targets deep hip muscles that are often tight"
            ],
            commonMistakes: [
                "Forcing the stretch - this should be intense but not painful",
                "Not supporting the body with props when needed",
                "Holding breath - breathe deeply throughout",
                "Uneven hips - try to keep them square",
                "Coming out of the pose too quickly"
            ],
            modifications: [
                "Easier: Use blocks or pillows under the hip, or try figure-4 stretch",
                "For knee issues: Try a seated figure-4 stretch instead",
                "Beginner: Reclined pigeon pose lying on your back"
            ],
            equipmentNeeded: ["Exercise mat", "Optional: Blocks or pillows"],
            targetMuscles: ["Hip flexors", "Glutes", "Piriformis", "IT band"],
            breathingCues: "Deep, slow breathing to help release tension"
        ),
        Exercise(
            id: "26",
            title: "Cobra Stretch",
            description: "Backbend that opens the chest and strengthens the spine",
            mediaUrl: nil,
            category: .flexibility,
            duration: 5,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Lie face down with your forehead on the mat",
                "Place your palms flat on the floor under your shoulders",
                "Press your hips and legs into the floor",
                "Slowly lift your chest by pressing through your hands",
                "Keep your shoulders away from your ears",
                "Look straight ahead or slightly upward",
                "Hold for 15-30 seconds, then lower down slowly"
            ],
            trainerTips: [
                "Start small and gradually increase the backbend",
                "Focus on lengthening your spine rather than just lifting high",
                "This is great for counteracting forward head posture",
                "Keep your legs active and pressing into the floor",
                "Excellent for people who spend time hunched over computers"
            ],
            commonMistakes: [
                "Lifting too high too quickly - build up gradually",
                "Putting too much weight on hands - use back muscles",
                "Hunching shoulders - keep them away from ears",
                "Holding breath - breathe steadily throughout",
                "Forcing the neck back - keep it in line with spine"
            ],
            modifications: [
                "Easier: Sphinx pose (on forearms) or smaller lift",
                "For lower back issues: Very gentle range of motion",
                "For wrist issues: Try sphinx pose on forearms"
            ],
            equipmentNeeded: ["Exercise mat"],
            targetMuscles: ["Back extensors", "Chest", "Shoulders", "Core"],
            breathingCues: "Inhale as you lift up, exhale as you lower down"
        ),
        
        // BALANCE EXERCISES
        Exercise(
            id: "27",
            title: "Tree Pose",
            description: "Balance exercise to improve stability and focus",
            mediaUrl: nil,
            category: .balance,
            duration: 10,
            difficulty: .intermediate,
            createdByTrainerId: nil,
            howToPerform: [
                "Stand tall with feet hip-width apart",
                "Shift your weight to your left foot",
                "Bend your right knee and place your right foot on your inner left thigh",
                "Avoid placing foot directly on the side of your knee",
                "Press your foot into your leg and your leg into your foot",
                "Bring your hands to prayer position at your chest",
                "Hold for 30 seconds to 1 minute, then switch sides"
            ],
            trainerTips: [
                "Find a focal point to help maintain balance",
                "It's normal to wobble - that's your balance system working",
                "Start by holding onto a wall if needed",
                "Focus on your breath to help maintain calm and balance",
                "This pose improves both physical balance and mental focus"
            ],
            commonMistakes: [
                "Placing foot on the side of the knee - avoid this area",
                "Holding breath - breathe normally throughout",
                "Tensing the standing leg - keep a micro-bend in the knee",
                "Looking around - maintain focus on one point",
                "Giving up too quickly - balance improves with practice"
            ],
            modifications: [
                "Easier: Keep toe on floor with heel on ankle, or hold wall for support",
                "Harder: Close your eyes or raise arms overhead",
                "For ankle issues: Keep both feet on ground and just shift weight"
            ],
            equipmentNeeded: ["None (bodyweight only)", "Optional: Wall for support"],
            targetMuscles: ["Core", "Ankles", "Calves", "Hip stabilizers"],
            breathingCues: "Breathe slowly and steadily to maintain calm focus"
        ),
        Exercise(
            id: "28",
            title: "Single-Leg Stand",
            description: "Simple balance exercise for proprioception and stability",
            mediaUrl: nil,
            category: .balance,
            duration: 5,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Stand tall with feet hip-width apart",
                "Shift your weight to your right foot",
                "Lift your left foot slightly off the ground",
                "Keep your lifted leg relaxed, knee slightly bent",
                "Maintain good posture with shoulders back",
                "Hold for 10-30 seconds",
                "Lower your foot and repeat on the other side"
            ],
            trainerTips: [
                "Start with shorter holds and gradually increase time",
                "Focus on a point in front of you to help with balance",
                "This exercise improves ankle stability and proprioception",
                "Great for injury prevention and functional movement",
                "Can be done anywhere throughout the day"
            ],
            commonMistakes: [
                "Lifting the leg too high - just off the ground is enough",
                "Tensing up - stay relaxed and breathe normally",
                "Looking down - keep eyes focused ahead",
                "Holding onto something when not needed",
                "Getting frustrated with wobbling - it's normal and beneficial"
            ],
            modifications: [
                "Easier: Hold onto chair or wall, or keep toe lightly touching ground",
                "Harder: Close eyes, stand on unstable surface, or add arm movements",
                "For ankle issues: Very short holds or just weight shifting"
            ],
            equipmentNeeded: ["None (bodyweight only)", "Optional: Chair for support"],
            targetMuscles: ["Core", "Ankles", "Calves", "Hip stabilizers"],
            breathingCues: "Breathe naturally and calmly throughout"
        ),
        Exercise(
            id: "29",
            title: "Heel-to-Toe Walk",
            description: "Balance and coordination exercise along a straight line",
            mediaUrl: nil,
            category: .balance,
            duration: 5,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Find a straight line on the floor or imagine one",
                "Stand at one end with feet together",
                "Step forward, placing your heel directly in front of your other foot's toes",
                "The heel of your front foot should touch the toes of your back foot",
                "Take 10-20 steps forward in this heel-to-toe pattern",
                "Keep your arms out to the sides for balance if needed",
                "Turn around and walk back"
            ],
            trainerTips: [
                "This exercise improves dynamic balance and coordination",
                "Start slowly and focus on accuracy rather than speed",
                "Great for improving gait and preventing falls",
                "Can be done in a hallway or any straight space",
                "Focus on a point ahead of you while walking"
            ],
            commonMistakes: [
                "Walking too fast - slow down and focus on precision",
                "Not actually touching heel to toe - ensure contact",
                "Looking down at feet - keep eyes focused ahead",
                "Tensing arms - let them move naturally for balance",
                "Getting discouraged by wobbling - it's part of the learning process"
            ],
            modifications: [
                "Easier: Walk along a wider line or hold onto wall",
                "Harder: Close eyes or walk backwards",
                "For balance issues: Start with regular walking, then progress"
            ],
            equipmentNeeded: ["None (bodyweight only)", "Optional: Tape for line on floor"],
            targetMuscles: ["Core", "Ankles", "Calves", "Hip stabilizers", "Coordination"],
            breathingCues: "Breathe naturally while maintaining focus"
        ),
        Exercise(
            id: "30",
            title: "Warrior III",
            description: "Challenging yoga balance pose that strengthens legs and core",
            mediaUrl: nil,
            category: .balance,
            duration: 8,
            difficulty: .advanced,
            createdByTrainerId: nil,
            howToPerform: [
                "Start standing with feet hip-width apart",
                "Shift weight to your right foot",
                "Hinge forward at the hips while lifting your left leg behind you",
                "Extend your arms forward or keep them at your sides",
                "Create a straight line from your fingertips to your lifted heel",
                "Keep your hips square to the floor",
                "Hold for 15-30 seconds, then switch sides"
            ],
            trainerTips: [
                "This is an advanced pose - build up gradually",
                "Focus on the hip hinge movement rather than just lifting the leg",
                "Start with hands on hips or use a wall for support",
                "Quality over quantity - shorter holds with good form are better",
                "This pose builds incredible strength and balance"
            ],
            commonMistakes: [
                "Lifting leg too high and losing balance - focus on alignment",
                "Opening hips instead of keeping them square",
                "Rounding the back - maintain straight spine",
                "Holding breath - breathe steadily throughout",
                "Rushing into the full pose - build up gradually"
            ],
            modifications: [
                "Easier: Keep hands on hips, use a wall support, or keep toe on ground",
                "Beginner: Practice the hip hinge movement first",
                "For balance issues: Hold onto chair or wall"
            ],
            equipmentNeeded: ["None (bodyweight only)", "Optional: Wall or chair for support"],
            targetMuscles: ["Core", "Glutes", "Hamstrings", "Standing leg", "Back"],
            breathingCues: "Steady, controlled breathing to maintain focus and balance"
        ),
        
        // MINDFULNESS EXERCISES
        Exercise(
            id: "31",
            title: "Deep Breathing",
            description: "Mindfulness exercise for stress relief and mental clarity",
            mediaUrl: nil,
            category: .mindfulness,
            duration: 5,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Sit comfortably or lie down in a quiet space",
                "Close your eyes or soften your gaze downward",
                "Place one hand on your chest, one on your belly",
                "Breathe in slowly through your nose for 4 counts",
                "Feel your belly rise more than your chest",
                "Hold your breath gently for 2 counts",
                "Exhale slowly through your mouth for 6 counts",
                "Repeat for 5-10 breath cycles"
            ],
            trainerTips: [
                "This is one of the most powerful stress-relief tools available",
                "Focus on making your exhale longer than your inhale",
                "If counting feels stressful, just focus on slow, deep breaths",
                "Can be done anywhere - at work, in the car, before bed",
                "Regular practice helps build resilience to stress"
            ],
            commonMistakes: [
                "Breathing too forcefully - keep it gentle and natural",
                "Focusing too much on perfect counting - rhythm matters more",
                "Breathing only into the chest - focus on belly breathing",
                "Getting frustrated if mind wanders - this is normal",
                "Holding breath too long - keep it comfortable"
            ],
            modifications: [
                "Easier: Just focus on natural breathing without counting",
                "For anxiety: Try 4-7-8 breathing (inhale 4, hold 7, exhale 8)",
                "Can be done sitting, lying down, or even standing"
            ],
            equipmentNeeded: ["None"],
            targetMuscles: ["Diaphragm", "Nervous system", "Mind"],
            breathingCues: "This IS the breathing exercise - focus on slow, deep breaths"
        ),
        Exercise(
            id: "32",
            title: "Body Scan Meditation",
            description: "Mindful awareness practice to connect with your body",
            mediaUrl: nil,
            category: .mindfulness,
            duration: 10,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Lie down comfortably on your back",
                "Close your eyes and take a few deep breaths",
                "Start by noticing your toes - how do they feel?",
                "Slowly move your attention up through your feet, ankles, calves",
                "Continue scanning up through your legs, hips, torso",
                "Notice your arms, hands, shoulders, neck, and head",
                "Don't try to change anything - just observe",
                "If you notice tension, breathe into that area"
            ],
            trainerTips: [
                "This practice helps develop body awareness and relaxation",
                "There's no 'right' way to feel - just notice what's there",
                "If your mind wanders, gently return to the body part you were on",
                "Great for before sleep or when feeling disconnected from your body",
                "Regular practice can help identify areas of chronic tension"
            ],
            commonMistakes: [
                "Trying to force relaxation - just observe without judgment",
                "Moving too quickly through body parts - take your time",
                "Getting frustrated with wandering mind - this is completely normal",
                "Expecting to feel something specific - be open to whatever arises",
                "Skipping areas that feel uncomfortable - include everything"
            ],
            modifications: [
                "Easier: Start with just hands and feet, or use a guided recording",
                "Shorter version: Focus on just your face and shoulders",
                "Can be done sitting if lying down is uncomfortable"
            ],
            equipmentNeeded: ["Comfortable surface to lie on", "Optional: Pillow or blanket"],
            targetMuscles: ["Full body awareness", "Nervous system", "Mind"],
            breathingCues: "Breathe naturally while scanning - use breath to soften tense areas"
        ),
        Exercise(
            id: "33",
            title: "Mindful Walking",
            description: "Moving meditation focusing on each step and breath",
            mediaUrl: nil,
            category: .mindfulness,
            duration: 15,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Find a quiet path or space where you can walk slowly",
                "Begin walking at about half your normal pace",
                "Focus on the sensation of your feet touching the ground",
                "Notice the lifting, moving, and placing of each foot",
                "Coordinate your breathing with your steps if it feels natural",
                "When your mind wanders, gently return focus to your feet",
                "Pay attention to your surroundings without judgment",
                "End by standing still for a moment and noticing how you feel"
            ],
            trainerTips: [
                "This combines the benefits of movement with mindfulness",
                "Perfect for people who find sitting meditation challenging",
                "Can be done indoors in a hallway or outdoors in nature",
                "Focus on quality of attention rather than distance covered",
                "Great way to transition between activities mindfully"
            ],
            commonMistakes: [
                "Walking too fast - slow down to really feel each step",
                "Trying to think about nothing - it's okay to notice thoughts",
                "Focusing only on feet - include awareness of whole body and environment",
                "Getting goal-oriented about distance - focus on the process",
                "Judging the experience - approach with curiosity and openness"
            ],
            modifications: [
                "Easier: Start with just 5 minutes or walk at normal pace",
                "Indoor version: Walk slowly back and forth in a hallway",
                "For mobility issues: Focus on mindful movement in wheelchair or chair"
            ],
            equipmentNeeded: ["Safe walking space"],
            targetMuscles: ["Legs", "Core", "Mind", "Awareness"],
            breathingCues: "Breathe naturally - some people like to coordinate breath with steps"
        ),
        Exercise(
            id: "34",
            title: "Gratitude Practice",
            description: "Mindfulness exercise focusing on appreciation and positivity",
            mediaUrl: nil,
            category: .mindfulness,
            duration: 5,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Sit comfortably and close your eyes or soften your gaze",
                "Take a few deep breaths to center yourself",
                "Think of three things you're grateful for today",
                "Start with something simple - maybe your morning coffee or a comfortable bed",
                "For each item, really feel the appreciation in your body",
                "Notice where you feel gratitude - your heart, chest, or whole body",
                "Spend 30-60 seconds with each gratitude item",
                "End by taking a deep breath and opening your eyes"
            ],
            trainerTips: [
                "Research shows gratitude practice can improve mood and health",
                "Start small - even appreciating basic things like food or shelter counts",
                "Try to feel the emotion, not just think the thoughts",
                "Can be done anytime you need a mood boost",
                "Consider keeping a gratitude journal for deeper practice"
            ],
            commonMistakes: [
                "Rushing through the list - take time to really feel each item",
                "Only thinking of big things - small daily pleasures count too",
                "Judging your gratitude items - there's no right or wrong",
                "Forcing positive feelings - just notice what naturally arises",
                "Making it complicated - simple appreciation is powerful"
            ],
            modifications: [
                "Easier: Start with just one thing you're grateful for",
                "Harder: Include difficult situations you're grateful to have learned from",
                "Can be done while walking or as part of another activity"
            ],
            equipmentNeeded: ["None"],
            targetMuscles: ["Heart", "Mind", "Emotional well-being"],
            breathingCues: "Breathe naturally while focusing on feelings of appreciation"
        ),
        Exercise(
            id: "35",
            title: "Progressive Muscle Relaxation",
            description: "Systematic tension and relaxation of muscle groups",
            mediaUrl: nil,
            category: .mindfulness,
            duration: 15,
            difficulty: .beginner,
            createdByTrainerId: nil,
            howToPerform: [
                "Lie down comfortably and close your eyes",
                "Start with your toes - tense them tightly for 5 seconds",
                "Release the tension and notice the relaxation for 10 seconds",
                "Move to your calves - tense for 5 seconds, then relax",
                "Continue up through thighs, glutes, abdomen, hands, arms",
                "Include shoulders, neck, face, and forehead",
                "For each muscle group: tense, hold, release, and notice",
                "End by lying still and enjoying the full-body relaxation"
            ],
            trainerTips: [
                "This technique helps you learn the difference between tension and relaxation",
                "Great for people who carry stress in their muscles",
                "Perfect before bed to help with sleep",
                "Don't tense so hard that you cause pain - firm tension is enough",
                "The contrast between tension and relaxation is key to the technique"
            ],
            commonMistakes: [
                "Tensing too hard - use about 70% of your maximum tension",
                "Not holding the tension long enough - aim for 5 seconds",
                "Rushing through muscle groups - take time with each one",
                "Forgetting to notice the relaxation phase - this is the most important part",
                "Tensing multiple muscle groups at once - focus on one area at a time"
            ],
            modifications: [
                "Easier: Just focus on major muscle groups (legs, arms, shoulders, face)",
                "For injury: Skip any areas that are painful or injured",
                "Can be done sitting if lying down is uncomfortable"
            ],
            equipmentNeeded: ["Comfortable surface to lie on"],
            targetMuscles: ["All major muscle groups", "Nervous system", "Mind"],
            breathingCues: "Breathe normally during tension, breathe out as you release"
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