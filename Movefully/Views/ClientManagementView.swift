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
            // Search field - only show when there are clients to search
            if !viewModel.clients.isEmpty {
                MovefullySearchField(
                    placeholder: "Search clients...",
                    text: $searchText
                )
            }
            
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

// MARK: - Redesigned Invite Sheet
struct InviteClientSheet: View {
    @EnvironmentObject var viewModel: ClientManagementViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var clientName = ""
    @State private var clientEmail = ""
    @State private var clientPhone = ""
    @State private var note = ""
    @State private var showingCopyConfirmation = false
    @State private var showingLinkView = false
    
    private var isFormValid: Bool {
        !clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            if showingLinkView && !viewModel.generatedInviteLink.isEmpty {
                // Link Generated View
                linkGeneratedView
            } else {
                // Form Input View
                formInputView
            }
        }
        .alert("Link Copied!", isPresented: $showingCopyConfirmation) {
            Button("OK") { }
        } message: {
            Text("The invitation link has been copied to your clipboard.")
        }
        .onChange(of: viewModel.showInviteClientSheet) { newValue in
            if !newValue {
                // Reset form when sheet is dismissed
                clientName = ""
                clientEmail = ""
                clientPhone = ""
                note = ""
                showingLinkView = false
                viewModel.errorMessage = ""
                viewModel.generatedInviteLink = ""
            }
        }
    }
    
    // MARK: - Form Input View
    private var formInputView: some View {
        ScrollView {
            VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Text("Invite Client")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("Create a personalized invitation link for your client")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, MovefullyTheme.Layout.paddingL)
                
                // Show error message if present
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .padding(MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.textSecondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
                }
                
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    FormField(title: "Name", text: $clientName, placeholder: "Client's full name", isRequired: true)
                    FormField(title: "Email", text: $clientEmail, placeholder: "client@example.com", isRequired: false)
                    FormField(title: "Phone", text: $clientPhone, placeholder: "(555) 123-4567", isRequired: false)
                    
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
                
                Button {
                    Task {
                        await viewModel.createInviteLink(
                            clientName: clientName.trimmingCharacters(in: .whitespacesAndNewlines),
                            clientEmail: clientEmail.trimmingCharacters(in: .whitespacesAndNewlines),
                            personalNote: note
                        )
                        if !viewModel.generatedInviteLink.isEmpty {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingLinkView = true
                            }
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.9)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "link")
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        Text(viewModel.isLoading ? "Creating Link..." : "Create Invite Link")
                            .font(MovefullyTheme.Typography.buttonMedium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MovefullyTheme.Layout.paddingL)
                    .background(MovefullyTheme.Colors.primaryTeal)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                }
                .disabled(!isFormValid || viewModel.isLoading)
                .opacity(!isFormValid || viewModel.isLoading ? 0.6 : 1.0)
                
                Spacer()
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
            .padding(.bottom, MovefullyTheme.Layout.paddingXXL)
        }
        .background(MovefullyTheme.Colors.backgroundPrimary)
        .navigationTitle("Invite Client")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
        }
    }
    
    // MARK: - Link Generated View
    private var linkGeneratedView: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingXL) {
            Spacer()
            
            // Success Icon and Message
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                ZStack {
                    Circle()
                        .fill(MovefullyTheme.Colors.success.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.success)
                }
                
                VStack(spacing: MovefullyTheme.Layout.paddingS) {
                    Text("Invitation Link Created!")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("Share this link with \(clientName)")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Link Display
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                HStack {
                    Text(viewModel.generatedInviteLink)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                    
                    Spacer()
                }
                .padding(MovefullyTheme.Layout.paddingL)
                .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                .overlay(
                    RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                        .stroke(MovefullyTheme.Colors.primaryTeal.opacity(0.3), lineWidth: 1)
                )
                
                // Action Buttons
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    // Copy Button
                    Button {
                        UIPasteboard.general.string = viewModel.generatedInviteLink
                        showingCopyConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 16, weight: .medium))
                            Text("Copy")
                        }
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                        .overlay(
                            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                                .stroke(MovefullyTheme.Colors.primaryTeal, lineWidth: 1)
                        )
                    }
                    
                    // Share Button
                    ShareLink(
                        item: viewModel.generatedInviteLink,
                        subject: Text("Movefully Invitation"),
                        message: Text("Hi \(clientName)! I've created your personalized Movefully invitation. Click the link below to get started with your wellness journey.")
                    ) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .medium))
                            Text("Share")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.primaryTeal)
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                    }
                }
            }
            
            // Expiration Notice
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
                
                Text("Link expires in 7 days")
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingM)
            .padding(.vertical, MovefullyTheme.Layout.paddingS)
            .background(MovefullyTheme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            
            Spacer()
            
            // Done Button
            Button("Done") {
                dismiss()
            }
            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, MovefullyTheme.Layout.paddingM)
            .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
            .overlay(
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                    .stroke(MovefullyTheme.Colors.primaryTeal, lineWidth: 1)
            )
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
        .background(MovefullyTheme.Colors.backgroundPrimary)
        .navigationTitle("Invitation Ready")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            }
        }
    }
}

// MARK: - Simple Form Field
struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let isRequired: Bool
    
    init(title: String, text: Binding<String>, placeholder: String, isRequired: Bool = false) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.isRequired = isRequired
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
            HStack {
                Text(title)
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                if !isRequired {
                    Text("(Optional)")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                }
                
                Spacer()
            }
            
            TextField(placeholder, text: $text)
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                .padding(MovefullyTheme.Layout.paddingM)
                .background(MovefullyTheme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                .keyboardType(title == "Phone" ? .phonePad : (title == "Email" ? .emailAddress : .default))
                .autocapitalization(title == "Email" ? .none : .words)
        }
    }
} 