import SwiftUI

struct ClientDashboardView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome header
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hello beautiful!")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                                
                                Text(authViewModel.userName.isEmpty ? "Mover" : authViewModel.userName)
                                    .font(MovefullyTheme.Typography.title1)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showingSignOutAlert = true
                            }) {
                                Image(systemName: "person.circle")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color(.systemPink))
                            }
                        }
                        
                        Text("Ready to move mindfully today?")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Today's focus card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Focus")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Morning Movement")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Text("Gentle stretches to awaken your body")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 12))
                                        Text("15 min")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                    }
                                    .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    // Start workout
                                }) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(20)
                            .background(
                                LinearGradient(
                                    colors: [Color(.systemPink).opacity(0.8), Color(.systemPurple).opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Quick actions
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        DashboardCard(
                            title: "My Workouts",
                            subtitle: "Your personalized plans",
                            icon: "heart.circle",
                            gradientColors: [Color(.systemPink).opacity(0.7), Color(.systemRed).opacity(0.7)]
                        ) {
                            // Navigate to workouts
                        }
                        
                        DashboardCard(
                            title: "Progress",
                            subtitle: "Track your journey",
                            icon: "chart.line.uptrend.xyaxis.circle",
                            gradientColors: [Color(.systemGreen).opacity(0.7), Color(.systemMint).opacity(0.7)]
                        ) {
                            // Navigate to progress
                        }
                        
                        DashboardCard(
                            title: "Mindfulness",
                            subtitle: "Breathing & meditation",
                            icon: "leaf.circle",
                            gradientColors: [Color(.systemTeal).opacity(0.7), Color(.systemCyan).opacity(0.7)]
                        ) {
                            // Navigate to mindfulness
                        }
                        
                        DashboardCard(
                            title: "Messages",
                            subtitle: "Chat with your trainer",
                            icon: "message.circle",
                            gradientColors: [Color(.systemIndigo).opacity(0.7), Color(.systemPurple).opacity(0.7)]
                        ) {
                            // Navigate to messages
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Weekly goals
                    VStack(alignment: .leading, spacing: 16) {
                        Text("This Week's Goals")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            GoalRow(
                                icon: "checkmark.circle.fill",
                                iconColor: .green,
                                title: "Complete 3 workouts",
                                progress: 2,
                                total: 3
                            )
                            
                            GoalRow(
                                icon: "timer.circle",
                                iconColor: .orange,
                                title: "15 minutes of mindfulness",
                                progress: 1,
                                total: 5
                            )
                            
                            GoalRow(
                                icon: "drop.circle",
                                iconColor: .blue,
                                title: "Stay hydrated daily",
                                progress: 4,
                                total: 7
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical, 20)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemPink).opacity(0.03)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

struct GoalRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let progress: Int
    let total: Int
    
    var progressPercent: Double {
        guard total > 0 else { return 0 }
        return Double(progress) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("\(progress) of \(total) completed")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(progressPercent * 100))%")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(iconColor)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .frame(height: 4)
                        .clipShape(Capsule())
                    
                    Rectangle()
                        .fill(iconColor)
                        .frame(width: geometry.size.width * progressPercent, height: 4)
                        .clipShape(Capsule())
                        .animation(.easeInOut(duration: 0.5), value: progressPercent)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DashboardCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(16)
            .frame(height: 120)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 