import SwiftUI
import Combine

@MainActor
class OnboardingCoordinator: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var selectedPath: UserPath? = nil
    @Published var hasCompletedOnboarding: Bool = false
    @Published var showAuthentication: Bool = false
    @Published var profileSetupCurrentPage: Int = 0
    
    // Profile data storage
    @Published var trainerProfileData: TrainerProfileData?
    @Published var clientProfileData: ClientProfileData?
    
    // Temporary storage for profile data during onboarding
    private var tempTrainerData: TrainerProfileData?
    private var tempClientData: ClientProfileData?
    
    // Temporary form data storage to persist across navigation
    @Published var tempTrainerName: String = ""
    @Published var tempProfessionalTitle: String = ""
    @Published var tempSelectedSpecialties: Set<String> = []
    @Published var tempYearsOfExperience: Int = 0
    @Published var tempBio: String = ""
    @Published var tempLocation: String = ""
    @Published var tempPhoneNumber: String = ""
    @Published var tempWebsite: String = ""
    
    @Published var tempClientName: String = ""
    @Published var tempFitnessLevel: String = "Beginner"
    @Published var tempSelectedGoals: Set<String> = []
    
    enum OnboardingStep: CaseIterable {
        case welcome
        case features
        case profileSetup
        case authentication
        case complete
        
        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .features: return "Features"
            case .profileSetup: return "Profile Setup"
            case .authentication: return "Create Account"
            case .complete: return "Complete"
            }
        }
    }
    
    enum UserPath: String, CaseIterable {
        case trainer = "trainer"
        case client = "client"
        
        var displayName: String {
            switch self {
            case .trainer:
                return "Wellness Coach"
            case .client:
                return "Client"
            }
        }
    }
    
    // Computed property for ProfileSetupView compatibility
    var selectedUserType: UserPath? {
        return selectedPath
    }
    
    // Legacy support for existing role-based code
    var selectedRole: UserRole? {
        guard let path = selectedPath else { return nil }
        switch path {
        case .trainer: return .trainer
        case .client: return .client
        }
    }
    
    enum UserRole: String, CaseIterable {
        case trainer = "trainer"
        case client = "client"
        
        var displayName: String {
            switch self {
            case .client:
                return "I seek gentle guidance"
            case .trainer:
                return "I guide others mindfully"
            }
        }
        
        var description: String {
            switch self {
            case .client:
                return "Connect with a certified wellness coach"
            case .trainer:
                return "Support others through mindful movement"
            }
        }
        
        var detailedDescription: String {
            switch self {
            case .client:
                return "Receive personalized support for your wellness journey without judgment or pressure"
            case .trainer:
                return "Guide clients with gentle, evidence-based wellness practices that honor every body"
            }
        }
    }
    
    init() {
        // Check if user has completed onboarding before
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    // MARK: - Navigation Methods
    
    func selectTrainerPath() {
        selectedPath = .trainer
        nextStep()
    }
    
    func selectClientPath() {
        selectedPath = .client
        nextStep()
    }
    
    func nextStep() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            switch currentStep {
            case .welcome:
                // Clients skip features screen and go directly to profile setup
                if selectedPath == .client {
                    currentStep = .profileSetup
                } else {
                    currentStep = .features
                }
            case .features:
                currentStep = .profileSetup
            case .profileSetup:
                currentStep = .authentication
            case .authentication:
                currentStep = .complete
            case .complete:
                completeOnboarding()
            }
        }
    }
    
    func previousStep() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            switch currentStep {
            case .welcome:
                // Can't go back from welcome
                break
            case .features:
                currentStep = .welcome
                selectedPath = nil // Reset path selection
                // Clear profile data when going back
                trainerProfileData = nil
                clientProfileData = nil
                clearTempFormData()
                profileSetupCurrentPage = 0
            case .profileSetup:
                // Clients skip features, so go back to welcome
                if selectedPath == .client {
                    currentStep = .welcome
                    selectedPath = nil // Reset path selection
                    // Clear profile data when going back
                    trainerProfileData = nil
                    clientProfileData = nil
                    clearTempFormData()
                } else {
                    currentStep = .features
                }
                profileSetupCurrentPage = 0 // Reset to first page when returning
            case .authentication:
                currentStep = .profileSetup
            case .complete:
                currentStep = .authentication
            }
        }
    }
    
    func skipToAuthentication() {
        currentStep = .authentication
        showAuthentication = true
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    // Legacy methods for backward compatibility
    func selectRole(_ role: UserRole) {
        switch role {
        case .trainer:
            selectedPath = .trainer
        case .client:
            selectedPath = .client
        }
    }
    
    // MARK: - Profile Data Storage
    
    func storeTrainerData(name: String, title: String, specialties: [String], yearsOfExperience: Int, bio: String?, location: String?, phoneNumber: String?, website: String?) {
        tempTrainerData = TrainerProfileData(
            name: name,
            title: title,
            specialties: specialties,
            yearsOfExperience: yearsOfExperience,
            bio: bio,
            location: location,
            phoneNumber: phoneNumber,
            website: website
        )
    }
    
    func storeClientData(name: String, fitnessLevel: String, goals: [String]) {
        tempClientData = ClientProfileData(
            name: name,
            fitnessLevel: fitnessLevel,
            goals: goals
        )
    }
    
    func getStoredTrainerData() -> TrainerProfileData? {
        return tempTrainerData
    }
    
    func getStoredClientData() -> ClientProfileData? {
        return tempClientData
    }
    
    // MARK: - Profile Data Access
    
    func getTrainerProfileForCreation() -> TrainerProfileData? {
        return tempTrainerData ?? trainerProfileData
    }
    
    func getClientProfileForCreation() -> ClientProfileData? {
        return tempClientData ?? clientProfileData
    }
    
    func getProfileForCreation() -> Any? {
        if let trainerData = getStoredTrainerData() {
            return trainerData
        }
        if let clientData = getStoredClientData() {
            return clientData
        }
        // Fallback to temp data if needed
        if !tempTrainerName.isEmpty {
            return TrainerProfileData(name: tempTrainerName, title: tempProfessionalTitle, specialties: Array(tempSelectedSpecialties), yearsOfExperience: tempYearsOfExperience, bio: tempBio, location: tempLocation, phoneNumber: tempPhoneNumber, website: tempWebsite)
        }
        if !tempClientName.isEmpty {
            return ClientProfileData(name: tempClientName, fitnessLevel: tempFitnessLevel, goals: Array(tempSelectedGoals))
        }
        return nil
    }
    
    func clearProfileData() {
        trainerProfileData = nil
        clientProfileData = nil
        tempTrainerData = nil
        tempClientData = nil
        clearTempFormData()
    }
    
    func clearTempFormData() {
        // Clear trainer temp data
        tempTrainerName = ""
        tempProfessionalTitle = ""
        tempSelectedSpecialties = []
        tempYearsOfExperience = 0
        tempBio = ""
        tempLocation = ""
        tempPhoneNumber = ""
        tempWebsite = ""
        
        // Clear client temp data
        tempClientName = ""
        tempFitnessLevel = "Beginner"
        tempSelectedGoals = []
    }
}

// MARK: - Data Transfer Objects

struct TrainerProfileData {
    let name: String
    let title: String
    let specialties: [String]
    let yearsOfExperience: Int
    let bio: String?
    let location: String?
    let phoneNumber: String?
    let website: String?
}

struct ClientProfileData {
    let name: String
    let fitnessLevel: String
    let goals: [String]
} 