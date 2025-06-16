import Foundation
import SwiftUI
import Combine

// MARK: - Programs View Model (New Unified)
@MainActor
class ProgramsViewModel: ObservableObject {
    @Published var workoutTemplates: [WorkoutTemplate] = []
    @Published var programs: [Program] = []
    @Published var exercises: [Exercise] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    
    // Live usage counts
    @Published var programAssignedCounts: [UUID: Int] = [:]
    @Published var templateUsageCounts: [UUID: Int] = [:]
    
    // Firebase Services
    private let templateService = TemplateDataService()
    private let exerciseService = ExerciseDataService()
    private let programService = ProgramDataService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSubscriptions()
        loadInitialData()
    }
    
    private func setupSubscriptions() {
        // Subscribe to template updates
        templateService.$templates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] templates in
                self?.workoutTemplates = templates
                // Update usage counts when templates change
                self?.refreshTemplateUsageCounts()
            }
            .store(in: &cancellables)
        
        // Subscribe to exercise updates
        exerciseService.$exercises
            .combineLatest(exerciseService.$customExercises)
            .map { global, custom in
                return global + custom
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.exercises, on: self)
            .store(in: &cancellables)
        
        // Subscribe to program updates
        programService.$programs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] programs in
                self?.programs = programs
                // Update assigned counts when programs change
                self?.refreshProgramAssignedCounts()
            }
            .store(in: &cancellables)
        
        // Subscribe to loading states
        Publishers.CombineLatest3(
            templateService.$isLoading,
            exerciseService.$isLoading,
            programService.$isLoading
        )
        .map { templateLoading, exerciseLoading, programLoading in
            return templateLoading || exerciseLoading || programLoading
        }
        .receive(on: DispatchQueue.main)
        .assign(to: \.isLoading, on: self)
        .store(in: &cancellables)
        
        // Subscribe to error messages
        Publishers.CombineLatest3(
            templateService.$errorMessage,
            exerciseService.$errorMessage,
            programService.$errorMessage
        )
        .compactMap { templateError, exerciseError, programError in
            return templateError ?? exerciseError ?? programError
        }
        .receive(on: DispatchQueue.main)
        .assign(to: \.errorMessage, on: self)
        .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        // Force seed database if empty (for first-time setup)
        Task {
            if await exerciseService.isDatabaseEmpty() {
                try? await exerciseService.forceSeedDatabase()
            }
        }
        
        // Services will automatically load their data through Firebase integration
        // No fallback to sample data - this ensures we only show real data
    }
    
    // MARK: - Template Management
    func createTemplate(_ template: WorkoutTemplate, exercisesWithPrescription: [ExerciseWithSetsReps]? = nil) {
        Task {
            do {
                try await templateService.createTemplate(template, exercisesWithPrescription: exercisesWithPrescription)
                await MainActor.run {
                    self.successMessage = "Template created successfully!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.successMessage = ""
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ ProgramsViewModel: Failed to create template: \(error)")
                    self.errorMessage = "Failed to create template: \(error.localizedDescription)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.errorMessage = ""
                    }
                }
            }
        }
    }
    
    func updateTemplate(_ template: WorkoutTemplate, exercisesWithPrescription: [ExerciseWithSetsReps]? = nil) {
        print("✅ ProgramsViewModel: Starting template update for '\(template.name)'")
        Task {
            do {
                try await templateService.updateTemplate(template, exercisesWithPrescription: exercisesWithPrescription)
                await MainActor.run {
                    print("✅ ProgramsViewModel: Template update successful for '\\(template.name)'")
                    self.successMessage = "Template updated successfully!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.successMessage = ""
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ ProgramsViewModel: Failed to update template '\(template.name)': \(error)")
                                          self.errorMessage = "Failed to update template: \(error.localizedDescription)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.errorMessage = ""
                    }
                }
            }
        }
    }
    
    func deleteTemplate(_ template: WorkoutTemplate) {
        Task {
            do {
                // Check if template is used in any programs first
                let isUsed = try await programService.isTemplateUsedInPrograms(template.id)
                if isUsed {
                    await MainActor.run {
                        self.errorMessage = "Cannot delete template '\(template.name)' because it's being used in one or more programs. Please remove it from all programs first."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            self.errorMessage = ""
                        }
                    }
                    return
                }
                
                // Safe to delete
                try await templateService.deleteTemplate(template)
                await MainActor.run {
                    self.successMessage = "Template deleted successfully!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.successMessage = ""
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to delete template: \(error.localizedDescription)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.errorMessage = ""
                    }
                }
            }
        }
    }
    
    // MARK: - Program Management
    func createProgram(_ program: Program) {
        Task {
            do {
                try await programService.createProgram(program)
                await MainActor.run {
                    self.successMessage = "Program created successfully!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.successMessage = ""
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ ProgramsViewModel: Failed to create program: \(error)")
                    self.errorMessage = "Failed to create program: \(error.localizedDescription)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.errorMessage = ""
                    }
                }
            }
        }
    }
    
    func updateProgram(_ program: Program) {
        Task {
            do {
                try await programService.updateProgram(program)
                await MainActor.run {
                    self.successMessage = "Program updated successfully!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.successMessage = ""
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ ProgramsViewModel: Failed to update program: \(error)")
                    self.errorMessage = "Failed to update program: \(error.localizedDescription)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.errorMessage = ""
                    }
                }
            }
        }
    }
    
    func deleteProgram(_ program: Program) {
        Task {
            do {
                try await programService.deleteProgram(program)
                await MainActor.run {
                    self.successMessage = "Program deleted successfully!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.successMessage = ""
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ ProgramsViewModel: Failed to delete program: \(error)")
                    self.errorMessage = "Failed to delete program: \(error.localizedDescription)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.errorMessage = ""
                    }
                }
            }
        }
    }
    
    // MARK: - Utility Functions
    func getTemplatesByTag(_ tag: String) -> [WorkoutTemplate] {
        return templateService.getTemplatesByTag(tag)
    }
    
    func getTemplatesByDifficulty(_ difficulty: WorkoutDifficulty) -> [WorkoutTemplate] {
        return templateService.getTemplatesByDifficulty(difficulty)
    }
    
    func searchTemplates(query: String) -> [WorkoutTemplate] {
        return templateService.searchTemplates(query: query)
    }
    
    func getPopularPrograms() -> [Program] {
        return programService.getPopularPrograms()
    }
    
    func getProgramsByDifficulty(_ difficulty: WorkoutDifficulty) -> [Program] {
        return programService.getProgramsByDifficulty(difficulty)
    }
    
    func getDraftPrograms() -> [Program] {
        return programService.getDraftPrograms()
    }
    
    func getActivePrograms() -> [Program] {
        return programService.getActivePrograms()
    }
    
    func searchPrograms(query: String) -> [Program] {
        return programService.searchPrograms(query: query)
    }
    
    // MARK: - Template Dependency Management
    func checkTemplateDependencies(_ templateId: UUID) async throws -> Bool {
        return try await programService.isTemplateUsedInPrograms(templateId)
    }
    
    func getProgramsUsingTemplate(_ templateId: UUID) async throws -> [Program] {
        return try await programService.getProgramsUsingTemplate(templateId)
    }
    
    func incrementTemplateUsage(_ templateId: UUID) {
        Task {
            do {
                try await templateService.incrementUsageCount(for: templateId)
            } catch {
                print("Failed to increment template usage: \(error)")
            }
        }
    }
    
    // MARK: - Exercise Management
    func createCustomExercise(_ exercise: Exercise) {
        Task {
            do {
                try await exerciseService.createCustomExercise(exercise)
                await MainActor.run {
                    self.successMessage = "Exercise created successfully!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.successMessage = ""
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to create exercise: \(error.localizedDescription)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.errorMessage = ""
                    }
                }
            }
        }
    }
    
    func searchExercises(query: String, category: ExerciseCategory? = nil) -> [Exercise] {
        return exerciseService.searchExercises(query: query, category: category)
    }
    
    func clearMessages() {
        errorMessage = ""
        successMessage = ""
    }
    
    // MARK: - Live Usage Count Management
    
    /// Refreshes the assigned client counts for all programs
    func refreshProgramAssignedCounts() {
        Task {
            var newCounts: [UUID: Int] = [:]
            
            for program in programs {
                do {
                    let count = try await programService.getAssignedClientCount(for: program.id)
                    newCounts[program.id] = count
                } catch {
                    print("❌ ProgramsViewModel: Failed to get assigned count for program \(program.name): \(error)")
                    newCounts[program.id] = 0
                }
            }
            
            await MainActor.run {
                self.programAssignedCounts = newCounts
            }
        }
    }
    
    /// Refreshes the usage counts for all templates
    func refreshTemplateUsageCounts() {
        Task {
            var newCounts: [UUID: Int] = [:]
            
            for template in workoutTemplates {
                do {
                    let count = try await templateService.getLiveUsageCount(for: template.id)
                    newCounts[template.id] = count
                } catch {
                    print("❌ ProgramsViewModel: Failed to get usage count for template \(template.name): \(error)")
                    newCounts[template.id] = 0
                }
            }
            
            await MainActor.run {
                self.templateUsageCounts = newCounts
            }
        }
    }
    
    /// Gets the live assigned count for a specific program
    func getAssignedCount(for programId: UUID) -> Int {
        return programAssignedCounts[programId] ?? 0
    }
    
    /// Gets the live usage count for a specific template
    func getUsageCount(for templateId: UUID) -> Int {
        return templateUsageCounts[templateId] ?? 0
    }
    
    // MARK: - Template Prescription Data
    func loadTemplatePrescriptionData(for templateId: UUID) async -> [ExerciseWithSetsReps] {
        do {
            return try await templateService.getTemplatePrescriptionData(for: templateId)
        } catch {
            print("❌ ProgramsViewModel: Failed to load template prescription data: \(error)")
            // Return default prescription data based on template exercises
            if let template = workoutTemplates.first(where: { $0.id == templateId }) {
                return template.exercises.map { ExerciseWithSetsReps(exercise: $0) }
            }
            return []
        }
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