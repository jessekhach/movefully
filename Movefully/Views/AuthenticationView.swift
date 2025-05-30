import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showEmailSignIn = false
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Header with app branding
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Text("Movefully")
                            .font(.system(size: 42, weight: .light, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Your wellness journey starts here")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .frame(height: geometry.size.height * 0.35)
                    
                    // Authentication options
                    VStack(spacing: 24) {
                        // Apple Sign-In (Primary)
                        VStack(spacing: 16) {
                            SignInWithAppleButton(
                                onRequest: { request in
                                    // This is handled by the AuthenticationViewModel
                                },
                                onCompletion: { result in
                                    // This is handled by the AuthenticationViewModel
                                }
                            )
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .onTapGesture {
                                authViewModel.signInWithApple()
                            }
                            
                            Text("Continue with Apple for the fastest sign-in")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color(.systemGray4))
                                .frame(height: 1)
                            
                            Text("or")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            Rectangle()
                                .fill(Color(.systemGray4))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 32)
                        
                        // Email/Password option (Secondary)
                        if showEmailSignIn {
                            emailPasswordSection
                        } else {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showEmailSignIn = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "envelope")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Continue with Email")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color(.secondarySystemBackground))
                                .foregroundColor(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        
                        // Error message
                        if !authViewModel.errorMessage.isEmpty {
                            Text(authViewModel.errorMessage)
                                .foregroundColor(.red)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemPink).opacity(0.05),
                    Color(.systemPurple).opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private var emailPasswordSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 16) {
                if isSignUp {
                    CustomTextField(
                        placeholder: "Your name",
                        text: $name,
                        icon: "person"
                    )
                }
                
                CustomTextField(
                    placeholder: "Email",
                    text: $email,
                    icon: "envelope"
                )
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                
                CustomSecureField(
                    placeholder: "Password",
                    text: $password,
                    icon: "lock"
                )
                
                if isSignUp {
                    CustomSecureField(
                        placeholder: "Confirm password",
                        text: $confirmPassword,
                        icon: "lock"
                    )
                }
            }
            
            // Email/Password action button
            Button(action: {
                if isSignUp {
                    handleSignUp()
                } else {
                    authViewModel.signIn(email: email, password: password)
                }
            }) {
                HStack {
                    if authViewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [Color(.systemPink).opacity(0.8), Color(.systemPurple).opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(authViewModel.isLoading)
            
            // Toggle between sign in/sign up
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSignUp.toggle()
                    clearFields()
                }
            }) {
                HStack(spacing: 4) {
                    Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                        .foregroundColor(.secondary)
                    Text(isSignUp ? "Sign In" : "Sign Up")
                        .foregroundColor(Color(.systemPink))
                        .fontWeight(.semibold)
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .padding(.top, 8)
            
            // Back to Apple Sign-In
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showEmailSignIn = false
                    clearFields()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 12, weight: .medium))
                    Text("Back to Apple Sign-In")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
    }
    
    private func handleSignUp() {
        guard password == confirmPassword else {
            authViewModel.errorMessage = "Passwords don't match"
            return
        }
        
        guard password.count >= 6 else {
            authViewModel.errorMessage = "Password must be at least 6 characters"
            return
        }
        
        authViewModel.signUp(email: email, password: password, name: name)
    }
    
    private func clearFields() {
        email = ""
        password = ""
        confirmPassword = ""
        name = ""
        authViewModel.errorMessage = ""
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, design: .rounded))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            SecureField(placeholder, text: $text)
                .font(.system(size: 16, design: .rounded))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
} 