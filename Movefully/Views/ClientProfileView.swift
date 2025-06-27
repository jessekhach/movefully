import SwiftUI
import FirebaseAuth
import PhotosUI
#if canImport(MessageUI)
import MessageUI
#endif

struct ClientProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @ObservedObject var viewModel: ClientViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showSignOutAlert = false
    @State private var showEditProfile = false
    @State private var showNotificationSettings = false
    @State private var showAbout = false
    @State private var isEditing = false
    @State private var showingSettings = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    
    // Delete account states
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteAccountConfirmation = false
    @State private var deleteConfirmationText = ""
    @StateObject private var deletionService = ClientDeletionService()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with gradient background
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        // Profile photo and basic info
                        VStack(spacing: MovefullyTheme.Layout.paddingM) {
                            // Profile image with photo picker
                            ZStack {
                                Circle()
                                    .fill(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                
                                if let profileImageUrl = viewModel.currentClient?.profileImageUrl, !profileImageUrl.isEmpty {
                                    AsyncImage(url: URL(string: profileImageUrl)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                    } placeholder: {
                                        if isUploadingPhoto {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .tint(MovefullyTheme.Colors.primaryTeal)
                                        } else {
                                            Image(systemName: "person.crop.circle.fill")
                                                .font(.system(size: 60))
                                                .foregroundColor(MovefullyTheme.Colors.primaryTeal.opacity(0.7))
                                        }
                                    }
                                } else {
                                    if isUploadingPhoto {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(MovefullyTheme.Colors.primaryTeal)
                                    } else {
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(MovefullyTheme.Colors.primaryTeal.opacity(0.7))
                                    }
                                }
                                
                                // Camera button overlay
                                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(MovefullyTheme.Colors.primaryTeal)
                                        .clipShape(Circle())
                                        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
                                }
                                .offset(x: 35, y: 35)
                                .disabled(isUploadingPhoto)
                            }
                            .shadow(color: MovefullyTheme.Colors.primaryTeal.opacity(0.2), radius: 10, x: 0, y: 5)
                            
                            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                                Text(viewModel.currentClient?.name ?? "Client")
                                    .font(MovefullyTheme.Typography.title2)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                    .fontWeight(.semibold)
                                
                                Text(userEmail)
                                    .font(MovefullyTheme.Typography.body)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            }
                        }
                        
                        // Quick stats
                        HStack(spacing: MovefullyTheme.Layout.paddingL) {
                            ClientProfileStatView(
                                title: "Workouts",
                                value: "\(viewModel.completedAssignments)",
                                subtitle: "this week",
                                icon: "figure.run"
                            )
                            
                            Divider()
                                .frame(height: 40)
                                .background(MovefullyTheme.Colors.textTertiary.opacity(0.3))
                            
                            ClientProfileStatView(
                                title: "Streak",
                                value: "\(viewModel.currentStreak)",
                                subtitle: "days",
                                icon: "flame.fill"
                            )
                            
                            Divider()
                                .frame(height: 40)
                                .background(MovefullyTheme.Colors.textTertiary.opacity(0.3))
                            
                            ClientProfileStatView(
                                title: "Progress",
                                value: "\(Int(viewModel.progressPercentage * 100))%",
                                subtitle: "this week",
                                icon: "chart.line.uptrend.xyaxis"
                            )
                        }
                        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                        .padding(.vertical, MovefullyTheme.Layout.paddingM)
                        .background(MovefullyTheme.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                    .padding(.vertical, MovefullyTheme.Layout.paddingL)
                    .background(
                        LinearGradient(
                            colors: [
                                MovefullyTheme.Colors.primaryTeal.opacity(0.05),
                                MovefullyTheme.Colors.backgroundPrimary
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Profile sections
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        // Goals section
                        ClientProfileSectionCard(title: "My Goals", icon: "target") {
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                                if let goals = viewModel.currentClient?.goals {
                                    Text(goals)
                                        .font(MovefullyTheme.Typography.body)
                                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                } else {
                                    Text("Set your wellness goals to help your trainer create the perfect plan for you.")
                                        .font(MovefullyTheme.Typography.body)
                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                        .italic()
                                }
                            }
                        }
                        
                        // Health info section
                        ClientProfileSectionCard(title: "Health Information", icon: "heart.text.square") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                if let height = viewModel.currentClient?.height, let weight = viewModel.currentClient?.weight {
                                    HStack {
                                        ClientProfileInfoItem(label: "Height", value: height)
                                        Spacer()
                                        ClientProfileInfoItem(label: "Weight", value: weight)
                                    }
                                }
                                
                                if let injuries = viewModel.currentClient?.injuries {
                                    ClientProfileInfoItem(label: "Notes/Injuries", value: injuries, fullWidth: true)
                                }
                                
                                if let coachingStyle = viewModel.currentClient?.preferredCoachingStyle {
                                    ClientProfileInfoItem(label: "Preferred Style", value: coachingStyle.rawValue, fullWidth: true)
                                }
                            }
                        }
                        
                        // Quick actions
                        ClientProfileSectionCard(title: "Account", icon: "gearshape") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                ClientProfileActionRow(title: "Edit Profile", icon: "person.crop.circle", action: { isEditing = true })
                                ClientProfileActionRow(title: "Notifications", icon: "bell", action: { showNotificationSettings = true })
                                ClientProfileActionRow(title: "Settings & Privacy", icon: "lock.shield", action: { showingSettings = true })
                                ClientProfileActionRow(title: "Help & Support", icon: "questionmark.circle", action: { showAbout = true })
                                
                                // Danger zone separator
                                Divider()
                                    .background(MovefullyTheme.Colors.divider)
                                
                                ClientProfileActionRow(title: "Sign Out", icon: "rectangle.portrait.and.arrow.right", isDanger: true, action: { showSignOutAlert = true })
                                ClientProfileActionRow(title: "Delete Account", icon: "trash", isDanger: true, action: { showDeleteAccountAlert = true })
                            }
                        }
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                    .padding(.vertical, MovefullyTheme.Layout.paddingL)
                }
            }
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
            .movefullyNavigationThemed()
        }
        .sheet(isPresented: $isEditing) {
            ClientEditProfileView(viewModel: viewModel)
        }
        .sheet(isPresented: $showNotificationSettings) {
            ClientNotificationSettingsView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingSettings) {
            ClientSettingsView()
        }
        .sheet(isPresented: $showAbout) {
            ClientHelpSupportView()
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("I Understand", role: .destructive) {
                showDeleteAccountConfirmation = true
            }
        } message: {
            Text("⚠️ WARNING: This action is permanent and cannot be undone.\n\nDeleting your account will:\n• Remove all your workout history\n• Delete all progress data\n• Remove all conversations with your trainer\n• Permanently delete your account\n\nAre you absolutely sure?")
        }
        .sheet(isPresented: $showDeleteAccountConfirmation) {
            DeleteAccountConfirmationView(
                deletionService: deletionService,
                onCancel: { showDeleteAccountConfirmation = false },
                onComplete: { 
                    authViewModel.signOut()
                    showDeleteAccountConfirmation = false
                }
            )
        }
        .onChange(of: selectedPhoto) { newPhoto in
            if let newPhoto = newPhoto {
                uploadProfilePhoto(newPhoto)
            }
        }
    }
    
    private var userEmail: String {
        return authViewModel.userEmail
    }
    
    private func uploadProfilePhoto(_ photo: PhotosPickerItem) {
        isUploadingPhoto = true
        
        Task {
            do {
                // Load the image data
                guard let imageData = try await photo.loadTransferable(type: Data.self) else {
                    await MainActor.run {
                        isUploadingPhoto = false
                    }
                    return
                }
                
                // Upload to Firebase Storage and update client profile
                try await viewModel.uploadProfilePhoto(imageData)
                
                await MainActor.run {
                    isUploadingPhoto = false
                    selectedPhoto = nil
                }
            } catch {
                await MainActor.run {
                    isUploadingPhoto = false
                    selectedPhoto = nil
                    print("❌ Failed to upload profile photo: \(error)")
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ClientProfileStatView: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingS) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            
            Text(value)
                .font(MovefullyTheme.Typography.title3)
                .fontWeight(.semibold)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                
                Text(subtitle)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct ClientProfileSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    @ObservedObject private var themeManager = ThemeManager.shared
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                
                Text(title)
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            content
        }
        .padding(MovefullyTheme.Layout.paddingL)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 8, x: 0, y: 4)
    }
}

struct ClientProfileInfoItem: View {
    let label: String
    let value: String
    var fullWidth: Bool = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: fullWidth ? .leading : .center, spacing: MovefullyTheme.Layout.paddingXS) {
            Text(label)
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
            
            Text(value)
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                .multilineTextAlignment(fullWidth ? .leading : .center)
        }
        .frame(maxWidth: fullWidth ? .infinity : nil, alignment: fullWidth ? .leading : .center)
    }
}

struct ClientProfileActionRow: View {
    let title: String
    let icon: String
    var isDanger: Bool = false
    let action: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDanger ? MovefullyTheme.Colors.warmOrange : MovefullyTheme.Colors.primaryTeal)
                    .frame(width: 20)
                
                Text(title)
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(isDanger ? MovefullyTheme.Colors.warmOrange : MovefullyTheme.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            .padding(.vertical, MovefullyTheme.Layout.paddingS)
            .padding(.horizontal, MovefullyTheme.Layout.paddingM)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Profile View

struct ClientEditProfileView: View {
    @ObservedObject var viewModel: ClientViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var email: String
    @State private var goals: String
    @State private var height: String
    @State private var weight: String
    @State private var injuries: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    init(viewModel: ClientViewModel) {
        self.viewModel = viewModel
        _name = State(initialValue: viewModel.currentClient?.name ?? "")
        // Pre-fill email with authenticated user's email from Firebase Auth
        _email = State(initialValue: Auth.auth().currentUser?.email ?? viewModel.currentClient?.email ?? "")
        _goals = State(initialValue: viewModel.currentClient?.goals ?? "")
        _height = State(initialValue: viewModel.currentClient?.height ?? "")
        _weight = State(initialValue: viewModel.currentClient?.weight ?? "")
        _injuries = State(initialValue: viewModel.currentClient?.injuries ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Header
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Edit Profile")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Update your information to help your trainer personalize your wellness journey")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                    
                    // Form sections
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        // Personal Information
                        ClientEditSection(title: "Personal Information") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                MovefullyFormField(title: "Full Name") {
                                    MovefullyTextField(
                                        placeholder: "Enter your full name",
                                        text: $name
                                    )
                                }
                                
                                MovefullyFormField(title: "Email Address") {
                                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                                        Text(email)
                                            .font(MovefullyTheme.Typography.body)
                                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                            .padding(MovefullyTheme.Layout.paddingM)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(MovefullyTheme.Colors.backgroundSecondary)
                                            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                                        
                                        Text("Email address cannot be changed from this view")
                                            .font(MovefullyTheme.Typography.caption)
                                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                    }
                                }
                            }
                        }
                        
                        // Goals
                        ClientEditSection(title: "Wellness Goals") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                MovefullyFormField(title: "Goals") {
                                    MovefullyTextEditor(
                                        placeholder: "Describe your wellness and fitness goals...",
                                        text: $goals
                                    )
                                }
                            }
                        }
                        
                        // Health info
                        ClientEditSection(title: "Health Information") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                                    MovefullyFormField(title: "Height") {
                                        MovefullyTextField(
                                            placeholder: "5'8\"",
                                            text: $height
                                        )
                                    }
                                    
                                    MovefullyFormField(title: "Weight") {
                                        MovefullyTextField(
                                            placeholder: "150 lbs",
                                            text: $weight
                                        )
                                    }
                                }
                                
                                MovefullyFormField(title: "Injuries/Medical Notes") {
                                    MovefullyTextEditor(
                                        placeholder: "Any injuries, medical conditions, or limitations...",
                                        text: $injuries
                                    )
                                }
                            }
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .movefullyButtonStyle(.tertiary)
                        
                        Button("Save Changes") {
                            saveProfileChanges()
                        }
                        .movefullyButtonStyle(.primary)
                        .disabled(isLoading)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXL)
            }
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { 
                        saveProfileChanges()
                    }
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    .disabled(isLoading)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An error occurred while saving your profile.")
        }
    }
    
    private func saveProfileChanges() {
        // Validate required fields
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Name is required"
            showingError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // Update the client data (email is not updated as it's managed by Firebase Auth)
                var updatedClient = viewModel.currentClient
                updatedClient?.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                // Note: Email is not updated here as it's managed by Firebase Authentication
                updatedClient?.goals = goals.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : goals.trimmingCharacters(in: .whitespacesAndNewlines)
                updatedClient?.height = height.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : height.trimmingCharacters(in: .whitespacesAndNewlines)
                updatedClient?.weight = weight.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : weight.trimmingCharacters(in: .whitespacesAndNewlines)
                updatedClient?.injuries = injuries.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : injuries.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Save to the view model (this will handle the actual data persistence)
                try await viewModel.updateClientProfile(updatedClient!)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to save profile changes: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

struct ClientEditSection<Content: View>: View {
    let title: String
    let content: Content
    @ObservedObject private var themeManager = ThemeManager.shared
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            Text(title)
                .font(MovefullyTheme.Typography.title3)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            content
        }
        .padding(MovefullyTheme.Layout.paddingL)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Dedicated Notification Settings View

struct ClientNotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var clientViewModel: ClientViewModel
    @State private var iosPermissionGranted = true
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Header
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Push Notifications")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Choose which notifications you'd like to receive")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                    
                    // Notification Section
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        ClientSettingsSection(title: "Push Notifications", icon: "bell") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                ClientSettingsToggle(
                                    title: "Push Notifications", 
                                    subtitle: "", 
                                    isOn: $clientViewModel.notificationsEnabled
                                )
                                .disabled(!iosPermissionGranted)
                                .onChange(of: clientViewModel.notificationsEnabled) { _ in
                                    Task {
                                        await clientViewModel.saveNotificationSettings()
                                    }
                                }
                                
                                if !iosPermissionGranted {
                                    Button("Enable in iPhone Settings") {
                                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(settingsUrl)
                                        }
                                    }
                                    .font(MovefullyTheme.Typography.callout)
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    
                    // Info card
                    MovefullyCard {
                        HStack(spacing: MovefullyTheme.Layout.paddingM) {
                            Image(systemName: "moon.circle.fill")
                                .font(MovefullyTheme.Typography.buttonSmall)
                                .foregroundColor(MovefullyTheme.Colors.gentleBlue)
                            
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                                Text("Quiet Hours")
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Text("Notifications are automatically paused from 10:00 PM to 7:00 AM to respect your rest time.")
                                    .font(MovefullyTheme.Typography.callout)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .lineLimit(nil)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXL)
            }
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
    }
}

// MARK: - Settings View (Updated to remove duplicate notification settings)

struct ClientSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Header
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Settings & Privacy")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Customize your Movefully experience")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                    
                    // Settings Sections
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        // App Preferences
                        ClientSettingsSection(title: "Appearance", icon: "paintbrush") {
                            MovefullyThemePicker()
                                .environmentObject(themeManager)
                        }
                        
                        // Privacy
                        ClientSettingsSection(title: "Privacy", icon: "hand.raised") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                ClientSettingsActionRow(title: "Privacy Policy", icon: "doc.text", isDanger: false, action: {
                                    // Handle privacy policy
                                })
                                
                                ClientSettingsActionRow(title: "Terms of Service", icon: "doc.plaintext", isDanger: false, action: {
                                    // Handle terms of service
                                })
                            }
                        }
                    }
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXL)
            }
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
        .environmentObject(themeManager)
    }
}

// MARK: - Delete Account Confirmation View

struct DeleteAccountConfirmationView: View {
    @ObservedObject var deletionService: ClientDeletionService
    let onCancel: () -> Void
    let onComplete: () -> Void
    
    @State private var confirmationText = ""
    @State private var showError = false
    
    private let requiredText = "DELETE MY ACCOUNT"
    private var isConfirmationValid: Bool {
        confirmationText.uppercased() == requiredText
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                // Warning header
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(MovefullyTheme.Colors.warning)
                    
                    Text("Delete Account")
                        .font(MovefullyTheme.Typography.title1)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("This action cannot be undone")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, MovefullyTheme.Layout.paddingXL)
                
                // Consequences list
                MovefullyCard {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("What will be deleted:")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            DeleteConsequenceRow(text: "All workout history and progress")
                            DeleteConsequenceRow(text: "All messages with your trainer")
                            DeleteConsequenceRow(text: "All body measurements and milestones")
                            DeleteConsequenceRow(text: "Your complete profile and preferences")
                            DeleteConsequenceRow(text: "Your authentication account")
                        }
                    }
                }
                
                // Confirmation input
                MovefullyCard {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Type '\(requiredText)' to confirm:")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        MovefullyTextField(
                            placeholder: "Type here to confirm...",
                            text: $confirmationText
                        )
                        
                        if !confirmationText.isEmpty && !isConfirmationValid {
                            Text("Text doesn't match. Please type exactly: \(requiredText)")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.warning)
                        }
                    }
                }
                
                // Progress indicator
                if deletionService.isDeleting {
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(MovefullyTheme.Colors.warning)
                        
                        Text(deletionService.deletionProgress)
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(MovefullyTheme.Layout.paddingL)
                }
                
                Spacer()
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            .movefullyBackground()
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .disabled(deletionService.isDeleting)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete") {
                        deleteAccount()
                    }
                    .foregroundColor(MovefullyTheme.Colors.warning)
                    .disabled(!isConfirmationValid || deletionService.isDeleting)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(deletionService.errorMessage ?? "An error occurred while deleting your account.")
        }
    }
    
    private func deleteAccount() {
        Task {
            do {
                try await deletionService.deleteClientAccount()
                await MainActor.run {
                    deletionService.cleanup()
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    deletionService.errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct DeleteConsequenceRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingS) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(MovefullyTheme.Colors.warning)
            
            Text(text)
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
            
            Spacer()
        }
    }
}

struct ClientSettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    @ObservedObject private var themeManager = ThemeManager.shared
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                
                Text(title)
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            content
        }
        .padding(MovefullyTheme.Layout.paddingL)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 8, x: 0, y: 4)
    }
}

struct ClientSettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text(subtitle)
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(MovefullyTheme.Colors.primaryTeal)
        }
    }
}

// MARK: - Enhanced Help & Support View

struct ClientHelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingFeedback = false
    @State private var showingIssueReport = false
    @State private var showingTermsOfService = false
    @State private var showingPrivacyPolicy = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Header
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Help & Support")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("We're here to help you on your wellness journey")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                    
                    // Help options
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        ClientHelpOptionCard(
                            title: "Send Feedback",
                            subtitle: "Help us improve Movefully",
                            icon: "envelope",
                            color: MovefullyTheme.Colors.softGreen
                        ) { 
                            showingFeedback = true
                        }
                        
                        ClientHelpOptionCard(
                            title: "Report an Issue",
                            subtitle: "Technical support and bug reports",
                            icon: "exclamationmark.triangle",
                            color: MovefullyTheme.Colors.warmOrange
                        ) { 
                            showingIssueReport = true
                        }
                    }
                    
                    // App info
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Text("Movefully v1.0.0")
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXL)
            }
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
        .sheet(isPresented: $showingFeedback) {
            ClientFeedbackView()
        }
        .sheet(isPresented: $showingIssueReport) {
            ClientIssueReportView()
        }
        .sheet(isPresented: $showingTermsOfService) {
            ClientTermsOfServiceView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            ClientPrivacyPolicyView()
        }
    }
}

// MARK: - Contact Trainer View
struct ClientContactTrainerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subject = ""
    @State private var message = ""
    @State private var urgency = UrgencyLevel.normal
    @State private var showingSentConfirmation = false
    
    enum UrgencyLevel: String, CaseIterable {
        case low = "Low Priority"
        case normal = "Normal"
        case high = "High Priority"
        case urgent = "Urgent"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Header
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        
                        Text("Contact Your Trainer")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Send a message to your trainer about your program, exercises, or any concerns")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                    
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        MovefullyFormField(title: "Subject", isRequired: true) {
                            MovefullyTextField(
                                placeholder: "What's this about?",
                                text: $subject
                            )
                        }
                        
                        MovefullyFormField(title: "Priority Level") {
                            Picker("Priority", selection: $urgency) {
                                ForEach(UrgencyLevel.allCases, id: \.self) { level in
                                    Text(level.rawValue).tag(level)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        MovefullyFormField(title: "Message", isRequired: true) {
                            MovefullyTextEditor(
                                placeholder: "Describe your question or concern in detail...",
                                text: $message,
                                minLines: 4,
                                maxLines: 8
                            )
                        }
                        
                        MovefullyCharacterCount(currentCount: message.count, maxCount: 500)
                    }
                    
                    Button("Send Message") {
                        // Handle sending message
                        showingSentConfirmation = true
                    }
                    .movefullyButtonStyle(.primary)
                    .disabled(subject.isEmpty || message.isEmpty)
                    .opacity(subject.isEmpty || message.isEmpty ? 0.6 : 1.0)
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXL)
            }
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
        .alert("Message Sent", isPresented: $showingSentConfirmation) {
            Button("OK") { 
                dismiss() 
            }
        } message: {
            Text("Your message has been sent to your trainer. They'll respond within 24 hours.")
        }
    }
}

// MARK: - FAQ View
struct ClientFAQView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    MovefullySearchField(
                        placeholder: "Search frequently asked questions...",
                        text: $searchText
                    )
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.top, MovefullyTheme.Layout.paddingM)
                
                ScrollView {
                    LazyVStack(spacing: MovefullyTheme.Layout.paddingM) {
                        ForEach(filteredFAQs, id: \.question) { faq in
                            FAQItemView(faq: faq)
                        }
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                    .padding(.bottom, MovefullyTheme.Layout.paddingXL)
                }
            }
            .movefullyBackground()
            .navigationTitle("FAQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
    }
    
    private var filteredFAQs: [FAQ] {
        if searchText.isEmpty {
            return sampleFAQs
        } else {
            return sampleFAQs.filter { faq in
                faq.question.localizedCaseInsensitiveContains(searchText) ||
                faq.answer.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct FAQ {
    let question: String
    let answer: String
    let category: String
}

struct FAQItemView: View {
    let faq: FAQ
    @State private var isExpanded = false
    
    var body: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                Button(action: { isExpanded.toggle() }) {
                    HStack {
                        Text(faq.question)
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                if isExpanded {
                    Text(faq.answer)
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(nil)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

private let sampleFAQs = [
    FAQ(question: "How do I track my workouts?", answer: "You can track workouts by marking exercises as complete in your assigned workout plans. Progress is automatically saved and synced with your trainer.", category: "Workouts"),
    FAQ(question: "Can I modify exercises?", answer: "If you need to modify an exercise due to injury or equipment limitations, contact your trainer through the messages tab. They can provide alternatives or adjustments.", category: "Exercises"),
    FAQ(question: "How often should I message my trainer?", answer: "Feel free to message your trainer whenever you have questions or concerns. Most trainers respond within 24 hours during business days.", category: "Communication"),
    FAQ(question: "What if I miss a workout?", answer: "Don't worry! Life happens. You can catch up on missed workouts or ask your trainer to adjust your schedule. Consistency over perfection is key.", category: "Workouts"),
    FAQ(question: "How do I update my fitness goals?", answer: "You can update your goals in your profile settings. Your trainer will be notified and can adjust your program accordingly.", category: "Profile"),
    FAQ(question: "Can I use the app offline?", answer: "Yes, you can view your current workout plans and track exercises offline. Data will sync when you reconnect to the internet.", category: "App Usage")
]

// MARK: - Feedback View
struct ClientFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackType = FeedbackType.general
    @State private var rating = 5
    @State private var feedback = ""
    @State private var includeEmail = false
    @State private var showingSentConfirmation = false
    
    enum FeedbackType: String, CaseIterable {
        case general = "General Feedback"
        case feature = "Feature Request"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Header
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 48))
                            .foregroundColor(MovefullyTheme.Colors.softGreen)
                        
                        Text("Send Feedback")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Help us improve Movefully with your suggestions and feedback")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                    
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        MovefullyFormField(title: "Feedback Type") {
                            Picker("Type", selection: $feedbackType) {
                                ForEach(FeedbackType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        MovefullyFormField(title: "Overall Rating") {
                            HStack {
                                ForEach(1...5, id: \.self) { star in
                                    Button(action: { rating = star }) {
                                        Image(systemName: star <= rating ? "star.fill" : "star")
                                            .font(.title2)
                                            .foregroundColor(star <= rating ? MovefullyTheme.Colors.warmOrange : MovefullyTheme.Colors.textTertiary)
                                    }
                                }
                                Spacer()
                            }
                        }
                        
                        MovefullyFormField(title: "Your Feedback", isRequired: true) {
                            MovefullyTextEditor(
                                placeholder: "Tell us what you think about Movefully...",
                                text: $feedback,
                                minLines: 4,
                                maxLines: 8
                            )
                        }
                        
                        MovefullyCharacterCount(currentCount: feedback.count, maxCount: 1000)
                        
                        MovefullyToggleField(
                            title: "Include my email",
                            subtitle: "Let us contact you about this feedback",
                            isOn: $includeEmail
                        )
                    }
                    
                    Button("Send Feedback") {
                        // Handle sending feedback
                        showingSentConfirmation = true
                    }
                    .movefullyButtonStyle(.primary)
                    .disabled(feedback.isEmpty)
                    .opacity(feedback.isEmpty ? 0.6 : 1.0)
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXL)
            }
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
        .alert("Feedback Sent", isPresented: $showingSentConfirmation) {
            Button("OK") { 
                dismiss() 
            }
        } message: {
            Text("Thank you for your feedback! We appreciate you helping us improve Movefully.")
        }
    }
}

// MARK: - Issue Report View
struct ClientIssueReportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var issueType = IssueType.bug
    @State private var description = ""
    @State private var stepsToReproduce = ""
    @State private var includeDeviceInfo = true
    @State private var showingSentConfirmation = false
    
    enum IssueType: String, CaseIterable {
        case bug = "Bug Report"
        case crash = "App Crash"
        case performance = "Performance Issue"
        case sync = "Sync Problem"
        case other = "Other Issue"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Header
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(MovefullyTheme.Colors.warmOrange)
                        
                        Text("Report an Issue")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Help us fix technical problems and improve app stability")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                    
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        MovefullyFormField(title: "Issue Type") {
                            Picker("Type", selection: $issueType) {
                                ForEach(IssueType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        MovefullyFormField(title: "Description", isRequired: true) {
                            MovefullyTextEditor(
                                placeholder: "Describe the issue you're experiencing...",
                                text: $description,
                                minLines: 3,
                                maxLines: 6
                            )
                        }
                        
                        MovefullyFormField(title: "Steps to Reproduce") {
                            MovefullyTextEditor(
                                placeholder: "1. First I did...\n2. Then I tapped...\n3. The issue occurred when...",
                                text: $stepsToReproduce,
                                minLines: 3,
                                maxLines: 6
                            )
                        }
                        
                        MovefullyToggleField(
                            title: "Include device information",
                            subtitle: "Helps us diagnose the issue faster",
                            isOn: $includeDeviceInfo
                        )
                        
                        if includeDeviceInfo {
                            MovefullyCard {
                                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                                    Text("Device Info (will be included)")
                                        .font(MovefullyTheme.Typography.caption)
                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    
                                    Text("• iOS \(UIDevice.current.systemVersion)")
                                    Text("• \(UIDevice.current.model)")
                                    Text("• Movefully v1.0.0")
                                }
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textTertiary)
                            }
                        }
                    }
                    
                    Button("Submit Report") {
                        // Handle sending issue report
                        showingSentConfirmation = true
                    }
                    .movefullyButtonStyle(.primary)
                    .disabled(description.isEmpty)
                    .opacity(description.isEmpty ? 0.6 : 1.0)
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXL)
            }
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
        }
        .alert("Report Submitted", isPresented: $showingSentConfirmation) {
            Button("OK") { 
                dismiss() 
            }
        } message: {
            Text("Your issue report has been submitted. Our support team will investigate and get back to you soon.")
        }
    }
}

struct ClientHelpOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MovefullyTheme.Layout.paddingL) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text(title)
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
            }
            .padding(MovefullyTheme.Layout.paddingL)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Terms of Service View
struct ClientTermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingL) {
                    Text("Terms of Service")
                        .font(MovefullyTheme.Typography.title1)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("Last updated: December 2024")
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Welcome to Movefully")
                            .font(MovefullyTheme.Typography.title3)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("By using Movefully, you agree to these terms of service. Please read them carefully.")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Text("1. Acceptance of Terms")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("By accessing and using Movefully, you accept and agree to be bound by the terms and provision of this agreement.")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Text("2. Use License")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Permission is granted to temporarily use Movefully for personal, non-commercial transitory viewing only.")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Text("3. Health and Safety")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Movefully provides fitness guidance and wellness resources. Always consult with healthcare professionals before beginning any fitness program.")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Text("For complete terms and conditions, visit our website or contact support.")
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                            .italic()
                    }
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXL)
            }
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
    }
}

// MARK: - Privacy Policy View
struct ClientPrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingL) {
                    Text("Privacy Policy")
                        .font(MovefullyTheme.Typography.title1)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("Last updated: December 2024")
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Your Privacy Matters")
                            .font(MovefullyTheme.Typography.title3)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("At Movefully, we are committed to protecting your privacy and ensuring the security of your personal information.")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Text("Information We Collect")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("We collect information you provide directly, such as your fitness goals, health information, and workout preferences to personalize your experience.")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Text("How We Use Your Information")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Your information helps us provide personalized fitness plans, connect you with trainers, and improve our services.")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Text("Data Security")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Text("For our complete privacy policy, visit our website or contact support.")
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                            .italic()
                    }
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXL)
            }
            .movefullyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
    }
}

// MARK: - Client Settings Action Row

struct ClientSettingsActionRow: View {
    let title: String
    let icon: String
    let isDanger: Bool
    let action: () -> Void
    
    init(title: String, icon: String, isDanger: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isDanger = isDanger
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDanger ? MovefullyTheme.Colors.warmOrange : MovefullyTheme.Colors.textSecondary)
                    .frame(width: 24)
                
                Text(title)
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(isDanger ? MovefullyTheme.Colors.warmOrange : MovefullyTheme.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingM)
            .padding(.vertical, MovefullyTheme.Layout.paddingM)
            .background(MovefullyTheme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ClientProfileView(viewModel: ClientViewModel())
        .environmentObject(AuthenticationViewModel())
} 