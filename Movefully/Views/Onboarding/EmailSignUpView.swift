import SwiftUI

struct EmailSignUpView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @Environment(\.presentationMode) var presentationMode
    
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                Text("Create with Email")
                    .font(MovefullyTheme.Typography.title1)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .padding(.top, MovefullyTheme.Layout.paddingL)

                Text("We'll create your account and get you started.")
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, MovefullyTheme.Layout.paddingL)
                
                MovefullyTextField(
                    placeholder: "Full Name",
                    text: $fullName,
                    icon: "person.fill"
                )
                
                MovefullyTextField(
                    placeholder: "Email",
                    text: $email,
                    icon: "envelope.fill",
                    keyboardType: .emailAddress
                )
                
                MovefullySecureField(
                    placeholder: "Password (8+ characters)",
                    text: $password,
                    icon: "lock.fill"
                )
                
                if let errorMessage = authViewModel.errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(MovefullyTheme.Colors.warmOrange)
                        .font(MovefullyTheme.Typography.caption)
                        .padding(.top)
                }
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
        }
        .background(MovefullyTheme.Colors.backgroundPrimary.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: handleEmailSignUp) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Account & Continue")
                    }
                }
                .buttonStyle(MovefullyPrimaryButtonStyle())
                .disabled(!isFormValid() || authViewModel.isLoading)
                .padding()
            }
        }
        .onAppear(perform: prefillName)
    }
    
    private func isFormValid() -> Bool {
        return !fullName.isEmpty && !email.isEmpty && password.count >= 8
    }
    
    private func prefillName() {
        if let trainerData = coordinator.getStoredTrainerData() {
            self.fullName = trainerData.name
        } else if let clientData = coordinator.getStoredClientData() {
            self.fullName = clientData.name
        } else if !coordinator.tempTrainerName.isEmpty {
            self.fullName = coordinator.tempTrainerName
        } else if !coordinator.tempClientName.isEmpty {
            self.fullName = coordinator.tempClientName
        }
        authViewModel.errorMessage = nil
    }
    
    private func handleEmailSignUp() {
        let profileData = coordinator.getProfileForCreation()
        authViewModel.signUp(
            email: email,
            password: password,
            fullName: fullName,
            profileData: profileData
        ) { result in
            switch result {
            case .success:
                coordinator.nextStep()
            case .failure:
                // Error is handled by the authViewModel's errorMessage property
                break
            }
        }
    }
}

#if DEBUG
struct EmailSignUpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EmailSignUpView()
                .environmentObject(AuthenticationViewModel())
                .environmentObject(OnboardingCoordinator())
        }
    }
}
#endif 