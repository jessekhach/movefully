import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class TrainerOnboardingViewModel: ObservableObject {
    @Published var fullName: String = ""
    @Published var coachingBio: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var profileCompleted: Bool = false
    
    private let db = Firestore.firestore()
    
    func saveTrainerProfile(userId: String, email: String) {
        // Validation
        guard !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter your full name"
            return
        }
        
        guard !coachingBio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please share a bit about your coaching philosophy"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        // Prepare trainer profile data
        let trainerData: [String: Any] = [
            "name": fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            "bio": coachingBio.trimmingCharacters(in: .whitespacesAndNewlines),
            "email": email,
            "role": "trainer",
            "createdAt": Timestamp(),
            "updatedAt": Timestamp(),
            "profileCompleted": true
        ]
        
        print("💾 Saving trainer profile for user: \(userId)")
        print("📝 Profile data: \(trainerData)")
        
        // Save to Firestore
        db.collection("users").document(userId).setData(trainerData, merge: true) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Error saving trainer profile: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to save profile: \(error.localizedDescription)"
                } else {
                    print("✅ Trainer profile saved successfully")
                    self?.profileCompleted = true
                }
            }
        }
        
        // Also create a document in the trainers collection for easier querying
        let trainersData: [String: Any] = [
            "userId": userId,
            "name": fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            "email": email,
            "bio": coachingBio.trimmingCharacters(in: .whitespacesAndNewlines),
            "createdAt": Timestamp(),
            "updatedAt": Timestamp()
        ]
        
        db.collection("trainers").document(userId).setData(trainersData, merge: true) { error in
            if let error = error {
                print("❌ Error saving to trainers collection: \(error.localizedDescription)")
            } else {
                print("✅ Trainer document created in trainers collection")
            }
        }
    }
    
    func clearForm() {
        fullName = ""
        coachingBio = ""
        errorMessage = ""
        profileCompleted = false
    }
    
    // Validation helpers
    var isFormValid: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !coachingBio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var nameCharacterCount: Int {
        fullName.count
    }
    
    var bioCharacterCount: Int {
        coachingBio.count
    }
    
    let maxBioLength = 500
    let maxNameLength = 50
} 