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
                        // Title
                        VStack(spacing: 8) {
                            Text("Welcome to")
                                .font(.system(size: 28, weight: .light, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            Text("Movefully")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        
                        // Simulator warning banner
                        #if targetEnvironment(simulator)
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Running on Simulator")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.orange)
                            }
                            
                            Text("Apple Sign-In has limited support on simulator. Email/password is recommended for testing.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                        #endif
                        
                        // Apple Sign-In (Primary)
                        if AuthenticationViewModel.isSignInWithAppleAvailable {
                            VStack(spacing: 16) {
                                Button(action: {
                                    authViewModel.signInWithApple()
                                }) {
                                    HStack {
                                        if authViewModel.isLoading {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Image(systemName: "applelogo")
                                                .font(.title2)
                                            Text("Continue with Apple")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.black)
                                    .cornerRadius(12)
                                }
                                .disabled(authViewModel.isLoading)
                                
                                // Alternative Authentication Options
                                Text("OR")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)
                            }
                        } else {
                            // Message for when Sign in with Apple is not available
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Sign in with Apple")
                                            .font(.headline)
                                        Text("Requires a paid Apple Developer Program membership")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                
                                Text("Continue with alternative method")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        #if targetEnvironment(simulator)
                        // Test Account Button (Simulator only)
                        Button(action: {
                            authViewModel.signInWithTestAccount()
                        }) {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "flask")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Quick Test Account")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundColor(.white)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.red]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                        }
                        .disabled(authViewModel.isLoading)
                        #endif
                        
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
                                        .font(MovefullyTheme.Typography.buttonMedium)
                                    Text("Continue with Email")
                                        .font(MovefullyTheme.Typography.buttonMedium)
                                }
                            }
                            .movefullyButtonStyle(.secondary)
                        }
                        
                        // Error message
                        if !authViewModel.errorMessage.isEmpty {
                            MovefullyAlertBanner(
                                title: "Error",
                                message: authViewModel.errorMessage,
                                type: .error,
                                actionButton: nil
                            )
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
                    MovefullyTheme.Colors.backgroundPrimary,
                    MovefullyTheme.Colors.backgroundSecondary
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
                    MovefullyTextField(
                        placeholder: "Your name",
                        text: $name,
                        icon: "person",
                        autocapitalization: .words
                    )
                }
                
                MovefullyTextField(
                    placeholder: "Email",
                    text: $email,
                    icon: "envelope",
                    keyboardType: .emailAddress,
                    autocapitalization: .never,
                    disableAutocorrection: true
                )
                
                MovefullySecureField(
                    placeholder: "Password",
                    text: $password,
                    icon: "lock"
                )
                
                if isSignUp {
                    MovefullySecureField(
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
                        Text(isSignUp ? "Create Account" : "Sign In")
            }
            .movefullyButtonStyle(.primary)
            .disabled(email.isEmpty || password.isEmpty || (isSignUp && (confirmPassword.isEmpty || name.isEmpty)))
            
            // Toggle between sign in and sign up
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSignUp.toggle()
                    clearFields()
                }
            }) {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
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
                        .font(MovefullyTheme.Typography.caption)
                    Text("Back to Apple Sign-In")
                        .font(MovefullyTheme.Typography.callout)
                }
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
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
        MovefullyTextField(
            placeholder: placeholder,
            text: $text,
            icon: icon
        )
    }
}

struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        MovefullySecureField(
            placeholder: placeholder,
            text: $text,
            icon: icon
        )
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
} 