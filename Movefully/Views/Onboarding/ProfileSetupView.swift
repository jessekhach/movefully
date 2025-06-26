import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @State private var animateContent = false
    
    
    // Use shared specialty list from constants
    private let availableSpecialties = MovefullyConstants.availableSpecialties
    
    // Fitness levels for clients
    private let fitnessLevels = ["Beginner", "Intermediate", "Advanced"]
    
    // Fitness goals enum - optimized for single-line display
    enum FitnessGoal: String, CaseIterable {
        case weightLoss = "Weight Loss"
        case muscleGain = "Muscle Gain"
        case endurance = "Endurance"
        case flexibility = "Flexibility"
        case strength = "Strength"
        case wellness = "Wellness"
        case recovery = "Recovery"
        
        var displayName: String { rawValue }
    }
    
    // Total pages based on user type
    private var totalPages: Int {
        coordinator.selectedPath == .trainer ? 3 : 2
    }
    
    var body: some View {
        MovefullyStandardNavigation(
            title: coordinator.selectedPath == .trainer ? "Trainer Profile" : "Client Profile",
            leadingButton: MovefullyStandardNavigation.ToolbarButton(
                icon: "chevron.left",
                action: { 
                    if coordinator.profileSetupCurrentPage > 0 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            coordinator.profileSetupCurrentPage -= 1
                        }
                    } else {
                        coordinator.previousStep()
                    }
                },
                accessibilityLabel: "Back"
            ),
            titleDisplayMode: .inline
        ) {
            ScrollView {
                // Using a ZStack for page transitions
                ZStack {
                    Group {
                        if coordinator.selectedPath == .trainer {
                            switch coordinator.profileSetupCurrentPage {
                            case 0: trainerBasicInfoPage
                            case 1: trainerSpecialtiesPage
                            case 2: trainerOptionalInfoPage
                            default: EmptyView()
                            }
                        } else {
                            switch coordinator.profileSetupCurrentPage {
                            case 0: clientBasicInfoPage
                            case 1: clientGoalsPage
                            default: EmptyView()
                            }
                        }
                    }
                    .padding(.top, MovefullyTheme.Layout.paddingL)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity))
                    )
                    .id(coordinator.profileSetupCurrentPage)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: coordinator.profileSetupCurrentPage)
            .movefullyBackground()
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    navigationButtonsSection
                }
            }
        }
        .onAppear {
            if !animateContent {
                withAnimation {
                    animateContent = true
                }
            }
        }
    }
    
    // MARK: - Trainer Pages
    
    private var trainerBasicInfoPage: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            // Header
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                Text("Basic Information")
                    .font(MovefullyTheme.Typography.title1)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Let's start with your basic details")
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.top, MovefullyTheme.Layout.paddingM)
            
            // Form
            MovefullyCard {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    MovefullyTextField(
                        placeholder: "Full name",
                        text: $coordinator.tempTrainerName
                    )
                    
                    MovefullyTextField(
                        placeholder: "Professional title (e.g., CPT)",
                        text: $coordinator.tempProfessionalTitle
                    )
                    
                    // Years of experience picker
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text("Years of Experience")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Picker("Years", selection: $coordinator.tempYearsOfExperience) {
                            ForEach(0..<31) { year in
                                Text(year == 0 ? "< 1 year" : "\(year) year\(year == 1 ? "" : "s")")
                                    .tag(year)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 120)
                        .clipped()
                    }
                }
                .padding(MovefullyTheme.Layout.paddingL)
            }
        }
    }
    
    private var trainerSpecialtiesPage: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            // Header
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                Text("Your Specialties")
                    .font(MovefullyTheme.Typography.title1)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Select at least 2 areas of expertise")
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.top, MovefullyTheme.Layout.paddingM)
            
            // Specialties grid
            MovefullyCard {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: MovefullyTheme.Layout.paddingS) {
                    ForEach(availableSpecialties, id: \.self) { specialty in
                        MovefullyPill(
                            title: specialty,
                            isSelected: coordinator.tempSelectedSpecialties.contains(specialty),
                            style: .filter,
                            action: {
                                if coordinator.tempSelectedSpecialties.contains(specialty) {
                                    coordinator.tempSelectedSpecialties.remove(specialty)
                                } else {
                                    coordinator.tempSelectedSpecialties.insert(specialty)
                                }
                            }
                        )
                        .lineLimit(2)
                    }
                }
                .padding(MovefullyTheme.Layout.paddingL)
            }
            
            // Selection count indicator
            HStack {
                Image(systemName: coordinator.tempSelectedSpecialties.count >= 2 ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(coordinator.tempSelectedSpecialties.count >= 2 ? MovefullyTheme.Colors.softGreen : MovefullyTheme.Colors.textSecondary)
                    .font(.system(size: 14))
                
                Text("\(coordinator.tempSelectedSpecialties.count) selected (minimum 2)")
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingM)
        }
    }
    
    private var trainerOptionalInfoPage: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            // Header
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                Text("Additional Details")
                    .font(MovefullyTheme.Typography.title1)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Optional information to help clients find you")
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.top, MovefullyTheme.Layout.paddingM)
            
            // Form
            MovefullyCard {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    MovefullyTextField(
                        placeholder: "Location (City, State)",
                        text: $coordinator.tempLocation
                    )
                    
                    MovefullyTextField(
                        placeholder: "Brief bio or specializations",
                        text: $coordinator.tempBio
                    )
                    
                    MovefullyTextField(
                        placeholder: "Phone number (optional)",
                        text: $coordinator.tempPhoneNumber
                    )
                    
                    MovefullyTextField(
                        placeholder: "Website (optional)",
                        text: $coordinator.tempWebsite
                    )
                }
                .padding(MovefullyTheme.Layout.paddingL)
            }
        }
    }
    
    // MARK: - Client Pages
    
    private var clientBasicInfoPage: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            // Header
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                Text("Tell Us About Yourself")
                    .font(MovefullyTheme.Typography.title1)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Help us personalize your fitness journey")
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.top, MovefullyTheme.Layout.paddingM)
            
            // Form
            MovefullyCard {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    MovefullyTextField(
                        placeholder: "Full name",
                        text: $coordinator.tempClientName
                    )
                    
                    Divider()
                    
                    // Fitness level section
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                        Text("Current Fitness Level")
                            .font(MovefullyTheme.Typography.bodyMedium)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        VStack(spacing: 0) {
                            ForEach(fitnessLevels, id: \.self) { level in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        coordinator.tempFitnessLevel = level
                                    }
                                }) {
                                    HStack {
                                        Text(level)
                                            .font(MovefullyTheme.Typography.body)
                                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                        Spacer()
                                        if coordinator.tempFitnessLevel == level {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                                .transition(.opacity.combined(with: .scale))
                                        }
                                    }
                                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                                }
                                if level != fitnessLevels.last {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .padding(MovefullyTheme.Layout.paddingL)
            }
            .movefullyShadow()
        }
    }
    
    private var clientGoalsPage: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            // Header
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                Text("Your Fitness Goals")
                    .font(MovefullyTheme.Typography.title1)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Select all that apply to you")
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.top, MovefullyTheme.Layout.paddingM)
            
            // Goals grid
            MovefullyCard {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: MovefullyTheme.Layout.paddingS) {
                    ForEach(FitnessGoal.allCases, id: \.self) { goal in
                        MovefullyPill(
                            title: goal.displayName,
                            isSelected: coordinator.tempSelectedGoals.contains(goal.rawValue),
                            style: .filter,
                            action: {
                                if coordinator.tempSelectedGoals.contains(goal.rawValue) {
                                    coordinator.tempSelectedGoals.remove(goal.rawValue)
                                } else {
                                    coordinator.tempSelectedGoals.insert(goal.rawValue)
                                }
                            }
                        )
                        .lineLimit(2)
                    }
                }
                .padding(MovefullyTheme.Layout.paddingL)
            }
            
            // Selection indicator
            HStack {
                Image(systemName: coordinator.tempSelectedGoals.isEmpty ? "circle" : "checkmark.circle.fill")
                    .foregroundColor(coordinator.tempSelectedGoals.isEmpty ? MovefullyTheme.Colors.textSecondary : MovefullyTheme.Colors.softGreen)
                    .font(.system(size: 14))
                
                Text("\(coordinator.tempSelectedGoals.count) selected")
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingM)
        }
    }
    
    // MARK: - Navigation
    
    private var navigationButtonsSection: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            // Main action button
            Button(action: {
                if coordinator.profileSetupCurrentPage < totalPages - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        coordinator.profileSetupCurrentPage += 1
                    }
                } else {
                    saveProfileData()
                    coordinator.nextStep()
                }
            }) {
                HStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Text(coordinator.profileSetupCurrentPage < totalPages - 1 ? "Next" : "Continue to Account Setup")
                    Image(systemName: "arrow.right")
                        .font(MovefullyTheme.Typography.buttonSmall)
                }
            }
            .buttonStyle(MovefullyPrimaryButtonStyle())
            .disabled(!canContinue)
            
            // Page indicators
            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == coordinator.profileSetupCurrentPage ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.divider)
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == coordinator.profileSetupCurrentPage ? 1.2 : 1.0)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: coordinator.profileSetupCurrentPage)
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
        .padding(.vertical, MovefullyTheme.Layout.paddingM)
    }
    
    private var canContinue: Bool {
        if coordinator.selectedPath == .trainer {
            switch coordinator.profileSetupCurrentPage {
            case 0:
                return !coordinator.tempTrainerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case 1:
                return coordinator.tempSelectedSpecialties.count >= 2
            case 2:
                return true // Optional page, always can continue
            default:
                return false
            }
        } else {
            switch coordinator.profileSetupCurrentPage {
            case 0:
                return !coordinator.tempClientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case 1:
                return true // Goals are optional
            default:
                return false
            }
        }
    }
    
    private func saveProfileData() {
        if coordinator.selectedPath == .trainer {
            // Store trainer data in coordinator for next step
            coordinator.storeTrainerData(
                name: coordinator.tempTrainerName.trimmingCharacters(in: .whitespacesAndNewlines),
                title: coordinator.tempProfessionalTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                specialties: Array(coordinator.tempSelectedSpecialties),
                yearsOfExperience: coordinator.tempYearsOfExperience,
                bio: coordinator.tempBio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : coordinator.tempBio.trimmingCharacters(in: .whitespacesAndNewlines),
                location: coordinator.tempLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : coordinator.tempLocation.trimmingCharacters(in: .whitespacesAndNewlines),
                phoneNumber: coordinator.tempPhoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : coordinator.tempPhoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                website: coordinator.tempWebsite.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : coordinator.tempWebsite.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        } else {
            // Store client data in coordinator for next step
            coordinator.storeClientData(
                name: coordinator.tempClientName.trimmingCharacters(in: .whitespacesAndNewlines),
                fitnessLevel: coordinator.tempFitnessLevel,
                goals: Array(coordinator.tempSelectedGoals)
            )
        }
    }
}

#Preview {
    NavigationView {
        ProfileSetupView()
            .environmentObject({
                let coordinator = OnboardingCoordinator()
                coordinator.selectedPath = .trainer
                return coordinator
            }())
    }
} 