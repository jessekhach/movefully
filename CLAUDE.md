# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Movefully is a native iOS fitness coaching app built with SwiftUI and Firebase. It connects trainers with clients through a warm, client-first interface that emphasizes holistic wellness.

## Common Commands

### iOS Development
```bash
# Build and run the iOS app
open Movefully.xcodeproj  # Open in Xcode, then Cmd+R to build and run

# Clean build folder
# In Xcode: Product > Clean Build Folder (Cmd+Shift+K)
```

### Firebase Backend
```bash
# Start Firebase emulators for local development
cd functions && firebase emulators:start

# Deploy Firebase functions
cd functions && npm run deploy

# View Firebase function logs
cd functions && npm run logs

# Lint Firebase functions
cd functions && npm run lint
```

### Firebase Functions Development
```bash
# Install dependencies
cd functions && npm install

# Start local development server
cd functions && npm run serve

# Deploy to production
cd functions && firebase deploy --only functions
```

## Architecture

### Core Structure
- **MVVM Pattern**: Views → ViewModels → Services → Models
- **SwiftUI**: Declarative UI with iOS 18.0+ target
- **Firebase Backend**: Authentication, Firestore database, Cloud Functions
- **Role-Based**: Separate experiences for trainers and clients

### Key Directories
- `Movefully/ViewModels/` - Business logic and state management (12+ files)
- `Movefully/Views/` - SwiftUI views including onboarding flow (30+ files)  
- `Movefully/Services/` - Business services layer (21+ files)
- `Movefully/Models/` - Data models and structures
- `Movefully/Theme/` - Design system (colors, typography, components)
- `functions/` - Node.js Cloud Functions backend

### Authentication Flow
1. **Primary**: Apple Sign-In with biometric authentication
2. **Secondary**: Email/password authentication
3. **Firebase Integration**: Secure token exchange
4. **Role Selection**: Users choose trainer or client role after signup

### Data Architecture
- **Firebase Firestore**: Real-time NoSQL database
- **Local Caching**: Multiple specialized cache services
- **Service Layer**: 21 specialized services handle business logic:
  - Client management (data, deletion, progress tracking)
  - Workout management (assignment, caching, sessions)
  - Communication (messages, invitations, alerts)
  - Exercise library and program templates

### Design System
- **MovefullyTheme.swift**: Centralized design tokens
- **Warm Aesthetic**: Soft pastels, rounded corners, gentle transitions
- **Dark/Light Mode**: System-aware theme management
- **Role-Specific UI**: Different dashboards for trainers vs clients

## Development Workflow

### iOS Development
1. Open `Movefully.xcodeproj` in Xcode 15.0+
2. Ensure Firebase dependencies are resolved via Swift Package Manager
3. Verify `GoogleService-Info.plist` is included in project
4. Build and run with Cmd+R

### Firebase Development  
1. Navigate to `functions/` directory
2. Install dependencies: `npm install`
3. Start emulators: `firebase emulators:start`
4. Deploy functions: `npm run deploy`

### Key Configuration Files
- `GoogleService-Info.plist` - Firebase project configuration
- `Movefully.entitlements` - Apple Sign-In entitlements
- `firebase.json` - Firebase hosting and functions configuration
- `Info.plist` - Custom URL scheme (`movefully://`) for deep linking

## Firebase Integration

### Authentication
- Apple Sign-In as primary method with biometric support
- Email/password as secondary option
- Secure token exchange between Apple and Firebase
- Role-based access control through Firestore security rules

### Database Structure
```
users/{userId} {
  "role": "trainer" | "client",
  "name": string,
  "email": string,
  "createdAt": timestamp
}
```

### Cloud Functions
- Node.js 18 runtime
- Located in `functions/` directory
- Handles backend business logic and API endpoints
- Supports Firebase emulator for local development

## Testing and Quality

### iOS Testing
- Use Xcode's built-in testing framework
- Run tests with Cmd+U in Xcode
- No external testing dependencies configured

### Firebase Functions Testing
- Use Firebase emulators for local testing
- Lint with: `cd functions && npm run lint`
- No explicit test framework configured

## Deployment

### iOS App
- Distributed via App Store or TestFlight
- Requires Apple Developer Account for signing
- Automatic code signing configured in Xcode

### Firebase Backend
- Functions deployed to Google Cloud
- Web hosting via Firebase Hosting
- Deploy with: `cd functions && npm run deploy`

## Dependencies

### iOS (Swift Package Manager)
- Firebase iOS SDK v10.29.0
  - FirebaseAuth (Apple Sign-In integration)
  - FirebaseFirestore (real-time database)
  - FirebaseStorage (file uploads)

### Firebase Functions (npm)
- firebase-admin: ^12.1.0
- firebase-functions: ^5.0.0
- eslint: ^8.15.0 (development)