import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var clientViewModel = ClientViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @EnvironmentObject private var urlHandler: URLHandlingService
    
    var body: some View {
        ZStack {
        VStack {
            if authViewModel.isAuthenticated {
                    if authViewModel.userRole == nil && !urlHandler.isProcessingInvitation {
                    RoleSelectionView()
                        .environmentObject(authViewModel)
                        .environmentObject(themeManager)
                } else if authViewModel.userRole == "trainer" {
                    TrainerDashboardView()
                        .environmentObject(authViewModel)
                        .environmentObject(themeManager)
                } else {
                    // Check if client has been removed by trainer
                    if clientViewModel.currentClient?.status == .trainer_removed {
                        // Trainer Removed View - inline for now
                        NavigationStack {
                            VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                                Spacer()
                                
                                // Icon
                                Image(systemName: "person.crop.circle.badge.minus")
                                    .font(.system(size: 80))
                                    .foregroundColor(MovefullyTheme.Colors.warning)
                                
                                // Title
                                Text("Your trainer has removed you")
                                    .font(MovefullyTheme.Typography.title1)
                                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                                    .multilineTextAlignment(.center)
                                
                                // Message
                                Text("Please reach out to your trainer for more information.")
                                    .font(MovefullyTheme.Typography.body)
                                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                                
                                Spacer()
                                
                                // Acknowledge Button
                                Button(action: {
                                    // Client acknowledged removal - delete their data immediately
                                    Task {
                                        let deletionService = ClientDeletionService()
                                        try? await deletionService.deleteClientAccount()
                                        try? await authViewModel.signOut()
                                    }
                                }) {
                                    Text("I Understand")
                                        .font(MovefullyTheme.Typography.buttonMedium)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, MovefullyTheme.Layout.paddingM)
                                        .background(MovefullyTheme.Colors.warning)
                                        .cornerRadius(MovefullyTheme.Layout.cornerRadiusM)
                                }
                                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                                
                                Spacer()
                            }
                            .padding(MovefullyTheme.Layout.paddingL)
                            .navigationTitle("Account Status")
                            .navigationBarTitleDisplayMode(.inline)
                        }
                    } else {
                        ClientMainView(viewModel: clientViewModel)
                            .environmentObject(authViewModel)
                            .environmentObject(themeManager)
                    }
                }
            } else {
                AuthenticationView()
                    .environmentObject(authViewModel)
                    .environmentObject(themeManager)
            }
        }
        .onAppear {
            authViewModel.checkAuthenticationState()
            Task {
                print("🔄 [DEBUG] ContentView: Refreshing cache on appear (app launch)")
                await WorkoutDataCacheService.shared.refreshOnLaunch()
                await ProgressDataCacheService.shared.refreshOnLaunch()
            }
        }
        }
        .sheet(isPresented: $urlHandler.showInvitationAcceptance) {
            if let invitationId = urlHandler.pendingInvitationId {
                InvitationAcceptanceView(invitationId: invitationId)
                    .environmentObject(urlHandler)
                    .onAppear {
                        print("🎯 ContentView: InvitationAcceptanceView is appearing in sheet")
                        print("🎯 ContentView: Sheet is being presented with invitationId: \(invitationId)")
                    }
            } else {
                Text("Error: No invitation ID")
                    .onAppear {
                        print("🎯 ContentView: ERROR - Sheet presented but no invitationId")
                    }
            }
        }
        .onReceive(urlHandler.$showInvitationAcceptance) { showSheet in
            print("🎯 ContentView: showInvitationAcceptance changed to: \(showSheet)")
        }
        .onReceive(urlHandler.$pendingInvitationId) { invitationId in
            print("🎯 ContentView: pendingInvitationId changed to: \(invitationId ?? "nil")")
        }
        .onReceive(urlHandler.$isProcessingInvitation) { isProcessing in
            print("🎯 ContentView: isProcessingInvitation changed to: \(isProcessing)")
        }
    }
} 