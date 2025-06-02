import SwiftUI

struct ExerciseLibraryView: View {
    @StateObject private var viewModel = ExerciseLibraryViewModel()
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory? = nil // nil means "all"
    @State private var selectedExercise: Exercise?
    
    var body: some View {
        MovefullyNavigationPageLayout {
            MovefullyPageLayout {
                // Header Section
                MovefullyContentSection {
                    MovefullyPageSection {
                        MovefullyPageHeader(
                            title: "Movement Library",
                            subtitle: "Discover exercises that inspire movement",
                            actionButton: MovefullyPageHeader.ActionButton(
                                title: "Add",
                                icon: "plus.circle.fill",
                                action: { /* TODO: Add new exercise */ }
                            )
                        )
                        
                        MovefullySearchField(
                            placeholder: "Find your perfect movement...",
                            text: $searchText
                        )
                        
                        // Category filters - need custom implementation since we need "All" option
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
                    }
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
                    MovefullyListLayout(
                        items: filteredExercises,
                        itemView: { exercise in
                            Button(action: {
                                selectedExercise = exercise
                            }) {
                                ExerciseRowView(exercise: exercise)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    )
                }
            }
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
        
        if selectedCategory != nil {
            exercises = exercises.filter { $0.category == selectedCategory }
        }
        
        return exercises.sorted { $0.title < $1.title }
    }
} 