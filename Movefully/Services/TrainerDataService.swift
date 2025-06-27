import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine

@MainActor
class TrainerDataService: ObservableObject {
    static let shared = TrainerDataService()
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    @Published var trainerProfile: TrainerProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Statistics
    @Published var activeClientCount = 0
    @Published var totalProgramCount = 0
    
    // Computed property for easy access to showClientProfilePictures setting
    var shouldShowClientProfilePictures: Bool {
        trainerProfile?.showClientProfilePictures ?? true
    }
    
    private var currentTrainerId: String? {
        Auth.auth().currentUser?.uid
    }
    
    private init() {
        setupRealtimeListener()
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Real-time Profile Loading
    
    func refreshProfile() {
        setupRealtimeListener()
    }
    
    private func setupRealtimeListener() {
        guard let trainerId = currentTrainerId else {
            print("❌ TrainerDataService: No authenticated trainer found")
            return
        }
        
        // Don't setup multiple listeners for the same trainer
        if listener != nil {
            print("🔄 TrainerDataService: Listener already exists for trainer: \(trainerId)")
            return
        }
        
        print("✅ TrainerDataService: Setting up real-time listener for trainer: \(trainerId)")
        
        listener = db.collection("trainers").document(trainerId)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    if let error = error {
                        print("❌ TrainerDataService: Error fetching trainer profile: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let snapshot = snapshot, snapshot.exists else {
                        print("❌ TrainerDataService: Trainer profile not found - attempting to migrate from users collection")
                        Task {
                            await self?.createProfileFromUserData()
                        }
                        return
                    }
                    
                    do {
                        // Debug: Print raw data to see what we're trying to decode
                        if let data = snapshot.data() {
                            print("🔍 TrainerDataService: Raw profile data keys: \(Array(data.keys))")
                            print("🔍 TrainerDataService: Raw profile data: \(data)")
                        }
                        
                        var profile = try snapshot.data(as: TrainerProfile.self)
                        profile.id = snapshot.documentID
                        self?.trainerProfile = profile
                        print("✅ TrainerDataService: Trainer profile loaded successfully")
                    } catch {
                        print("❌ TrainerDataService: Error decoding trainer profile: \(error)")
                        
                        // Try manual decoding as fallback
                        if let data = snapshot.data() {
                            let manualProfile = TrainerProfile(
                                id: snapshot.documentID,
                                name: data["name"] as? String ?? "Trainer",
                                email: data["email"] as? String ?? "",
                                phoneNumber: data["phoneNumber"] as? String,
                                title: data["title"] as? String,
                                bio: data["bio"] as? String,
                                profileImageUrl: data["profileImageUrl"] as? String,
                                location: data["location"] as? String,
                                website: data["website"] as? String,
                                specialties: data["specialties"] as? [String],
                                yearsOfExperience: data["yearsOfExperience"] as? Int,
                                createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
                                updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue()
                            )
                            self?.trainerProfile = manualProfile
                            print("✅ TrainerDataService: Trainer profile loaded via manual decoding")
                        } else {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        
        // Load statistics
        loadStatistics()
    }
    
    // MARK: - Statistics Calculation
    
    func loadStatistics() {
        guard let trainerId = currentTrainerId else { return }
        
        Task {
            do {
                // Load active client count
                let clientsSnapshot = try await db.collection("trainers")
                    .document(trainerId)
                    .collection("clients")
                    .whereField("status", isEqualTo: "active")
                    .getDocuments()
                
                await MainActor.run {
                    self.activeClientCount = clientsSnapshot.documents.count
                }
                
                // Load total program count
                let programsSnapshot = try await db.collection("programs")
                    .whereField("trainerId", isEqualTo: trainerId)
                    .getDocuments()
                
                await MainActor.run {
                    self.totalProgramCount = programsSnapshot.documents.count
                }
                
                print("✅ TrainerDataService: Statistics loaded - Clients: \(activeClientCount), Programs: \(totalProgramCount)")
                
            } catch {
                print("❌ TrainerDataService: Error loading statistics: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Profile Updates
    
    func updateTrainerProfile(_ profile: TrainerProfile) async throws {
        guard let trainerId = currentTrainerId else {
            throw NSError(domain: "TrainerDataService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("✅ TrainerDataService: Updating trainer profile")
        isLoading = true
        defer { isLoading = false }
        
        var updatedProfile = profile
        updatedProfile.updatedAt = Date()
        
        // Update in trainers collection
        try await db.collection("trainers").document(trainerId).setData(from: updatedProfile, merge: true)
        
        // Also update in users collection for consistency
        let userData: [String: Any] = [
            "name": profile.name,
            "bio": profile.bio ?? "",
            "updatedAt": Timestamp()
        ]
        
        try await db.collection("users").document(trainerId).updateData(userData)
        
        print("✅ TrainerDataService: Trainer profile updated successfully")
    }
    
    // MARK: - Helper Methods
    
    func createInitialProfile(name: String, email: String) async throws {
        guard let trainerId = currentTrainerId else {
            throw NSError(domain: "TrainerDataService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let newProfile = TrainerProfile(
            id: trainerId,
            name: name,
            email: email,
            phoneNumber: nil,
            bio: nil,
            profileImageUrl: nil,
            specialties: nil,
            yearsOfExperience: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await db.collection("trainers").document(trainerId).setData(from: newProfile)
        print("✅ TrainerDataService: Initial trainer profile created")
    }
    
    private func createProfileFromUserData() async {
        guard let trainerId = currentTrainerId else { return }
        
        do {
            // First, try to get existing data from users collection
            let userDoc = try await db.collection("users").document(trainerId).getDocument()
            
            var name = "Trainer"
            var email = ""
            var bio: String? = nil
            var title: String? = nil
            var location: String? = nil
            var phoneNumber: String? = nil
            var yearsOfExperience: Int? = nil
            var specialties: [String]? = nil
            
            if userDoc.exists, let userData = userDoc.data() {
                print("✅ TrainerDataService: Found existing user data, migrating to trainer profile")
                name = userData["name"] as? String ?? name
                email = userData["email"] as? String ?? email
                bio = userData["bio"] as? String
                title = userData["title"] as? String
                location = userData["location"] as? String
                phoneNumber = userData["phoneNumber"] as? String
                yearsOfExperience = userData["yearsOfExperience"] as? Int
                specialties = userData["specialties"] as? [String]
            } else {
                print("📝 TrainerDataService: No existing user data found, using Auth data")
                // Get user info from Auth
                let user = Auth.auth().currentUser
                name = user?.displayName ?? name
                email = user?.email ?? email
                bio = "Welcome to Movefully! Update your profile to get started."
            }
            
            let newProfile = TrainerProfile(
                id: trainerId,
                name: name,
                email: email,
                phoneNumber: phoneNumber,
                title: title,
                bio: bio,
                profileImageUrl: nil,
                location: location,
                website: nil,
                specialties: specialties,
                yearsOfExperience: yearsOfExperience,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await db.collection("trainers").document(trainerId).setData(from: newProfile)
            print("✅ TrainerDataService: Trainer profile created successfully")
            
            // The listener will automatically pick up this new profile
            
        } catch {
            print("❌ TrainerDataService: Error creating profile from user data: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Notification Settings
    
    func updateNotificationSettings(enabled: Bool, fcmToken: String?) async throws {
        guard let trainerId = currentTrainerId else {
            throw NSError(domain: "TrainerDataService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("✅ TrainerDataService: Updating notification settings - enabled: \(enabled)")
        isLoading = true
        defer { isLoading = false }
        
        let updateData: [String: Any] = [
            "notificationsEnabled": enabled,
            "fcmToken": fcmToken as Any,
            "updatedAt": Timestamp()
        ]
        
        // Update in trainers collection
        try await db.collection("trainers").document(trainerId).updateData(updateData)
        
        // Also update in users collection for consistency
        try await db.collection("users").document(trainerId).updateData(updateData)
        
        print("✅ TrainerDataService: Notification settings updated successfully")
    }
    
    // MARK: - Cache Management
    
    /// Clears all cached data - useful after account deletion or major data changes
    func clearCache() {
        trainerProfile = nil
        activeClientCount = 0
        totalProgramCount = 0
        errorMessage = nil
        print("✅ TrainerDataService: Cache cleared")
    }
} 