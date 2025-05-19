export interface User {
  id: string;
  email: string;
  displayName: string;
  role: 'trainer' | 'client';
  createdAt: Date;
  updatedAt: Date;
}

export interface Trainer extends User {
  role: 'trainer';
  clients: string[]; // Array of client IDs
  specialties?: string[];
  bio?: string;
}

export interface Client extends User {
  role: 'client';
  trainerId: string;
  goals?: string[];
  medicalHistory?: string;
  preferences?: {
    workoutDays?: string[];
    preferredTime?: string;
    equipment?: string[];
  };
}

export interface WorkoutPlan {
  id: string;
  trainerId: string;
  clientId: string;
  name: string;
  description?: string;
  exercises: Exercise[];
  createdAt: Date;
  updatedAt: Date;
  status: 'active' | 'completed' | 'archived';
}

export interface Exercise {
  id: string;
  name: string;
  sets: number;
  reps: number;
  weight?: number;
  duration?: number; // in seconds
  restTime?: number; // in seconds
  notes?: string;
  completed?: boolean;
}

export interface ChatMessage {
  id: string;
  senderId: string;
  receiverId: string;
  content: string;
  timestamp: Date;
  read: boolean;
} 