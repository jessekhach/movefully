import SwiftUI
import FirebaseAuth
import MessageUI

struct TrainerProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var viewModel = TrainerProfileViewModel()
    @State private var showSignOutAlert = false
    @State private var showingMailComposer = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with gradient background
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        // Profile photo and basic info
                        VStack(spacing: MovefullyTheme.Layout.paddingL) {
                            // Profile Picture
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [MovefullyTheme.Colors.primaryTeal.opacity(0.8), MovefullyTheme.Colors.lavender.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                
                                Text("JK")
                                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                // Edit button overlay
                                Button(action: { viewModel.startEditingProfile() }) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(MovefullyTheme.Colors.primaryTeal)
                                        .clipShape(Circle())
                                        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
                                }
                                .offset(x: 35, y: 35)
                            }
                            
                            // Name and title
                            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                                Text(viewModel.trainerProfile?.name ?? "Trainer")
                                    .font(MovefullyTheme.Typography.title1)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Text(viewModel.trainerProfile?.title ?? "Wellness Coach & Movement Specialist")
                                    .font(MovefullyTheme.Typography.callout)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                
                                // Location
                                if let location = viewModel.trainerProfile?.location, !location.isEmpty {
                                    HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                        Text(location)
                                            .font(MovefullyTheme.Typography.caption)
                                            .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                    }
                                }
                                
                                // Certification (commented for future use)
                                /*
                                HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(MovefullyTheme.Colors.softGreen)
                                    Text("NASM Certified")
                                        .font(MovefullyTheme.Typography.caption)
                                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                }
                                */
                            }
                        }
                        
                        // Quick stats
                        HStack(spacing: MovefullyTheme.Layout.paddingL) {
                            TrainerProfileStatView(title: "Active Clients", value: "\(viewModel.activeClientCount)", icon: "heart.circle")
                            TrainerProfileStatView(title: "Total Plans", value: "\(viewModel.totalProgramCount)", icon: "doc.text")
                            TrainerProfileStatView(title: "Experience", value: viewModel.yearsExperienceText, icon: "star.circle")
                        }
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                    .padding(.vertical, MovefullyTheme.Layout.paddingXL)
                    .background(
                        LinearGradient(
                            colors: [MovefullyTheme.Colors.cardBackground, MovefullyTheme.Colors.backgroundPrimary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Content sections
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        // About section
                        TrainerProfileSectionCard(title: "About Me", icon: "person.circle") {
                            HStack {
                                Text(viewModel.trainerProfile?.bio ?? "No bio available. Edit your profile to add a bio.")
                                    .font(MovefullyTheme.Typography.body)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .lineLimit(nil)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                        }
                        
                        // Specialties section
                        TrainerProfileSectionCard(title: "Specialties", icon: "sparkles") {
                            let specialties = viewModel.trainerProfile?.specialties ?? []
                            if specialties.isEmpty {
                                Text("No specialties added yet")
                                    .font(MovefullyTheme.Typography.body)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .italic()
                            } else {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: MovefullyTheme.Layout.paddingM) {
                                    ForEach(specialties, id: \.self) { specialty in
                                        SpecialtyTag(text: specialty)
                                    }
                                }
                            }
                        }
                        
                        // Contact Information section (only show if contact info exists)
                        if hasContactInformation {
                            TrainerProfileSectionCard(title: "Contact Information", icon: "envelope.circle") {
                                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                                    if !(viewModel.trainerProfile?.email.isEmpty ?? true) {
                                        ContactInfoRow(icon: "envelope.fill", text: viewModel.trainerProfile?.email ?? "")
                                    }
                                    
                                    if let phoneNumber = viewModel.trainerProfile?.phoneNumber, !phoneNumber.isEmpty {
                                        ContactInfoRow(icon: "phone.fill", text: phoneNumber)
                                    }
                                    
                                    Text("Your contact information is visible to your clients.")
                                        .font(MovefullyTheme.Typography.caption)
                                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }
                        
                        // Quick actions
                        TrainerProfileSectionCard(title: "Quick Actions", icon: "bolt.circle") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                TrainerProfileActionRow(title: "Edit Profile", icon: "person.crop.circle", action: { 
                                    viewModel.startEditingProfile()
                                })
                                TrainerProfileActionRow(title: "Settings & Privacy", icon: "gearshape", action: { 
                                    viewModel.showingSettings = true
                                })
                                TrainerProfileActionRow(title: "Help & Support", icon: "questionmark.circle", action: { 
                                    showingMailComposer = true 
                                })
                                TrainerProfileActionRow(title: "Sign Out", icon: "rectangle.portrait.and.arrow.right", action: { 
                                    showSignOutAlert = true
                                })
                            }
                        }
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                    .padding(.vertical, MovefullyTheme.Layout.paddingL)
                }
            }
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $viewModel.showingEditProfile) {
            EditProfileView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingMailComposer) {
            SupportContactView()
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
    
    private var userDisplayName: String {
        if let user = Auth.auth().currentUser {
            return user.displayName ?? "Trainer"
        }
        return "Trainer"
    }
    
    private var userEmail: String {
        if let user = Auth.auth().currentUser {
            return user.email ?? authViewModel.userEmail
        }
        return authViewModel.userEmail
    }
    
    private var hasContactInformation: Bool {
        let hasEmail = !(viewModel.trainerProfile?.email.isEmpty ?? true)
        let hasPhone = !(viewModel.trainerProfile?.phoneNumber?.isEmpty ?? true)
        return hasEmail || hasPhone
    }
}

struct TrainerProfileStatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingS) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            
            VStack(spacing: MovefullyTheme.Layout.paddingXS) {
                Text(value)
                    .font(MovefullyTheme.Typography.title2)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text(title)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MovefullyTheme.Layout.paddingL)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 6, x: 0, y: 3)
    }
}

struct TrainerProfileSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
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
        .padding(MovefullyTheme.Layout.paddingXL)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 8, x: 0, y: 4)
    }
}

struct SpecialtyTag: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(MovefullyTheme.Typography.caption)
            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            .padding(.horizontal, MovefullyTheme.Layout.paddingM)
            .padding(.vertical, MovefullyTheme.Layout.paddingS)
            .background(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
    }
}

struct TrainerProfileActionRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .frame(width: 24)
                
                Text(title)
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
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

struct ContactInfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                .frame(width: 24)
            
            Text(text)
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
            
            Spacer()
        }
    }
}

// Real edit profile view with functionality
struct EditProfileView: View {
    @ObservedObject var viewModel: TrainerProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newSpecialty = ""
    @State private var showingAddSpecialtyAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Profile Picture Section
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        ZStack {
                            Circle()
                                .fill(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            
                            Button(action: {
                                // Handle photo change
                            }) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(MovefullyTheme.Colors.primaryTeal)
                                    .clipShape(Circle())
                            }
                            .offset(x: 40, y: 40)
                            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
                        }
                        
                        Text("Update Profile Photo")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                    
                    // Form Fields
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        ProfileEditField(title: "Display Name", text: $viewModel.profileName)
                        ProfileEditFieldWithLimit(
                            title: "Professional Title", 
                            text: $viewModel.profileTitle, 
                            characterLimit: viewModel.titleCharacterLimit
                        )
                        ProfileEditFieldWithLimit(
                            title: "Bio", 
                            text: $viewModel.profileBio, 
                            characterLimit: viewModel.bioCharacterLimit,
                            isMultiline: true
                        )
                        ProfileEditFieldWithLimit(
                            title: "Location", 
                            text: $viewModel.profileLocation, 
                            characterLimit: viewModel.locationCharacterLimit
                        )
                        ProfileEditField(title: "Website", text: $viewModel.profileWebsite)
                        
                        // Contact Information Section
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                            Text("Contact Information")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            ProfileEditField(title: "Email", text: $viewModel.profileEmail)
                            ProfileEditField(title: "Phone Number", text: $viewModel.profilePhoneNumber)
                            
                            Text("Contact information is optional. If provided, it will be visible to your clients.")
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        ProfileEditField(title: "Years of Experience", text: $viewModel.profileYearsExperience)
                        
                        // Specialties Section
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                            Text("Specialties")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: MovefullyTheme.Layout.paddingS) {
                                ForEach(viewModel.profileSpecialties, id: \.self) { specialty in
                                    HStack {
                                        Text(specialty)
                                            .font(MovefullyTheme.Typography.caption)
                                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            viewModel.removeSpecialty(specialty)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                        }
                                    }
                                    .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                                    .padding(.vertical, MovefullyTheme.Layout.paddingS)
                                    .background(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                                }
                            }
                            
                            AddSpecialtyButton(
                                canAddMore: viewModel.profileSpecialties.count < viewModel.maxSpecialties,
                                maxSpecialties: viewModel.maxSpecialties,
                                onTap: { showingAddSpecialtyAlert = true }
                            )
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .movefullyButtonStyle(.tertiary)
                        
                        Button("Save Changes") {
                            Task {
                                await viewModel.saveProfile()
                            }
                        }
                        .movefullyButtonStyle(.primary)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.bottom, MovefullyTheme.Layout.paddingXL)
            }
            .movefullyBackground()
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
            .alert("Add Specialty", isPresented: $showingAddSpecialtyAlert) {
                TextField("Enter specialty", text: $newSpecialty)
                Button("Add") {
                    if !newSpecialty.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        viewModel.addSpecialty(newSpecialty.trimmingCharacters(in: .whitespacesAndNewlines))
                        newSpecialty = ""
                    }
                }
                Button("Cancel", role: .cancel) {
                    newSpecialty = ""
                }
            } message: {
                Text("Enter a specialty to add to your profile")
            }
        }
    }
}

struct ProfileEditField: View {
    let title: String
    @Binding var text: String
    let isMultiline: Bool
    
    init(title: String, text: Binding<String>, isMultiline: Bool = false) {
        self.title = title
        self._text = text
        self.isMultiline = isMultiline
    }
    
    var body: some View {
        MovefullyFormField(title: title) {
            if isMultiline {
                MovefullyTextEditor(
                    placeholder: title,
                    text: $text,
                    minLines: 4,
                    maxLines: 8
                )
            } else {
                MovefullyTextField(
                    placeholder: title,
                    text: $text
                    )
            }
        }
    }
}

struct AddSpecialtyButton: View {
    let canAddMore: Bool
    let maxSpecialties: Int
    let onTap: () -> Void
    
    var body: some View {
        if canAddMore {
            Button("Add Specialty") {
                onTap()
            }
            .font(MovefullyTheme.Typography.caption)
            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
            .padding(.horizontal, MovefullyTheme.Layout.paddingM)
            .padding(.vertical, MovefullyTheme.Layout.paddingS)
            .background(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            .overlay(
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                    .stroke(MovefullyTheme.Colors.primaryTeal.opacity(0.3), lineWidth: 1)
            )
        } else {
            Text("Maximum \(maxSpecialties) specialties reached")
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(MovefullyTheme.Colors.textTertiary)
                .italic()
        }
    }
}

struct ProfileEditFieldWithLimit: View {
    let title: String
    @Binding var text: String
    let characterLimit: Int
    let isMultiline: Bool
    
    init(title: String, text: Binding<String>, characterLimit: Int, isMultiline: Bool = false) {
        self.title = title
        self._text = text
        self.characterLimit = characterLimit
        self.isMultiline = isMultiline
    }
    
    var body: some View {
        MovefullyFormField(title: title) {
            VStack(alignment: .trailing, spacing: MovefullyTheme.Layout.paddingXS) {
                if isMultiline {
                    MovefullyTextEditor(
                        placeholder: title,
                        text: $text,
                        minLines: 4,
                        maxLines: 8
                    )
                    .onChange(of: text) { newValue in
                        if newValue.count > characterLimit {
                            text = String(newValue.prefix(characterLimit))
                        }
                    }
                } else {
                    MovefullyTextField(
                        placeholder: title,
                        text: $text
                    )
                    .onChange(of: text) { newValue in
                        if newValue.count > characterLimit {
                            text = String(newValue.prefix(characterLimit))
                        }
                    }
                }
                
                Text("\(text.count)/\(characterLimit)")
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(text.count > characterLimit * 9 / 10 ? MovefullyTheme.Colors.warning : MovefullyTheme.Colors.textTertiary)
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var emailUpdates = true
    @State private var biometricAuth = true
    @State private var dataSharing = false
    
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
                        SettingsSection(title: "Notifications", icon: "bell") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                MovefullyToggleField(
                                    title: "Push Notifications",
                                    subtitle: "Get notified about client activity and messages",
                                    isOn: $notificationsEnabled
                                )
                                MovefullyToggleField(
                                    title: "Email Updates",
                                    subtitle: "Receive weekly summaries and updates",
                                    isOn: $emailUpdates
                                )
                            }
                        }
                        
                        SettingsSection(title: "Appearance", icon: "paintbrush") {
                            MovefullyThemePicker()
                        }
                        
                        SettingsSection(title: "Security", icon: "lock.shield") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                MovefullyToggleField(
                                    title: "Biometric Authentication",
                                    subtitle: "Use Touch ID or Face ID to unlock",
                                    isOn: $biometricAuth
                                )
                                
                                MovefullyActionRow(
                                    title: "Change Password",
                                    icon: "key"
                                ) {
                                    // Handle password change
                                }
                                
                                MovefullyActionRow(
                                    title: "Two-Factor Authentication",
                                    icon: "shield.checkered"
                                ) {
                                    // Handle 2FA setup
                                }
                            }
                        }
                        
                        SettingsSection(title: "Privacy", icon: "hand.raised") {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                SettingsToggle(title: "Anonymous Usage Data", subtitle: "Help improve Movefully by sharing anonymous data", isOn: $dataSharing)
                                
                                SettingsActionRow(title: "Privacy Policy", icon: "doc.text", isDanger: false, action: {
                                    // Handle privacy policy
                                })
                                
                                SettingsActionRow(title: "Terms of Service", icon: "doc.plaintext", isDanger: false, action: {
                                    // Handle terms of service
                                })
                            }
                        }
                        
                        // Danger Zone
                        SettingsSection(title: "Account", icon: "person.circle", isDanger: true) {
                            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                                SettingsActionRow(title: "Export Data", icon: "square.and.arrow.up", isDanger: true, action: {
                                    // Handle data export
                                })
                                
                                SettingsActionRow(title: "Delete Account", icon: "trash", isDanger: true, action: {
                                    // Handle account deletion
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let isDanger: Bool
    let content: Content
    
    init(title: String, icon: String, isDanger: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.isDanger = isDanger
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isDanger ? MovefullyTheme.Colors.warmOrange : MovefullyTheme.Colors.primaryTeal)
                
                Text(title)
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            content
        }
        .padding(MovefullyTheme.Layout.paddingXL)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 8, x: 0, y: 4)
    }
}

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                Text(title)
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text(subtitle)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(MovefullyTheme.Colors.primaryTeal)
        }
    }
}

struct SettingsActionRow: View {
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

struct HelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Header
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Help & Support")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("We're here to help you succeed")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                    
                    // Quick Actions
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        HelpActionCard(
                            title: "Contact Support",
                            subtitle: "Get help from our wellness support team",
                            icon: "headphones",
                            color: MovefullyTheme.Colors.primaryTeal
                        ) {
                            // Handle contact support
                        }
                        
                        HelpActionCard(
                            title: "Video Tutorials",
                            subtitle: "Learn how to use Movefully effectively",
                            icon: "play.rectangle",
                            color: MovefullyTheme.Colors.gentleBlue
                        ) {
                            // Handle video tutorials
                        }
                        
                        HelpActionCard(
                            title: "Community Forum",
                            subtitle: "Connect with other trainers and share tips",
                            icon: "person.3",
                            color: MovefullyTheme.Colors.lavender
                        ) {
                            // Handle community forum
                        }
                    }
                    
                    // FAQ Section
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Frequently Asked Questions")
                            .font(MovefullyTheme.Typography.title3)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        VStack(spacing: MovefullyTheme.Layout.paddingS) {
                            FAQItem(
                                question: "How do I invite my first client?",
                                answer: "Navigate to the Clients tab and tap the 'Invite' button. You can send invitations via email or generate a shareable link."
                            )
                            
                            FAQItem(
                                question: "Can I customize workout plans?",
                                answer: "Yes! You can create custom plans in the Plans tab, selecting specific exercises and adjusting difficulty levels for each client."
                            )
                            
                            FAQItem(
                                question: "How do I track client progress?",
                                answer: "Client progress is automatically tracked. Visit any client's profile to see their workout history, streaks, and achievements."
                            )
                            
                            FAQItem(
                                question: "Is my data secure?",
                                answer: "Absolutely. We use industry-standard encryption and never share your personal data with third parties."
                            )
                        }
                    }
                    
                    // Contact Info
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Still need help?")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        VStack(spacing: MovefullyTheme.Layout.paddingS) {
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                Text("support@movefully.app")
                                    .font(MovefullyTheme.Typography.body)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            }
                            
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                Text("help.movefully.app")
                                    .font(MovefullyTheme.Typography.body)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            }
                        }
                    }
                    .padding(MovefullyTheme.Layout.paddingL)
                    .background(MovefullyTheme.Colors.primaryTeal.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
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

struct HelpActionCard: View {
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

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            
            if isExpanded {
                Text(answer)
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .lineLimit(nil)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(MovefullyTheme.Layout.paddingL)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 2, x: 0, y: 1)
    }
}

struct ShareProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var shareableLink = "https://movefully.app/trainer/sarah-chen"
    @State private var showingQRCode = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Header
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Share Your Profile")
                            .font(MovefullyTheme.Typography.title2)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Help others discover your wellness expertise")
                            .font(MovefullyTheme.Typography.body)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                    
                    // Profile Preview
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        Circle()
                            .fill(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            )
                        
                        VStack(spacing: MovefullyTheme.Layout.paddingS) {
                            Text("Sarah Chen")
                                .font(MovefullyTheme.Typography.title3)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Text("Movement Coach • San Francisco, CA")
                                .font(MovefullyTheme.Typography.callout)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                            
                            Text("Passionate movement coach dedicated to helping clients discover joy in their wellness journey.")
                                .font(MovefullyTheme.Typography.body)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                        }
                    }
                    .padding(MovefullyTheme.Layout.paddingL)
                    .background(MovefullyTheme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                    .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
                    
                    // Share Options
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        ShareOptionCard(
                            title: "Copy Profile Link",
                            subtitle: "Share your profile URL directly",
                            icon: "link",
                            color: MovefullyTheme.Colors.primaryTeal
                        ) {
                            UIPasteboard.general.string = shareableLink
                        }
                        
                        ShareOptionCard(
                            title: "Generate QR Code",
                            subtitle: "Create a QR code for easy sharing",
                            icon: "qrcode",
                            color: MovefullyTheme.Colors.gentleBlue
                        ) {
                            showingQRCode = true
                        }
                        
                        ShareOptionCard(
                            title: "Share via Social Media",
                            subtitle: "Post to your social platforms",
                            icon: "share",
                            color: MovefullyTheme.Colors.lavender
                        ) {
                            // Handle social sharing
                        }
                        
                        ShareOptionCard(
                            title: "Email Introduction",
                            subtitle: "Send a professional introduction email",
                            icon: "envelope.badge",
                            color: MovefullyTheme.Colors.warmOrange
                        ) {
                            // Handle email introduction
                        }
                    }
                    
                    // Shareable Link Preview
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        Text("Your Profile Link")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        HStack {
                            Text(shareableLink)
                                .font(MovefullyTheme.Typography.callout)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Button("Copy") {
                                UIPasteboard.general.string = shareableLink
                            }
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                            .padding(.vertical, MovefullyTheme.Layout.paddingS)
                            .background(MovefullyTheme.Colors.primaryTeal.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
                        }
                    }
                    .padding(MovefullyTheme.Layout.paddingL)
                    .background(MovefullyTheme.Colors.primaryTeal.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
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
        .sheet(isPresented: $showingQRCode) {
            QRCodeView(content: shareableLink)
        }
    }
}

struct ShareOptionCard: View {
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

struct QRCodeView: View {
    let content: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                Spacer()
                
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    Text("QR Code")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Text("Scan to view profile")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
                
                // QR Code placeholder
                Rectangle()
                    .fill(MovefullyTheme.Colors.cardBackground)
                    .frame(width: 200, height: 200)
                    .overlay(
                        Image(systemName: "qrcode")
                            .font(.system(size: 120))
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal.opacity(0.3))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                    .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 8, x: 0, y: 4)
                
                Button("Save to Photos") {
                    // Handle save to photos
                }
                .movefullyButtonStyle(.primary)
                .frame(maxWidth: 200)
                
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
        }
    }
}

#Preview {
    TrainerProfileView()
} 