import SwiftUI

struct FeatureHighlightsView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @State private var animateContent = false
    
    private var features: [FeatureHighlight] {
        guard let path = coordinator.selectedPath else { return [] }
        
        switch path {
        case .trainer:
            return [
                FeatureHighlight(
                    icon: "figure.2.and.child.holdinghands",
                    title: "Grow Your Practice",
                    description: "Grow your client base and build your practice.",
                    gradient: [MovefullyTheme.Colors.softGreen, MovefullyTheme.Colors.primaryTeal]
                ),
                FeatureHighlight(
                    icon: "doc.text.below.ecg",
                    title: "Professional Tools",
                    description: "Easily manage clients and create programs.",
                    gradient: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.gentleBlue]
                ),
                FeatureHighlight(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Build Relationships",
                    description: "Build lasting connections with your clients.",
                    gradient: [MovefullyTheme.Colors.gentleBlue, MovefullyTheme.Colors.lavender]
                )
            ]
        case .client:
            return [
                FeatureHighlight(
                    icon: "heart.circle.fill",
                    title: "Your Wellness Journey",
                    description: "Get personalized guidance from your coach.",
                    gradient: [MovefullyTheme.Colors.softGreen, MovefullyTheme.Colors.primaryTeal]
                ),
                FeatureHighlight(
                    icon: "figure.yoga",
                    title: "Gentle Movement",
                    description: "Discover movement that feels good for you.",
                    gradient: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.gentleBlue]
                ),
                FeatureHighlight(
                    icon: "person.2.circle.fill",
                    title: "Supportive Community",
                    description: "Connect with your coach for ongoing support.",
                    gradient: [MovefullyTheme.Colors.gentleBlue, MovefullyTheme.Colors.lavender]
                )
            ]
        }
    }
    
    var body: some View {
        MovefullyStandardNavigation(
            title: "Features",
            leadingButton: MovefullyStandardNavigation.ToolbarButton(
                icon: "chevron.left",
                action: { coordinator.previousStep() },
                accessibilityLabel: "Back"
            ),
            titleDisplayMode: .inline
        ) {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Text(coordinator.selectedPath == .trainer ? "Welcome, Wellness Coach" : "Welcome to Your Journey")
                            .font(MovefullyTheme.Typography.title1)
                            .fontWeight(.bold)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text(coordinator.selectedPath == .trainer ? "Everything you need to grow your coaching business" : "Discover gentle movement that works for you")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingXL)
                    .padding(.bottom, MovefullyTheme.Layout.paddingXXL)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
                    
                    // Feature Cards
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                            featureCard(feature)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(y: animateContent ? 0 : 20)
                                .animation(.easeOut(duration: 0.6).delay(0.4 + Double(index) * 0.1), value: animateContent)
                        }
                    }
                }
            }
            .movefullyBackground()
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: {
                        coordinator.nextStep()
                    }) {
                        HStack(spacing: MovefullyTheme.Layout.paddingM) {
                            Text("Continue")
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    .buttonStyle(MovefullyPrimaryButtonStyle())
                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                }
            }
            .onAppear {
                if !animateContent {
                    animateContent = true
                }
            }
        }
    }

    private func featureCard(_ feature: FeatureHighlight) -> some View {
        HStack(spacing: MovefullyTheme.Layout.paddingL) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: feature.gradient.map { $0.opacity(0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(feature.gradient.first ?? MovefullyTheme.Colors.primaryTeal)
            }
            
            // Content
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                Text(feature.title)
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text(feature.description)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(MovefullyTheme.Layout.paddingL)
        .background(MovefullyTheme.Colors.cardBackground)
        .cornerRadius(MovefullyTheme.Layout.cornerRadiusL)
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 8, x: 0, y: 4)
    }
}

struct FeatureHighlight {
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
}

#Preview {
    FeatureHighlightsView()
        .environmentObject({
            let coordinator = OnboardingCoordinator()
            coordinator.selectedPath = .trainer
            return coordinator
        }())
} 