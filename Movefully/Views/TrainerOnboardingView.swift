import SwiftUI
import FirebaseAuth

struct TrainerOnboardingView: View {
    @StateObject private var viewModel = TrainerOnboardingViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: MovefullyTheme.Layout.paddingL) {
                // Header
                VStack(spacing: MovefullyTheme.Layout.paddingM) {
                    Text("Tell Us About Yourself, Coach!")
                        .font(MovefullyTheme.Typography.title1)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Help us create your trainer profile so you can start connecting with clients.")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, MovefullyTheme.Layout.paddingXL)
                
                // Form Card
                MovefullyCard {
                    VStack(spacing: MovefullyTheme.Layout.paddingL) {
                        // Full Name Field
                        MovefullyFormField(title: "Full Name", isRequired: true) {
                            VStack(spacing: MovefullyTheme.Layout.paddingXS) {
                                MovefullyTextField(
                                    placeholder: "Enter your full name",
                                    text: $viewModel.fullName,
                                    maxCharacters: viewModel.maxNameLength
                                )
                                
                                MovefullyCharacterCount(
                                    currentCount: viewModel.nameCharacterCount,
                                    maxCount: viewModel.maxNameLength
                                )
                                }
                        }
                        
                        // Coaching Bio Field
                        MovefullyFormField(
                            title: "Professional Bio",
                            subtitle: "Tell potential clients about your approach to wellness coaching",
                            isRequired: true
                        ) {
                            VStack(spacing: MovefullyTheme.Layout.paddingXS) {
                                MovefullyTextEditor(
                                    placeholder: "Share your coaching philosophy, experience, and what makes your approach unique...",
                                    text: $viewModel.coachingBio,
                                    minLines: 4,
                                    maxLines: 8,
                                    maxCharacters: viewModel.maxBioLength
                                )
                                
                                MovefullyCharacterCount(
                                    currentCount: viewModel.bioCharacterCount,
                                    maxCount: viewModel.maxBioLength
                                )
                            }
                        }
                        
                        // Error Message
                        if !viewModel.errorMessage.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(viewModel.errorMessage)
                                    .font(MovefullyTheme.Typography.callout)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding(MovefullyTheme.Layout.paddingM)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
                        }
                        
                        // Save Button
                        Button(action: saveProfile) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Complete Profile")
                                }
                            }
                        }
                        .movefullyButtonStyle(.primary)
                        .disabled(!viewModel.isFormValid || viewModel.isLoading)
                        .opacity(viewModel.isFormValid ? 1.0 : 0.6)
                    }
                }
                
                Spacer(minLength: MovefullyTheme.Layout.paddingXXL)
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
        }
        .movefullyBackground()
        .navigationBarHidden(true)
        .onReceive(viewModel.$profileCompleted) { completed in
            if completed {
                // Update the auth view model to reflect the completed onboarding
                // This will trigger navigation to the trainer dashboard
                dismiss()
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func saveProfile() {
        guard let user = Auth.auth().currentUser else {
            viewModel.errorMessage = "Authentication error. Please try again."
            return
        }
        
        let email = user.email ?? authViewModel.userEmail
        viewModel.saveTrainerProfile(userId: user.uid, email: email)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
} 