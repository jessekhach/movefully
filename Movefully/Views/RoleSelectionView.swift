import SwiftUI

struct RoleSelectionView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedRole: String? = nil
    @State private var showConfirmation = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Spacer()
                    
                    Text("Welcome to Movefully!")
                        .font(.system(size: 32, weight: .light, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("How would you like to use the app?")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .frame(height: geometry.size.height * 0.3)
                
                // Role selection cards
                VStack(spacing: 24) {
                    RoleCard(
                        title: "I'm a Trainer",
                        subtitle: "Help clients achieve their movement goals",
                        icon: "figure.strengthtraining.traditional",
                        gradientColors: [Color(.systemBlue).opacity(0.7), Color(.systemTeal).opacity(0.7)],
                        isSelected: selectedRole == "trainer"
                    ) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            selectedRole = "trainer"
                        }
                    }
                    
                    RoleCard(
                        title: "I'm here to move!",
                        subtitle: "Get guidance and support on your wellness journey",
                        icon: "heart.circle",
                        gradientColors: [Color(.systemPink).opacity(0.7), Color(.systemPurple).opacity(0.7)],
                        isSelected: selectedRole == "client"
                    ) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            selectedRole = "client"
                        }
                    }
                    
                    // Continue button
                    if selectedRole != nil {
                        Button(action: {
                            if let role = selectedRole {
                                authViewModel.selectRole(role)
                            }
                        }) {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Continue")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: selectedRole == "trainer" 
                                        ? [Color(.systemBlue).opacity(0.8), Color(.systemTeal).opacity(0.8)]
                                        : [Color(.systemPink).opacity(0.8), Color(.systemPurple).opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(authViewModel.isLoading)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.top, 8)
                    }
                    
                    // Error message
                    if !authViewModel.errorMessage.isEmpty {
                        Text(authViewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    selectedRole == "trainer" 
                        ? Color(.systemTeal).opacity(0.05)
                        : Color(.systemPink).opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct RoleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(
                color: isSelected ? gradientColors.first?.opacity(0.3) ?? .clear : .clear,
                radius: isSelected ? 15 : 0,
                x: 0,
                y: isSelected ? 5 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 