import SwiftUI

// MARK: - Client Schedule View
struct ClientScheduleView: View {
    @ObservedObject var viewModel: ClientViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedWeekOffset = 0
    @State private var selectedDate: Date?
    @State private var showingWorkoutDetail = false
    @State private var showingProfile = false
    
    // Animation states
    @State private var weekTransitionDirection: TransitionDirection = .none
    @State private var isWeekChanging = false
    @State private var contentTransitionId = UUID()
    
    // Week navigation limits
    private let maxWeekOffset = 4  // 4 weeks forward
    private let minWeekOffset = -2 // 2 weeks back
    
    enum TransitionDirection {
        case forward, backward, none
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Week selector (back to fixed header at top)
                weekSelectorSection
                
                // Main scrollable content
                ScrollView {
                    VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                        // Week calendar with transition
                        weekCalendarSection
                            .id(contentTransitionId)
                            .transition(.asymmetric(
                                insertion: .move(edge: weekTransitionDirection == .forward ? .trailing : .leading)
                                    .combined(with: .opacity),
                                removal: .move(edge: weekTransitionDirection == .forward ? .leading : .trailing)
                                    .combined(with: .opacity)
                            ))
                        
                        // Selected day details or no plan state with smooth transitions
                        Group {
                            if viewModel.hasNoPlan {
                                ScheduleNoPlanCard()
                                    .transition(.scale.combined(with: .opacity))
                            } else if let selectedDate = selectedDate {
                                selectedDayDetailsSection(for: selectedDate)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                                        removal: .scale(scale: 1.05).combined(with: .opacity)
                                    ))
                            } else {
                                todayOverviewSection
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .animation(.easeInOut(duration: 0.25), value: selectedDate)
                        .animation(.easeInOut(duration: 0.25), value: viewModel.hasNoPlan)
                        
                        Spacer(minLength: MovefullyTheme.Layout.paddingXXL)
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                }
                .background(MovefullyTheme.Colors.backgroundPrimary)
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingWorkoutDetail) {
            if let selectedDate = selectedDate,
               let assignment = getWorkoutAssignment(for: selectedDate) {
                WorkoutDetailView(assignment: assignment, viewModel: viewModel, isReadOnly: true)
            }
        }
        .sheet(isPresented: $showingProfile) {
            // ClientProfileView will be added when available
        }
        .onAppear {
            // Set today as initially selected
            selectedDate = Date()
            // Load weekly workouts if not already loaded
            if viewModel.weeklyAssignments.isEmpty && !viewModel.hasNoPlan {
                viewModel.loadRealData()
            }
        }
        .onChange(of: selectedWeekOffset) { _, newOffset in
            // Update weekly assignments from the preloaded data
            if let assignments = viewModel.assignmentsByWeek[newOffset] {
                viewModel.weeklyAssignments = assignments
            }
            
            // Update selected date to maintain the same day of week in the new week
            if let currentSelectedDate = selectedDate {
                let calendar = Calendar.current
                let selectedWeekday = calendar.component(.weekday, from: currentSelectedDate)
                
                // Find the corresponding day in the new week
                let newWeekDates = currentWeekDates
                if let correspondingDate = newWeekDates.first(where: { date in
                    calendar.component(.weekday, from: date) == selectedWeekday
                }) {
                    selectedDate = correspondingDate
                }
            }
        }
    }
    
    // MARK: - Week Selector Section
    private var weekSelectorSection: some View {
        HStack {
            Button(action: { 
                if selectedWeekOffset > minWeekOffset {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        weekTransitionDirection = .backward
                        selectedWeekOffset -= 1
                        contentTransitionId = UUID()
                    }
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(selectedWeekOffset > minWeekOffset ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.textTertiary)
                    .scaleEffect(selectedWeekOffset > minWeekOffset ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 0.2), value: selectedWeekOffset > minWeekOffset)
            }
            .disabled(selectedWeekOffset <= minWeekOffset)
            
            Spacer()
            
            Text(weekDisplayString)
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: weekDisplayString)
            
            Spacer()
            
            Button(action: { 
                if selectedWeekOffset < maxWeekOffset {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        weekTransitionDirection = .forward
                        selectedWeekOffset += 1
                        contentTransitionId = UUID()
                    }
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(selectedWeekOffset < maxWeekOffset ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.textTertiary)
                    .scaleEffect(selectedWeekOffset < maxWeekOffset ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 0.2), value: selectedWeekOffset < maxWeekOffset)
            }
            .disabled(selectedWeekOffset >= maxWeekOffset)
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
        .padding(.vertical, MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.cardBackground)
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Week Calendar Section
    private var weekCalendarSection: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            // Day labels
            HStack {
                ForEach(weekDays, id: \.self) { dayName in
                    Text(dayName)
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, MovefullyTheme.Layout.paddingS)
            
            // Calendar days
            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                ForEach(currentWeekDates, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isSelected: selectedDate != nil && Calendar.current.isDate(date, inSameDayAs: selectedDate!),
                        isToday: Calendar.current.isDate(date, inSameDayAs: Date()),
                        assignment: getWorkoutAssignment(for: date)
                    ) {
                        selectedDate = date
                    }
                }
            }
        }
    }
    
    // MARK: - Today Overview Section
    private var todayOverviewSection: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingL) {
                HStack {
                    Text("Today's Plan")
                        .font(MovefullyTheme.Typography.title3)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text(formatDate(Date(), style: .short))
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                if let todayWorkout = viewModel.todayWorkout {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        HStack {
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                                Text(todayWorkout.title)
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                HStack {
                                    MovefullyStatusBadge(
                                        text: todayWorkout.status.rawValue,
                                        color: todayWorkout.status.color,
                                        showDot: true
                                    )
                                    
                                    MovefullyStatusBadge(
                                        text: "\(todayWorkout.estimatedDuration) min",
                                        color: MovefullyTheme.Colors.primaryTeal,
                                        showDot: false
                                    )
                                }
                            }
                            
                            Spacer()
                        }
                        
                        if let notes = todayWorkout.trainerNotes {
                            Text(notes)
                                .font(MovefullyTheme.Typography.body)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .lineLimit(2)
                        }
                        
                        Button("View Details") {
                            selectedDate = Date()
                            showingWorkoutDetail = true
                        }
                        .font(MovefullyTheme.Typography.buttonMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.primaryTeal)
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    }
                } else {
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Image(systemName: "leaf.fill")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.softGreen)
                        
                        Text("Rest Day")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Enjoy your recovery time")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                }
            }
        }
    }
    
    // MARK: - Selected Day Details Section
    private func selectedDayDetailsSection(for date: Date) -> some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            HStack {
                Text("Selected Day")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Spacer()
                
                Button("Go To Today") {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.easeInOut(duration: 0.4)) {
                        // Navigate to today's date
                        let today = Date()
                        selectedDate = today
                        
                        // Calculate which week offset contains today
                        let currentWeekOffset = calculateWeekOffset(for: today)
                        if currentWeekOffset != selectedWeekOffset {
                            weekTransitionDirection = currentWeekOffset > selectedWeekOffset ? .forward : .backward
                            selectedWeekOffset = currentWeekOffset
                            contentTransitionId = UUID()
                        }
                    }
                }
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            }
            
            if let assignment = getWorkoutAssignment(for: date) {
                WorkoutAssignmentCard(
                    assignment: assignment,
                    isToday: Calendar.current.isDate(date, inSameDayAs: Date()),
                    onViewDetails: {
                        showingWorkoutDetail = true
                    }
                )
            } else {
                RestDayCard(date: date)
            }
        }
    }
    
    // MARK: - Helper Properties
    private var currentWeekDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        let weekOffset = selectedWeekOffset
        
        guard let targetWeek = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today),
              let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: targetWeek)?.start else {
            return []
        }
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private var weekDays: [String] {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }
    
    private var weekDisplayString: String {
        guard let firstDay = currentWeekDates.first,
              let lastDay = currentWeekDates.last else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startString = formatter.string(from: firstDay)
        let endString = formatter.string(from: lastDay)
        
        return "\(startString) - \(endString)"
    }
    
    private func getWorkoutAssignment(for date: Date) -> WorkoutAssignment? {
        // Use the correct week's assignments from the cache
        let weekAssignments = viewModel.assignmentsByWeek[selectedWeekOffset] ?? []
        return weekAssignments.first { assignment in
            Calendar.current.isDate(assignment.date, inSameDayAs: date)
        }
    }
    
    private func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: date)
    }
    
    private func calculateWeekOffset(for date: Date) -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the start of the week for both dates
        guard let targetWeekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start,
              let todayWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return 0
        }
        
        // Calculate the difference in weeks
        let weekDifference = calendar.dateComponents([.weekOfYear], from: todayWeekStart, to: targetWeekStart).weekOfYear ?? 0
        
        // Clamp to the allowed range
        return max(minWeekOffset, min(maxWeekOffset, weekDifference))
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let assignment: WorkoutAssignment?
    let action: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback for selection
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                // Day number
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(textColor)
                    .animation(.easeInOut(duration: 0.2), value: textColor)
                
                // Status indicator with pulse animation
                statusIndicator
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MovefullyTheme.Layout.paddingM)
            .background(
                ZStack {
                    // Base background
                    backgroundColor
                    
                    // Selection ripple effect
                    if isSelected {
                        RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                            .fill(MovefullyTheme.Colors.primaryTeal.opacity(0.3))
                            .scaleEffect(isSelected ? 1.1 : 0)
                            .animation(.easeOut(duration: 0.4), value: isSelected)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            .overlay(
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                    .stroke(borderColor, lineWidth: isToday ? 2 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isToday)
            )
            .scaleEffect(isSelected ? 1.05 : (isPressed ? 0.95 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return MovefullyTheme.Colors.primaryTeal
        } else {
            return MovefullyTheme.Colors.textPrimary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return MovefullyTheme.Colors.primaryTeal
        } else if isToday {
            return MovefullyTheme.Colors.primaryTeal.opacity(0.1)
        } else {
            return MovefullyTheme.Colors.cardBackground
        }
    }
    
    private var borderColor: Color {
        return isToday ? MovefullyTheme.Colors.primaryTeal : Color.clear
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        if let assignment = assignment {
            ZStack {
                // Pulse effect for pending workouts
                if assignment.status == .pending && isToday {
                    Circle()
                        .fill(assignment.status.color.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .scaleEffect(1.5)
                        .opacity(0.7)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: UUID())
                }
                
                // Main status indicator
                Circle()
                    .fill(assignment.status.color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
        } else {
            Circle()
                .fill(MovefullyTheme.Colors.divider)
                .frame(width: 6, height: 6)
                .scaleEffect(isSelected ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
    }
}

// MARK: - Workout Assignment Card
struct WorkoutAssignmentCard: View {
    let assignment: WorkoutAssignment
    let isToday: Bool
    let onViewDetails: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showAllExercises = false
    
    var body: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingL) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text(assignment.title)
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text(formatDate(assignment.date))
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: assignment.status.icon)
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(assignment.status.color)
                }
                
                // Status and duration badges
                HStack(spacing: MovefullyTheme.Layout.paddingS) {
                    MovefullyStatusBadge(
                        text: assignment.status.rawValue,
                        color: assignment.status.color,
                        showDot: true
                    )
                    
                    MovefullyStatusBadge(
                        text: "\(assignment.estimatedDuration) min",
                        color: MovefullyTheme.Colors.primaryTeal,
                        showDot: false
                    )
                    
                    MovefullyStatusBadge(
                        text: "\(assignment.exercises.count) exercises",
                        color: MovefullyTheme.Colors.gentleBlue,
                        showDot: false
                    )
                    
                    Spacer()
                }
                
                // Trainer notes (if present)
                if let notes = assignment.trainerNotes, !notes.isEmpty {
                    Text(notes)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(3)
                        .padding(MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.primaryTeal.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                }
                
                // Exercise overview - compact list
                if !assignment.exercises.isEmpty {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Exercises")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        VStack(spacing: MovefullyTheme.Layout.paddingS) {
                            // Show exercises based on expanded state
                            let exercisesToShow = showAllExercises ? assignment.exercises : Array(assignment.exercises.prefix(3))
                            
                            ForEach(Array(exercisesToShow.enumerated()), id: \.element.id) { index, exercise in
                                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                                    // Exercise number
                                    Text("\(index + 1)")
                                        .font(MovefullyTheme.Typography.caption)
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(MovefullyTheme.Colors.primaryTeal)
                                        .clipShape(Circle())
                                    
                                    // Exercise name
                                    Text(exercise.title)
                                        .font(MovefullyTheme.Typography.callout)
                                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    // Sets and reps/duration
                                    HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                                        if let sets = exercise.sets {
                                            Text("\(sets) sets")
                                                .font(MovefullyTheme.Typography.caption)
                                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                        }
                                        
                                        switch exercise.exerciseType {
                                        case .reps:
                                            if let reps = exercise.reps {
                                                Text("\(reps) reps")
                                                    .font(MovefullyTheme.Typography.caption)
                                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                            }
                                        case .duration:
                                            if let duration = exercise.duration {
                                                Text("\(duration)s")
                                                    .font(MovefullyTheme.Typography.caption)
                                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                            }
                                        }
                                    }
                                }
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity.combined(with: .move(edge: .top))
                                ))
                            }
                            
                            // Show expand/collapse button if there are more than 3 exercises
                            if assignment.exercises.count > 3 {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showAllExercises.toggle()
                                    }
                                }) {
                                    HStack {
                                        Text(showAllExercises ? 
                                             "Show less" : 
                                             "+\(assignment.exercises.count - 3) more exercises"
                                        )
                                        .font(MovefullyTheme.Typography.caption)
                                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                        .italic()
                                        
                                        Image(systemName: showAllExercises ? "chevron.up" : "chevron.down")
                                            .font(MovefullyTheme.Typography.caption)
                                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                        
                                        Spacer()
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.leading, MovefullyTheme.Layout.paddingXL)
                            }
                        }
                        .padding(MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.cardBackground.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                        .overlay(
                            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                                .stroke(MovefullyTheme.Colors.primaryTeal.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                
                // Action button
                Button("View Details") {
                    onViewDetails()
                }
                .font(MovefullyTheme.Typography.buttonMedium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MovefullyTheme.Layout.paddingM)
                .background(MovefullyTheme.Colors.primaryTeal)
                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            }
        }
        .onChange(of: assignment.id) { _, _ in
            // Reset without animation when switching days
            showAllExercises = false
        }
        .animation(nil, value: assignment.id) // Disable animation for day changes
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

// MARK: - Rest Day Card
struct RestDayCard: View {
    let date: Date
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                Image(systemName: "leaf.fill")
                    .font(MovefullyTheme.Typography.largeTitle)
                    .foregroundColor(MovefullyTheme.Colors.softGreen)
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Text("Rest Day")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text(formatDate(date))
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    Text("No workout scheduled. Take time to rest and recover, or enjoy some gentle movement if you feel like it.")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                
                // Gentle suggestions
                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                    Text("Optional gentle activities:")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    HStack(spacing: MovefullyTheme.Layout.paddingM) {
                        ForEach(["🚶‍♀️ Walk", "🧘‍♀️ Stretch", "📚 Read"], id: \.self) { activity in
                            Text(activity)
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .padding(.horizontal, MovefullyTheme.Layout.paddingS)
                                .padding(.vertical, MovefullyTheme.Layout.paddingXS)
                                .background(MovefullyTheme.Colors.softGreen.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.vertical, MovefullyTheme.Layout.paddingL)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

// MARK: - Schedule No Plan Card
struct ScheduleNoPlanCard: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(MovefullyTheme.Typography.largeTitle)
                    .foregroundColor(MovefullyTheme.Colors.warmOrange)
                
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Text("No Plan Assigned")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("You don't have a workout plan assigned yet. Your trainer will create a personalized plan for you soon!")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                
                // Gentle suggestions
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Text("In the meantime, you can:")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    HStack(spacing: MovefullyTheme.Layout.paddingL) {
                        VStack(spacing: MovefullyTheme.Layout.paddingS) {
                            Text("💪")
                                .font(MovefullyTheme.Typography.title3)
                            Text("Browse\nexercises")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(spacing: MovefullyTheme.Layout.paddingS) {
                            Text("📱")
                                .font(MovefullyTheme.Typography.title3)
                            Text("Message\ntrainer")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(spacing: MovefullyTheme.Layout.paddingS) {
                            Text("🎯")
                                .font(MovefullyTheme.Typography.title3)
                            Text("Review\ngoals")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ClientScheduleView(viewModel: ClientViewModel())
} 