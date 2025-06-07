import SwiftUI

struct ExerciseLibraryView: View {
    @StateObject private var viewModel = ExerciseLibraryViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory? = nil // nil means "all"
    @State private var selectedExercise: Exercise?
    
    var body: some View {
        ScrollView {
            exercisesContent
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.top, MovefullyTheme.Layout.paddingM)
        }
        .background(MovefullyTheme.Colors.backgroundPrimary)
        .onAppear {
            viewModel.loadExercises()
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
    }
    
    private var filteredExercises: [Exercise] {
        var exercises = viewModel.exercises
        
        if !searchText.isEmpty {
            exercises = exercises.filter { exercise in
                exercise.title.localizedCaseInsensitiveContains(searchText) ||
                exercise.description?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        if let selectedCategory = selectedCategory {
            exercises = exercises.filter { $0.category == selectedCategory }
        }
        
        return exercises.sorted { $0.title < $1.title }
    }
    
    @ViewBuilder
    private var exercisesContent: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            // Search Section
            MovefullySearchField(
                placeholder: "Find your perfect movement...",
                text: $searchText
            )
            
            // Category filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // All Categories button
                    Button("All Movements") {
                        selectedCategory = nil
                    }
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(selectedCategory == nil ? .white : MovefullyTheme.Colors.primaryTeal)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                    .padding(.vertical, MovefullyTheme.Layout.paddingS)
                    .background(selectedCategory == nil ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    
                    // Individual category buttons
                    ForEach(ExerciseCategory.allCases, id: \.self) { category in
                        Button(category.rawValue) {
                            selectedCategory = category
                        }
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(selectedCategory == category ? .white : MovefullyTheme.Colors.primaryTeal)
                        .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                        .padding(.vertical, MovefullyTheme.Layout.paddingS)
                        .background(selectedCategory == category ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    }
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            }
            
            // Content Section
            if filteredExercises.isEmpty && !searchText.isEmpty {
                MovefullyEmptyState(
                    icon: "magnifyingglass",
                    title: "No exercises found",
                    description: "Try adjusting your search terms or category filter to find the movement you're looking for.",
                    actionButton: nil
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: MovefullyTheme.Layout.paddingM) {
                    ForEach(filteredExercises) { exercise in
                        Button(action: {
                            selectedExercise = exercise
                        }) {
                            ExerciseLibraryCard(exercise: exercise)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

// MARK: - Exercise Library Card
struct ExerciseLibraryCard: View {
    let exercise: Exercise
    
    var body: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                // Exercise image placeholder or category icon
                ZStack {
                    RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                        .fill(
                            LinearGradient(
                                colors: [
                                    (exercise.category?.color.opacity(0.3) ?? MovefullyTheme.Colors.primaryTeal.opacity(0.3)),
                                    (exercise.category?.color.opacity(0.1) ?? MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 100)
                    
                    Image(systemName: exercise.category?.icon ?? "figure.flexibility")
                        .font(MovefullyTheme.Typography.largeTitle)
                        .foregroundColor(exercise.category?.color ?? MovefullyTheme.Colors.primaryTeal)
                }
                
                // Exercise info
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                    Text(exercise.title)
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let description = exercise.description {
                        Text(description)
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                    
                    HStack {
                        if let category = exercise.category {
                            MovefullyStatusBadge(
                                text: category.rawValue,
                                color: category.color,
                                showDot: false
                            )
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
} 