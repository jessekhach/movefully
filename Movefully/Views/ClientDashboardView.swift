import SwiftUI

// MARK: - Client Dashboard View
struct ClientDashboardView: View {
    @ObservedObject var viewModel: ClientViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingProfile = false
    
    var body: some View {
        MovefullyClientNavigation(
            title: "Progress",
            showProfileButton: false
        ) {
            // Welcome message
            welcomeSection
            
            // Weekly progress
            weeklyProgressSection
            
            // Monthly overview
            monthlyOverviewSection
            
            // Recent activity
            recentActivitySection
        }
        .sheet(isPresented: $showingProfile) {
            // ClientProfileView will be added when available
        }
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(spacing: 0) {
            // Add top padding to match trainer views
            Spacer()
                .frame(height: MovefullyTheme.Layout.paddingM)
            
            MovefullyCard {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                    HStack {
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            Text("Your Progress")
                                .font(MovefullyTheme.Typography.title2)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Text("Keep up the great momentum!")
                                .font(MovefullyTheme.Typography.body)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(MovefullyTheme.Typography.title1)
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal.opacity(0.7))
                    }
                    
                    // Quick completion rate
                    HStack {
                        Text("Overall completion rate:")
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Spacer()
                        
                        Text("\(Int(viewModel.progressPercentage * 100))%")
                            .font(MovefullyTheme.Typography.title3)
                            .foregroundColor(MovefullyTheme.Colors.softGreen)
                    }
                }
            }
        }
    }
    
    // MARK: - Weekly Progress Section
    private var weeklyProgressSection: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            HStack {
                Text("This Week")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                Spacer()
            }
            
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                // Workouts completed vs assigned
                MovefullyCard {
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        HStack {
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                                Text("Workouts Completed")
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Text("\(viewModel.completedAssignments) of \(viewModel.totalAssignments)")
                                    .font(MovefullyTheme.Typography.title1)
                                    .foregroundColor(MovefullyTheme.Colors.gentleBlue)
                            }
                            
                            Spacer()
                            
                            CircularProgressView(
                                progress: viewModel.progressPercentage,
                                color: MovefullyTheme.Colors.gentleBlue
                            )
                        }
                        
                        ProgressView(value: Double(viewModel.completedAssignments), total: Double(viewModel.totalAssignments))
                    }
                }
                
                // Weekly stats grid
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Completion percentage
                    MovefullyCard {
                        VStack(spacing: MovefullyTheme.Layout.paddingS) {
                            Image(systemName: "target")
                                .font(MovefullyTheme.Typography.title2)
                                .foregroundColor(MovefullyTheme.Colors.softGreen)
                            
                            Text("\(Int(viewModel.progressPercentage * 100))%")
                                .font(MovefullyTheme.Typography.title2)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Text("On Track")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1.1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Consistency
                    MovefullyCard {
                        VStack(spacing: MovefullyTheme.Layout.paddingS) {
                            Image(systemName: "flame.fill")
                                .font(MovefullyTheme.Typography.title2)
                                .foregroundColor(MovefullyTheme.Colors.warmOrange)
                            
                            Text("\(viewModel.currentStreak)")
                                .font(MovefullyTheme.Typography.title2)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Text("Days Active")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1.1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
    
    // MARK: - Monthly Overview Section
    private var monthlyOverviewSection: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            HStack {
                Text("This Month")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                Spacer()
            }
            
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                // Monthly completion card
                MovefullyCard {
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        HStack {
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                                Text("Monthly Progress")
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Text("\(viewModel.completedAssignments) of \(viewModel.totalAssignments)")
                                    .font(MovefullyTheme.Typography.title1)
                                    .foregroundColor(MovefullyTheme.Colors.gentleBlue)
                            }
                            
                            Spacer()
                            
                            CircularProgressView(
                                progress: viewModel.progressPercentage,
                                color: MovefullyTheme.Colors.gentleBlue
                            )
                        }
                        
                        ProgressView(value: Double(viewModel.completedAssignments), total: Double(viewModel.totalAssignments))
                            .tint(MovefullyTheme.Colors.gentleBlue)
                            .scaleEffect(y: 2)
                    }
                }
                
                // Monthly stats
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Total workouts
                    MovefullyCard {
                        VStack(spacing: MovefullyTheme.Layout.paddingS) {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(MovefullyTheme.Typography.title2)
                                .foregroundColor(MovefullyTheme.Colors.gentleBlue)
                            
                            Text("\(viewModel.currentClient.totalWorkoutsCompleted) this month")
                                .font(MovefullyTheme.Typography.callout)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Average per week
                    MovefullyCard {
                        VStack(spacing: MovefullyTheme.Layout.paddingS) {
                            Image(systemName: "chart.bar.fill")
                                .font(MovefullyTheme.Typography.title2)
                                .foregroundColor(MovefullyTheme.Colors.lavender)
                            
                            Text("\(viewModel.completedAssignments)")
                                .font(MovefullyTheme.Typography.title2)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Text("Per Week")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1.1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            HStack {
                Text("Recent Activity")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                Spacer()
            }
            
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                ForEach(WorkoutAssignment.sampleAssignments.prefix(3)) { assignment in
                    RecentActivityCard(assignment: assignment)
                }
            }
        }
    }
}

// MARK: - Circular Progress View Component
struct CircularProgressView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat = 8
    let size: CGFloat = 60
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [color, color.opacity(0.8)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Recent Activity Card Component
struct RecentActivityCard: View {
    let assignment: WorkoutAssignment
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        MovefullyCard {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                // Status indicator
                VStack {
                    Image(systemName: assignment.status.icon)
                        .font(MovefullyTheme.Typography.title3)
                        .foregroundColor(assignment.status.color)
                        .frame(width: 40, height: 40)
                        .background(assignment.status.color.opacity(0.1))
                        .clipShape(Circle())
                    
                    Spacer()
                }
                
                // Workout details
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                    Text(assignment.title)
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text(formatDate(assignment.date))
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    HStack {
                        MovefullyStatusBadge(
                            text: assignment.status.rawValue,
                            color: assignment.status.color,
                            showDot: false
                        )
                        
                        Spacer()
                        
                        Text("\(assignment.estimatedDuration) min")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    ClientDashboardView(viewModel: ClientViewModel())
} 