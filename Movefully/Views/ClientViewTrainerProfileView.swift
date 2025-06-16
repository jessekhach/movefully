import SwiftUI

// MARK: - Client View Trainer Profile (Read-Only)
/// A read-only version of the trainer profile that clients can view
/// Shows trainer information without any editing capabilities
struct ClientViewTrainerProfileView: View {
    let trainer: TrainerProfile
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with gradient background
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        // Profile photo and basic info
                        VStack(spacing: MovefullyTheme.Layout.paddingL) {
                            // Profile Picture (read-only)
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
                                
                                // Show trainer initials if no profile image
                                if let imageUrl = trainer.profileImageUrl, !imageUrl.isEmpty {
                                    AsyncImage(url: URL(string: imageUrl)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                    } placeholder: {
                                        Text(trainerInitials)
                                            .font(.system(size: 36, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                } else {
                                    Text(trainerInitials)
                                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Name and title
                            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                                Text(trainer.name)
                                    .font(MovefullyTheme.Typography.title1)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                
                                Text(trainer.title ?? trainer.bio ?? "Your Movement Coach")
                                    .font(MovefullyTheme.Typography.callout)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                
                                // Location and experience display
                                HStack(spacing: MovefullyTheme.Layout.paddingL) {
                                    if let location = trainer.location {
                                        HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                                            Image(systemName: "location.fill")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                            Text(location)
                                                .font(MovefullyTheme.Typography.caption)
                                                .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                        }
                                    }
                                    
                                    if let experience = trainer.yearsOfExperience {
                                        HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(MovefullyTheme.Colors.softGreen)
                                            Text("\(experience)y experience")
                                                .font(MovefullyTheme.Typography.caption)
                                                .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Quick stats (read-only)
                        HStack(spacing: MovefullyTheme.Layout.paddingL) {
                            if let experience = trainer.yearsOfExperience {
                                ClientViewTrainerStatView(title: "Experience", value: "\(experience)y", icon: "star.circle")
                            }
                            if let specialtyCount = trainer.specialties?.count {
                                ClientViewTrainerStatView(title: "Specialties", value: "\(specialtyCount)", icon: "sparkles")
                            }
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
                        // About section (read-only)
                        if let bio = trainer.bio, !bio.isEmpty {
                            ClientViewTrainerSectionCard(title: "About Your Coach", icon: "person.circle") {
                                HStack {
                                    Text(bio)
                                        .font(MovefullyTheme.Typography.body)
                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                        .lineLimit(nil)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                }
                            }
                        }
                        
                        // Specialties section (read-only)
                        if let specialties = trainer.specialties, !specialties.isEmpty {
                            ClientViewTrainerSectionCard(title: "Coach Specialties", icon: "sparkles") {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: MovefullyTheme.Layout.paddingM) {
                                    ForEach(specialties, id: \.self) { specialty in
                                        ClientViewSpecialtyTag(text: specialty)
                                    }
                                }
                            }
                        }
                        
                        // Contact info section (only show if contact info exists)
                        if hasContactInformation {
                            ClientViewTrainerSectionCard(title: "Contact Information", icon: "envelope.circle") {
                                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                                    if !trainer.email.isEmpty {
                                        HStack(spacing: MovefullyTheme.Layout.paddingM) {
                                            Image(systemName: "envelope.fill")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                                .frame(width: 24)
                                            
                                            Text(trainer.email)
                                                .font(MovefullyTheme.Typography.body)
                                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                            
                                            Spacer()
                                        }
                                    }
                                    
                                    if let phoneNumber = trainer.phoneNumber, !phoneNumber.isEmpty {
                                        HStack(spacing: MovefullyTheme.Layout.paddingM) {
                                            Image(systemName: "phone.fill")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                                .frame(width: 24)
                                            
                                            Text(phoneNumber)
                                                .font(MovefullyTheme.Typography.body)
                                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                            
                                            Spacer()
                                        }
                                    }
                                    
                                    Text("You can reach out to your coach anytime through the Messages tab or using the contact information above.")
                                        .font(MovefullyTheme.Typography.caption)
                                        .foregroundColor(MovefullyTheme.Colors.textTertiary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                    .padding(.vertical, MovefullyTheme.Layout.paddingL)
                }
            }
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationTitle("Your Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
    }
    
    // Helper computed properties
    private var trainerInitials: String {
        let components = trainer.name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }
        return initials.prefix(2).joined().uppercased()
    }
    
    private var hasContactInformation: Bool {
        let hasEmail = !trainer.email.isEmpty
        let hasPhone = !(trainer.phoneNumber?.isEmpty ?? true)
        return hasEmail || hasPhone
    }
}

// MARK: - Read-Only Supporting Views

struct ClientViewTrainerStatView: View {
    let title: String
    let value: String
    let icon: String
    @ObservedObject private var themeManager = ThemeManager.shared
    
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

struct ClientViewTrainerSectionCard<Content: View>: View {
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

struct ClientViewSpecialtyTag: View {
    let text: String
    @ObservedObject private var themeManager = ThemeManager.shared
    
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

#Preview {
    ClientViewTrainerProfileView(trainer: TrainerProfile(
        id: "trainer1",
        name: "Alex Martinez",
        email: "alex@movefully.com",
        phoneNumber: "(555) 123-4567",
        bio: "Certified movement coach specializing in mindful fitness and injury recovery. I believe every body is capable of beautiful movement.",
        profileImageUrl: nil,
        specialties: ["Mobility", "Recovery", "Mindful Movement", "Strength Training"],
        yearsOfExperience: 8
    ))
} 