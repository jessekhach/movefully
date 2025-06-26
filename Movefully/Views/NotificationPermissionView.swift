import SwiftUI

struct NotificationPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    let onPermissionGranted: () -> Void
    let onPermissionDenied: () -> Void
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingXL) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [MovefullyTheme.Colors.primaryTeal.opacity(0.8), MovefullyTheme.Colors.gentleBlue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Text("Stay Connected & Motivated")
                        .font(MovefullyTheme.Typography.title1)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Get helpful reminders and stay on track")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                // Benefits list
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    if authViewModel.userRole == "client" {
                        NotificationBenefitRow(
                            icon: "figure.run",
                            title: "Workout Reminders"
                        )
                        
                        NotificationBenefitRow(
                            icon: "message.fill",
                            title: "Trainer Messages"
                        )
                        
                        NotificationBenefitRow(
                            icon: "doc.text.fill",
                            title: "Plan Updates"
                        )
                    } else {
                        NotificationBenefitRow(
                            icon: "heart.circle.fill",
                            title: "Client Activity"
                        )
                        
                        NotificationBenefitRow(
                            icon: "message.fill",
                            title: "Client Messages"
                        )
                        
                        NotificationBenefitRow(
                            icon: "person.2.fill",
                            title: "New Clients"
                        )
                    }
                }
            }
            
            Spacer()
            
            // Quiet hours info
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                HStack(spacing: MovefullyTheme.Layout.paddingS) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    
                    Text("Quiet hours: 10:00 PM - 7:00 AM")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                Text("No notifications during quiet hours")
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            
            // Action buttons
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                Button("Enable Notifications") {
                    NotificationService.shared.requestNotificationPermission()
                    onPermissionGranted()
                    dismiss()
                }
                .movefullyButtonStyle(.primary)
                
                Button("Not Now") {
                    onPermissionDenied()
                    dismiss()
                }
                .movefullyButtonStyle(.tertiary)
            }
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
        .padding(.vertical, MovefullyTheme.Layout.paddingXL)
        .movefullyBackground()
    }
}

struct NotificationBenefitRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                Text(title)
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
            }
            
            Spacer()
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingM)
        .padding(.vertical, MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 2, x: 0, y: 1)
    }
}

#Preview {
    NotificationPermissionView(
        onPermissionGranted: {},
        onPermissionDenied: {}
    )
    .environmentObject(AuthenticationViewModel())
} 