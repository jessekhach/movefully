# Movefully iOS App

A warm, client-first coaching app built with SwiftUI and Firebase that helps trainers guide clients through daily movement and wellness journeys.

## Overview

Movefully is a native iOS application designed to connect fitness trainers with their clients in a supportive, nurturing environment. The app emphasizes holistic wellness with a soft, warm design that appeals to users who value gentle guidance and community.

## Features

### ✨ Core Features
- **Apple Sign-In**: Frictionless authentication as the primary sign-in method
- **Firebase Authentication**: Secure Apple Sign-In integration with email/password as backup
- **Role-Based Experience**: Different dashboards for trainers and clients
- **Firestore Integration**: Real-time data synchronization
- **Warm UI Design**: Soft pastel tones, rounded corners, and gentle transitions

### 👨‍🏫 For Trainers
- Client management dashboard
- Program and workout plan creation
- Exercise library management
- Client communication and messaging
- Progress tracking and analytics

### 🏃‍♀️ For Clients
- Personalized workout plans
- Daily movement focus
- Progress tracking with visual goals
- Mindfulness and meditation features
- Direct messaging with trainers

## Technology Stack

- **Frontend**: SwiftUI (iOS 15.0+)
- **Authentication**: Apple Sign-In + Firebase Auth
- **Backend**: Firebase
  - Authentication (Apple Sign-In, Email/Password)
  - Firestore (Database)
  - Storage (Media assets)
- **Architecture**: MVVM with ObservableObject
- **Minimum iOS Version**: 15.0

## Project Structure

```
Movefully/
├── MovefullyApp.swift              # App entry point
├── ContentView.swift               # Main navigation controller
├── Movefully.entitlements          # Apple Sign-In entitlements
├── ViewModels/
│   └── AuthenticationViewModel.swift  # Handles Apple Sign-In + Firebase
├── Views/
│   ├── AuthenticationView.swift    # Apple Sign-In primary, email secondary
│   ├── RoleSelectionView.swift     # Beautiful role selection
│   ├── TrainerDashboardView.swift  # Professional trainer interface
│   └── ClientDashboardView.swift   # Motivating client interface
├── Assets.xcassets/
├── GoogleService-Info.plist        # Firebase configuration
└── Preview Content/
```

## Authentication Flow

### Primary: Apple Sign-In (Recommended)
1. **Launch**: App checks for existing authentication
2. **Apple Sign-In**: One-tap authentication with Face ID/Touch ID
3. **Firebase Integration**: Apple ID token exchanges for Firebase auth
4. **Role Selection**: New users choose trainer or client role
5. **Dashboard**: Navigate to role-specific dashboard

### Secondary: Email/Password
- Available as "Continue with Email" option
- Traditional sign-up/sign-in flow
- Same role selection and dashboard flow

### Authentication Persistence
- Authentication state persists across app launches
- Apple Sign-In provides seamless re-authentication
- Automatic token refresh through Firebase

## Firebase Configuration

The app uses Firebase for backend services with Apple Sign-In integration:

1. **GoogleService-Info.plist**: Contains Firebase project settings
2. **Apple Sign-In Provider**: Enabled in Firebase Authentication
3. **Environment Variables**: Located in `.env.local` and `.env.production`

### Firestore Database Structure

```
users/{userId} {
  "role": "trainer" | "client",
  "name": string,
  "email": string,
  "createdAt": timestamp
}
```

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 15.0+ deployment target
- Firebase project with Authentication and Firestore enabled
- Apple Developer Account (for Apple Sign-In)

### Installation

1. **Clone the repository**
   ```bash
   git clone [repository-url]
   cd movefully
   ```

2. **Open in Xcode**
   ```bash
   open Movefully.xcodeproj
   ```

3. **Firebase Setup**
   - Ensure `GoogleService-Info.plist` is included in the project
   - Verify Apple Sign-In is enabled in Firebase Console
   - Verify Firebase dependencies are resolved

4. **Apple Sign-In Configuration**
   - Ensure Apple Sign-In capability is enabled in Xcode
   - `Movefully.entitlements` should include Apple Sign-In entitlement
   - Bundle identifier should match Firebase and Apple Developer settings

5. **Build and Run**
   - Select a simulator or device
   - Press `Cmd + R` to build and run

### Firebase Dependencies

The project uses Swift Package Manager for Firebase:
- FirebaseAuth (Authentication with Apple Sign-In)
- FirebaseFirestore (Database)
- FirebaseStorage (File storage)

## Design Philosophy

### Authentication Experience
- **Frictionless**: Apple Sign-In reduces signup barriers
- **Privacy-First**: Users can hide email with Apple Sign-In
- **Fallback Available**: Email/password for users who prefer it
- **Secure**: Industry-standard authentication with biometric protection

### Visual Design
- **Warm & Welcoming**: Soft pastels and gentle gradients
- **Rounded Corners**: Friendly, approachable interface elements
- **Smooth Transitions**: Gentle animations and spring physics
- **Accessibility**: High contrast options and readable fonts

### User Experience
- **Trainer-Focused**: Professional tools for client management
- **Client-Centered**: Motivating and supportive journey tracking
- **Role-Specific**: Tailored experiences based on user type
- **Intuitive Navigation**: Clear, simple user flows

## Development Notes

### Key Components

1. **AuthenticationViewModel**: 
   - Manages Apple Sign-In and email/password authentication
   - Handles Firebase token exchange
   - Manages auth state and Firestore operations

2. **ContentView**: Routes users based on authentication and role

3. **AuthenticationView**: 
   - Prominent Apple Sign-In button
   - Secondary email/password option
   - Smooth transitions between auth methods

4. **Role Selection**: Beautiful card-based interface for role choice

5. **Dashboards**: Rich, feature-specific home screens

### Apple Sign-In Integration

- **Security**: Uses secure nonce and SHA256 hashing
- **Privacy**: Supports private email relay from Apple
- **User Experience**: One-tap sign-in with biometric authentication
- **Firebase Integration**: Seamless token exchange for backend services

### Firebase Security

- Authentication required for all Firestore operations
- User data isolated by authenticated user ID
- Role-based access control through Firestore rules
- Apple Sign-In tokens validated server-side

## Future Enhancements

- [ ] Workout plan creation and management
- [ ] Real-time messaging between trainers and clients
- [ ] Progress photo upload and tracking
- [ ] Push notifications for workouts and check-ins
- [ ] Apple Health integration
- [ ] Sign In with Apple for tvOS (Apple TV workouts)
- [ ] Offline mode capabilities

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is proprietary and confidential. All rights reserved.

## Support

For questions or support, please contact the development team.

---

Built with ❤️ for the wellness community 