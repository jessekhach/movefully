import SwiftUI
import FirebaseAuth

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
        if let user = Auth.auth().currentUser {
            return user.email ?? authViewModel.userEmail
        }
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
    @State private var displayName: String
    @State private var goals: String
    @State private var height: String
    @State private var weight: String
    @State private var injuries: String
    @State private var preferredCoachingStyle: CoachingStyle
    
    init(viewModel: ClientViewModel) {
        self.viewModel = viewModel
        _displayName = State(initialValue: viewModel.currentClient.name)
        _goals = State(initialValue: viewModel.currentClient.goals ?? "")
        _height = State(initialValue: viewModel.currentClient.height ?? "")
        _weight = State(initialValue: viewModel.currentClient.weight ?? "")
        _injuries = State(initialValue: viewModel.currentClient.injuries ?? "")
        _preferredCoachingStyle = State(initialValue: viewModel.currentClient.preferredCoachingStyle ?? .hybrid)
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
                        // Basic info
                        ClientEditSection(title: "Basic Information") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                MovefullyFormField(title: "Display Name") {
                                    MovefullyTextField(
                                        placeholder: "Enter your name",
                                        text: $displayName
                                    )
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
                                
                                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                                    Text("Preferred Coaching Style")
                                        .font(MovefullyTheme.Typography.bodyMedium)
                                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                    
                                    Picker("Coaching Style", selection: $preferredCoachingStyle) {
                                        ForEach(CoachingStyle.allCases, id: \.self) { style in
                                            Text(style.rawValue).tag(style)
                                        }
                                    }
                                    .pickerStyle(.segmented)
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

// MARK: - Settings View

struct ClientSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var workoutReminders = true
    @State private var progressUpdates = true
    @State private var emailUpdates = false
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
                        // Notifications
                        ClientSettingsSection(title: "Notifications", icon: "bell") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                ClientSettingsToggle(title: "Push Notifications", subtitle: "Receive app notifications", isOn: $notificationsEnabled)
                                ClientSettingsToggle(title: "Workout Reminders", subtitle: "Get reminders for scheduled workouts", isOn: $workoutReminders)
                                ClientSettingsToggle(title: "Progress Updates", subtitle: "Weekly progress summaries", isOn: $progressUpdates)
                                ClientSettingsToggle(title: "Email Updates", subtitle: "Receive updates via email", isOn: $emailUpdates)
                            }
                        }
                        
                        // Privacy & Security
                        ClientSettingsSection(title: "Privacy & Security", icon: "lock.shield") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                ClientSettingsToggle(title: "Biometric Authentication", subtitle: "Use Face ID or Touch ID", isOn: $biometricAuth)
                                ClientSettingsToggle(title: "Share Workout Data", subtitle: "Help improve the app experience", isOn: $dataSharing)
                            }
                        }
                        
                        // App Preferences
                        ClientSettingsSection(title: "App Preferences", icon: "slider.horizontal.3") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                ClientSettingsToggle(title: "Dark Mode", subtitle: "Use dark theme", isOn: $darkModeEnabled)
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

// MARK: - Help & Support View

struct ClientHelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    
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
                            title: "Contact Your Trainer",
                            subtitle: "Get personalized support",
                            icon: "person.crop.circle.badge.questionmark",
                            color: MovefullyTheme.Colors.primaryTeal
                        ) { }
                        
                        ClientHelpOptionCard(
                            title: "Frequently Asked Questions",
                            subtitle: "Quick answers to common questions",
                            icon: "questionmark.circle",
                            color: MovefullyTheme.Colors.gentleBlue
                        ) { }
                        
                        ClientHelpOptionCard(
                            title: "Send Feedback",
                            subtitle: "Help us improve Movefully",
                            icon: "envelope",
                            color: MovefullyTheme.Colors.softGreen
                        ) { }
                        
                        ClientHelpOptionCard(
                            title: "Report an Issue",
                            subtitle: "Technical support and bug reports",
                            icon: "exclamationmark.triangle",
                            color: MovefullyTheme.Colors.warmOrange
                        ) { }
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

#Preview {
    ClientProfileView(viewModel: ClientViewModel())
        .environmentObject(AuthenticationViewModel())
} 