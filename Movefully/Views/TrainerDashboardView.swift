import SwiftUI

struct TrainerDashboardView: View {
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
                                Text("Welcome back!")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                                
                                Text(authViewModel.userName.isEmpty ? "Trainer" : authViewModel.userName)
                                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showingSignOutAlert = true
                            }) {
                                Image(systemName: "person.circle")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color(.systemBlue))
                            }
                        }
                        
                        Text("Ready to guide your clients today?")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Quick actions
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        DashboardCard(
                            title: "My Clients",
                            subtitle: "View and manage clients",
                            icon: "person.2",
                            gradientColors: [Color(.systemBlue).opacity(0.7), Color(.systemTeal).opacity(0.7)]
                        ) {
                            // Navigate to clients list
                        }
                        
                        DashboardCard(
                            title: "Programs",
                            subtitle: "Create workout plans",
                            icon: "list.clipboard",
                            gradientColors: [Color(.systemGreen).opacity(0.7), Color(.systemMint).opacity(0.7)]
                        ) {
                            // Navigate to programs
                        }
                        
                        DashboardCard(
                            title: "Exercises",
                            subtitle: "Manage exercise library",
                            icon: "figure.strengthtraining.traditional",
                            gradientColors: [Color(.systemOrange).opacity(0.7), Color(.systemYellow).opacity(0.7)]
                        ) {
                            // Navigate to exercises
                        }
                        
                        DashboardCard(
                            title: "Messages",
                            subtitle: "Client communication",
                            icon: "message",
                            gradientColors: [Color(.systemPink).opacity(0.7), Color(.systemPurple).opacity(0.7)]
                        ) {
                            // Navigate to messages
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Recent activity section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Activity")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            ActivityRow(
                                icon: "checkmark.circle.fill",
                                iconColor: .green,
                                title: "New client joined",
                                subtitle: "Welcome your newest team member",
                                timestamp: "2 hours ago"
                            )
                            
                            ActivityRow(
                                icon: "message.fill",
                                iconColor: .blue,
                                title: "3 new messages",
                                subtitle: "From your active clients",
                                timestamp: "4 hours ago"
                            )
                            
                            ActivityRow(
                                icon: "chart.line.uptrend.xyaxis",
                                iconColor: .purple,
                                title: "Progress update",
                                subtitle: "Client completed workout plan",
                                timestamp: "1 day ago"
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
                        Color(.systemBlue).opacity(0.03)
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

struct DashboardCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let timestamp: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(timestamp)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
} 