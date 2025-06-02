import SwiftUI
#if canImport(MessageUI)
import MessageUI
#endif

struct ClientProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @ObservedObject var viewModel: ClientViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSignOutAlert = false
    @State private var showEditProfile = false
    @State private var showNotificationSettings = false
    @State private var showAbout = false
    @State private var isEditing = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with gradient background
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        // Profile photo and basic info
                        VStack(spacing: MovefullyTheme.Layout.paddingM) {
                            // Profile image
                            ZStack {
                                Circle()
                                    .fill(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal.opacity(0.7))
                            }
                            .shadow(color: MovefullyTheme.Colors.primaryTeal.opacity(0.2), radius: 10, x: 0, y: 5)
                            
                            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                                Text(viewModel.currentClient.name)
                                    .font(MovefullyTheme.Typography.title1)
                                    .fontWeight(.semibold)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
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
                                value: "7", // This would come from actual data
                                subtitle: "days",
                                icon: "flame.fill"
                            )
                            
                            Divider()
                                .frame(height: 40)
                                .background(MovefullyTheme.Colors.textTertiary.opacity(0.3))
                            
                            ClientProfileStatView(
                                title: "Progress",
                                value: "85%",
                                subtitle: "this month",
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
                                if let goals = viewModel.currentClient.goals {
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
                                if let height = viewModel.currentClient.height, let weight = viewModel.currentClient.weight {
                                    HStack {
                                        ClientProfileInfoItem(label: "Height", value: height)
                                        Spacer()
                                        ClientProfileInfoItem(label: "Weight", value: weight)
                                    }
                                }
                                
                                if let injuries = viewModel.currentClient.injuries {
                                    ClientProfileInfoItem(label: "Notes/Injuries", value: injuries, fullWidth: true)
                                }
                                
                                if let coachingStyle = viewModel.currentClient.preferredCoachingStyle {
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
                                ClientProfileActionRow(title: "Sign Out", icon: "rectangle.portrait.and.arrow.right", isDanger: true, action: { showSignOutAlert = true })
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
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $isEditing) {
            ClientEditProfileView(viewModel: viewModel)
        }
        .sheet(isPresented: $showNotificationSettings) {
            ClientNotificationSettingsView()
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
    }
    
    private var userEmail: String {
        return authViewModel.userEmail
    }
}

// MARK: - Supporting Views

struct ClientProfileStatView: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    
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
                    .foregroundColor(MovefullyTheme.Colors.textTertiary)
            }
            .padding(.vertical, MovefullyTheme.Layout.paddingS)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Profile View

struct ClientEditProfileView: View {
    @ObservedObject var viewModel: ClientViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var goals: String
    @State private var height: String
    @State private var weight: String
    @State private var injuries: String
    
    init(viewModel: ClientViewModel) {
        self.viewModel = viewModel
        _goals = State(initialValue: viewModel.currentClient.goals ?? "")
        _height = State(initialValue: viewModel.currentClient.height ?? "")
        _weight = State(initialValue: viewModel.currentClient.weight ?? "")
        _injuries = State(initialValue: viewModel.currentClient.injuries ?? "")
    }
    
    var body: some View {
        NavigationView {
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
                            // Save profile changes
                            dismiss()
                        }
                        .movefullyButtonStyle(.primary)
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
                        // Save changes
                        dismiss() 
                    }
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
    }
}

struct ClientEditSection<Content: View>: View {
    let title: String
    let content: Content
    
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
    @State private var notificationsEnabled = true
    @State private var workoutReminders = true
    @State private var trainerMessages = true
    @State private var planUpdates = true
    @State private var emailNotifications = false
    @State private var soundEnabled = true
    @State private var vibrationEnabled = true
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Header
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Notifications")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Customize how and when you receive notifications from Movefully")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                    
                    // Notification Sections
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        // Main notifications toggle
                        ClientSettingsSection(title: "Push Notifications", icon: "bell") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                ClientSettingsToggle(
                                    title: "Enable Notifications", 
                                    subtitle: "Allow Movefully to send you notifications", 
                                    isOn: $notificationsEnabled
                                )
                            }
                        }
                        
                        // Workout & Training
                        ClientSettingsSection(title: "Workouts & Training", icon: "figure.run") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                ClientSettingsToggle(
                                    title: "Workout Reminders", 
                                    subtitle: "Get reminders for scheduled workouts", 
                                    isOn: $workoutReminders
                                )
                                .disabled(!notificationsEnabled)
                                .opacity(notificationsEnabled ? 1.0 : 0.6)
                                
                                ClientSettingsToggle(
                                    title: "Plan Updates", 
                                    subtitle: "When your trainer updates your plan", 
                                    isOn: $planUpdates
                                )
                                .disabled(!notificationsEnabled)
                                .opacity(notificationsEnabled ? 1.0 : 0.6)
                            }
                        }
                        
                        // Communication
                        ClientSettingsSection(title: "Communication", icon: "message") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                ClientSettingsToggle(
                                    title: "Trainer Messages", 
                                    subtitle: "New messages from your trainer", 
                                    isOn: $trainerMessages
                                )
                                .disabled(!notificationsEnabled)
                                .opacity(notificationsEnabled ? 1.0 : 0.6)
                                
                                ClientSettingsToggle(
                                    title: "Email Notifications", 
                                    subtitle: "Receive important updates via email", 
                                    isOn: $emailNotifications
                                )
                            }
                        }
                        
                        // Notification Style
                        ClientSettingsSection(title: "Notification Style", icon: "speaker.wave.2") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                ClientSettingsToggle(
                                    title: "Sound", 
                                    subtitle: "Play sound for notifications", 
                                    isOn: $soundEnabled
                                )
                                .disabled(!notificationsEnabled)
                                .opacity(notificationsEnabled ? 1.0 : 0.6)
                                
                                ClientSettingsToggle(
                                    title: "Vibration", 
                                    subtitle: "Vibrate for notifications", 
                                    isOn: $vibrationEnabled
                                )
                                .disabled(!notificationsEnabled)
                                .opacity(notificationsEnabled ? 1.0 : 0.6)
                            }
                        }
                    }
                    
                    // Info card
                    MovefullyCard {
                        HStack(spacing: MovefullyTheme.Layout.paddingM) {
                            Image(systemName: "info.circle.fill")
                                .font(MovefullyTheme.Typography.buttonSmall)
                                .foregroundColor(MovefullyTheme.Colors.gentleBlue)
                            
                            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                                Text("Notification Permissions")
                                    .font(MovefullyTheme.Typography.bodyMedium)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Text("You can also manage notifications in your device Settings app under Movefully.")
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
    @State private var darkModeEnabled = false
    @State private var biometricAuth = true
    @State private var dataSharing = false
    
    var body: some View {
        NavigationView {
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
                        // Privacy & Security
                        ClientSettingsSection(title: "Privacy & Security", icon: "lock.shield") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                ClientSettingsToggle(title: "Biometric Authentication", subtitle: "Use Face ID or Touch ID to unlock the app", isOn: $biometricAuth)
                                ClientSettingsToggle(title: "Share Anonymous Data", subtitle: "Help improve the app experience", isOn: $dataSharing)
                            }
                        }
                        
                        // App Preferences
                        ClientSettingsSection(title: "App Preferences", icon: "slider.horizontal.3") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                ClientSettingsToggle(title: "Dark Mode", subtitle: "Use dark theme for the app", isOn: $darkModeEnabled)
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
    }
}

struct ClientSettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
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
    @State private var showingFeedback = false
    @State private var showingIssueReport = false
    @State private var showingTermsOfService = false
    @State private var showingPrivacyPolicy = false
    
    var body: some View {
        NavigationView {
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
                    
                    // Legal section
                    ClientProfileSectionCard(title: "Legal", icon: "doc.text") {
                        VStack(spacing: MovefullyTheme.Layout.paddingM) {
                            MovefullyActionRow(
                                title: "Privacy Policy",
                                icon: "hand.raised",
                                action: {
                                    showingPrivacyPolicy = true
                                }
                            )
                            
                            MovefullyActionRow(
                                title: "Terms of Service",
                                icon: "doc.plaintext",
                                action: {
                                    showingTermsOfService = true
                                }
                            )
                        }
                    }
                    
                    // App info
                    VStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Text("Movefully v1.0.0")
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        Text("Made with ❤️ for mindful movement")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
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
        NavigationView {
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
        NavigationView {
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
        case improvement = "App Improvement"
        case trainer = "Trainer Experience"
    }
    
    var body: some View {
        NavigationView {
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
                            subtitle: "Allow us to contact you about your feedback",
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
        NavigationView {
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
        NavigationView {
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
        NavigationView {
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

#Preview {
    ClientProfileView(viewModel: ClientViewModel())
        .environmentObject(AuthenticationViewModel())
} 