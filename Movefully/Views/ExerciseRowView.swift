import SwiftUI

struct ExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            // Exercise category icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: exercise.category?.icon ?? "figure.walk")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(categoryColor)
            }
            
            // Exercise info
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                Text(exercise.title)
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                if let description = exercise.description {
                    Text(description)
                        .font(MovefullyTheme.Typography.callout)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(2)
                }
                
                // Tags
                HStack(spacing: MovefullyTheme.Layout.paddingS) {
                    // Duration
                    if let duration = exercise.duration {
                        ExerciseTagView(
                            text: "\(duration) min",
                            icon: "clock",
                            color: MovefullyTheme.Colors.primaryTeal
                        )
                    }
                    
                    // Difficulty
                    if let difficulty = exercise.difficulty {
                        ExerciseTagView(
                            text: difficulty.rawValue,
                            icon: "star.fill",
                            color: difficultyColor(for: difficulty)
                        )
                    }
                }
            }
            
            Spacer()
            
            // Navigation indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(MovefullyTheme.Colors.inactive)
        }
        .padding(MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 4, x: 0, y: 2)
    }
    
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
            return MovefullyTheme.Colors.success
        }
    }
    
    private func difficultyColor(for difficulty: DifficultyLevel) -> Color {
        switch difficulty {
        case .beginner:
            return MovefullyTheme.Colors.softGreen
        case .intermediate:
            return MovefullyTheme.Colors.primaryTeal
        case .advanced:
            return MovefullyTheme.Colors.warmOrange
        }
    }
}

// MARK: - Supporting Views

struct ExerciseTagView: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingXS) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
            
            Text(text)
                .font(MovefullyTheme.Typography.caption)
        }
        .foregroundColor(color)
        .padding(.horizontal, MovefullyTheme.Layout.paddingS)
        .padding(.vertical, MovefullyTheme.Layout.paddingXS)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
    }
} 