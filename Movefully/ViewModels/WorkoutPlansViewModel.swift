import Foundation
import SwiftUI

// MARK: - Workout Plans View Model
class WorkoutPlansViewModel: ObservableObject {
    @Published var workoutPlans: [WorkoutPlan] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    
    init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        workoutPlans = [
            // Beginner Strength Plans
            WorkoutPlan(
                id: "1",
                name: "Foundation Builder",
                description: "Perfect for beginners looking to build fundamental strength and movement patterns. Start your journey with confidence using basic bodyweight exercises.",
                category: .strength,
                difficulty: .beginner,
                duration: "8 weeks",
                workoutsPerWeek: 3,
                avgDuration: 45,
                clientsAssigned: 12,
                trainerId: "trainer1",
                createdAt: Date(),
                isActive: true
            ),
            WorkoutPlan(
                id: "2",
                name: "Bodyweight Basics",
                description: "Master fundamental movements like squats, push-ups, and planks. No equipment needed - just your body and determination.",
                category: .strength,
                difficulty: .beginner,
                duration: "6 weeks",
                workoutsPerWeek: 3,
                avgDuration: 35,
                clientsAssigned: 18,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-86400),
                isActive: true
            ),
            WorkoutPlan(
                id: "3",
                name: "Gentle Start",
                description: "Ultra-beginner friendly program focusing on form, breathing, and building confidence in movement.",
                category: .strength,
                difficulty: .beginner,
                duration: "4 weeks",
                workoutsPerWeek: 2,
                avgDuration: 25,
                clientsAssigned: 22,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-172800),
                isActive: true
            ),
            
            // Intermediate Strength Plans
            WorkoutPlan(
                id: "4",
                name: "Strength Builder Pro",
                description: "Take your strength to the next level with progressive overload and compound movements. Perfect for those ready to challenge themselves.",
                category: .strength,
                difficulty: .intermediate,
                duration: "10 weeks",
                workoutsPerWeek: 4,
                avgDuration: 55,
                clientsAssigned: 14,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-259200),
                isActive: true
            ),
            WorkoutPlan(
                id: "5",
                name: "Functional Fitness",
                description: "Real-world strength training that improves daily activities. Focus on multi-joint movements and core stability.",
                category: .strength,
                difficulty: .intermediate,
                duration: "8 weeks",
                workoutsPerWeek: 4,
                avgDuration: 50,
                clientsAssigned: 11,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-345600),
                isActive: true
            ),
            WorkoutPlan(
                id: "6",
                name: "Upper Body Power",
                description: "Focused upper body development with progressive resistance training. Build impressive strength in arms, chest, and back.",
                category: .strength,
                difficulty: .intermediate,
                duration: "6 weeks",
                workoutsPerWeek: 3,
                avgDuration: 45,
                clientsAssigned: 9,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-432000),
                isActive: true
            ),
            
            // Advanced Strength Plans
            WorkoutPlan(
                id: "7",
                name: "Strength Elite",
                description: "Advanced strength training for experienced athletes. High-intensity protocols with complex movement patterns.",
                category: .strength,
                difficulty: .advanced,
                duration: "12 weeks",
                workoutsPerWeek: 5,
                avgDuration: 75,
                clientsAssigned: 5,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-518400),
                isActive: true
            ),
            WorkoutPlan(
                id: "8",
                name: "Powerlifting Prep",
                description: "Competition-ready powerlifting program focusing on squat, bench press, and deadlift mastery.",
                category: .strength,
                difficulty: .advanced,
                duration: "16 weeks",
                workoutsPerWeek: 4,
                avgDuration: 90,
                clientsAssigned: 3,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-604800),
                isActive: true
            ),
            WorkoutPlan(
                id: "9",
                name: "Olympic Lifting",
                description: "Master the clean & jerk and snatch with progressive technique development and power training.",
                category: .strength,
                difficulty: .advanced,
                duration: "20 weeks",
                workoutsPerWeek: 5,
                avgDuration: 80,
                clientsAssigned: 2,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-691200),
                isActive: true
            ),
            
            // Cardio Plans - Beginner
            WorkoutPlan(
                id: "10",
                name: "Cardio Kickstart",
                description: "Gentle introduction to cardiovascular training with low-impact options and gradual progression.",
                category: .cardio,
                difficulty: .beginner,
                duration: "6 weeks",
                workoutsPerWeek: 3,
                avgDuration: 30,
                clientsAssigned: 25,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-777600),
                isActive: true
            ),
            WorkoutPlan(
                id: "11",
                name: "Walking Warriors",
                description: "Transform your health with structured walking programs. Perfect for absolute beginners or those returning to fitness.",
                category: .cardio,
                difficulty: .beginner,
                duration: "4 weeks",
                workoutsPerWeek: 5,
                avgDuration: 25,
                clientsAssigned: 31,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-864000),
                isActive: true
            ),
            
            // Cardio Plans - Intermediate
            WorkoutPlan(
                id: "12",
                name: "Cardio Blast",
                description: "High-energy cardiovascular training for improved endurance and fat loss. Mix of steady-state and interval training.",
                category: .cardio,
                difficulty: .intermediate,
                duration: "8 weeks",
                workoutsPerWeek: 4,
                avgDuration: 40,
                clientsAssigned: 16,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-950400),
                isActive: true
            ),
            WorkoutPlan(
                id: "13",
                name: "HIIT Revolution",
                description: "High-Intensity Interval Training that maximizes results in minimum time. Get ready to sweat!",
                category: .cardio,
                difficulty: .intermediate,
                duration: "6 weeks",
                workoutsPerWeek: 4,
                avgDuration: 30,
                clientsAssigned: 19,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-1036800),
                isActive: true
            ),
            WorkoutPlan(
                id: "14",
                name: "Endurance Builder",
                description: "Build serious cardiovascular endurance with progressive distance and time-based challenges.",
                category: .cardio,
                difficulty: .intermediate,
                duration: "10 weeks",
                workoutsPerWeek: 5,
                avgDuration: 45,
                clientsAssigned: 13,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-1123200),
                isActive: true
            ),
            
            // Cardio Plans - Advanced
            WorkoutPlan(
                id: "15",
                name: "Cardio Elite",
                description: "Elite-level cardiovascular conditioning for athletes. Prepare for competition or personal records.",
                category: .cardio,
                difficulty: .advanced,
                duration: "12 weeks",
                workoutsPerWeek: 6,
                avgDuration: 60,
                clientsAssigned: 7,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-1209600),
                isActive: true
            ),
            WorkoutPlan(
                id: "16",
                name: "Marathon Prep",
                description: "Complete marathon training program with periodization, tapering, and race-day strategy.",
                category: .cardio,
                difficulty: .advanced,
                duration: "20 weeks",
                workoutsPerWeek: 5,
                avgDuration: 75,
                clientsAssigned: 4,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-1296000),
                isActive: true
            ),
            
            // Flexibility Plans - Beginner
            WorkoutPlan(
                id: "17",
                name: "Flexibility Flow",
                description: "Gentle mobility and flexibility routine for better movement quality. Perfect for desk workers and beginners.",
                category: .flexibility,
                difficulty: .beginner,
                duration: "4 weeks",
                workoutsPerWeek: 5,
                avgDuration: 20,
                clientsAssigned: 28,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-1382400),
                isActive: true
            ),
            WorkoutPlan(
                id: "18",
                name: "Morning Stretch",
                description: "Start your day right with energizing stretches and mobility work. Wake up your body and mind.",
                category: .flexibility,
                difficulty: .beginner,
                duration: "6 weeks",
                workoutsPerWeek: 7,
                avgDuration: 15,
                clientsAssigned: 24,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-1468800),
                isActive: true
            ),
            
            // Flexibility Plans - Intermediate  
            WorkoutPlan(
                id: "19",
                name: "Yoga Flow",
                description: "Dynamic yoga sequences that build strength, flexibility, and mindfulness. Flow with your breath.",
                category: .flexibility,
                difficulty: .intermediate,
                duration: "8 weeks",
                workoutsPerWeek: 4,
                avgDuration: 45,
                clientsAssigned: 21,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-1555200),
                isActive: true
            ),
            WorkoutPlan(
                id: "20",
                name: "Deep Stretch",
                description: "Intensive flexibility training for increased range of motion and muscle relaxation.",
                category: .flexibility,
                difficulty: .intermediate,
                duration: "6 weeks",
                workoutsPerWeek: 3,
                avgDuration: 35,
                clientsAssigned: 17,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-1641600),
                isActive: true
            ),
            
            // Specialized Plans
            WorkoutPlan(
                id: "21",
                name: "Prenatal Fitness",
                description: "Safe and effective exercise routines designed specifically for expecting mothers.",
                category: .flexibility,
                difficulty: .beginner,
                duration: "12 weeks",
                workoutsPerWeek: 3,
                avgDuration: 30,
                clientsAssigned: 8,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-1728000),
                isActive: true
            ),
            WorkoutPlan(
                id: "22",
                name: "Senior Fitness",
                description: "Age-appropriate exercises focusing on balance, strength, and flexibility for active aging.",
                category: .strength,
                difficulty: .beginner,
                duration: "8 weeks",
                workoutsPerWeek: 3,
                avgDuration: 35,
                clientsAssigned: 15,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-1814400),
                isActive: true
            ),
            WorkoutPlan(
                id: "23",
                name: "Post-Injury Recovery",
                description: "Rehabilitation-focused program for safe return to full activity after injury.",
                category: .flexibility,
                difficulty: .beginner,
                duration: "10 weeks",
                workoutsPerWeek: 4,
                avgDuration: 40,
                clientsAssigned: 6,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-1900800),
                isActive: true
            ),
            WorkoutPlan(
                id: "24",
                name: "Weight Loss Bootcamp",
                description: "High-intensity fat-burning program combining cardio and strength training for maximum results.",
                category: .cardio,
                difficulty: .intermediate,
                duration: "12 weeks",
                workoutsPerWeek: 5,
                avgDuration: 50,
                clientsAssigned: 23,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-1987200),
                isActive: true
            ),
            WorkoutPlan(
                id: "25",
                name: "Athletic Performance",
                description: "Sport-specific training to enhance athletic performance across all disciplines.",
                category: .strength,
                difficulty: .advanced,
                duration: "16 weeks",
                workoutsPerWeek: 6,
                avgDuration: 85,
                clientsAssigned: 9,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-2073600),
                isActive: true
            ),
            WorkoutPlan(
                id: "26",
                name: "Core Crusher",
                description: "Specialized core strengthening program for a strong, stable midsection.",
                category: .strength,
                difficulty: .intermediate,
                duration: "6 weeks",
                workoutsPerWeek: 4,
                avgDuration: 25,
                clientsAssigned: 20,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-2160000),
                isActive: true
            ),
            WorkoutPlan(
                id: "27",
                name: "Mindful Movement",
                description: "Integrate mindfulness with gentle movement for stress relief and body awareness.",
                category: .flexibility,
                difficulty: .beginner,
                duration: "8 weeks",
                workoutsPerWeek: 4,
                avgDuration: 30,
                clientsAssigned: 19,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-2246400),
                isActive: true
            ),
            WorkoutPlan(
                id: "28",
                name: "CrossFit Prep",
                description: "Prepare for CrossFit with functional movements, Olympic lifts, and metabolic conditioning.",
                category: .strength,
                difficulty: .advanced,
                duration: "12 weeks",
                workoutsPerWeek: 5,
                avgDuration: 70,
                clientsAssigned: 8,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-2332800),
                isActive: true
            ),
            WorkoutPlan(
                id: "29",
                name: "Busy Professional",
                description: "Time-efficient workouts designed for busy schedules. Maximum impact in minimum time.",
                category: .cardio,
                difficulty: .intermediate,
                duration: "8 weeks",
                workoutsPerWeek: 4,
                avgDuration: 20,
                clientsAssigned: 27,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-2419200),
                isActive: true
            ),
            WorkoutPlan(
                id: "30",
                name: "Home Gym Hero",
                description: "Complete workouts designed for home gym setups with minimal equipment requirements.",
                category: .strength,
                difficulty: .intermediate,
                duration: "10 weeks",
                workoutsPerWeek: 4,
                avgDuration: 45,
                clientsAssigned: 16,
                trainerId: "trainer1",
                createdAt: Date().addingTimeInterval(-2505600),
                isActive: true
            )
        ]
    }
    
    func createPlan(_ plan: WorkoutPlan) {
        isLoading = true
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.workoutPlans.append(plan)
            self.successMessage = "Plan created successfully!"
            self.isLoading = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
                successMessage = ""
            }
        }
    }
    
    func deletePlan(_ plan: WorkoutPlan) {
        workoutPlans.removeAll { $0.id == plan.id }
        successMessage = "Plan deleted successfully!"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
            successMessage = ""
        }
    }
}

// MARK: - Data Models
struct WorkoutPlan: Identifiable {
    let id: String
    let name: String
    let description: String
    let category: WorkoutCategory
    let difficulty: WorkoutDifficulty
    let duration: String
    let workoutsPerWeek: Int
    let avgDuration: Int
    let clientsAssigned: Int
    let trainerId: String
    let createdAt: Date
    let isActive: Bool
    
    var categoryColor: Color {
        switch category {
        case .strength: return MovefullyTheme.Colors.primaryTeal
        case .cardio: return MovefullyTheme.Colors.secondaryPeach
        case .flexibility: return MovefullyTheme.Colors.success
        }
    }
    
    var categoryIcon: String {
        switch category {
        case .strength: return "dumbbell.fill"
        case .cardio: return "heart.fill"
        case .flexibility: return "figure.yoga"
        }
    }
    
    var difficultyColor: Color {
        switch difficulty {
        case .beginner: return MovefullyTheme.Colors.success
        case .intermediate: return MovefullyTheme.Colors.secondaryPeach
        case .advanced: return MovefullyTheme.Colors.info
        }
    }
}

enum WorkoutCategory: String, CaseIterable {
    case strength = "Strength"
    case cardio = "Cardio"
    case flexibility = "Flexibility"
}

enum WorkoutDifficulty: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
} 