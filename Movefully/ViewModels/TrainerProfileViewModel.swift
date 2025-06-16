import Foundation
import SwiftUI
import UIKit
import MessageUI

@MainActor
class TrainerProfileViewModel: ObservableObject {
    @Published var trainerDataService = TrainerDataService.shared
    @Published var showingEditProfile = false
    @Published var showingSettings = false
    @Published var showingHelpSupport = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Edit Profile Form
    @Published var editingProfile: TrainerProfile?
    @Published var profileName = ""
    @Published var profileTitle = ""
    @Published var profileBio = ""
    @Published var profileLocation = ""
    @Published var profileWebsite = ""
    @Published var profileEmail = ""
    @Published var profilePhoneNumber = ""
    @Published var profileYearsExperience = ""
    @Published var profileSpecialties: [String] = []
    
    // Character limits
    let titleCharacterLimit = 60
    let locationCharacterLimit = 50
    let bioCharacterLimit = 300
    
    // Specialty limits
    let maxSpecialties = 8
    
    // Settings
    @Published var notificationsEnabled = true
    @Published var emailUpdates = true
    @Published var biometricAuth = true
    @Published var dataSharing = false
    @Published var selectedTheme: ThemeOption = .system
    
    init() {
        loadSettings()
    }
    
    // MARK: - Profile Management
    
    var trainerProfile: TrainerProfile? {
        trainerDataService.trainerProfile
    }
    
    var activeClientCount: Int {
        trainerDataService.activeClientCount
    }
    
    var totalProgramCount: Int {
        trainerDataService.totalProgramCount
    }
    
    var yearsExperienceText: String {
        if let years = trainerProfile?.yearsOfExperience {
            return "\(years)y"
        }
        return "0y"
    }
    
    func startEditingProfile() {
        guard let profile = trainerProfile else { return }
        
        editingProfile = profile
        profileName = profile.name
        profileTitle = profile.title ?? "Wellness Coach & Movement Specialist"
        profileBio = profile.bio ?? ""
        profileLocation = profile.location ?? ""
        profileWebsite = profile.website ?? ""
        profileEmail = profile.email
        profilePhoneNumber = profile.phoneNumber ?? ""
        profileYearsExperience = profile.yearsOfExperience?.description ?? ""
        profileSpecialties = profile.specialties ?? []
        
        showingEditProfile = true
    }
    
    func saveProfile() async {
        guard var profile = editingProfile else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Update profile with form data
            profile.name = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.title = profileTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : profileTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.bio = profileBio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : profileBio.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.location = profileLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : profileLocation.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.website = profileWebsite.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : profileWebsite.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.email = profileEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.phoneNumber = profilePhoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : profilePhoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.specialties = profileSpecialties.isEmpty ? nil : profileSpecialties
            
            if let yearsInt = Int(profileYearsExperience.trimmingCharacters(in: .whitespacesAndNewlines)), yearsInt > 0 {
                profile.yearsOfExperience = yearsInt
            } else {
                profile.yearsOfExperience = nil
            }
            
            try await trainerDataService.updateTrainerProfile(profile)
            
            await MainActor.run {
                self.showingEditProfile = false
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func addSpecialty(_ specialty: String) {
        let trimmed = specialty.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !profileSpecialties.contains(trimmed) {
            profileSpecialties.append(trimmed)
        }
    }
    
    func removeSpecialty(_ specialty: String) {
        profileSpecialties.removeAll { $0 == specialty }
    }
    
    // MARK: - Settings Management
    
    func loadSettings() {
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        emailUpdates = UserDefaults.standard.bool(forKey: "emailUpdates")
        biometricAuth = UserDefaults.standard.bool(forKey: "biometricAuth")
        dataSharing = UserDefaults.standard.bool(forKey: "dataSharing")
        
        if let themeRaw = UserDefaults.standard.object(forKey: "selectedTheme") as? String,
           let theme = ThemeOption(rawValue: themeRaw) {
            selectedTheme = theme
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(emailUpdates, forKey: "emailUpdates")
        UserDefaults.standard.set(biometricAuth, forKey: "biometricAuth")
        UserDefaults.standard.set(dataSharing, forKey: "dataSharing")
        UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
    }
    
    // MARK: - Help & Support Actions
    
    func openContactSupport() {
        if MFMailComposeViewController.canSendMail() {
            // Will be handled by the view
        } else {
            // Fallback: open mail app with mailto URL
            if let url = URL(string: "mailto:support@movefully.com") {
                UIApplication.shared.open(url)
            }
        }
    }
    
    func openVideoTutorials() {
        if let url = URL(string: "https://help.movefully.app/tutorials") {
            UIApplication.shared.open(url)
        }
    }
    
    func openCommunityForum() {
        if let url = URL(string: "https://community.movefully.app") {
            UIApplication.shared.open(url)
        }
    }
    
    func openPrivacyPolicy() {
        if let url = URL(string: "https://movefully.app/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    func openTermsOfService() {
        if let url = URL(string: "https://movefully.app/terms") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Theme Option Enum

enum ThemeOption: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
} 