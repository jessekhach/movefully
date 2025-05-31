import SwiftUI

struct ClientRowView: View {
    let client: Client
    
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
                    StatusBadge(status: client.status)
                }
                
                if let email = client.email {
                    Text(email)
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                
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

// MARK: - Status Badge Component
struct StatusBadge: View {
    let status: ClientStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: 10, weight: .semibold))
            Text(status.rawValue)
                .font(MovefullyTheme.Typography.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch status.color {
        case "primaryTeal":
            return MovefullyTheme.Colors.primaryTeal
        case "success":
            return MovefullyTheme.Colors.success
        case "warning":
            return MovefullyTheme.Colors.warning
        case "textSecondary":
            return MovefullyTheme.Colors.textSecondary
        case "secondaryPeach":
            return MovefullyTheme.Colors.secondaryPeach
        default:
            return MovefullyTheme.Colors.textSecondary
        }
    }
} 