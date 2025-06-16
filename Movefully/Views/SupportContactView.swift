import SwiftUI

struct SupportContactView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showCopiedAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                // Header
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Image(systemName: "headphones")
                        .font(.system(size: 60))
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    
                    Text("Contact Support")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("We're here to help you succeed")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, MovefullyTheme.Layout.paddingXL)
                
                // Contact Options
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Email Option
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        HStack {
                            Image(systemName: "envelope")
                                .font(.system(size: 24))
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                                Text("Email Support")
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Text("support@movefully.com")
                                    .font(MovefullyTheme.Typography.callout)
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            }
                            
                            Spacer()
                        }
                        
                        Button("Copy Email Address") {
                            UIPasteboard.general.string = "support@movefully.com"
                            showCopiedAlert = true
                        }
                        .movefullyButtonStyle(.primary)
                    }
                    .padding(MovefullyTheme.Layout.paddingL)
                    .background(MovefullyTheme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                    .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
                    
                    // Device Info
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Device Information")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            InfoRow(label: "App Version", value: "1.0")
                            InfoRow(label: "iOS Version", value: UIDevice.current.systemVersion)
                            InfoRow(label: "Device Model", value: UIDevice.current.model)
                        }
                        
                        Button("Copy Device Info") {
                            let deviceInfo = """
                            Device Information:
                            - App Version: 1.0
                            - iOS Version: \(UIDevice.current.systemVersion)
                            - Device Model: \(UIDevice.current.model)
                            """
                            UIPasteboard.general.string = deviceInfo
                            showCopiedAlert = true
                        }
                        .movefullyButtonStyle(.secondary)
                    }
                    .padding(MovefullyTheme.Layout.paddingL)
                    .background(MovefullyTheme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                }
                
                Spacer()
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
            .alert("Copied!", isPresented: $showCopiedAlert) {
                Button("OK") { }
            } message: {
                Text("Information copied to clipboard")
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
        }
    }
}

#Preview {
    SupportContactView()
} 