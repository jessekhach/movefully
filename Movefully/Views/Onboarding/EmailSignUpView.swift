import SwiftUI

struct EmailSignUpView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @Environment(\.presentationMode) var presentationMode
    
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    
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
                    text: $name,
                    iconName: "person"
                )
                
                MovefullyTextField(
                    placeholder: "Email",
                    text: $email,
                    iconName: "envelope"
                )
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                
                MovefullySecureField(
                    placeholder: "Password (8+ characters)",
                    text: $password,
                    iconName: "lock"
                )
                
                if let errorMessage = authViewModel.errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(MovefullyTheme.Colors.alert)
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
                MovefullyButton(
                    title: "Create Account & Continue",
                    action: handleEmailSignUp,
                    style: .primary,
                    isLoading: authViewModel.isLoading,
                    disabled: !isFormValid()
                )
                .padding()
            }
        }
        .onAppear(perform: prefillName)
    }
    
    private func isFormValid() -> Bool {
        return !name.isEmpty && !email.isEmpty && password.count >= 8
    }
    
    private func prefillName() {
        if let trainerData = coordinator.getStoredTrainerData() {
            self.name = trainerData.name
        } else if let clientData = coordinator.getStoredClientData() {
            self.name = clientData.name
        } else if !coordinator.tempTrainerName.isEmpty {
            self.name = coordinator.tempTrainerName
        } else if !coordinator.tempClientName.isEmpty {
            self.name = coordinator.tempClientName
        }
        authViewModel.errorMessage = nil
    }
    
    private func handleEmailSignUp() {
        let profileData = coordinator.getProfileForCreation()
        authViewModel.signUp(
            email: email,
            password: password,
            name: name,
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