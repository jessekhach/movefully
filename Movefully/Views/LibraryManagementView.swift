import SwiftUI

struct LibraryManagementView: View {
    @StateObject private var programsViewModel = ProgramsViewModel()
    @State private var searchText = ""
    @State private var showingCreateTemplate = false
    @State private var showingExerciseLibrary = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                    // Search field as first item in scrollable content
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        MovefullySearchField(
                            placeholder: "Search templates...",
                            text: $searchText
                        )
                    }
                    .padding(.vertical, MovefullyTheme.Layout.paddingS)
                    
                    // Templates content
                    templatesContent
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.top, MovefullyTheme.Layout.paddingM)
                .padding(.bottom, MovefullyTheme.Layout.paddingXXL)
            }
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Menu {
                            Button("Browse Exercise Library") {
                                showingExerciseLibrary = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        }
                        
                        Button(action: { showingCreateTemplate = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        }
                        .accessibilityLabel("Create Template")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
                title: searchText.isEmpty ? "Build your template library" : "No templates found",
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
            ForEach(filteredTemplates) { template in
                WorkoutTemplateCard(template: template) {
                    // Handle template selection - could navigate to edit view
                }
            }
        }
    }
}

// MARK: - Simplified Create Template View
struct CreateTemplateView: View {
    @EnvironmentObject var programsViewModel: ProgramsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var templateName: String = ""
    @State private var templateDescription: String = ""
    @State private var selectedDifficulty: WorkoutDifficulty = .beginner
    @State private var tags: String = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Template Details") {
                    TextField("Template Name", text: $templateName)
                        .autocorrectionDisabled()
                    
                    TextField("Description", text: $templateDescription, axis: .vertical)
                        .lineLimit(3...6)
                        .autocorrectionDisabled()
                }
                
                Section("Difficulty") {
                    Picker("Difficulty", selection: $selectedDifficulty) {
                        ForEach(WorkoutDifficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.rawValue).tag(difficulty)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Tags (Optional)") {
                    TextField("e.g., Strength, Core, Beginner", text: $tags)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Create Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { createTemplate() }
                        .fontWeight(.semibold)
                        .disabled(templateName.isEmpty || templateDescription.isEmpty || isLoading)
                }
            }
        }
    }
    
    private func createTemplate() {
        isLoading = true
        
        let template = WorkoutTemplate(
            name: templateName,
            description: templateDescription,
            difficulty: selectedDifficulty,
            estimatedDuration: 30, // Default duration
            exercises: [], // Start with no exercises - can be added later
            tags: tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
            usageCount: 0,
            createdDate: Date(),
            updatedDate: Date()
        )
        
        programsViewModel.createTemplate(template)
        
        // Simulate creation delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            dismiss()
        }
    }
}

// MARK: - Workout Template Card
struct WorkoutTemplateCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
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
                
                // Tags (if any)
                if !template.tags.isEmpty {
                    HStack {
                        ForEach(template.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.warmOrange)
                                .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                                .padding(.vertical, 4)
                                .background(MovefullyTheme.Colors.warmOrange.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        
                        if template.tags.count > 3 {
                            Text("+\(template.tags.count - 3)")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textTertiary)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(MovefullyTheme.Layout.paddingL)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity, alignment: .leading)
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
        if template.tags.contains("Strength") {
            return "dumbbell.fill"
        } else if template.tags.contains("Cardio") || template.tags.contains("HIIT") {
            return "heart.fill"
        } else if template.tags.contains("Flexibility") || template.tags.contains("Yoga") {
            return "figure.yoga"
        } else if template.tags.contains("Recovery") {
            return "leaf.fill"
        } else {
            return "doc.text.below.ecg"
        }
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

#Preview {
    LibraryManagementView()
} 