# Movefully

Movefully is a personal training web application designed to help trainers manage their clients, focusing on making fitness simple, accessible, and focused on overall movement and well-being.

## Features (Phase 1)

- Client onboarding
- Text-based workout plan creation and assignment
- Workout completion tracking
- Two-way text chat between trainers and clients
- Multi-trainer support
- Progressive Web App (PWA) functionality

## Tech Stack

- Frontend: Next.js (App Router, React, TypeScript)
- Styling: Tailwind CSS
- Backend: Firebase (Firestore, Authentication)
- Hosting: Vercel

## Getting Started

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```
3. Create a `.env.local` file in the root directory with the following variables:
   ```
   NEXT_PUBLIC_FIREBASE_API_KEY=
   NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
   NEXT_PUBLIC_FIREBASE_PROJECT_ID=
   NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=
   NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=
   NEXT_PUBLIC_FIREBASE_APP_ID=
   ```
4. Run the development server:
   ```bash
   npm run dev
   ```

## Development

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint

## Security

- All Firebase configuration is handled through environment variables
- API keys and sensitive information are never committed to the repository
- Authentication is handled through Firebase Auth
- Data is secured through Firestore security rules

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request
