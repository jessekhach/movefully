import SwiftUI

// MARK: - Client Dashboard View
struct ClientDashboardView: View {
    @ObservedObject var viewModel: ClientViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var progressService = ProgressHistoryService()
    @StateObject private var progressCacheService = ProgressDataCacheService.shared
    @State private var progressEntries: [ProgressEntry] = []
    @State private var milestones: [Milestone] = []
    @State private var workoutCompletions: [ClientProgressService.WorkoutCompletion] = []
    @State private var selectedCategory: ProgressCategory? = nil
    @State private var isLoading = true
    @State private var showingAddProgressSheet = false
    @State private var showingWorkoutDetail = false
    @State private var selectedWorkoutCompletion: ClientProgressService.WorkoutCompletion?
    
    var body: some View {
        NavigationStack {
            MovefullyClientNavigation(
                title: "Progress",
                showProfileButton: false,
                trailingButton: MovefullyStandardNavigation.ToolbarButton(
                    icon: "plus",
                    action: { showingAddProgressSheet = true },
                    accessibilityLabel: "Add Progress"
                )
            ) {
                if isLoading {
                    loadingView
                } else {
                    // Progress Overview + Chart Section
                    progressOverviewSection
                    
                    // Progress Updates Section (includes trend and updates)
                    progressUpdatesSection
                    
                    // Recent Workouts Section (at bottom)
                    recentWorkoutsSection
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadProgressData()
            }
            .sheet(isPresented: $showingAddProgressSheet) {
                if let currentClient = viewModel.currentClient {
                    AddProgressSheet(client: currentClient) {
                        Task { await loadProgressData() }
                    }
                }
            }
            .sheet(isPresented: $showingWorkoutDetail) {
                if let selectedWorkout = selectedWorkoutCompletion {
                    WorkoutReviewView(
                        assignment: createWorkoutAssignmentFromCompletion(selectedWorkout),
                        viewModel: viewModel
                    )
                }
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.2)
                .tint(MovefullyTheme.Colors.primaryTeal)
            
            Text("Loading your progress...")
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
            
            Spacer()
        }
    }
    
    // MARK: - Progress Overview Section
    private var progressOverviewSection: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            // Stats Header
            MovefullyCard {
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    HStack {
                        Text("Progress Overview")
                            .font(MovefullyTheme.Typography.title3)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Spacer()
                    }
                    
                    HStack(spacing: MovefullyTheme.Layout.paddingL) {
                        ProgressStatView(
                            title: "Total Updates",
                            value: "\(progressEntries.count)",
                            icon: "chart.line.uptrend.xyaxis"
                        )
                        
                        ProgressStatView(
                            title: "This Month",
                            value: "\(entriesThisMonth)",
                            icon: "calendar.badge.checkmark"
                        )
                        
                        ProgressStatView(
                            title: "Milestones",
                            value: "\(milestones.count)",
                            icon: "trophy"
                        )
                    }
                }
            }
            
            // Progress Chart
            if !progressEntries.isEmpty {
                ProgressChartView(entries: progressEntries)
            }
        }
    }
    
    // MARK: - Progress Updates Section
    private var progressUpdatesSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                Text("Progress Updates")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            // Category Filter
            categoryFilter
            
            // Progress Entries
            if filteredProgressEntries.isEmpty {
                MovefullyEmptyState(
                    icon: "chart.line.uptrend.xyaxis",
                    title: selectedCategory == nil ? "No Progress Updates" : "No Updates in \(selectedCategory?.displayName ?? "")",
                    description: "Tap the + button to start tracking your progress measurements",
                    actionButton: nil
                )
            } else {
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    ForEach(Array(filteredProgressEntries.prefix(5))) { entry in
                        ProgressEntryCard(entry: entry)
                    }
                    
                    if filteredProgressEntries.count > 5 {
                        Button("View All Updates") {
                            // Could navigate to full history view if needed
                        }
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        .padding(.top, MovefullyTheme.Layout.paddingS)
                    }
                }
            }
            
            // Milestones
            if !milestones.isEmpty {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                    HStack {
                        Text("Milestones")
                            .font(MovefullyTheme.Typography.title3)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        ForEach(Array(milestones.prefix(3))) { milestone in
                            MilestoneCard(milestone: milestone)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Workouts Section
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            HStack {
                Text("Recent Workouts")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            if workoutCompletions.isEmpty {
                MovefullyEmptyState(
                    icon: "figure.strengthtraining.traditional",
                    title: "No Recent Workouts",
                    description: "Complete workouts to see your progress here",
                    actionButton: nil
                )
            } else {
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    ForEach(workoutCompletions, id: \.id) { completion in
                        workoutCompletionCard(completion)
                    }
                }
            }
        }
    }
    
    // MARK: - Workout Completion Card
    private func workoutCompletionCard(_ completion: ClientProgressService.WorkoutCompletion) -> some View {
        Button {
            selectedWorkoutCompletion = completion
            showingWorkoutDetail = true
        } label: {
            MovefullyCard {
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Workout Icon
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        .frame(width: 40, height: 40)
                        .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                        Text(completion.workoutTitle)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: MovefullyTheme.Layout.paddingM) {
                            // Rating
                            HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= completion.rating ? "star.fill" : "star")
                                        .font(.system(size: 12))
                                        .foregroundColor(star <= completion.rating ? MovefullyTheme.Colors.warmOrange : MovefullyTheme.Colors.textTertiary)
                                }
                            }
                            
                            // Duration
                            if completion.duration > 0 {
                                Text("\(completion.duration) min")
                                    .font(MovefullyTheme.Typography.caption)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            }
                        }
                        
                        // Date
                        Text(formatRelativeTime(completion.completedDate))
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                    }
                    
                    Spacer()
                    
                    // Right arrow
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                }
                .padding(MovefullyTheme.Layout.paddingM)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                // All Categories
                categoryFilterButton(
                    title: "All",
                    icon: "list.bullet",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                // Individual Categories
                ForEach(ProgressCategory.allCases, id: \.self) { category in
                    categoryFilterButton(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
        }
    }
    
    private func categoryFilterButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(title)
                    .font(MovefullyTheme.Typography.callout)
            }
            .foregroundColor(isSelected ? .white : MovefullyTheme.Colors.textSecondary)
            .padding(.horizontal, MovefullyTheme.Layout.paddingM)
            .padding(.vertical, MovefullyTheme.Layout.paddingS)
            .background(
                isSelected 
                    ? MovefullyTheme.Colors.primaryTeal
                    : MovefullyTheme.Colors.cardBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            .shadow(color: isSelected ? MovefullyTheme.Colors.primaryTeal.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Properties
    private var entriesThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return progressEntries.filter { entry in
            calendar.isDate(entry.timestamp, equalTo: now, toGranularity: .month)
        }.count
    }
    
    private var filteredProgressEntries: [ProgressEntry] {
        if let selectedCategory = selectedCategory {
            return progressEntries.filter { $0.field.category == selectedCategory }
        }
        return progressEntries
    }
    
    // MARK: - Helper Functions
    private func formatRelativeTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let daysDiff = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if daysDiff < 7 {
                return "\(daysDiff) days ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: date)
            }
        }
    }
    
    private func findWorkoutInWeeklyAssignments(title: String, date: Date) -> WorkoutAssignment? {
        // Search through all weekly assignments to find a matching workout
        for weekAssignments in viewModel.assignmentsByWeek.values {
            if let foundWorkout = weekAssignments.first(where: { workout in
                workout.title == title && Calendar.current.isDate(workout.date, inSameDayAs: date)
            }) {
                return foundWorkout
            }
        }
        return nil
    }
    
    private func createWorkoutAssignmentFromCompletion(_ completion: ClientProgressService.WorkoutCompletion) -> WorkoutAssignment {
        // First, try to find the workout in today's workout
        if let todayWorkout = viewModel.todayWorkout,
           todayWorkout.title == completion.workoutTitle,
           Calendar.current.isDate(todayWorkout.date, inSameDayAs: completion.completedDate) {
            return todayWorkout
        }
        
        // Then try to find it in the weekly assignments
        if let foundWorkout = findWorkoutInWeeklyAssignments(
            title: completion.workoutTitle,
            date: completion.completedDate
        ) {
            return foundWorkout
        }
        
        // Fallback: create a minimal workout assignment
        return WorkoutAssignment(
            title: completion.workoutTitle,
            description: completion.notes.isEmpty ? "Completed workout session" : completion.notes,
            date: completion.completedDate,
            status: .completed,
            exercises: [], // Will show completion data only
            trainerNotes: nil,
            estimatedDuration: completion.duration
        )
    }
    
    // MARK: - Data Loading
    private func loadProgressData() async {
        guard let currentClient = viewModel.currentClient else { return }
        
        // First, try to load from cache
        if let cachedData = progressCacheService.getCachedProgressData() {
            print("📦 ClientDashboardView: Using cached progress data")
            progressEntries = cachedData.progressEntries
            milestones = cachedData.milestones
            workoutCompletions = cachedData.workoutCompletions
            isLoading = false
            return
        }
        
        // If no cache available, fetch fresh data
        isLoading = true
        
        do {
            let (entries, milestonesList, completions) = try await progressCacheService.fetchAndCacheProgressData()
            progressEntries = entries
            milestones = milestonesList
            workoutCompletions = completions
        } catch {
            print("Error loading progress data: \(error)")
        }
        
        isLoading = false
    }
}

#Preview {
    ClientDashboardView(viewModel: ClientViewModel())
} 