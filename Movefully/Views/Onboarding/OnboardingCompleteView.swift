import SwiftUI

struct OnboardingCompleteView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @State private var animateContent = false
    @State private var showCheckmark = false
    
    var body: some View {
        // Using a NavigationView to host the toolbar
        NavigationView {
            VStack {
                Spacer()
                
                // Main content
                VStack(spacing: MovefullyTheme.Layout.paddingXXL) {
                    // Animated checkmark
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [MovefullyTheme.Colors.softGreen, MovefullyTheme.Colors.primaryTeal],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: MovefullyTheme.Colors.softGreen.opacity(0.4), radius: 20, x: 0, y: 10)
                            .scaleEffect(showCheckmark ? 1.0 : 0.8)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.white)
                            .scaleEffect(showCheckmark ? 1.0 : 0.5)
                    }
                    .opacity(showCheckmark ? 1.0 : 0.0)
                    
                    // Welcome message
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Text(coordinator.selectedPath == .trainer ? "Your coaching profile is ready!" : "Welcome to your wellness journey!")
                            .font(MovefullyTheme.Typography.title1)
                            .fontWeight(.bold)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text(coordinator.selectedPath == .trainer ?
                             "Start inviting clients and building your practice." :
                             "Your trainer is excited to support your wellness goals.")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .opacity(animateContent ? 1.0 : 0.0)
                
                Spacer()
                Spacer()
            }
            .movefullyBackground()
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: {
                        coordinator.completeOnboarding()
                    }) {
                        HStack(spacing: MovefullyTheme.Layout.paddingM) {
                            Text("Get Started")
                            Image(systemName: "arrow.right")
                                .font(MovefullyTheme.Typography.buttonSmall)
                        }
                    }
                    .buttonStyle(MovefullyPrimaryButtonStyle())
                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.3)) {
                    showCheckmark = true
                }
                
                withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                    animateContent = true
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
} 