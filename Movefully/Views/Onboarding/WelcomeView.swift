import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @EnvironmentObject var urlHandler: URLHandlingService
    @State private var animateContent = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Top section - Logo and welcome message
                VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                    // Icon with enhanced visual treatment
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [MovefullyTheme.Colors.primaryTeal.opacity(0.15), MovefullyTheme.Colors.gentleBlue.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.gentleBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateContent)
                    
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Welcome to Movefully")
                            .font(MovefullyTheme.Typography.title1)
                            .fontWeight(.bold)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("The trainer-focused wellness platform")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.top, MovefullyTheme.Layout.paddingXL) // Use fixed padding instead of relative
                    
                // Flexible spacer to push content up but allow for cards
                Spacer()
                    .frame(minHeight: MovefullyTheme.Layout.paddingXXL, maxHeight: 80) // Flexible spacer
                
                // Path selection cards
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    pathSelectionButton(
                        title: "I'm a Wellness Coach",
                        subtitle: "Grow your practice",
                        icon: "figure.mind.and.body",
                        color: MovefullyTheme.Colors.primaryTeal
                    ) {
                        coordinator.selectTrainerPath()
                    }
                    
                    pathSelectionButton(
                        title: "I have an invitation",
                        subtitle: "Join your coach's program",
                        icon: "envelope.circle",
                        color: MovefullyTheme.Colors.gentleBlue
                    ) {
                        coordinator.selectClientPath()
                    }
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
            }
        }
        .movefullyBackground()
        .toolbar {
            // Toolbar group for the bottom bar
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: {
                    coordinator.skipToAuthentication()
                }) {
                    Text("Already have an account? **Sign In**")
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, MovefullyTheme.Layout.paddingS)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            animateContent = true
        }
    }

    private func pathSelectionButton(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: MovefullyTheme.Layout.paddingL) {
                // Icon background
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text(title)
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
            }
            .padding(MovefullyTheme.Layout.paddingL)
            .frame(maxWidth: .infinity)
            .background(MovefullyTheme.Colors.cardBackground)
            .cornerRadius(MovefullyTheme.Layout.cornerRadiusL)
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 