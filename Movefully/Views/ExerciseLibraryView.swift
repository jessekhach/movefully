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

// MARK: - Exercise Detail View
struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        MovefullyNavigationPageLayout {
            MovefullyPageLayout {
                MovefullyPageSection {
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        // Exercise Header
                        VStack(spacing: MovefullyTheme.Layout.paddingM) {
                            ZStack {
                                Circle()
                                    .fill(MovefullyTheme.Colors.primaryTeal.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: exercise.category?.icon ?? "figure.walk")
                                    .font(MovefullyTheme.Typography.largeTitle)
                                    .foregroundColor(difficultyColor)
                            }
                            
                            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                                Text(exercise.title)
                                    .font(MovefullyTheme.Typography.title1)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                if let description = exercise.description {
                                    Text(description)
                                        .font(MovefullyTheme.Typography.body)
                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            
                            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                                if let category = exercise.category {
                                    MovefullyStatusBadge(
                                        text: category.rawValue,
                                        color: categoryColor,
                                        showDot: false
                                    )
                                }
                                
                                if let difficulty = exercise.difficulty {
                                    MovefullyStatusBadge(
                                        text: difficulty.rawValue,
                                        color: difficultyColor,
                                        showDot: false
                                    )
                                }
                            }
                        }
                        
                        // Note: DataModels Exercise doesn't have instructions property
                        // This would need to be added to the Exercise model or removed
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            Text("Exercise Details")
                                .font(MovefullyTheme.Typography.title3)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            if let duration = exercise.duration {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                    Text("Duration: \(duration) minutes")
                                        .font(MovefullyTheme.Typography.body)
                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Exercise Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            }
        }
    }
    
    private var categoryColor: Color {
        MovefullyTheme.Colors.primaryTeal
    }
    
    private var difficultyColor: Color {
        guard let difficulty = exercise.difficulty else { return MovefullyTheme.Colors.primaryTeal }
        
        switch difficulty.color {
        case "success":
            return MovefullyTheme.Colors.success
        case "primaryTeal":
            return MovefullyTheme.Colors.primaryTeal
        case "secondaryPeach":
            return MovefullyTheme.Colors.secondaryPeach
        default:
            return MovefullyTheme.Colors.primaryTeal
        }
    }
} 