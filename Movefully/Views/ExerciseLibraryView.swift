import SwiftUI

struct ExerciseLibraryView: View {
    @StateObject private var viewModel = ExerciseLibraryViewModel()
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory? = nil
    @State private var selectedExercise: Exercise?
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with improved spacing and layout
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        HStack(spacing: MovefullyTheme.Layout.paddingL) {
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                                Text("Movement Library")
                                    .font(MovefullyTheme.Typography.title1)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Text("Discover exercises that inspire movement")
                                    .font(MovefullyTheme.Typography.callout)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // TODO: Add new exercise
                            }) {
                                HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("Add")
                                        .font(MovefullyTheme.Typography.buttonSmall)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                                .padding(.vertical, MovefullyTheme.Layout.paddingM)
                                .background(
                                    LinearGradient(
                                        colors: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.primaryTeal.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                                .shadow(color: MovefullyTheme.Colors.primaryTeal.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        
                        // Search Bar - Soft wellness styling
                        TextField("Find your perfect movement...", text: $searchText)
                            .movefullySearchFieldStyle()
                            .overlay(
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                        .padding(.leading, MovefullyTheme.Layout.paddingL)
                                    
                                    Spacer()
                                }, 
                                alignment: .leading
                            )
                        
                        // Category Filter - Wellness focused
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                                CategoryPill(
                                    title: "All Movements",
                                    isSelected: selectedCategory == nil
                                ) {
                                    selectedCategory = nil
                                }
                                
                                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                                    CategoryPill(
                                        title: category.rawValue,
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = selectedCategory == category ? nil : category
                                    }
                                }
                            }
                            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                        }
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                    .padding(.bottom, MovefullyTheme.Layout.paddingL)
                    .background(MovefullyTheme.Colors.cardBackground)
                    
                    // Soft divider
                    Rectangle()
                        .fill(MovefullyTheme.Colors.divider)
                        .frame(height: 1)
                        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 1, x: 0, y: 1)
                    
                    // Exercises List
                    if filteredExercises.isEmpty && !searchText.isEmpty {
                        // No results state
                        VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                            Spacer(minLength: 100)
                            
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 80, weight: .light))
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal.opacity(0.6))
                            
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                Text("No exercises found")
                                    .font(MovefullyTheme.Typography.title2)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Text("Try adjusting your search terms or category filter to find the movement you're looking for.")
                                    .font(MovefullyTheme.Typography.body)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            }
                            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                            
                            Spacer(minLength: 100)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                    } else {
                        LazyVStack(spacing: MovefullyTheme.Layout.paddingL) {
                            ForEach(filteredExercises) { exercise in
                                ExerciseRowView(exercise: exercise) {
                                    selectedExercise = exercise
                                }
                            }
                        }
                        .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                        .padding(.vertical, MovefullyTheme.Layout.paddingL)
                    }
                }
            }
            .movefullyBackground()
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var filteredExercises: [Exercise] {
        var exercises = viewModel.exercises
        
        if !searchText.isEmpty {
            exercises = exercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let category = selectedCategory {
            exercises = exercises.filter { $0.category == category }
        }
        
        return exercises.sorted { $0.name < $1.name }
    }
}

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(MovefullyTheme.Typography.buttonSmall)
                .foregroundColor(isSelected ? .white : MovefullyTheme.Colors.primaryTeal)
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.vertical, MovefullyTheme.Layout.paddingM)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.primaryTeal.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            LinearGradient(
                                colors: [MovefullyTheme.Colors.primaryTeal.opacity(0.15), MovefullyTheme.Colors.primaryTeal.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                .shadow(color: isSelected ? MovefullyTheme.Colors.primaryTeal.opacity(0.3) : MovefullyTheme.Effects.cardShadow, 
                       radius: isSelected ? 6 : 3, x: 0, y: isSelected ? 3 : 2)
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Exercise Category Icon
                ZStack {
                    Circle()
                        .fill(exercise.categoryColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: exercise.categoryIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(exercise.categoryColor)
                }
                
                // Exercise Details
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(exercise.name)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Spacer()
                        
                        Text(exercise.difficulty.rawValue)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(exercise.difficultyColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(exercise.difficultyColor.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    
                    Text(exercise.description)
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text(exercise.duration)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Spacer()
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            .padding(16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.smallCornerRadius))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Exercise Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(exercise.categoryColor.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: exercise.categoryIcon)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(exercise.categoryColor)
                        }
                        
                        VStack(spacing: 8) {
                            Text(exercise.name)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Text(exercise.description)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        HStack(spacing: 16) {
                            Text(exercise.category.rawValue)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(exercise.categoryColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(exercise.categoryColor.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Text(exercise.difficulty.rawValue)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(exercise.difficultyColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(exercise.difficultyColor.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.top, 20)
                    
                    // Exercise Instructions
                    if !exercise.instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Instructions")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1).")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                        .frame(width: 20, alignment: .leading)
                                    
                                    Text(instruction)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(MovefullyTheme.Colors.backgroundSecondary)
            .navigationTitle("Exercise Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
    }
} 