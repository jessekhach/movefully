import SwiftUI

struct ClientRowView: View {
    let client: Client
    @ObservedObject private var smartAlertService = SmartAlertService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            // Profile initials circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            MovefullyTheme.Colors.primaryTeal,
                            MovefullyTheme.Colors.secondaryPeach
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay(
                    Text(initials)
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
            
            // Client info
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                HStack {
                    Text(client.name)
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    // Status badge
                    ClientStatusBadge(status: client.status)
                }
                
                Text(client.email)
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .lineLimit(1)
                
                // Last activity
                HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                    if client.needsAttention {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(MovefullyTheme.Colors.warning)
                    } else {
                        Circle()
                            .fill(client.status == .active ? MovefullyTheme.Colors.success : MovefullyTheme.Colors.textSecondary)
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(client.lastActivityText)
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
            
            // Navigation indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(MovefullyTheme.Colors.inactive)
        }
        .padding(MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                .stroke(
                    client.needsAttention ? MovefullyTheme.Colors.warning.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
    }
    
    private var initials: String {
        let components = client.name.components(separatedBy: " ")
        let firstInitial = components.first?.first?.uppercased() ?? ""
        let lastInitial = components.count > 1 ? (components.last?.first?.uppercased() ?? "") : ""
        return firstInitial + lastInitial
    }
}

// MARK: - Status Badge for Client
struct ClientStatusBadge: View {
    let status: ClientStatus
    
    var body: some View {
        MovefullyStatusBadge(
            text: statusText,
            color: statusColor,
            showDot: true
        )
    }
    
    private var statusText: String {
        switch status {
        case .active:
            return "Active"
        case .needsAttention:
            return "Alert"
        case .paused:
            return "Paused"
        case .pending:
            return "Pending"
        case .trainer_removed:
            return "Removed"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .active:
            return MovefullyTheme.Colors.softGreen
        case .needsAttention:
            return MovefullyTheme.Colors.warmOrange
        case .paused:
            return MovefullyTheme.Colors.mediumGray
        case .pending:
            return MovefullyTheme.Colors.lavender
        case .trainer_removed:
            return MovefullyTheme.Colors.warning
        }
    }
} 