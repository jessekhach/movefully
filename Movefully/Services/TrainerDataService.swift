import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

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
                        print("❌ TrainerDataService: Trainer profile not found - creating default profile")
                        self?.createDefaultProfile()
                        return
                    }
                    
                    do {
                        var profile = try snapshot.data(as: TrainerProfile.self)
                        profile.id = snapshot.documentID
                        self?.trainerProfile = profile
                        print("✅ TrainerDataService: Trainer profile loaded successfully")
                    } catch {
                        print("❌ TrainerDataService: Error decoding trainer profile: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
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
    
    private func createDefaultProfile() {
        guard let trainerId = currentTrainerId else { return }
        
        Task {
            do {
                // Get user info from Auth
                let user = Auth.auth().currentUser
                let name = user?.displayName ?? "Trainer"
                let email = user?.email ?? ""
                
                let defaultProfile = TrainerProfile(
                    id: trainerId,
                    name: name,
                    email: email,
                    phoneNumber: nil,
                    bio: "Welcome to Movefully! Update your profile to get started.",
                    profileImageUrl: nil,
                    specialties: [],
                    yearsOfExperience: 0,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                try await db.collection("trainers").document(trainerId).setData(from: defaultProfile)
                print("✅ TrainerDataService: Default trainer profile created")
                
                // The listener will automatically pick up this new profile
                
            } catch {
                print("❌ TrainerDataService: Error creating default profile: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
} 