import SwiftUI

// MARK: - Client Schedule View
struct ClientScheduleView: View {
    @ObservedObject var viewModel: ClientViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedWeekOffset = 0
    @State private var selectedDate: Date?
    @State private var showingWorkoutDetail = false
    @State private var showingWorkoutSession = false
    @State private var showingProfile = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Week selector (back to fixed header at top)
                weekSelectorSection
                
                // Main scrollable content
                ScrollView {
                    VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                        // Week calendar
                        weekCalendarSection
                        
                        // Selected day details
                        if let selectedDate = selectedDate {
                            selectedDayDetailsSection(for: selectedDate)
                        } else {
                            todayOverviewSection
                        }
                        
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
        .sheet(isPresented: $showingWorkoutSession) {
            if let selectedDate = selectedDate,
               let assignment = getWorkoutAssignment(for: selectedDate) {
                WorkoutSessionView(assignment: assignment, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingProfile) {
            // ClientProfileView will be added when available
        }
        .onAppear {
            // Set today as initially selected
            selectedDate = Date()
        }
    }
    
    // MARK: - Week Selector Section
    private var weekSelectorSection: some View {
        HStack {
            Button(action: { selectedWeekOffset -= 1 }) {
                Image(systemName: "chevron.left")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            }
            
            Spacer()
            
            Text(weekDisplayString)
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            Spacer()
            
            Button(action: { selectedWeekOffset += 1 }) {
                Image(systemName: "chevron.right")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            }
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
                
                Button("Clear Selection") {
                    selectedDate = nil
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
                    },
                    onStartWorkout: {
                        showingWorkoutSession = true
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
        return WorkoutAssignment.sampleAssignments.first { assignment in
            Calendar.current.isDate(assignment.date, inSameDayAs: date)
        }
    }
    
    private func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: date)
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
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                // Day number
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(textColor)
                
                // Status indicator
                statusIndicator
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MovefullyTheme.Layout.paddingM)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            .overlay(
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                    .stroke(borderColor, lineWidth: isToday ? 2 : 0)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
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
            Circle()
                .fill(assignment.status.color)
                .frame(width: 8, height: 8)
        } else {
            Circle()
                .fill(MovefullyTheme.Colors.divider)
                .frame(width: 6, height: 6)
        }
    }
}

// MARK: - Workout Assignment Card
struct WorkoutAssignmentCard: View {
    let assignment: WorkoutAssignment
    let isToday: Bool
    let onViewDetails: () -> Void
    let onStartWorkout: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text(assignment.title)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text(formatDate(assignment.date))
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: assignment.status.icon)
                        .font(MovefullyTheme.Typography.title3)
                        .foregroundColor(assignment.status.color)
                }
                
                // Status and duration
                HStack {
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
                
                // Trainer notes
                if let notes = assignment.trainerNotes {
                    Text(notes)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(3)
                        .padding(MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.primaryTeal.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
                }
                
                // Action buttons
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Button("View Details") {
                        onViewDetails()
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    .background(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    
                    if isToday {
                        Button("Start Workout") {
                            onStartWorkout()
                        }
                        .font(MovefullyTheme.Typography.buttonMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.primaryTeal)
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                    }
                }
            }
        }
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

#Preview {
    ClientScheduleView(viewModel: ClientViewModel())
} 