import SwiftUI

// MARK: - Content Views

struct ClientManagementView: View {
    @StateObject private var viewModel = ClientManagementViewModel()
    @State private var searchText = ""
    
    var body: some View {
        MovefullyTrainerNavigation(
            title: "Clients",
            showProfileButton: false,
            trailingButton: MovefullyStandardNavigation.ToolbarButton(
                icon: "plus",
                action: { viewModel.showInviteClientSheet = true },
                accessibilityLabel: "Invite Client"
            )
        ) {
            // Search field inside navigation content
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                MovefullySearchField(
                    placeholder: "Search clients...",
                    text: $searchText
                )
            }
            .padding(.vertical, MovefullyTheme.Layout.paddingS)
            
            // Clients content
            clientsContent
        }
        .sheet(isPresented: $viewModel.showInviteClientSheet) {
            InviteClientSheet()
                .environmentObject(viewModel)
        }
    }
    
    // MARK: - Clients Content
    @ViewBuilder
    private var clientsContent: some View {
        if viewModel.isLoading {
            MovefullyLoadingState(message: "Loading clients...")
        } else if filteredClients.isEmpty {
            clientsEmptyState
        } else {
            ForEach(filteredClients, id: \.id) { client in
                NavigationLink(destination: ClientDetailView(client: client)) {
                    SimpleClientCard(client: client)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var clientsEmptyState: some View {
        MovefullyEmptyState(
            icon: searchText.isEmpty ? "person.2.circle" : "magnifyingglass",
            title: searchText.isEmpty ? "No clients yet" : "No clients found",
            description: searchText.isEmpty ? 
                "Invite your first client to get started with Movefully." : 
                "Try adjusting your search terms to find the client you're looking for.",
            actionButton: searchText.isEmpty ? 
                MovefullyEmptyState.ActionButton(
                    title: "Invite Your First Client",
                    action: { viewModel.showInviteClientSheet = true }
                ) : nil
        )
    }
    
    private var filteredClients: [Client] {
        if searchText.isEmpty {
            return viewModel.clients
        } else {
            return viewModel.clients.filter { client in
                client.name.localizedCaseInsensitiveContains(searchText) ||
                client.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Minimal Alert Banner
struct MinimalAlertBanner: View {
    let alertCount: Int
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingS) {
            Circle()
                .fill(MovefullyTheme.Colors.warmOrange)
                .frame(width: 6, height: 6)
            
            Text("\(alertCount) need\(alertCount == 1 ? "s" : "") attention")
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
            
            Spacer()
            
            Button("Review") {
                // Handle review action
            }
            .font(MovefullyTheme.Typography.caption)
            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingM)
        .padding(.vertical, MovefullyTheme.Layout.paddingS)
        .background(MovefullyTheme.Colors.warmOrange.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
    }
}

// MARK: - Simple Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(MovefullyTheme.Colors.textTertiary)
            
            TextField("Search clients...", text: $text)
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
        .padding(.vertical, MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 1, x: 0, y: 1)
    }
}

// MARK: - Clean Client List
struct ClientListView: View {
    let clients: [Client]
    
    var body: some View {
        LazyVStack(spacing: MovefullyTheme.Layout.paddingM) {
            ForEach(clients, id: \.id) { client in
                NavigationLink(destination: ClientDetailView(client: client)) {
                    SimpleClientCard(client: client)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Simple Client Card - Built from scratch
struct SimpleClientCard: View {
    let client: Client
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingL) {
            // Profile circle
            ZStack {
                Circle()
                    .fill(MovefullyTheme.Colors.primaryTeal)
                    .frame(width: 48, height: 48)
                
                Text(clientInitials)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Client info
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                HStack {
                    Text(client.name)
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    StatusIndicator(status: client.status)
                }
                
                Text(client.email)
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                
                if client.needsAttention {
                    HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                        Circle()
                            .fill(MovefullyTheme.Colors.warmOrange)
                            .frame(width: 4, height: 4)
                        
                        Text("Needs attention")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.warmOrange)
                    }
                } else {
                    Text(client.lastActivityText)
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                }
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MovefullyTheme.Colors.textTertiary)
        }
        .padding(MovefullyTheme.Layout.paddingL)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                .stroke(
                    client.needsAttention ? MovefullyTheme.Colors.warmOrange.opacity(0.2) : Color.clear,
                    lineWidth: 1
                )
        )
    }
    
    private var clientInitials: String {
        let nameComponents = client.name.components(separatedBy: " ")
        let firstInitial = nameComponents.first?.first?.uppercased() ?? ""
        let lastInitial = nameComponents.count > 1 ? nameComponents.last?.first?.uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }
}

// MARK: - Simple Status Indicator
struct StatusIndicator: View {
    let status: ClientStatus
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingXS) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(statusText)
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingS)
        .padding(.vertical, 2)
        .background(statusColor.opacity(0.1))
        .clipShape(Capsule())
    }
    
    private var statusText: String {
        switch status {
        case .active: return "Active"
        case .new: return "New"
        case .needsAttention: return "Attention"
        case .paused: return "Paused"
        case .pending: return "Pending"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .active: return MovefullyTheme.Colors.softGreen
        case .new: return MovefullyTheme.Colors.gentleBlue
        case .needsAttention: return MovefullyTheme.Colors.warmOrange
        case .paused: return MovefullyTheme.Colors.mediumGray
        case .pending: return MovefullyTheme.Colors.lavender
        }
    }
}

// MARK: - Simple Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(MovefullyTheme.Colors.primaryTeal)
            
            Text("Loading clients...")
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Simple Empty State
struct EmptyStateView: View {
    let onInvite: () -> Void
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingXL) {
            Spacer()
            
            Image(systemName: "person.2.circle")
                .font(.system(size: 60))
                .foregroundColor(MovefullyTheme.Colors.primaryTeal.opacity(0.6))
            
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                Text("No clients yet")
                    .font(MovefullyTheme.Typography.title2)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text("Start building your wellness community by inviting your first client.")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
            
            Button("Invite Your First Client") {
                onInvite()
            }
            .font(MovefullyTheme.Typography.buttonMedium)
            .foregroundColor(.white)
            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
            .padding(.vertical, MovefullyTheme.Layout.paddingL)
            .background(MovefullyTheme.Colors.primaryTeal)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
            .shadow(color: MovefullyTheme.Colors.primaryTeal.opacity(0.3), radius: 8, x: 0, y: 4)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Simple Invite Sheet
struct InviteClientSheet: View {
    @EnvironmentObject var viewModel: ClientManagementViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var clientName = ""
    @State private var clientEmail = ""
    @State private var note = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Invite Client")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Send an invitation to start their wellness journey.")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                    
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        FormField(title: "Name", text: $clientName, placeholder: "Client's full name")
                        FormField(title: "Email", text: $clientEmail, placeholder: "client@example.com")
                        
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            Text("Personal Note (Optional)")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            TextField("Add a personal message...", text: $note, axis: .vertical)
                                .font(MovefullyTheme.Typography.body)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                .lineLimit(3...6)
                                .padding(MovefullyTheme.Layout.paddingM)
                                .background(MovefullyTheme.Colors.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                        }
                    }
                    
                    Button("Send Invitation") {
                        // Send invitation logic
                        dismiss()
                    }
                    .font(MovefullyTheme.Typography.buttonMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MovefullyTheme.Layout.paddingL)
                    .background(MovefullyTheme.Colors.primaryTeal)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                    .disabled(clientName.isEmpty || clientEmail.isEmpty)
                    .opacity(clientName.isEmpty || clientEmail.isEmpty ? 0.6 : 1.0)
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXXL)
            }
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Simple Form Field
struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
            Text(title)
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            TextField(placeholder, text: $text)
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                .padding(MovefullyTheme.Layout.paddingM)
                .background(MovefullyTheme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        }
    }
} 