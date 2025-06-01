import SwiftUI

// MARK: - Client Resources View
struct ClientResourcesView: View {
    @ObservedObject var viewModel: ClientViewModel
    @State private var searchText = ""
    @State private var selectedExercise: Exercise?
    @State private var showingExerciseDetail = false
    @State private var showingProfile = false
    
    var body: some View {
        MovefullyClientNavigation(
            title: "Exercise Library",
            showProfileButton: false
        ) {
            // Search and filters (now inside navigation content)
            searchAndFiltersSection
            
            // Category filters
            categoryFiltersSection
            
            // Exercise grid
            exerciseGridSection
        }
        .sheet(isPresented: $showingExerciseDetail) {
            if let exercise = selectedExercise {
                ExerciseDetailModal(exercise: exercise)
            }
        }
        .sheet(isPresented: $showingProfile) {
            // ClientProfileView will be added when available
        }
    }
    
    // MARK: - Search and Filters Section
    private var searchAndFiltersSection: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            MovefullySearchField(
                placeholder: "Search exercises...",
                text: $searchText
            )
        }
        .padding(.vertical, MovefullyTheme.Layout.paddingS)
    }
    
    // MARK: - Category Filters Section
    private var categoryFiltersSection: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                Text("Browse by Category")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // "All" category filter pill
                    CategoryFilterPill(
                        category: nil,
                        isSelected: viewModel.selectedExerciseCategory == nil
                    ) {
                        viewModel.filterExercises(by: nil)
                    }
                    
                    ForEach(ExerciseCategory.allCases, id: \.self) { category in
                        CategoryFilterPill(
                            category: category,
                            isSelected: viewModel.selectedExerciseCategory == category
                        ) {
                            viewModel.filterExercises(by: category)
                        }
                    }
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            }
        }
    }
    
    // MARK: - Exercise Grid Section
    private var exerciseGridSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: MovefullyTheme.Layout.paddingM) {
            ForEach(filteredExercises) { exercise in
                ExerciseCard(exercise: exercise) {
                    selectedExercise = exercise
                    showingExerciseDetail = true
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredExercises: [Exercise] {
        let categoryFiltered = viewModel.filteredExercises
        
        if searchText.isEmpty {
            return categoryFiltered
        }
        
        return categoryFiltered.filter { exercise in
            exercise.title.localizedCaseInsensitiveContains(searchText) ||
            exercise.description?.localizedCaseInsensitiveContains(searchText) == true
        }
    }
}

// MARK: - Category Filter Pill
struct CategoryFilterPill: View {
    let category: ExerciseCategory?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                Image(systemName: category?.icon ?? "figure.flexibility")
                    .font(MovefullyTheme.Typography.callout)
                
                Text(category?.rawValue ?? "All")
                    .font(MovefullyTheme.Typography.callout)
            }
            .foregroundColor(isSelected ? .white : MovefullyTheme.Colors.primaryTeal)
            .padding(.horizontal, MovefullyTheme.Layout.paddingM)
            .padding(.vertical, MovefullyTheme.Layout.paddingS)
            .background(
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                    .fill(isSelected ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.primaryTeal.opacity(0.1))
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Exercise Card
struct ExerciseCard: View {
    let exercise: Exercise
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
                            
                            if let duration = exercise.duration {
                                HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                                    Image(systemName: "clock")
                                        .font(MovefullyTheme.Typography.caption)
                                    Text("\(duration) min")
                                        .font(MovefullyTheme.Typography.caption)
                                }
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Exercise Detail Modal
struct ExerciseDetailModal: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                    // Exercise header
                    exerciseHeaderSection
                    
                    // Exercise description
                    if let description = exercise.description {
                        exerciseDescriptionSection(description)
                    }
                    
                    // Exercise specifications
                    exerciseSpecsSection
                    
                    // Instructions section
                    instructionsSection
                    
                    // Demo section placeholder
                    demoSection
                    
                    Spacer(minLength: MovefullyTheme.Layout.paddingXXL)
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            }
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationTitle(exercise.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
    }
    
    private var exerciseHeaderSection: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                HStack {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text(exercise.title)
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        if let category = exercise.category {
                            MovefullyStatusBadge(
                                text: category.rawValue,
                                color: category.color,
                                showDot: true
                            )
                        }
                    }
                    
                    Spacer()
                    
                    // Category icon
                    Image(systemName: exercise.category?.icon ?? "figure.flexibility")
                        .font(MovefullyTheme.Typography.title1)
                        .foregroundColor(exercise.category?.color ?? MovefullyTheme.Colors.primaryTeal)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill((exercise.category?.color ?? MovefullyTheme.Colors.primaryTeal).opacity(0.1))
                        )
                }
                
                if let difficulty = exercise.difficulty {
                    HStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Text("Difficulty:")
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        MovefullyStatusBadge(
                            text: difficulty.rawValue,
                            color: difficulty.colorValue,
                            showDot: false
                        )
                    }
                }
            }
        }
    }
    
    private func exerciseDescriptionSection(_ description: String) -> some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                Text("About This Exercise")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text(description)
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .lineLimit(nil)
            }
        }
    }
    
    private var exerciseSpecsSection: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                Text("Exercise Details")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                    if let duration = exercise.duration {
                        specRow(icon: "clock", label: "Duration", value: "\(duration) minutes")
                    }
                    
                    if let difficulty = exercise.difficulty {
                        specRow(icon: "chart.bar", label: "Difficulty", value: difficulty.rawValue)
                    }
                    
                    if let category = exercise.category {
                        specRow(icon: category.icon, label: "Category", value: category.rawValue)
                    }
                }
            }
        }
    }
    
    private func specRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            Image(systemName: icon)
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                .frame(width: 20)
            
            Text(label)
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
        }
    }
    
    private var instructionsSection: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    Text("How to Perform")
                        .font(MovefullyTheme.Typography.title3)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                    instructionStep(number: 1, text: "Begin in a comfortable starting position with your feet hip-width apart")
                    instructionStep(number: 2, text: "Take a deep breath and engage your core muscles")
                    instructionStep(number: 3, text: "Move slowly and mindfully through the exercise")
                    instructionStep(number: 4, text: "Focus on your breath throughout the movement")
                    instructionStep(number: 5, text: "Return to starting position with control")
                }
                
                // Trainer tips
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(MovefullyTheme.Colors.warmOrange)
                        Text("Trainer Tips")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.warmOrange)
                    }
                    
                    Text("Listen to your body and move at your own pace. If you feel any discomfort, modify the movement or take a break. Quality over quantity always!")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .italic()
                }
                .padding(MovefullyTheme.Layout.paddingM)
                .background(MovefullyTheme.Colors.warmOrange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            }
        }
    }
    
    private func instructionStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: MovefullyTheme.Layout.paddingM) {
            Text("\(number)")
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(MovefullyTheme.Colors.primaryTeal)
                .clipShape(Circle())
            
            Text(text)
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                .lineLimit(nil)
            
            Spacer()
        }
    }
    
    private var demoSection: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                HStack {
                    Image(systemName: "play.rectangle")
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    Text("Exercise Demo")
                        .font(MovefullyTheme.Typography.title3)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    Spacer()
                }
                
                // Demo placeholder
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                        .fill(MovefullyTheme.Colors.backgroundSecondary)
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                Image(systemName: "play.circle")
                                    .font(MovefullyTheme.Typography.largeTitle)
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                
                                Text("Demo Video Coming Soon")
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            }
                        )
                    
                    Text("Visual demonstrations will help you perfect your form and get the most out of each exercise.")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

// MARK: - Extensions for Category Colors
extension ExerciseCategory {
    var color: Color {
        switch self {
        case .strength: return MovefullyTheme.Colors.primaryTeal
        case .cardio: return MovefullyTheme.Colors.warmOrange
        case .flexibility: return MovefullyTheme.Colors.softGreen
        case .balance: return MovefullyTheme.Colors.lavender
        case .mindfulness: return MovefullyTheme.Colors.gentleBlue
        }
    }
}

extension DifficultyLevel {
    var colorValue: Color {
        switch self {
        case .beginner: return MovefullyTheme.Colors.softGreen
        case .intermediate: return MovefullyTheme.Colors.primaryTeal
        case .advanced: return MovefullyTheme.Colors.warmOrange
        }
    }
}

#Preview {
    ClientResourcesView(viewModel: ClientViewModel())
} 