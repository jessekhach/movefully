import SwiftUI
import Foundation

// MARK: - Comprehensive Exercise Detail View
struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    @State private var showingVideoPlayer = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) {
                    // Demo video/GIF section - now at the top and prominent
                    demoMediaSection
                    
                    // Step-by-step instructions with embedded muscle targets
                    instructionsWithMuscleTargetsSection
                    
                    // Tips and modifications
                    tipsAndModificationsSection
                    
                    Spacer(minLength: MovefullyTheme.Layout.paddingXXL)
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                .padding(.top, MovefullyTheme.Layout.paddingL)
            }
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationTitle(exercise.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                }
            }
        }
        .sheet(isPresented: $showingVideoPlayer) {
            if let mediaUrl = exercise.mediaUrl {
                VideoPlayerView(url: mediaUrl)
            }
        }
    }
    
    // MARK: - Enhanced Demo Media Section
    private var demoMediaSection: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingM) {
            // Video/GIF preview
            Button {
                if exercise.mediaUrl != nil {
                    showingVideoPlayer = true
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                        .fill(
                            LinearGradient(
                                colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 220)
                        .overlay(
                            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                                .stroke(categoryColor.opacity(0.3), lineWidth: 2)
                        )
                    
                    VStack(spacing: MovefullyTheme.Layout.paddingM) {
                        // Category icon
                        ZStack {
                            Circle()
                                .fill(categoryColor)
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: exercise.category?.icon ?? "figure.walk")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        if exercise.mediaUrl != nil {
                            // Play button overlay
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.9))
                                    .frame(width: 50, height: 50)
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                
                                Image(systemName: "play.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(categoryColor)
                            }
                            
                            Text("Tap to watch demonstration")
                                .font(MovefullyTheme.Typography.callout)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        } else {
                            Text("Exercise Demonstration")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Quick exercise info with muscle targets (removed duration)
            HStack(spacing: MovefullyTheme.Layout.paddingL) {
                // Difficulty badge
                if let difficulty = exercise.difficulty {
                    VStack(spacing: MovefullyTheme.Layout.paddingXS) {
                        Text("Difficulty")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        
                        MovefullyStatusBadge(
                            text: difficulty.rawValue,
                            color: difficultyColor,
                            showDot: false
                        )
                    }
                }
                
                Spacer()
                
                // Muscle targets
                VStack(spacing: MovefullyTheme.Layout.paddingXS) {
                    Text("Target Muscles")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    
                    HStack(spacing: MovefullyTheme.Layout.paddingXS) {
                        Image(systemName: "target")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        
                        Text(primaryMuscles)
                            .font(MovefullyTheme.Typography.callout)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Instructions with Embedded Muscle Targets Section
    private var instructionsWithMuscleTargetsSection: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingL) {
                // Section header
                HStack {
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                        Text("How to Perform")
                            .font(MovefullyTheme.Typography.title3)
                            .foregroundColor(MovefullyTheme.Colors.textPrimary)
                        
                        Text("Follow these steps for proper form")
                            .font(MovefullyTheme.Typography.caption)
                            .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
                
                // Step-by-step instructions
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                    ForEach(Array(exerciseInstructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: MovefullyTheme.Layout.paddingM) {
                            // Step number
                            Text("\(index + 1)")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(
                                    LinearGradient(
                                        colors: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.primaryTeal.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                            
                            // Instruction text
                            Text(instruction)
                                .font(MovefullyTheme.Typography.body)
                                .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                .lineLimit(nil)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Enhanced Tips and Modifications Section
    private var tipsAndModificationsSection: some View {
        MovefullyCard {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingL) {
                // Section header
                Text("Tips & Modifications")
                    .font(MovefullyTheme.Typography.title3)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingL) {
                    // Pro Tips
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        HStack(spacing: MovefullyTheme.Layout.paddingS) {
                            ZStack {
                                Circle()
                                    .fill(MovefullyTheme.Colors.warmOrange.opacity(0.2))
                                    .frame(width: 28, height: 28)
                                
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(MovefullyTheme.Colors.warmOrange)
                            }
                            
                            Text("Pro Tips")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            ForEach(exerciseTips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: MovefullyTheme.Layout.paddingS) {
                                    Circle()
                                        .fill(MovefullyTheme.Colors.warmOrange)
                                        .frame(width: 4, height: 4)
                                        .padding(.top, 8)
                                    
                                    Text(tip)
                                        .font(MovefullyTheme.Typography.callout)
                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                        .lineLimit(nil)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    Divider()
                        .background(MovefullyTheme.Colors.divider)
                    
                    // Modifications
                    VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
                        HStack(spacing: MovefullyTheme.Layout.paddingS) {
                            ZStack {
                                Circle()
                                    .fill(MovefullyTheme.Colors.gentleBlue.opacity(0.2))
                                    .frame(width: 28, height: 28)
                                
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(MovefullyTheme.Colors.gentleBlue)
                            }
                            
                            Text("Modifications")
                                .font(MovefullyTheme.Typography.bodyMedium)
                                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                            ForEach(exerciseModifications, id: \.self) { modification in
                                HStack(alignment: .top, spacing: MovefullyTheme.Layout.paddingS) {
                                    Circle()
                                        .fill(MovefullyTheme.Colors.gentleBlue)
                                        .frame(width: 4, height: 4)
                                        .padding(.top, 8)
                                    
                                    Text(modification)
                                        .font(MovefullyTheme.Typography.callout)
                                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                                        .lineLimit(nil)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var categoryColor: Color {
        guard let category = exercise.category else {
            return MovefullyTheme.Colors.primaryTeal
        }
        
        switch category {
        case .strength:
            return Color(red: 0.8, green: 0.4, blue: 0.4) // Warm red
        case .cardio:
            return Color(red: 0.4, green: 0.7, blue: 0.9) // Sky blue
        case .flexibility:
            return MovefullyTheme.Colors.secondaryPeach
        case .balance:
            return Color(red: 0.7, green: 0.5, blue: 0.9) // Lavender
        case .mindfulness:
            return MovefullyTheme.Colors.softGreen
        }
    }
    
    private var difficultyColor: Color {
        guard let difficulty = exercise.difficulty else {
            return MovefullyTheme.Colors.primaryTeal
        }
        
        switch difficulty {
        case .beginner:
            return MovefullyTheme.Colors.softGreen
        case .intermediate:
            return MovefullyTheme.Colors.primaryTeal
        case .advanced:
            return MovefullyTheme.Colors.warmOrange
        }
    }
    
    // MARK: - Dynamic Exercise Data
    private var exerciseInstructions: [String] {
        // Use the new howToPerform field from the Exercise model
        return exercise.howToPerform ?? [
            "Begin in the starting position as demonstrated",
            "Perform the movement with controlled, deliberate form",
            "Focus on proper breathing throughout the exercise",
            "Complete the movement through its full range of motion"
        ]
    }
    
    private var exerciseTips: [String] {
        // Use the new trainerTips field from the Exercise model
        return exercise.trainerTips ?? [
            "Quality of movement is more important than quantity",
            "Listen to your body and rest when you feel fatigue",
            "Maintain steady breathing throughout the exercise"
        ]
    }
    
    private var exerciseModifications: [String] {
        // Use the new modifications field from the Exercise model
        return exercise.modifications ?? [
            "Reduce range of motion if you experience discomfort",
            "Use assistance or support as needed for your fitness level",
            "Adjust intensity by modifying duration or resistance"
        ]
    }

    private var primaryMuscles: String {
        // Use the new targetMuscles field from the Exercise model
        if let targetMuscles = exercise.targetMuscles, !targetMuscles.isEmpty {
            return targetMuscles.joined(separator: ", ")
        }
        
        // Fallback to the existing logic if targetMuscles is not available
        switch exercise.title.lowercased() {
        case let title where title.contains("push"):
            return "Chest, Shoulders, Triceps"
        case let title where title.contains("squat"):
            return "Quads, Glutes, Hamstrings"
        case let title where title.contains("plank"):
            return "Core, Shoulders"
        case let title where title.contains("lunge"):
            return "Quads, Glutes, Calves"
        case let title where title.contains("deadlift"):
            return "Hamstrings, Glutes, Back"
        case let title where title.contains("row"):
            return "Back, Biceps"
        case let title where title.contains("press"):
            return "Shoulders, Triceps"
        default:
            return exercise.category?.rawValue.capitalized ?? "Full Body"
        }
    }
}

// MARK: - Supporting Views

struct ExerciseStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        MovefullyCard {
            VStack(spacing: MovefullyTheme.Layout.paddingS) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.0)
                
                Text(value)
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .lineLimit(1)
            }
        }
    }
}

struct ExerciseSpecRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            Image(systemName: icon)
                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                .frame(width: 20)
            
            Text(title)
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
        }
    }
}

struct VideoPlayerView: View {
    let url: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Placeholder for video player
                VStack {
                    Text("Video Player")
                        .font(MovefullyTheme.Typography.title2)
                        .foregroundColor(.white)
                    
                    Text("Demo video would play here")
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("URL: \(url)")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    ExerciseDetailView(exercise: Exercise.sampleExercises[0])
} 