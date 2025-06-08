import Foundation
import SwiftUI

// MARK: - Programs View Model (New Unified)
@MainActor
class ProgramsViewModel: ObservableObject {
    @Published var workoutTemplates: [WorkoutTemplate] = []
    @Published var programs: [Program] = []
    @Published var exercises: [Exercise] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    
    init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        workoutTemplates = WorkoutTemplate.sampleTemplates
        programs = Program.samplePrograms
        exercises = Exercise.sampleExercises
    }
    
    // MARK: - Template Management
    func createTemplate(_ template: WorkoutTemplate) {
        isLoading = true
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.workoutTemplates.append(template)
            self.successMessage = "Template created successfully!"
            self.isLoading = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
                successMessage = ""
            }
        }
    }
    
    func updateTemplate(_ template: WorkoutTemplate) {
        if let index = workoutTemplates.firstIndex(where: { $0.id == template.id }) {
            workoutTemplates[index] = template
            successMessage = "Template updated successfully!"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
                successMessage = ""
            }
        }
    }
    
    func deleteTemplate(_ template: WorkoutTemplate) {
        workoutTemplates.removeAll { $0.id == template.id }
        successMessage = "Template deleted successfully!"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
            successMessage = ""
        }
    }
    
    // MARK: - Program Management
    func createProgram(_ program: Program) {
        isLoading = true
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.programs.append(program)
            self.successMessage = "Program created successfully!"
            self.isLoading = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
                successMessage = ""
            }
        }
    }
    
    func updateProgram(_ program: Program) {
        if let index = programs.firstIndex(where: { $0.id == program.id }) {
            programs[index] = program
            successMessage = "Program updated successfully!"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
                successMessage = ""
            }
        }
    }
    
    func deleteProgram(_ program: Program) {
        programs.removeAll { $0.id == program.id }
        successMessage = "Program deleted successfully!"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
            successMessage = ""
        }
    }
    
    // MARK: - Utility Functions
    func getTemplatesByTag(_ tag: String) -> [WorkoutTemplate] {
        return workoutTemplates.filter { $0.tags.contains(tag) }
    }
    
    func getTemplatesByDifficulty(_ difficulty: WorkoutDifficulty) -> [WorkoutTemplate] {
        return workoutTemplates.filter { $0.difficulty == difficulty }
    }
    
    func getPopularPrograms() -> [Program] {
        return programs.sorted { $0.usageCount > $1.usageCount }
    }
    
    func getProgramsByDifficulty(_ difficulty: WorkoutDifficulty) -> [Program] {
        return programs.filter { $0.difficulty == difficulty }
    }
    
    func incrementTemplateUsage(_ templateId: UUID) {
        // In a real implementation, this would update the usage count
        // For now, this is a placeholder for when templates are used in programs
    }
    
    func clearMessages() {
        errorMessage = ""
        successMessage = ""
    }
}

// MARK: - Legacy Workout Plans View Model (Kept for compatibility)
@MainActor
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