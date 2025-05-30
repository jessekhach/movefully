# Movefully iOS App

A warm, client-first coaching app built with SwiftUI and Firebase that helps trainers guide clients through daily movement and wellness journeys.

## Overview

Movefully is a native iOS application designed to connect fitness trainers with their clients in a supportive, nurturing environment. The app emphasizes holistic wellness with a soft, warm design that appeals to users who value gentle guidance and community.

## Features

### ✨ Core Features
- **Firebase Authentication**: Secure email/password authentication
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
- **Backend**: Firebase
  - Authentication (Email/Password)
  - Firestore (Database)
  - Storage (Media assets)
- **Architecture**: MVVM with ObservableObject
- **Minimum iOS Version**: 15.0

## Project Structure

```
Movefully/
├── MovefullyApp.swift          # App entry point
├── ContentView.swift           # Main navigation controller
├── ViewModels/
│   └── AuthenticationViewModel.swift
├── Views/
│   ├── AuthenticationView.swift
│   ├── RoleSelectionView.swift
│   ├── TrainerDashboardView.swift
│   └── ClientDashboardView.swift
├── Assets.xcassets/
├── GoogleService-Info.plist    # Firebase configuration
└── Preview Content/
```

## Firebase Configuration

The app uses Firebase for backend services. Configuration is handled through:

1. **GoogleService-Info.plist**: Contains Firebase project settings
2. **Environment Variables**: Located in `.env.local` and `.env.production`

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
   - Verify Firebase dependencies are resolved

4. **Build and Run**
   - Select a simulator or device
   - Press `Cmd + R` to build and run

### Firebase Dependencies

The project uses Swift Package Manager for Firebase:
- FirebaseAuth (Authentication)
- FirebaseFirestore (Database)
- FirebaseStorage (File storage)

## Authentication Flow

1. **Launch**: App checks for existing authentication
2. **Sign In/Up**: Users authenticate with email/password
3. **Role Selection**: New users choose trainer or client role
4. **Dashboard**: Navigate to role-specific dashboard
5. **Persistence**: Authentication state persists across app launches

## Design Philosophy

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

1. **AuthenticationViewModel**: Manages auth state and Firestore operations
2. **ContentView**: Routes users based on authentication and role
3. **Role Selection**: Beautiful card-based interface for role choice
4. **Dashboards**: Rich, feature-specific home screens

### Firebase Security

- Authentication required for all Firestore operations
- User data isolated by authenticated user ID
- Role-based access control through Firestore rules

## Future Enhancements

- [ ] Workout plan creation and management
- [ ] Real-time messaging between trainers and clients
- [ ] Progress photo upload and tracking
- [ ] Push notifications for workouts and check-ins
- [ ] Apple Health integration
- [ ] Apple Sign-In support
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