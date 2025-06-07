import Foundation
import SwiftUI
import Combine

class ExerciseLibraryViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var selectedCategory: ExerciseCategory? = nil
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSampleExercises()
    }
    
    // MARK: - Public Methods
    
    func loadExercises() {
        isLoading = true
        // In a real app, this would fetch from an API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.exercises = Exercise.sampleExercises
            self.isLoading = false
        }
    }
    
    func filterByCategory(_ category: ExerciseCategory?) {
        selectedCategory = category
    }
    
    func searchExercises(_ query: String) {
        searchText = query
    }
    
    // MARK: - Private Methods
    
    private func loadSampleExercises() {
        exercises = Exercise.sampleExercises // Use centralized exercise data
    }
}

// MARK: - Extensions for UI Support

extension ExerciseCategory {
    var categoryColor: Color {
        switch self {
        case .strength: return MovefullyTheme.Colors.primaryTeal
        case .cardio: return MovefullyTheme.Colors.secondaryPeach
        case .flexibility: return MovefullyTheme.Colors.softGreen
        case .balance: return MovefullyTheme.Colors.gentleBlue
        case .mindfulness: return MovefullyTheme.Colors.lavender
        }
    }
} 