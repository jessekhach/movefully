import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

class ExerciseLibraryViewModel: ObservableObject {
    @Published var exercises: [WellnessExercise] = []
    @Published var filteredExercises: [WellnessExercise] = []
    @Published var isLoading: Bool = false
    @Published var searchText: String = ""
    @Published var selectedCategory: ExerciseCategory? = nil
    @Published var selectedDifficulty: ExerciseDifficulty? = nil
    @Published var errorMessage: String = ""
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSampleData()
        setupSearchAndFilter()
    }
    
    private func loadSampleData() {
        exercises = WellnessExercise.sampleExercises
    }
    
    private func setupSearchAndFilter() {
        // Combine search text and filter changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        $selectedCategory
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        $selectedDifficulty
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    private func applyFilters() {
        var filtered = exercises
        
        // Apply search filter
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let searchQuery = searchText.lowercased()
            filtered = filtered.filter { exercise in
                exercise.name.lowercased().contains(searchQuery) ||
                exercise.description.lowercased().contains(searchQuery) == true
            }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply difficulty filter
        if let difficulty = selectedDifficulty {
            filtered = filtered.filter { $0.difficulty == difficulty }
        }
        
        filteredExercises = filtered
        print("🔍 Applied filters: \(filteredExercises.count) exercises match criteria")
    }
    
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedDifficulty = nil
    }
    
    func refreshExercises() {
        loadSampleData()
    }
    
    // Computed properties for filter UI
    var categoriesWithCounts: [(ExerciseCategory, Int)] {
        ExerciseCategory.allCases.map { category in
            let count = exercises.filter { $0.category == category }.count
            return (category, count)
        }.filter { $0.1 > 0 }
    }
    
    var difficultiesWithCounts: [(ExerciseDifficulty, Int)] {
        ExerciseDifficulty.allCases.map { difficulty in
            let count = exercises.filter { $0.difficulty == difficulty }.count
            return (difficulty, count)
        }.filter { $0.1 > 0 }
    }
    
    var hasActiveFilters: Bool {
        !searchText.isEmpty || selectedCategory != nil || selectedDifficulty != nil
    }
    
    var filteredExercisesCount: Int {
        filteredExercises.count
    }
    
    var totalExercisesCount: Int {
        exercises.count
    }
}

// MARK: - Exercise Data Models

// Type alias for compatibility
typealias Exercise = WellnessExercise

struct WellnessExercise: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let category: ExerciseCategory
    let difficulty: ExerciseDifficulty
    let equipment: [EquipmentType]
    let targetMuscles: [String]
    let duration: String
    let instructions: [String]
    let tips: [String]
    let modifications: [String]
    let imageURL: String?
    let videoURL: String?
    
    static let sampleExercises: [WellnessExercise] = [
        // Strength Exercises - Bodyweight
        WellnessExercise(
            id: "1",
            name: "Push-ups",
            description: "Classic bodyweight exercise targeting chest, shoulders, and triceps",
            category: .strength,
            difficulty: .beginner,
            equipment: [.none],
            targetMuscles: ["Chest", "Shoulders", "Triceps", "Core"],
            duration: "3 sets of 8-15 reps",
            instructions: [
                "Start in plank position with hands slightly wider than shoulders",
                "Lower body until chest nearly touches floor",
                "Push back up to starting position",
                "Keep core engaged throughout movement"
            ],
            tips: [
                "Keep your body in a straight line",
                "Don't let hips sag or pike up",
                "Control the descent"
            ],
            modifications: [
                "Knee push-ups for beginners",
                "Incline push-ups on bench or wall",
                "Diamond push-ups for advanced"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "2",
            name: "Squats",
            description: "Fundamental lower body exercise for building leg and glute strength",
            category: .strength,
            difficulty: .beginner,
            equipment: [.none],
            targetMuscles: ["Quadriceps", "Glutes", "Hamstrings", "Calves"],
            duration: "3 sets of 12-20 reps",
            instructions: [
                "Stand with feet shoulder-width apart",
                "Lower hips back and down as if sitting in chair",
                "Keep chest up and knees tracking over toes",
                "Push through heels to return to standing"
            ],
            tips: [
                "Don't let knees cave inward",
                "Keep weight in heels",
                "Go as low as comfortable"
            ],
            modifications: [
                "Chair-assisted squats",
                "Goblet squats with weight",
                "Jump squats for cardio"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "3",
            name: "Lunges",
            description: "Unilateral lower body exercise that improves balance and leg strength",
            category: .strength,
            difficulty: .beginner,
            equipment: [.none],
            targetMuscles: ["Quadriceps", "Glutes", "Hamstrings", "Calves"],
            duration: "3 sets of 10 reps each leg",
            instructions: [
                "Step forward with one leg, lowering hips",
                "Both knees should be at 90-degree angles",
                "Front thigh parallel to floor",
                "Push back to starting position"
            ],
            tips: [
                "Keep torso upright",
                "Don't let front knee go past toes",
                "Control the movement"
            ],
            modifications: [
                "Reverse lunges",
                "Static lunges",
                "Walking lunges for advanced"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "4",
            name: "Plank",
            description: "Isometric core exercise that builds strength and stability",
            category: .strength,
            difficulty: .beginner,
            equipment: [.none],
            targetMuscles: ["Core", "Shoulders", "Back"],
            duration: "3 sets of 30-60 seconds",
            instructions: [
                "Start in push-up position",
                "Hold body in straight line from head to heels",
                "Engage core and breathe normally",
                "Hold for target time"
            ],
            tips: [
                "Don't let hips sag or pike up",
                "Keep head neutral",
                "Breathe steadily"
            ],
            modifications: [
                "Knee plank for beginners",
                "Side planks",
                "Plank with leg lifts for advanced"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "5",
            name: "Pull-ups",
            description: "Upper body strength exercise using body weight",
            category: .strength,
            difficulty: .advanced,
            equipment: [.pullUpBar],
            targetMuscles: ["Lats", "Biceps", "Upper Back", "Core"],
            duration: "3 sets of 5-12 reps",
            instructions: [
                "Hang from pull-up bar with palms facing away",
                "Pull body up until chin clears bar",
                "Lower with control to full hang",
                "Keep core engaged throughout"
            ],
            tips: [
                "Avoid swinging or kipping",
                "Full range of motion",
                "Control the negative"
            ],
            modifications: [
                "Assisted pull-ups with band",
                "Negative pull-ups",
                "Chin-ups (palms facing you)"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        // Strength Exercises - With Equipment
        WellnessExercise(
            id: "6",
            name: "Dumbbell Bicep Curls",
            description: "Isolation exercise targeting the bicep muscles",
            category: .strength,
            difficulty: .beginner,
            equipment: [.dumbbells],
            targetMuscles: ["Biceps", "Forearms"],
            duration: "3 sets of 10-15 reps",
            instructions: [
                "Stand with feet shoulder-width apart, dumbbells in hands",
                "Keep elbows close to torso",
                "Curl weights up toward shoulders",
                "Lower with control"
            ],
            tips: [
                "Don't swing the weights",
                "Keep wrists neutral",
                "Focus on the muscle contraction"
            ],
            modifications: [
                "Use resistance bands",
                "Alternate arms",
                "Seated position"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "7",
            name: "Dumbbell Rows",
            description: "Strengthens the back muscles and improves posture",
            category: .strength,
            difficulty: .intermediate,
            equipment: [.dumbbells],
            targetMuscles: ["Lats", "Rhomboids", "Middle Traps", "Biceps"],
            duration: "3 sets of 8-12 reps",
            instructions: [
                "Bend over with dumbbell in hand",
                "Support yourself with other hand on bench",
                "Pull dumbbell to hip, squeezing shoulder blade",
                "Lower with control"
            ],
            tips: [
                "Keep back neutral",
                "Pull with your back, not just arms",
                "Squeeze at the top"
            ],
            modifications: [
                "Two-arm bent-over rows",
                "Seated rows with resistance band",
                "Single-arm cable rows"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "8",
            name: "Dumbbell Shoulder Press",
            description: "Builds shoulder strength and stability",
            category: .strength,
            difficulty: .intermediate,
            equipment: [.dumbbells],
            targetMuscles: ["Shoulders", "Triceps", "Upper Chest"],
            duration: "3 sets of 8-12 reps",
            instructions: [
                "Hold dumbbells at shoulder height",
                "Press weights overhead",
                "Lower with control to start position",
                "Keep core engaged"
            ],
            tips: [
                "Don't arch your back excessively",
                "Control the weight on the way down",
                "Full range of motion"
            ],
            modifications: [
                "Seated shoulder press",
                "Single-arm press",
                "Pike push-ups for bodyweight"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        // Cardio Exercises
        WellnessExercise(
            id: "9",
            name: "Jumping Jacks",
            description: "Full-body cardio exercise that gets your heart rate up quickly",
            category: .cardio,
            difficulty: .beginner,
            equipment: [.none],
            targetMuscles: ["Full Body", "Cardiovascular System"],
            duration: "30-60 seconds",
            instructions: [
                "Start standing with feet together, arms at sides",
                "Jump feet apart while raising arms overhead",
                "Jump back to starting position",
                "Maintain steady rhythm"
            ],
            tips: [
                "Land softly on balls of feet",
                "Keep core engaged",
                "Breathe steadily"
            ],
            modifications: [
                "Step-touch version for low impact",
                "Half jacks (arms only)",
                "Star jumps for more intensity"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "10",
            name: "Burpees",
            description: "High-intensity full-body exercise combining strength and cardio",
            category: .cardio,
            difficulty: .advanced,
            equipment: [.none],
            targetMuscles: ["Full Body", "Cardiovascular System"],
            duration: "3 sets of 5-10 reps",
            instructions: [
                "Start standing, then squat down and place hands on floor",
                "Jump or step feet back into plank position",
                "Perform push-up (optional)",
                "Jump or step feet back to squat, then jump up"
            ],
            tips: [
                "Maintain good form over speed",
                "Modify as needed",
                "Control your breathing"
            ],
            modifications: [
                "Step back instead of jumping",
                "Remove push-up",
                "Remove jump at top"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "11",
            name: "High Knees",
            description: "Dynamic cardio exercise that improves coordination and leg strength",
            category: .cardio,
            difficulty: .beginner,
            equipment: [.none],
            targetMuscles: ["Hip Flexors", "Calves", "Core"],
            duration: "30-45 seconds",
            instructions: [
                "Stand tall with feet hip-width apart",
                "Run in place lifting knees to hip height",
                "Pump arms naturally",
                "Maintain quick tempo"
            ],
            tips: [
                "Land on balls of feet",
                "Keep core engaged",
                "Drive knees up high"
            ],
            modifications: [
                "Marching in place for low impact",
                "Add arm variations",
                "Increase speed for intensity"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "12",
            name: "Mountain Climbers",
            description: "Dynamic exercise combining core strength with cardio",
            category: .cardio,
            difficulty: .intermediate,
            equipment: [.none],
            targetMuscles: ["Core", "Shoulders", "Hip Flexors"],
            duration: "30-45 seconds",
            instructions: [
                "Start in plank position",
                "Bring one knee toward chest",
                "Quickly switch legs",
                "Keep hips level and core engaged"
            ],
            tips: [
                "Don't let hips bounce up",
                "Keep hands firmly planted",
                "Maintain steady rhythm"
            ],
            modifications: [
                "Slow controlled alternating",
                "Feet on sliders",
                "Cross-body mountain climbers"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        // Flexibility & Yoga Exercises
        WellnessExercise(
            id: "13",
            name: "Cat-Cow Stretch",
            description: "Gentle spinal mobility exercise to improve flexibility",
            category: .flexibility,
            difficulty: .beginner,
            equipment: [.yogaMat],
            targetMuscles: ["Spine", "Core", "Neck"],
            duration: "10-15 repetitions",
            instructions: [
                "Start on hands and knees in tabletop position",
                "Arch back and lift head for cow pose",
                "Round spine and tuck chin for cat pose",
                "Move slowly between positions"
            ],
            tips: [
                "Move with your breath",
                "Keep movements smooth",
                "Don't force the stretch"
            ],
            modifications: [
                "Seated version in chair",
                "Standing version",
                "Add side bends"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "14",
            name: "Downward Dog",
            description: "Classic yoga pose that stretches and strengthens multiple muscle groups",
            category: .yoga,
            difficulty: .intermediate,
            equipment: [.yogaMat],
            targetMuscles: ["Hamstrings", "Calves", "Shoulders", "Back"],
            duration: "30-60 seconds",
            instructions: [
                "Start on hands and knees",
                "Tuck toes under and lift hips up and back",
                "Straighten legs as much as comfortable",
                "Press hands firmly into mat"
            ],
            tips: [
                "Keep slight bend in knees if needed",
                "Focus on lengthening spine",
                "Distribute weight evenly"
            ],
            modifications: [
                "Forearm downward dog",
                "Pedal feet to warm up",
                "Use blocks under hands"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "15",
            name: "Child's Pose",
            description: "Restorative yoga pose for relaxation and gentle spine stretch",
            category: .yoga,
            difficulty: .beginner,
            equipment: [.yogaMat],
            targetMuscles: ["Lower Back", "Hips", "Ankles"],
            duration: "30-60 seconds",
            instructions: [
                "Kneel on floor with toes together",
                "Sit back on heels",
                "Fold forward with arms extended",
                "Rest forehead on mat"
            ],
            tips: [
                "Breathe deeply and relax",
                "Let gravity do the work",
                "Find comfortable position"
            ],
            modifications: [
                "Place pillow under forehead",
                "Widen knees for comfort",
                "Arms by sides instead of extended"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "16",
            name: "Warrior I",
            description: "Standing yoga pose that builds strength and improves balance",
            category: .yoga,
            difficulty: .intermediate,
            equipment: [.yogaMat],
            targetMuscles: ["Legs", "Core", "Shoulders"],
            duration: "30-45 seconds each side",
            instructions: [
                "Step one foot back in lunge position",
                "Turn back foot out 45 degrees",
                "Raise arms overhead",
                "Square hips forward"
            ],
            tips: [
                "Ground through both feet",
                "Keep front knee over ankle",
                "Lengthen through crown of head"
            ],
            modifications: [
                "Hands on hips instead of overhead",
                "Use wall for support",
                "Shorten stance"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        // Balance Exercises
        WellnessExercise(
            id: "17",
            name: "Single Leg Stand",
            description: "Simple balance exercise to improve stability and proprioception",
            category: .balance,
            difficulty: .beginner,
            equipment: [.none],
            targetMuscles: ["Core", "Ankles", "Stabilizing Muscles"],
            duration: "30 seconds each leg",
            instructions: [
                "Stand on one foot with other foot lifted",
                "Keep standing leg slightly bent",
                "Focus on a fixed point ahead",
                "Hold for target time, then switch"
            ],
            tips: [
                "Start near wall for support",
                "Keep core engaged",
                "Progress by closing eyes"
            ],
            modifications: [
                "Hold onto chair or wall",
                "Add arm movements",
                "Stand on unstable surface"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "18",
            name: "Tree Pose",
            description: "Classic yoga balance pose that improves focus and stability",
            category: .balance,
            difficulty: .intermediate,
            equipment: [.yogaMat],
            targetMuscles: ["Core", "Ankles", "Hip Stabilizers"],
            duration: "30-60 seconds each side",
            instructions: [
                "Stand on one foot",
                "Place other foot on inner thigh or calf",
                "Bring hands to prayer position",
                "Find your balance and breathe"
            ],
            tips: [
                "Never place foot on side of knee",
                "Use wall for support if needed",
                "Focus on one point"
            ],
            modifications: [
                "Toe on ground, heel on ankle",
                "Hands on hips",
                "Use wall support"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        // Advanced Strength Exercises
        WellnessExercise(
            id: "19",
            name: "Deadlifts",
            description: "Compound exercise that builds total body strength",
            category: .strength,
            difficulty: .advanced,
            equipment: [.barbell],
            targetMuscles: ["Glutes", "Hamstrings", "Lower Back", "Traps"],
            duration: "3 sets of 5-8 reps",
            instructions: [
                "Stand with feet hip-width apart, bar over mid-foot",
                "Bend at hips and knees to grip bar",
                "Lift by extending hips and knees",
                "Keep back neutral throughout"
            ],
            tips: [
                "Keep bar close to body",
                "Drive through heels",
                "Full hip extension at top"
            ],
            modifications: [
                "Romanian deadlifts",
                "Sumo deadlifts",
                "Trap bar deadlifts"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "20",
            name: "Bench Press",
            description: "Classic upper body strength exercise",
            category: .strength,
            difficulty: .intermediate,
            equipment: [.barbell, .bench],
            targetMuscles: ["Chest", "Shoulders", "Triceps"],
            duration: "3 sets of 6-10 reps",
            instructions: [
                "Lie on bench with feet flat on floor",
                "Grip bar slightly wider than shoulders",
                "Lower bar to chest with control",
                "Press bar back to starting position"
            ],
            tips: [
                "Keep shoulder blades retracted",
                "Don't bounce bar off chest",
                "Control the descent"
            ],
            modifications: [
                "Dumbbell bench press",
                "Incline bench press",
                "Push-ups for bodyweight"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        // More Cardio Exercises
        WellnessExercise(
            id: "21",
            name: "Jump Rope",
            description: "Classic cardio exercise that improves coordination",
            category: .cardio,
            difficulty: .intermediate,
            equipment: [.jumpRope],
            targetMuscles: ["Calves", "Shoulders", "Core"],
            duration: "30-60 seconds",
            instructions: [
                "Hold rope handles at hip level",
                "Swing rope overhead and under feet",
                "Jump just high enough to clear rope",
                "Stay on balls of feet"
            ],
            tips: [
                "Keep elbows close to body",
                "Use wrists to turn rope",
                "Start slowly and build rhythm"
            ],
            modifications: [
                "Imaginary rope",
                "Single foot hops",
                "Double unders for advanced"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "22",
            name: "Running",
            description: "Classic endurance exercise for cardiovascular fitness",
            category: .cardio,
            difficulty: .intermediate,
            equipment: [.none],
            targetMuscles: ["Legs", "Cardiovascular System"],
            duration: "20-60 minutes",
            instructions: [
                "Start with gentle warm-up",
                "Maintain steady, comfortable pace",
                "Land on midfoot, not heel",
                "Keep posture upright"
            ],
            tips: [
                "Start gradually if new to running",
                "Focus on time, not speed initially",
                "Listen to your body"
            ],
            modifications: [
                "Walk-run intervals",
                "Treadmill running",
                "Trail running for variety"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        // Pilates Exercises
        WellnessExercise(
            id: "23",
            name: "Pilates Hundred",
            description: "Core strengthening exercise that builds endurance",
            category: .pilates,
            difficulty: .intermediate,
            equipment: [.yogaMat],
            targetMuscles: ["Core", "Hip Flexors"],
            duration: "100 pulses (10 breaths)",
            instructions: [
                "Lie on back, lift head and shoulders",
                "Extend legs and arms",
                "Pump arms up and down",
                "Breathe in for 5 pumps, out for 5"
            ],
            tips: [
                "Keep core engaged",
                "Don't strain neck",
                "Control the movement"
            ],
            modifications: [
                "Bend knees for easier version",
                "Lower legs to floor",
                "Reduce number of reps"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "24",
            name: "Pilates Roll-Up",
            description: "Spinal articulation exercise that builds core strength",
            category: .pilates,
            difficulty: .intermediate,
            equipment: [.yogaMat],
            targetMuscles: ["Core", "Spine"],
            duration: "5-8 repetitions",
            instructions: [
                "Lie on back with arms overhead",
                "Slowly roll up vertebra by vertebra",
                "Reach for toes at top",
                "Roll back down with control"
            ],
            tips: [
                "Move slowly and controlled",
                "Use core, not momentum",
                "Imagine pressing spine into mat"
            ],
            modifications: [
                "Bend knees slightly",
                "Use towel for assistance",
                "Roll up only halfway"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        // Functional Movement Exercises
        WellnessExercise(
            id: "25",
            name: "Turkish Get-Up",
            description: "Complex full-body movement that builds strength and mobility",
            category: .strength,
            difficulty: .advanced,
            equipment: [.kettlebell],
            targetMuscles: ["Full Body", "Core", "Shoulders"],
            duration: "3-5 reps each side",
            instructions: [
                "Start lying with weight in one hand",
                "Follow specific sequence to standing",
                "Reverse the movement back down",
                "Keep eyes on weight throughout"
            ],
            tips: [
                "Learn steps slowly without weight first",
                "Take your time",
                "Focus on smooth transitions"
            ],
            modifications: [
                "Practice without weight",
                "Break into individual steps",
                "Use lighter weight"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "26",
            name: "Farmer's Walk",
            description: "Functional exercise that builds grip strength and core stability",
            category: .strength,
            difficulty: .intermediate,
            equipment: [.dumbbells],
            targetMuscles: ["Forearms", "Core", "Traps", "Legs"],
            duration: "30-60 seconds",
            instructions: [
                "Hold heavy weights at sides",
                "Walk forward with good posture",
                "Keep core engaged",
                "Don't let weights sway"
            ],
            tips: [
                "Start with moderate weight",
                "Focus on posture",
                "Breathe normally"
            ],
            modifications: [
                "Use lighter weights",
                "Shorter distance",
                "Single-arm carries"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        // Cool Down & Stretching
        WellnessExercise(
            id: "27",
            name: "Hamstring Stretch",
            description: "Essential stretch for posterior chain flexibility",
            category: .flexibility,
            difficulty: .beginner,
            equipment: [.none],
            targetMuscles: ["Hamstrings", "Calves"],
            duration: "30-60 seconds each leg",
            instructions: [
                "Sit with one leg extended",
                "Bend forward from hips",
                "Reach toward toes",
                "Feel stretch in back of leg"
            ],
            tips: [
                "Don't round your back",
                "Stretch should be comfortable",
                "Breathe deeply"
            ],
            modifications: [
                "Use towel around foot",
                "Lying version",
                "Standing version with leg elevated"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "28",
            name: "Hip Flexor Stretch",
            description: "Important stretch for hip mobility and posture",
            category: .flexibility,
            difficulty: .beginner,
            equipment: [.none],
            targetMuscles: ["Hip Flexors", "Quads"],
            duration: "30-60 seconds each side",
            instructions: [
                "Step into lunge position",
                "Lower back knee to ground",
                "Push hips forward",
                "Feel stretch in front of back leg"
            ],
            tips: [
                "Keep torso upright",
                "Don't overstretch",
                "Breathe and relax"
            ],
            modifications: [
                "Standing version",
                "Use pillow under knee",
                "Hold onto wall for balance"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "29",
            name: "Shoulder Rolls",
            description: "Simple mobility exercise for shoulder and neck tension",
            category: .flexibility,
            difficulty: .beginner,
            equipment: [.none],
            targetMuscles: ["Shoulders", "Upper Traps", "Neck"],
            duration: "10-15 in each direction",
            instructions: [
                "Stand with arms at sides",
                "Lift shoulders up toward ears",
                "Roll them back and down",
                "Reverse direction"
            ],
            tips: [
                "Move slowly and controlled",
                "Focus on full range of motion",
                "Relax between rolls"
            ],
            modifications: [
                "Seated version",
                "One shoulder at a time",
                "Add arm circles"
            ],
            imageURL: nil,
            videoURL: nil
        ),
        
        WellnessExercise(
            id: "30",
            name: "Meditation Breathing",
            description: "Mindfulness practice to reduce stress and improve focus",
            category: .flexibility,
            difficulty: .beginner,
            equipment: [.none],
            targetMuscles: ["Diaphragm", "Mind"],
            duration: "5-20 minutes",
            instructions: [
                "Sit comfortably with eyes closed",
                "Focus on natural breath",
                "When mind wanders, return to breath",
                "Start with shorter sessions"
            ],
            tips: [
                "No right or wrong way",
                "Be patient with yourself",
                "Consistency is key"
            ],
            modifications: [
                "Guided meditation apps",
                "Walking meditation",
                "Focus on counting breaths"
            ],
            imageURL: nil,
            videoURL: nil
        )
    ]
}

enum ExerciseCategory: String, CaseIterable {
    case strength = "Strength"
    case cardio = "Cardio" 
    case flexibility = "Flexibility"
    case balance = "Balance"
    case yoga = "Yoga"
    case pilates = "Pilates"
    
    var color: Color {
        switch self {
        case .strength: return MovefullyTheme.Colors.primaryTeal
        case .cardio: return MovefullyTheme.Colors.secondaryPeach
        case .flexibility: return MovefullyTheme.Colors.success
        case .balance: return MovefullyTheme.Colors.info
        case .yoga: return .purple
        case .pilates: return .pink
        }
    }
    
    var icon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .cardio: return "heart.fill"
        case .flexibility: return "figure.flexibility"
        case .balance: return "figure.mind.and.body"
        case .yoga: return "figure.yoga"
        case .pilates: return "figure.pilates"
        }
    }
}

enum ExerciseDifficulty: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var color: Color {
        switch self {
        case .beginner: return MovefullyTheme.Colors.success
        case .intermediate: return MovefullyTheme.Colors.secondaryPeach
        case .advanced: return MovefullyTheme.Colors.info
        }
    }
}

enum EquipmentType: String, CaseIterable {
    case none = "No Equipment"
    case dumbbells = "Dumbbells"
    case resistanceBands = "Resistance Bands"
    case yogaMat = "Yoga Mat"
    case kettlebell = "Kettlebell"
    case barbell = "Barbell"
    case bench = "Bench"
    case pullUpBar = "Pull-up Bar"
    case jumpRope = "Jump Rope"
    case stabilityBall = "Stability Ball"
    case foamRoller = "Foam Roller"
    
    var icon: String {
        switch self {
        case .none: return "hand.raised.fill"
        case .dumbbells: return "dumbbell.fill"
        case .resistanceBands: return "oval.portrait"
        case .yogaMat: return "rectangle.fill"
        case .kettlebell: return "kettlebell.fill"
        case .barbell: return "barbell"
        case .bench: return "bed.double.fill"
        case .pullUpBar: return "minus"
        case .jumpRope: return "rope.skipping"
        case .stabilityBall: return "circle.fill"
        case .foamRoller: return "cylinder.fill"
        }
    }
}

// Extension for exercise filtering and searching
extension WellnessExercise {
    var categoryColor: Color {
        category.color
    }
    
    var categoryIcon: String {
        category.icon
    }
    
    var difficultyColor: Color {
        difficulty.color
    }
} 