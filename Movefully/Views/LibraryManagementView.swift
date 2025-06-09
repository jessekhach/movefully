import SwiftUI
import Foundation

struct LibraryManagementView: View {
    @StateObject private var programsViewModel = ProgramsViewModel()
    @State private var searchText = ""
    @State private var showingCreateTemplate = false
    @State private var showingExerciseLibrary = false


    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Search field - only show when there are templates to search
                    if !programsViewModel.workoutTemplates.isEmpty {
                        MovefullySearchField(
                            placeholder: "Search templates...",
                            text: $searchText
                        )
                    }
                    
                    // Templates content
                    templatesContent
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.top, MovefullyTheme.Layout.paddingL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXXL)
            }
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: MovefullyTheme.Layout.paddingS) {
                        // Menu button with proper ellipsis menu
                        Menu {
                            Button(action: {
                                showingExerciseLibrary = true
                            }) {
                                Label("Browse Exercise Library", systemImage: "book.fill")
                            }
                            
                            // Future menu items can go here
                            // Button(action: {}) {
                            //     Label("Import Templates", systemImage: "square.and.arrow.down")
                            // }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        }
                        .menuStyle(.borderlessButton)
                        
                        // Create template button
                        Button(action: {
                            showingCreateTemplate = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        }
                    }
                }
            }
                }
        .sheet(isPresented: $showingCreateTemplate) {
            CreateTemplateView()
                .environmentObject(programsViewModel)
        }
        .sheet(isPresented: $showingExerciseLibrary) {
            NavigationStack {
                ExerciseLibraryView()
                    .navigationTitle("Exercise Library")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Done") { 
                                showingExerciseLibrary = false 
                            }
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        }
                    }
            }
        }


        .onAppear {
            // Data loads automatically in ViewModels init
        }
    }
    
    // MARK: - Templates Content
    @ViewBuilder
    private var templatesContent: some View {
        let filteredTemplates = programsViewModel.workoutTemplates.filter { template in
            searchText.isEmpty || template.name.localizedCaseInsensitiveContains(searchText) ||
            template.description.localizedCaseInsensitiveContains(searchText) ||
            template.tags.joined().localizedCaseInsensitiveContains(searchText)
        }
        
        if filteredTemplates.isEmpty {
            // Empty state using Movefully styling
            MovefullyEmptyState(
                icon: searchText.isEmpty ? "doc.text.below.ecg" : "magnifyingglass",
                title: searchText.isEmpty ? "Build your template collection" : "No templates found",
                description: searchText.isEmpty ? 
                    "Create reusable workout templates to speed up your plan creation process." : 
                    "Try adjusting your search terms to find the template you're looking for.",
                actionButton: searchText.isEmpty ? 
                    MovefullyEmptyState.ActionButton(
                        title: "Create Your First Template",
                        action: { showingCreateTemplate = true }
                    ) : nil
            )
        } else {
            LazyVStack(spacing: MovefullyTheme.Layout.paddingL) {
                ForEach(filteredTemplates) { template in
                    NavigationLink(destination: TemplateDetailView(template: template).environmentObject(programsViewModel)) {
                        WorkoutTemplateCardContent(template: template)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Exercise with Sets/Reps
struct ExerciseWithSetsReps: Identifiable, Codable {
    let id = UUID()
    let exercise: Exercise
    var sets: Int = 3
    var reps: String = "12" // Can be "12", "10-15", "30 sec", etc.
    
    init(exercise: Exercise) {
        self.exercise = exercise
        // Set default values based on exercise type
        if exercise.exerciseType == .duration {
            self.reps = "\(exercise.duration ?? 30)" // Use exercise's default duration or 30 seconds
        } else {
            self.reps = "12" // Default reps
        }
    }
    
    // Custom Codable implementation to handle UUID
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.exercise = try container.decode(Exercise.self, forKey: .exercise)
        self.sets = try container.decode(Int.self, forKey: .sets)
        self.reps = try container.decode(String.self, forKey: .reps)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(exercise, forKey: .exercise)
        try container.encode(sets, forKey: .sets)
        try container.encode(reps, forKey: .reps)
    }
    
    private enum CodingKeys: String, CodingKey {
        case exercise, sets, reps
    }
}

// MARK: - Comprehensive Template Builder
struct CreateTemplateView: View {
    @EnvironmentObject var programsViewModel: ProgramsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 1
    @State private var templateName: String = ""
    @State private var templateDescription: String = ""
    @State private var selectedDifficulty: WorkoutDifficulty = .beginner
    @State private var estimatedDuration: Int = 30

    @State private var selectedTags: Set<String> = []
    @State private var selectedExercises: [ExerciseWithSetsReps] = []
    @State private var targetMuscleGroups: [String] = []
    @State private var coachingNotes: String = ""
    @State private var isLoading = false
    @State private var showingExerciseLibrary = false
    @State private var showingCancelConfirmation = false
    
    private let totalSteps = 4
    
    // Check if there are unsaved changes
    private var hasUnsavedChanges: Bool {
        !templateName.isEmpty || !templateDescription.isEmpty || !selectedExercises.isEmpty || !selectedTags.isEmpty || !coachingNotes.isEmpty
    }
    
    // Pre-defined tag options for multi-select
    private let availableTags = [
        "Strength", "Cardio", "Flexibility", "Balance", "HIIT", "Core", 
        "Upper Body", "Lower Body", "Full Body", "Beginner Friendly", 
        "Advanced", "Recovery", "Mobility", "Endurance", "Power", 
        "Stability", "Functional", "Sport Specific"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Progress Indicator
                    progressIndicator
                    
                    // Step Content
                    Group {
                        switch currentStep {
                        case 1:
                            templateBasicsStep
                        case 2:
                            exerciseSelectionStep
                        case 3:
                            additionalDetailsStep
                        case 4:
                            reviewAndCreateStep
                        default:
                            EmptyView()
                        }
                    }
                    
                    // Navigation Buttons
                    navigationButtons
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            }
            .movefullyBackground()
            .navigationTitle("Create Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { 
                        if hasUnsavedChanges {
                            showingCancelConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
        .fullScreenCover(isPresented: $showingExerciseLibrary) {
            ExerciseSelectionSheet(selectedExercises: $selectedExercises)
        }
        .interactiveDismissDisabled(showingExerciseLibrary) // Prevent swipe to dismiss exercise selection
        .alert("Discard Template?", isPresented: $showingCancelConfirmation) {
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) { }
        } message: {
            Text("You have unsaved changes that will be lost if you cancel.")
        }
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        HStack {
            ForEach(1...totalSteps, id: \.self) { step in
                HStack(spacing: MovefullyTheme.Layout.paddingS) {
                    Circle()
                        .fill(step <= currentStep ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.inactive)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("\(step)")
                                .font(MovefullyTheme.Typography.footnote)
                                .foregroundColor(.white)
                        )
                    
                    if step < totalSteps {
                        Rectangle()
                            .fill(step < currentStep ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.inactive)
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.top, MovefullyTheme.Layout.paddingL)
    }
    
    // MARK: - Step 1: Template Basics
    private var templateBasicsStep: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                MovefullyPageHeader(
                    title: "Template Basics",
                    subtitle: "Let's start with the fundamentals of your workout template"
                )
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    MovefullyFormField(title: "Template Name", isRequired: true) {
                        MovefullyTextField(
                            placeholder: "e.g., Core Strength Essentials",
                            text: $templateName
                        )
                    }
                    
                    MovefullyFormField(title: "Description", isRequired: true) {
                        MovefullyTextEditor(
                            placeholder: "Describe what this template focuses on...",
                            text: $templateDescription,
                            minLines: 3,
                            maxLines: 5
                        )
                    }
                    
                    MovefullyFormField(title: "Difficulty Level") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                ForEach(WorkoutDifficulty.allCases, id: \.self) { difficulty in
                                    MovefullyPill(
                                        title: difficulty.rawValue,
                                        isSelected: selectedDifficulty == difficulty,
                                        style: .filter
                                    ) {
                                        selectedDifficulty = difficulty
                                    }
                                }
                            }
                            .padding(.horizontal, MovefullyTheme.Layout.paddingXS)
                        }
                    }
                    
                    MovefullyFormField(title: "Estimated Duration (minutes)") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                                ForEach([15, 30, 45, 60, 90], id: \.self) { duration in
                                    MovefullyPill(
                                        title: "\(duration) min",
                                        isSelected: estimatedDuration == duration,
                                        style: .filter
                                    ) {
                                        estimatedDuration = duration
                                    }
                                }
                            }
                            .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                        }
                    }
                    

                }
            }
        }
    }
    
    // MARK: - Step 2: Exercise Selection
    private var exerciseSelectionStep: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                MovefullyPageHeader(
                    title: "Select Exercises",
                    subtitle: "Choose the exercises that will be included in this template"
                )
                
                Button("Browse Exercise Library") {
                    showingExerciseLibrary = true
                }
                .movefullyButtonStyle(.secondary)
                
                if !selectedExercises.isEmpty {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Selected Exercises (\(selectedExercises.count))")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        LazyVStack(spacing: MovefullyTheme.Layout.paddingS) {
                            ForEach($selectedExercises, id: \.id) { $exercise in
                                SelectedExerciseRow(exercise: $exercise) {
                                    selectedExercises.removeAll { $0.id == exercise.id }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 3: Additional Details
    private var additionalDetailsStep: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                MovefullyPageHeader(
                    title: "Additional Details",
                    subtitle: "Add tags and template notes to help organize and guide this template"
                )
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    MovefullyFormField(
                        title: "Tags",
                        subtitle: "Select relevant tags to categorize this template"
                    ) {
                        // Tag selection grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: MovefullyTheme.Layout.paddingS) {
                            ForEach(availableTags, id: \.self) { tag in
                                MovefullyPill(
                                    title: tag,
                                    isSelected: selectedTags.contains(tag),
                                    style: .tag
                                ) {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                }
                            }
                        }
                    }
                    
                    MovefullyFormField(
                        title: "Template Notes",
                        subtitle: "Optional notes for trainers using this template"
                    ) {
                        MovefullyTextEditor(
                            placeholder: "Add any coaching tips or special instructions...",
                            text: $coachingNotes,
                            minLines: 3,
                            maxLines: 6
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Step 4: Review and Create
    private var reviewAndCreateStep: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                MovefullyPageHeader(
                    title: "Review Template",
                    subtitle: "Review your template details before creating"
                )
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    TemplateReviewSection(title: "Basic Information") {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            ReviewItem(label: "Name", value: templateName)
                            ReviewItem(label: "Description", value: templateDescription)
                            ReviewItem(label: "Difficulty", value: selectedDifficulty.rawValue)
                            ReviewItem(label: "Duration", value: "\(estimatedDuration) minutes")
                        }
                    }
                    
                    TemplateReviewSection(title: "Selected Exercises") {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            ReviewItem(label: "Count", value: "\(selectedExercises.count) exercises")
                            
                            if !selectedExercises.isEmpty {
                                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                                    ForEach(selectedExercises, id: \.id) { exercise in
                                        HStack {
                                            Text("• \(exercise.exercise.title)")
                                                .font(MovefullyTheme.Typography.caption)
                                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                            
                                            Spacer()
                                            
                                            // Show sets/reps or duration based on exercise type
                                            if exercise.exercise.exerciseType == .reps {
                                                Text("\(exercise.sets) sets × \(exercise.reps) reps")
                                                    .font(MovefullyTheme.Typography.caption)
                                                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                            } else {
                                                Text("\(exercise.exercise.duration ?? 0) sec")
                                                    .font(MovefullyTheme.Typography.caption)
                                                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    

                }
            }
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            if currentStep > 1 {
                Button("Previous") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                }
                .movefullyButtonStyle(.tertiary)
            }
            
            Spacer()
            
            if currentStep < totalSteps {
                Button("Next") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                }
                .movefullyButtonStyle(.primary)
                .disabled(!canProceedFromCurrentStep)
            } else {
                Button("Create Template") {
                    createTemplate()
                }
                .movefullyButtonStyle(.primary)
                .disabled(isLoading || !isFormValid)
            }
        }
        .padding(.bottom, MovefullyTheme.Layout.paddingXL)
    }
    
    // MARK: - Helper Properties
    private var canProceedFromCurrentStep: Bool {
        switch currentStep {
        case 1:
            return !templateName.isEmpty && !templateDescription.isEmpty
        case 2:
            return !selectedExercises.isEmpty
        case 3:
            return true // Additional details are optional
        case 4:
            return isFormValid
        default:
            return false
        }
    }
    
    private var isFormValid: Bool {
        !templateName.isEmpty && !templateDescription.isEmpty && !selectedExercises.isEmpty
    }
    
    // MARK: - Create Template
    private func createTemplate() {
        isLoading = true
        
        let template = WorkoutTemplate(
            name: templateName,
            description: templateDescription,
            difficulty: selectedDifficulty,
            estimatedDuration: estimatedDuration,
            exercises: selectedExercises.map { $0.exercise },
            tags: Array(selectedTags).sorted(),
            icon: "doc.text.fill", // Default icon, will be derived from tags
            coachingNotes: coachingNotes.isEmpty ? nil : coachingNotes,
            usageCount: 0,
            createdDate: Date(),
            updatedDate: Date()
        )
        
        programsViewModel.createTemplate(template)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            dismiss()
        }
    }
}

// MARK: - Supporting Views for Template Creation
struct SelectedExerciseRow: View {
    @Binding var exercise: ExerciseWithSetsReps
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text(exercise.exercise.title)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    if let description = exercise.exercise.description {
                        Text(description)
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                }
            }
            
            // Sets and Reps Input
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text("Sets")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    HStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Button("-") {
                            if exercise.sets > 1 {
                                exercise.sets -= 1
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        .frame(width: 24, height: 24)
                        .background(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                        .clipShape(Circle())
                        
                        Text("\(exercise.sets)")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            .frame(minWidth: 16)
                        
                        Button("+") {
                            if exercise.sets < 10 {
                                exercise.sets += 1
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        .frame(width: 24, height: 24)
                        .background(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                        .clipShape(Circle())
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                                            Text(exercise.exercise.exerciseType == .reps ? "Reps" : "Duration (sec)")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                                            TextField(exercise.exercise.exerciseType == .reps ? "12" : "60", text: $exercise.reps)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                        .keyboardType(exercise.exercise.exerciseType == .duration ? .numberPad : .default)
                }
            }
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingM)
        .padding(.vertical, MovefullyTheme.Layout.paddingS)
        .background(MovefullyTheme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
    }
}

struct TemplateReviewSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
            Text(title)
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            content
        }
        .padding(MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
    }
}

struct ReviewItem: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
            
            Text(value)
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            Spacer()
        }
    }
}

struct ExerciseSelectionSheet: View {
    @Binding var selectedExercises: [ExerciseWithSetsReps]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory? = nil
    @State private var showingCancelConfirmation = false
    
    // Use the master exercise repository
    private let availableExercises = Exercise.sampleExercises
    
    private var filteredExercises: [Exercise] {
        var exercises = availableExercises
        
        // Filter by search text
        if !searchText.isEmpty {
            exercises = exercises.filter { exercise in
                exercise.title.localizedCaseInsensitiveContains(searchText) ||
                exercise.description?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            exercises = exercises.filter { $0.category == selectedCategory }
        }
        
        // Sort alphabetically by default
        return exercises.sorted { $0.title < $1.title }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and Filter Section
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Compact Search Field
                    HStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                            .font(.system(size: 16))
                        
                        TextField("Search exercises...", text: $searchText)
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                    .padding(.vertical, MovefullyTheme.Layout.paddingS)
                    .background(MovefullyTheme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: MovefullyTheme.Layout.paddingS) {
                            // All Categories button
                            MovefullyPill(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                style: .filter
                            ) {
                                selectedCategory = nil
                            }
                            
                            // Individual category buttons
                            ForEach(ExerciseCategory.allCases, id: \.self) { category in
                                MovefullyPill(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    style: .filter
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    }
                }
                .padding(.vertical, MovefullyTheme.Layout.paddingM)
                .background(MovefullyTheme.Colors.cardBackground)
                
                // Exercise List
                List {
                    ForEach(filteredExercises, id: \.id) { exercise in
                        ExerciseSelectionRowWithType(
                            exercise: exercise,
                            isSelected: selectedExercises.contains { $0.exercise.id == exercise.id }
                        ) {
                            if selectedExercises.contains(where: { $0.exercise.id == exercise.id }) {
                                selectedExercises.removeAll { $0.exercise.id == exercise.id }
                            } else {
                                selectedExercises.append(ExerciseWithSetsReps(exercise: exercise))
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Select Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { 
                        if selectedExercises.isEmpty {
                            dismiss()
                        } else {
                            showingCancelConfirmation = true
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }

        .alert("Discard Changes?", isPresented: $showingCancelConfirmation) {
            Button("Discard", role: .destructive) {
                selectedExercises.removeAll()
                dismiss()
            }
            Button("Keep Editing", role: .cancel) { }
        } message: {
            Text("You have selected exercises that will be lost if you cancel.")
        }
    }
}

// MARK: - Enhanced Exercise Selection Row with Type Indicator
struct ExerciseSelectionRowWithType: View {
    let exercise: Exercise
    let isSelected: Bool
    let onToggle: () -> Void
    
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
    
    private var exerciseTypeColor: Color {
        switch exercise.exerciseType {
        case .reps:
            return MovefullyTheme.Colors.primaryTeal
        case .duration:
            return MovefullyTheme.Colors.secondaryPeach
        }
    }
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.cardBackground)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.divider, lineWidth: 2)
                        )
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Exercise info
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    HStack {
                        Text(exercise.title)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Spacer()
                        

                        
                        if let difficulty = exercise.difficulty {
                            Text(difficulty.rawValue)
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(difficultyColor)
                                .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                                .padding(.vertical, MovefullyTheme.Layout.paddingXS)
                                .background(difficultyColor.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
                        }
                    }
                    
                    if let description = exercise.description {
                        Text(description)
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
            }
            .padding(MovefullyTheme.Layout.paddingM)
            .background(isSelected ? MovefullyTheme.Colors.primaryTeal.opacity(0.05) : MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            .overlay(
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                    .stroke(isSelected ? MovefullyTheme.Colors.primaryTeal.opacity(0.3) : MovefullyTheme.Colors.divider, lineWidth: 1)
            )
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: isSelected ? 4 : 2, x: 0, y: isSelected ? 2 : 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Workout Template Card Content (for NavigationLink)
struct WorkoutTemplateCardContent: View {
    let template: WorkoutTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            // Header
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                // Template Icon
                ZStack {
                    RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                        .fill(templateColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: templateIcon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(templateColor)
                }
                
                // Template Info
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text(template.name)
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text(template.description)
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                }
            }
            
            // Stats Row
            HStack(spacing: MovefullyTheme.Layout.paddingL) {
                TemplateStatView(
                    icon: "clock",
                    value: "\(template.estimatedDuration)",
                    label: "min"
                )
                
                TemplateStatView(
                    icon: "list.bullet",
                    value: "\(template.exercises.count)",
                    label: "exercises"
                )
                
                TemplateStatView(
                    icon: "arrow.clockwise",
                    value: "\(template.usageCount)",
                    label: "uses"
                )
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
            }
            
            // Tags section (always present)
            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                if template.tags.isEmpty {
                    Text("No tags assigned")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                        .italic()
                } else {
                    ForEach(template.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                            .padding(.vertical, MovefullyTheme.Layout.paddingXS)
                            .background(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    
                    if template.tags.count > 3 {
                        Text("+\(template.tags.count - 3)")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                            .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                            .padding(.vertical, MovefullyTheme.Layout.paddingXS)
                            .background(MovefullyTheme.Colors.textTertiary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
            }
        }
        .padding(MovefullyTheme.Layout.paddingL)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    private var templateColor: Color {
        switch template.difficulty {
        case .beginner:
            return MovefullyTheme.Colors.softGreen
        case .intermediate:
            return MovefullyTheme.Colors.primaryTeal
        case .advanced:
            return MovefullyTheme.Colors.warmOrange
        }
    }
    
    private var templateIcon: String {
        // Priority order for icon selection based on tags
        if template.tags.contains("Strength") || template.tags.contains("Upper Body") || template.tags.contains("Lower Body") {
            return "dumbbell.fill"
        } else if template.tags.contains("Cardio") || template.tags.contains("HIIT") || template.tags.contains("Endurance") {
            return "heart.fill"
        } else if template.tags.contains("Flexibility") || template.tags.contains("Mobility") {
            return "figure.yoga"
        } else if template.tags.contains("Core") || template.tags.contains("Stability") {
            return "circle.grid.3x3.fill"
        } else if template.tags.contains("Balance") || template.tags.contains("Functional") {
            return "figure.stand"
        } else if template.tags.contains("Recovery") {
            return "leaf.fill"
        } else if template.tags.contains("Quick Workout") || template.tags.contains("Beginner Friendly") {
            return "timer"
        } else {
            return "doc.text.fill"
        }
    }
}

// MARK: - Workout Template Card (with Button for other uses)
struct WorkoutTemplateCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            WorkoutTemplateCardContent(template: template)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Views
struct TemplateStatView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingXS) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(MovefullyTheme.Colors.textTertiary)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
            }
        }
    }
}

// MARK: - Template Detail View
struct TemplateDetailView: View {
    let template: WorkoutTemplate
    @EnvironmentObject var programsViewModel: ProgramsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditTemplate = false
    @State private var showingDeleteConfirmation = false
    @State private var showingDuplicateSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                // Header Card
                templateHeaderCard
                
                // Quick Stats
                templateStatsCard
                
                // Exercises List
                exercisesCard
                
                // Template Notes (always show)
                templateNotesCard
            }
            .padding(.top, MovefullyTheme.Layout.paddingL)
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            .padding(.bottom, MovefullyTheme.Layout.paddingXXL)
        }
        .movefullyBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit Template") {
                        showingEditTemplate = true
                    }
                    
                    Button("Duplicate Template") {
                        showingDuplicateSheet = true
                    }
                    
                    Divider()
                    
                    Button("Delete Template", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                }
            }
        }
        .sheet(isPresented: $showingEditTemplate) {
            EditTemplateView(template: template)
                .environmentObject(programsViewModel)
        }
        .sheet(isPresented: $showingDuplicateSheet) {
            DuplicateTemplateSheet(originalTemplate: template)
                .environmentObject(programsViewModel)
        }
        .confirmationDialog("Delete Template", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                programsViewModel.deleteTemplate(template)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. The template will be permanently deleted.")
        }
    }
    
    // MARK: - Template Header Card
    private var templateHeaderCard: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Template Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                            .fill(templateColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: templateIcon)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(templateColor)
                    }
                    
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text(template.name)
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text(template.description)
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .lineLimit(nil)
                        
                        // Difficulty Badge
                        HStack {
                            Text(template.difficulty.rawValue)
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(templateColor)
                                .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                                .padding(.vertical, MovefullyTheme.Layout.paddingS)
                                .background(templateColor.opacity(0.15))
                                .clipShape(Capsule())
                            
                            Spacer()
                        }
                    }
                }
                
                // Tags
                if !template.tags.isEmpty {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        HStack {
                            Text("Tags")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            Spacer()
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                ForEach(template.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(MovefullyTheme.Typography.caption)
                                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                        .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                                        .padding(.vertical, MovefullyTheme.Layout.paddingS)
                                        .background(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Template Stats Card
    private var templateStatsCard: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                HStack {
                    Text("Template Overview")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    Spacer()
                }
                
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    TemplateStatCard(
                        icon: "clock",
                        value: "\(template.estimatedDuration) min",
                        label: "Duration",
                        color: MovefullyTheme.Colors.primaryTeal
                    )
                    
                    TemplateStatCard(
                        icon: "list.bullet",
                        value: "\(template.exercises.count)",
                        label: "Exercises",
                        color: MovefullyTheme.Colors.secondaryPeach
                    )
                }
            }
        }
    }
    
    // MARK: - Exercises Card
    private var exercisesCard: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                HStack {
                    Text("Exercises (\(template.exercises.count))")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    Spacer()
                }
                
                if template.exercises.isEmpty {
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 32))
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                        
                        Text("No exercises added yet")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Button("Add Exercises") {
                            showingEditTemplate = true
                        }
                        .movefullyButtonStyle(.secondary)
                    }
                    .padding(.vertical, MovefullyTheme.Layout.paddingL)
                } else {
                    LazyVStack(spacing: MovefullyTheme.Layout.paddingS) {
                        ForEach(Array(template.exercises.enumerated()), id: \.offset) { index, exercise in
                            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                                // Exercise number
                                Text("\(index + 1)")
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                    .frame(width: 28, height: 28)
                                    .background(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                                    .clipShape(Circle())
                                
                                // Exercise details
                                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                                    Text(exercise.title)
                                        .font(MovefullyTheme.Typography.bodyMedium)
                                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                    
                                    if let description = exercise.description {
                                        Text(description)
                                            .font(MovefullyTheme.Typography.caption)
                                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                            .lineLimit(2)
                                    }
                                }
                                
                                Spacer()
                                
                                // Sets and reps (placeholder for now)
                                VStack(alignment: .trailing, spacing: MovefullyTheme.Layout.paddingXS) {
                                    Text("3 sets")
                                        .font(MovefullyTheme.Typography.caption)
                                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                    Text("12 reps")
                                        .font(MovefullyTheme.Typography.caption)
                                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                }
                            }
                            .padding(.vertical, MovefullyTheme.Layout.paddingS)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Template Notes Card
    private var templateNotesCard: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.warmOrange)
                    
                    Text("Template Notes")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Spacer()
                }
                
                HStack {
                    Text(template.coachingNotes?.isEmpty == false ? template.coachingNotes! : "No template notes added")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(template.coachingNotes?.isEmpty == false ? MovefullyTheme.Colors.textSecondary : MovefullyTheme.Colors.textTertiary)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(MovefullyTheme.Layout.paddingM)
                .background(MovefullyTheme.Colors.warmOrange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                .overlay(
                    RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                        .stroke(MovefullyTheme.Colors.warmOrange.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Usage Analytics Card
    private var usageAnalyticsCard: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                HStack {
                    Text("Usage Analytics")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    Spacer()
                }
                
                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                    HStack {
                        Text("Used in \(template.usageCount) programs")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Last updated \(formatDate(template.updatedDate))")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Management Actions Card
    private var managementActionsCard: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                HStack {
                    Text("Template Actions")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    Spacer()
                }
                
                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                    TemplateActionButton(
                        icon: "pencil",
                        title: "Edit Template",
                        subtitle: "Modify exercises and details",
                        color: MovefullyTheme.Colors.primaryTeal
                    ) {
                        showingEditTemplate = true
                    }
                    
                    TemplateActionButton(
                        icon: "doc.on.doc",
                        title: "Duplicate Template",
                        subtitle: "Create a copy to modify",
                        color: MovefullyTheme.Colors.secondaryPeach
                    ) {
                        showingDuplicateSheet = true
                    }
                    
                    TemplateActionButton(
                        icon: "square.and.arrow.up",
                        title: "Share Template",
                        subtitle: "Export or share with others",
                        color: MovefullyTheme.Colors.softGreen
                    ) {
                        // TODO: Implement sharing functionality
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    private var templateColor: Color {
        switch template.difficulty {
        case .beginner:
            return MovefullyTheme.Colors.softGreen
        case .intermediate:
            return MovefullyTheme.Colors.primaryTeal
        case .advanced:
            return MovefullyTheme.Colors.warmOrange
        }
    }
    
    private var templateIcon: String {
        // Priority order for icon selection based on tags
        if template.tags.contains("Strength") || template.tags.contains("Upper Body") || template.tags.contains("Lower Body") {
            return "dumbbell.fill"
        } else if template.tags.contains("Cardio") || template.tags.contains("HIIT") || template.tags.contains("Endurance") {
            return "heart.fill"
        } else if template.tags.contains("Flexibility") || template.tags.contains("Mobility") {
            return "figure.yoga"
        } else if template.tags.contains("Core") || template.tags.contains("Stability") {
            return "circle.grid.3x3.fill"
        } else if template.tags.contains("Balance") || template.tags.contains("Functional") {
            return "figure.stand"
        } else if template.tags.contains("Recovery") {
            return "leaf.fill"
        } else if template.tags.contains("Quick Workout") || template.tags.contains("Beginner Friendly") {
            return "timer"
        } else {
            return "doc.text.fill"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views for Template Detail
struct TemplateStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingS) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            Text(label)
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(MovefullyTheme.Layout.paddingM)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .overlay(
            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct TemplateExerciseRow: View {
    let exercise: Exercise
    let index: Int
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            // Exercise Number
            Text("\(index)")
                .font(MovefullyTheme.Typography.buttonSmall)
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                .frame(width: 24, height: 24)
                .background(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                Text(exercise.title)
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                if let description = exercise.description {
                    Text(description)
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
                                            Text("\(exercise.duration ?? 0) sec")
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                .padding(.vertical, MovefullyTheme.Layout.paddingXS)
                .background(MovefullyTheme.Colors.backgroundSecondary)
                .clipShape(Capsule())
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingM)
        .padding(.vertical, MovefullyTheme.Layout.paddingS)
        .background(MovefullyTheme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
    }
}

struct TemplateActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text(title)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
            }
            .padding(MovefullyTheme.Layout.paddingM)
            .background(MovefullyTheme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Template View
struct EditTemplateView: View {
    let template: WorkoutTemplate
    @EnvironmentObject var programsViewModel: ProgramsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 1
    @State private var templateName: String
    @State private var templateDescription: String
    @State private var selectedDifficulty: WorkoutDifficulty
    @State private var estimatedDuration: Int

    @State private var selectedTags: Set<String>
    @State private var selectedExercises: [ExerciseWithSetsReps]
    @State private var coachingNotes: String
    @State private var isLoading = false
    @State private var showingExerciseLibrary = false
    @State private var showingUnsavedChangesAlert = false
    
    private let availableExercises = Exercise.sampleExercises
    private let totalSteps = 4
    
    // Pre-defined tags
    private let availableTags = [
        "Strength", "Cardio", "HIIT", "Flexibility", "Balance", 
        "Core", "Upper Body", "Lower Body", "Full Body", "Recovery",
        "Beginner Friendly", "Advanced", "Quick Workout", "Endurance"
    ]
    
    init(template: WorkoutTemplate) {
        self.template = template
        // Initialize state with template data
        self._templateName = State(initialValue: template.name)
        self._templateDescription = State(initialValue: template.description)
        self._selectedDifficulty = State(initialValue: template.difficulty)
        self._estimatedDuration = State(initialValue: template.estimatedDuration)

        self._selectedTags = State(initialValue: Set(template.tags))
        self._selectedExercises = State(initialValue: template.exercises.map { exercise in
            ExerciseWithSetsReps(exercise: exercise) // Will use default sets/reps
        })
        self._coachingNotes = State(initialValue: template.coachingNotes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Progress Indicator
                    progressIndicator
                    
                    // Step Content
                    Group {
                        switch currentStep {
                        case 1:
                            templateBasicsStep
                        case 2:
                            exerciseSelectionStep
                        case 3:
                            additionalDetailsStep
                        case 4:
                            reviewAndUpdateStep
                        default:
                            EmptyView()
                        }
                    }
                    
                    // Navigation Buttons
                    navigationButtons
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXXL)
            }
            .movefullyBackground()
            .navigationTitle("Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { 
                        if hasUnsavedChanges {
                            showingUnsavedChangesAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
        .fullScreenCover(isPresented: $showingExerciseLibrary) {
            ExerciseSelectionSheet(selectedExercises: $selectedExercises)
        }
        .interactiveDismissDisabled(showingExerciseLibrary) // Prevent swipe to dismiss exercise selection
        .alert("Unsaved Changes", isPresented: $showingUnsavedChangesAlert) {
            Button("Save Changes") { updateTemplate() }
            Button("Discard", role: .destructive) { dismiss() }
            Button("Continue Editing", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. Would you like to save them?")
        }
        .overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: MovefullyTheme.Layout.paddingM) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: MovefullyTheme.Colors.primaryTeal))
                            
                            Text("Updating Template...")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        }
                        .padding(MovefullyTheme.Layout.paddingXL)
                        .background(MovefullyTheme.Colors.backgroundPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 20, x: 0, y: 10)
                    }
                }
            }
        )
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        HStack {
            ForEach(1...totalSteps, id: \.self) { step in
                HStack(spacing: MovefullyTheme.Layout.paddingS) {
                    Circle()
                        .fill(step <= currentStep ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.inactive)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("\(step)")
                                .font(MovefullyTheme.Typography.footnote)
                                .foregroundColor(.white)
                        )
                    
                    if step < totalSteps {
                        Rectangle()
                            .fill(step < currentStep ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.inactive)
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.top, MovefullyTheme.Layout.paddingL)
    }
    

    
    // MARK: - Step 1: Template Basics
    private var templateBasicsStep: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                MovefullyPageHeader(
                    title: "Template Basics",
                    subtitle: "Update the fundamental details of your template"
                )
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    MovefullyFormField(title: "Template Name", isRequired: true) {
                        MovefullyTextField(
                            placeholder: "e.g., Core Strength Essentials",
                            text: $templateName
                        )
                    }
                    
                    MovefullyFormField(title: "Description", isRequired: true) {
                        MovefullyTextEditor(
                            placeholder: "Describe what this template focuses on...",
                            text: $templateDescription,
                            minLines: 3,
                            maxLines: 5
                        )
                    }
                    
                    MovefullyFormField(title: "Difficulty Level") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                                ForEach(WorkoutDifficulty.allCases, id: \.self) { difficulty in
                                    MovefullyPill(
                                        title: difficulty.rawValue,
                                        isSelected: selectedDifficulty == difficulty,
                                        style: .filter
                                    ) {
                                        selectedDifficulty = difficulty
                                    }
                                }
                            }
                            .padding(.horizontal, MovefullyTheme.Layout.paddingXS)
                        }
                    }
                    
                    MovefullyFormField(title: "Estimated Duration (minutes)") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                                ForEach([15, 30, 45, 60, 90], id: \.self) { duration in
                                    MovefullyPill(
                                        title: "\(duration) min",
                                        isSelected: estimatedDuration == duration,
                                        style: .filter
                                    ) {
                                        estimatedDuration = duration
                                    }
                                }
                            }
                            .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                        }
                    }
                }
            }
        }
    }
    
    private var exerciseSelectionStep: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                Text("Update exercises")
                    .font(MovefullyTheme.Typography.title2)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text("Modify the exercises in your template with sets and reps")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                Button(action: { showingExerciseLibrary = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Browse Exercise Library")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(MovefullyTheme.Layout.paddingM)
                    .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                }
                
                if !selectedExercises.isEmpty {
                    MovefullyCard {
                        VStack(spacing: MovefullyTheme.Layout.paddingM) {
                            HStack {
                                Text("Selected Exercises (\(selectedExercises.count))")
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                Spacer()
                            }
                            
                            LazyVStack(spacing: MovefullyTheme.Layout.paddingS) {
                                ForEach($selectedExercises, id: \.id) { $exercise in
                                    SelectedExerciseRow(exercise: $exercise) {
                                        selectedExercises.removeAll { $0.id == exercise.id }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var additionalDetailsStep: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                Text("Additional details")
                    .font(MovefullyTheme.Typography.title2)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text("Add tags and template notes to your template")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                MovefullyFormField(
                    title: "Tags",
                    subtitle: "Select relevant tags to categorize this template"
                ) {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: MovefullyTheme.Layout.paddingS) {
                        ForEach(availableTags, id: \.self) { tag in
                            MovefullyPill(
                                title: tag,
                                isSelected: selectedTags.contains(tag),
                                style: .filter
                            ) {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                }
                            }
                        }
                    }
                }
                
                MovefullyFormField(
                    title: "Template Notes",
                    subtitle: "Optional notes for trainers using this template"
                ) {
                    MovefullyTextField(
                        placeholder: "Add any special instructions, modifications, or tips...",
                        text: $coachingNotes
                    )
                }
            }
        }
    }
    
    private var reviewAndUpdateStep: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                Text("Review changes")
                    .font(MovefullyTheme.Typography.title2)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text("Review your template updates before saving")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                TemplateReviewSection(title: "Basic Information") {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        reviewRow(label: "Name", value: templateName)
                        reviewRow(label: "Description", value: templateDescription)
                        reviewRow(label: "Difficulty", value: selectedDifficulty.rawValue)
                        reviewRow(label: "Duration", value: "\(estimatedDuration) minutes")
                    }
                }
                
                TemplateReviewSection(title: "Selected Exercises") {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        reviewRow(label: "Count", value: "\(selectedExercises.count) exercises")
                        
                        if !selectedExercises.isEmpty {
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                                ForEach(selectedExercises.prefix(3), id: \.id) { exercise in
                                    Text("• \(exercise.exercise.title) - \(exercise.sets) sets × \(exercise.reps) reps")
                                        .font(MovefullyTheme.Typography.caption)
                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                }
                                
                                if selectedExercises.count > 3 {
                                    Text("• +\(selectedExercises.count - 3) more...")
                                        .font(MovefullyTheme.Typography.caption)
                                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func reviewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            if currentStep > 1 {
                Button("Previous") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                }
                .movefullyButtonStyle(.tertiary)
            }
            
            Spacer()
            
            if currentStep < totalSteps {
                Button("Next") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                }
                .movefullyButtonStyle(.primary)
                .disabled(!canProceedToNextStep)
            } else {
                Button("Update Template") {
                    updateTemplate()
                }
                .movefullyButtonStyle(.primary)
                .disabled(isLoading || !canProceedToNextStep)
            }
        }
        .padding(.bottom, MovefullyTheme.Layout.paddingXL)
    }
    
    private var hasUnsavedChanges: Bool {
        templateName != template.name ||
        templateDescription != template.description ||
        selectedDifficulty != template.difficulty ||
        estimatedDuration != template.estimatedDuration ||
        selectedTags != Set(template.tags) ||
        selectedExercises.map { $0.exercise.id } != template.exercises.map { $0.id } ||
        coachingNotes != (template.coachingNotes ?? "")
    }
    
    private var canProceedToNextStep: Bool {
        switch currentStep {
        case 1:
            return !templateName.isEmpty && !templateDescription.isEmpty
        case 2:
            return !selectedExercises.isEmpty
        case 3:
            return true // Optional step
        case 4:
            return true // Review step
        default:
            return false
        }
    }
    
    private func updateTemplate() {
        isLoading = true
        
        let updatedTemplate = WorkoutTemplate(
            id: template.id, // ✅ PRESERVE ORIGINAL ID!
            name: templateName,
            description: templateDescription,
            difficulty: selectedDifficulty,
            estimatedDuration: estimatedDuration,
            exercises: selectedExercises.map(\.exercise),
            tags: Array(selectedTags).sorted(),
            icon: "doc.text.fill", // Default icon, will be derived from tags
            coachingNotes: coachingNotes.isEmpty ? nil : coachingNotes,
            usageCount: template.usageCount,
            createdDate: template.createdDate,
            updatedDate: Date()
        )
        
        programsViewModel.updateTemplate(updatedTemplate)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            dismiss()
        }
    }
}

// MARK: - Duplicate Template Sheet
struct DuplicateTemplateSheet: View {
    let originalTemplate: WorkoutTemplate
    @EnvironmentObject var programsViewModel: ProgramsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newName: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                MovefullyCard {
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Duplicate Template")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Create a copy of '\(originalTemplate.name)' that you can modify independently.")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        MovefullyFormField(title: "New Template Name", isRequired: true) {
                            MovefullyTextField(
                                placeholder: "Enter name for the duplicate",
                                text: $newName
                            )
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Duplicate Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        duplicateTemplate()
                    }
                    .disabled(newName.isEmpty)
                }
            }
        }
        .onAppear {
            newName = originalTemplate.name + " Copy"
        }
    }
    
    private func duplicateTemplate() {
        let duplicatedTemplate = WorkoutTemplate(
            name: newName,
            description: originalTemplate.description,
            difficulty: originalTemplate.difficulty,
            estimatedDuration: originalTemplate.estimatedDuration,
            exercises: originalTemplate.exercises,
            tags: originalTemplate.tags,
            icon: originalTemplate.icon,
            coachingNotes: originalTemplate.coachingNotes,
            usageCount: 0,
            createdDate: Date(),
            updatedDate: Date()
        )
        
        programsViewModel.createTemplate(duplicatedTemplate)
        dismiss()
    }
}

#Preview {
    LibraryManagementView()
} 