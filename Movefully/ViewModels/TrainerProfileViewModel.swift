import Foundation
import SwiftUI
import UIKit
import MessageUI
import PhotosUI
import FirebaseStorage
import Combine

@MainActor
class TrainerProfileViewModel: ObservableObject {
    @Published var trainerDataService = TrainerDataService.shared
    @Published var showingEditProfile = false
    @Published var showingSettings = false
    @Published var showingHelpSupport = false
    @Published var showingSpecialtySelection = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Profile Picture Upload
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var isUploadingPhoto = false
    
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
    let minSpecialties = 2
    
    // Settings
    @Published var notificationsEnabled = true
    @Published var selectedTheme: ThemeOption = .system
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Ensure TrainerDataService is properly initialized
        refreshProfileData()
        loadSettings()
        
        // Listen for photo selection changes
        $selectedPhoto
            .compactMap { $0 }
            .sink { [weak self] photo in
                Task {
                    await self?.uploadProfilePhoto(photo)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Profile Management
    
    func refreshProfileData() {
        trainerDataService.refreshProfile()
    }
    
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
        print("🔍 TrainerProfileViewModel: startEditingProfile called, profile exists: \(trainerProfile != nil)")
        
        // If profile isn't loaded yet, refresh and try again
        if trainerProfile == nil {
            print("🔄 TrainerProfileViewModel: Profile not loaded, refreshing...")
            refreshProfileData()
            // Give it a moment to load, then try again
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if self.trainerProfile != nil {
                    print("✅ TrainerProfileViewModel: Profile loaded after refresh, retrying edit")
                    self.startEditingProfile()
                } else {
                    print("❌ TrainerProfileViewModel: Profile still not loaded after refresh")
                }
            }
            return
        }
        
        guard let profile = trainerProfile else { 
            print("❌ TrainerProfileViewModel: No profile available for editing")
            return 
        }
        
        print("✅ TrainerProfileViewModel: Starting profile edit with data: \(profile.name)")
        
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
        if !profileSpecialties.contains(specialty) && profileSpecialties.count < maxSpecialties {
            profileSpecialties.append(specialty)
        }
    }
    
    func removeSpecialty(_ specialty: String) {
        // Only allow removal if we have more than the minimum required
        if profileSpecialties.count > minSpecialties {
            profileSpecialties.removeAll { $0 == specialty }
        }
    }
    
    // MARK: - Settings Management
    
    func loadSettings() {
        // Load notification setting from profile or default to true
        notificationsEnabled = trainerProfile?.notificationsEnabled ?? true
        
        // Load other local settings
        if let themeRaw = UserDefaults.standard.object(forKey: "selectedTheme") as? String,
           let theme = ThemeOption(rawValue: themeRaw) {
            selectedTheme = theme
        }
    }
    
    func saveSettings() async {
        // Save notification settings to Firebase
        do {
            let fcmToken = trainerProfile?.fcmToken
            try await trainerDataService.updateNotificationSettings(enabled: notificationsEnabled, fcmToken: fcmToken)
        } catch {
            print("❌ TrainerProfileViewModel: Error saving notification settings: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        // Save other local settings
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
    
    // MARK: - Profile Picture Upload
    
    func uploadProfilePhoto(_ photo: PhotosPickerItem) async {
        print("🔄 TrainerProfileViewModel: Starting profile photo upload")
        isUploadingPhoto = true
        
        do {
            print("🔄 TrainerProfileViewModel: Loading image data from PhotosPicker")
            // Load the image data
            guard let imageData = try await photo.loadTransferable(type: Data.self) else {
                print("❌ TrainerProfileViewModel: Failed to load image data from PhotosPicker")
                await MainActor.run {
                    isUploadingPhoto = false
                    errorMessage = "Failed to load image data"
                }
                return
            }
            
            print("✅ TrainerProfileViewModel: Image data loaded successfully, size: \(imageData.count) bytes")
            
            guard let trainerId = trainerProfile?.id else {
                print("❌ TrainerProfileViewModel: No trainer profile found")
                await MainActor.run {
                    isUploadingPhoto = false
                    errorMessage = "No trainer profile found"
                }
                return
            }
            
            print("🔄 TrainerProfileViewModel: Uploading profile photo for trainer: \(trainerId)")
            
            // Compress the image data to reduce storage costs and upload time
            print("🔄 TrainerProfileViewModel: Starting image compression...")
            let compressedImageData = compressImageData(imageData, maxSizeKB: 500) // Max 500KB
            print("✅ TrainerProfileViewModel: Image compression completed")
            
            // Create a reference to Firebase Storage
            let storage = Storage.storage()
            let storageRef = storage.reference()
            
            // Use the same pattern as client profile images
            let profileImageRef = storageRef.child("profile_images/trainers/\(trainerId).jpg")
            print("🔄 TrainerProfileViewModel: Firebase Storage reference created: profile_images/trainers/\(trainerId).jpg")
            
            // Upload the compressed image
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            print("🔄 TrainerProfileViewModel: Starting Firebase Storage upload...")
            do {
                let _ = try await profileImageRef.putDataAsync(compressedImageData, metadata: metadata)
                print("✅ TrainerProfileViewModel: Firebase Storage upload completed")
            } catch {
                print("❌ TrainerProfileViewModel: Firebase Storage upload failed: \(error)")
                print("🔄 TrainerProfileViewModel: Trying alternative upload approach...")
                
                // Try with a different path structure
                let alternativeRef = storageRef.child("profile_images/\(trainerId).jpg")
                print("🔄 TrainerProfileViewModel: Trying alternative path: profile_images/\(trainerId).jpg")
                
                do {
                    let _ = try await alternativeRef.putDataAsync(compressedImageData, metadata: metadata)
                    print("✅ TrainerProfileViewModel: Alternative upload succeeded")
                    
                    // Update the reference to use the successful path
                    let downloadURL = try await alternativeRef.downloadURL()
                    print("✅ TrainerProfileViewModel: Download URL obtained from alternative path: \(downloadURL.absoluteString)")
                    
                    // Update the trainer profile with the new image URL
                    guard var updatedProfile = trainerProfile else {
                        print("❌ TrainerProfileViewModel: Failed to get current profile for update")
                        await MainActor.run {
                            isUploadingPhoto = false
                            errorMessage = "Failed to get current profile"
                        }
                        return
                    }
                    
                    updatedProfile.profileImageUrl = downloadURL.absoluteString
                    print("🔄 TrainerProfileViewModel: Updating trainer profile with new image URL")
                    
                    // Save the updated trainer profile
                    try await trainerDataService.updateTrainerProfile(updatedProfile)
                    print("✅ TrainerProfileViewModel: Trainer profile updated successfully")
                    
                    await MainActor.run {
                        isUploadingPhoto = false
                        selectedPhoto = nil
                        print("✅ TrainerProfileViewModel: Profile photo upload process completed successfully")
                    }
                    return
                    
                } catch {
                    print("❌ TrainerProfileViewModel: Alternative upload also failed: \(error)")
                    throw error
                }
            }
            
            // Get the download URL
            print("🔄 TrainerProfileViewModel: Getting download URL...")
            let downloadURL = try await profileImageRef.downloadURL()
            print("✅ TrainerProfileViewModel: Download URL obtained: \(downloadURL.absoluteString)")
            
            // Update the trainer profile with the new image URL
            guard var updatedProfile = trainerProfile else {
                print("❌ TrainerProfileViewModel: Failed to get current profile for update")
                await MainActor.run {
                    isUploadingPhoto = false
                    errorMessage = "Failed to get current profile"
                }
                return
            }
            
            updatedProfile.profileImageUrl = downloadURL.absoluteString
            print("🔄 TrainerProfileViewModel: Updating trainer profile with new image URL")
            
            // Save the updated trainer profile
            try await trainerDataService.updateTrainerProfile(updatedProfile)
            print("✅ TrainerProfileViewModel: Trainer profile updated successfully")
            
            await MainActor.run {
                isUploadingPhoto = false
                selectedPhoto = nil
                print("✅ TrainerProfileViewModel: Profile photo upload process completed successfully")
            }
            
        } catch {
            await MainActor.run {
                isUploadingPhoto = false
                selectedPhoto = nil
                errorMessage = "Failed to upload profile photo: \(error.localizedDescription)"
                print("❌ TrainerProfileViewModel: Failed to upload profile photo: \(error)")
            }
        }
    }
    
    /// Compresses image data to reduce file size for storage efficiency
    private func compressImageData(_ imageData: Data, maxSizeKB: Int) -> Data {
        guard let image = UIImage(data: imageData) else {
            print("⚠️ TrainerProfileViewModel: Could not create UIImage from data, returning original")
            return imageData
        }
        
        let maxSizeBytes = maxSizeKB * 1024
        var compressionQuality: CGFloat = 1.0
        var compressedData = imageData
        
        // If the image is already small enough, return it
        if imageData.count <= maxSizeBytes {
            print("✅ TrainerProfileViewModel: Image already under size limit (\(imageData.count) bytes)")
            return imageData
        }
        
        // Resize image if it's too large (max 1024x1024 for profile pictures)
        let resizedImage = resizeImage(image, targetSize: CGSize(width: 1024, height: 1024))
        
        // Start with high quality and reduce until we hit our size target
        repeat {
            if let data = resizedImage.jpegData(compressionQuality: compressionQuality) {
                compressedData = data
                if data.count <= maxSizeBytes {
                    break
                }
            }
            compressionQuality -= 0.1
        } while compressionQuality > 0.1
        
        let originalSizeKB = imageData.count / 1024
        let compressedSizeKB = compressedData.count / 1024
        print("✅ TrainerProfileViewModel: Image compressed from \(originalSizeKB)KB to \(compressedSizeKB)KB")
        
        return compressedData
    }
    
    /// Resizes an image while maintaining aspect ratio
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        // Choose the smaller ratio to ensure the image fits within the target size
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
    
    /// Deletes the trainer's profile picture from Firebase Storage
    func deleteProfilePicture() async throws {
        guard let trainerId = trainerProfile?.id else {
            throw NSError(domain: "TrainerProfileViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No trainer profile found"])
        }
        
        // Delete from Firebase Storage
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profile_images/trainers/\(trainerId).jpg")
        
        do {
            try await profileImageRef.delete()
            print("✅ TrainerProfileViewModel: Profile picture deleted from storage")
        } catch {
            // If the file doesn't exist, that's fine - we just want to make sure it's gone
            print("⚠️ TrainerProfileViewModel: Profile picture may not exist in storage: \(error)")
        }
        
        // Update the trainer profile to remove the image URL
        guard var updatedProfile = trainerProfile else {
            throw NSError(domain: "TrainerProfileViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get current profile"])
        }
        
        updatedProfile.profileImageUrl = nil
        try await trainerDataService.updateTrainerProfile(updatedProfile)
        
        print("✅ TrainerProfileViewModel: Profile picture URL removed from profile")
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