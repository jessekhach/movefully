import Foundation
import SwiftUI

// MARK: - Workout Plans View Model
class WorkoutPlansViewModel: ObservableObject {
    @Published var workoutPlans: [WorkoutPlan] = []
    @Published var selectedDifficulty: WorkoutDifficulty = .beginner
    @Published var selectedCategory: String = "All"
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    
    // Filter options
    let difficultyOptions: [WorkoutDifficulty] = WorkoutDifficulty.allCases
    let categoryOptions = ["All", "Strength", "Cardio", "Flexibility", "Balance", "Mindfulness"]
    
    init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        workoutPlans = WorkoutPlan.samplePlans
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