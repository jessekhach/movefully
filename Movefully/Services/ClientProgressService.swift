import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ClientProgressService: ObservableObject {
    private let db = Firestore.firestore()
    
    // MARK: - Progress Data Models
    
    struct ProgressInsights {
        let workoutTrends: WorkoutTrends
        let recentMeasurements: [ProgressEntry]
        let achievements: [Achievement]
        let recentCompletions: [WorkoutCompletion]
    }
    
    struct WorkoutTrends {
        let averageRating: Double
        let averageDuration: Int
        let consistencyScore: Double
        let improvementTrend: String // "improving", "stable", "declining"
    }
    
    struct Achievement {
        let id: String
        let title: String
        let description: String
        let achievedDate: Date
        let category: String
        let icon: String
    }
    
    struct WorkoutCompletion {
        let id: String
        let workoutTitle: String
        let completedDate: Date
        let rating: Int
        let duration: Int
        let notes: String
    }
    
    // MARK: - Main Progress Fetch
    
    func fetchProgressInsights(for clientId: String) async throws -> ProgressInsights {
        print("📊 Fetching progress insights for client: \(clientId)")
        
        async let workoutTrends = fetchWorkoutTrends(for: clientId)
        async let recentMeasurements = fetchRecentMeasurements(for: clientId)
        async let achievements = fetchRecentAchievements(for: clientId)
        async let recentCompletions = fetchRecentWorkoutCompletions(for: clientId)
        
        let (trends, measurements, achievementsList, completions) = try await (workoutTrends, recentMeasurements, achievements, recentCompletions)
        
        return ProgressInsights(
            workoutTrends: trends,
            recentMeasurements: measurements,
            achievements: achievementsList,
            recentCompletions: completions
        )
    }
    
    // MARK: - Workout Trends Analysis
    
    private func fetchWorkoutTrends(for clientId: String) async throws -> WorkoutTrends {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let snapshot = try await db.collection("clients")
            .document(clientId)
            .collection("workoutCompletions")
            .whereField("completedDate", isGreaterThan: Timestamp(date: thirtyDaysAgo))
            .order(by: "completedDate", descending: true)
            .getDocuments()
        
        var ratings: [Int] = []
        var durations: [Int] = []
        var completionDates: [Date] = []
        
        for document in snapshot.documents {
            let data = document.data()
            
            if let rating = data["rating"] as? Int {
                ratings.append(rating)
            }
            
            if let duration = data["duration"] as? Int {
                durations.append(duration)
            }
            
            if let timestamp = data["completedDate"] as? Timestamp {
                completionDates.append(timestamp.dateValue())
            }
        }
        
        let averageRating = ratings.isEmpty ? 0.0 : Double(ratings.reduce(0, +)) / Double(ratings.count)
        let averageDuration = durations.isEmpty ? 0 : durations.reduce(0, +) / durations.count
        let consistencyScore = calculateConsistencyScore(completionDates: completionDates)
        let improvementTrend = calculateImprovementTrend(ratings: ratings)
        
        return WorkoutTrends(
            averageRating: averageRating,
            averageDuration: averageDuration,
            consistencyScore: consistencyScore,
            improvementTrend: improvementTrend
        )
    }
    
    // MARK: - Recent Measurements
    
    private func fetchRecentMeasurements(for clientId: String) async throws -> [ProgressEntry] {
        let snapshot = try await db.collection("progressHistory")
            .whereField("clientId", isEqualTo: clientId)
            .order(by: "timestamp", descending: true)
            .limit(to: 5)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document -> ProgressEntry? in
            let data = document.data()
            
            guard let clientId = data["clientId"] as? String,
                  let fieldRaw = data["field"] as? String,
                  let field = ProgressField(rawValue: fieldRaw),
                  let newValue = data["newValue"] as? String,
                  let changedBy = data["changedBy"] as? String,
                  let changedByName = data["changedByName"] as? String,
                  let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
                return nil
            }
            
            return ProgressEntry(
                id: document.documentID,
                clientId: clientId,
                field: field,
                oldValue: data["oldValue"] as? String,
                newValue: newValue,
                changedBy: changedBy,
                changedByName: changedByName,
                timestamp: timestamp,
                note: data["note"] as? String,
                sessionId: data["sessionId"] as? String
            )
        }
    }
    
    // MARK: - Recent Achievements
    
    private func fetchRecentAchievements(for clientId: String) async throws -> [Achievement] {
        let snapshot = try await db.collection("milestones")
            .whereField("clientId", isEqualTo: clientId)
            .order(by: "achievedDate", descending: true)
            .limit(to: 3)
            .getDocuments()
        
        var achievements: [Achievement] = []
        
        for document in snapshot.documents {
            let data = document.data()
            
            guard let title = data["title"] as? String,
                  let achievedDate = (data["achievedDate"] as? Timestamp)?.dateValue(),
                  let categoryRaw = data["category"] as? String,
                  let category = MilestoneCategory(rawValue: categoryRaw) else {
                continue
            }
            
            let achievement = Achievement(
                id: document.documentID,
                title: title,
                description: data["description"] as? String ?? "",
                achievedDate: achievedDate,
                category: category.displayName,
                icon: category.icon
            )
            
            achievements.append(achievement)
        }
        
        // Add automatic achievements based on workout data
        let automaticAchievements = try await generateAutomaticAchievements(for: clientId)
        achievements.append(contentsOf: automaticAchievements)
        
        return Array(achievements.prefix(3))
    }
    
    // MARK: - Recent Workout Completions
    
    func fetchRecentWorkoutCompletions(for clientId: String) async throws -> [WorkoutCompletion] {
        print("🔍 ClientProgressService: Fetching workout completions for client: \(clientId)")
        
        let snapshot = try await db.collection("clients")
            .document(clientId)
            .collection("workoutCompletions")
            .order(by: "completedDate", descending: true)
            .limit(to: 5)
            .getDocuments()
        
        print("📊 ClientProgressService: Found \(snapshot.documents.count) workout completion documents")
        
        let completions = snapshot.documents.compactMap { document -> WorkoutCompletion? in
            let data = document.data()
            print("📄 Document ID: \(document.documentID)")
            print("📄 Document data keys: \(data.keys.sorted())")
            
            guard let workoutTitle = data["workoutTitle"] as? String,
                  let completedDate = (data["completedDate"] as? Timestamp)?.dateValue(),
                  let rating = data["rating"] as? Int,
                  let duration = data["duration"] as? Int else {
                print("❌ Missing required fields in document \(document.documentID)")
                print("   - workoutTitle: \(data["workoutTitle"] ?? "missing")")
                print("   - completedDate: \(data["completedDate"] ?? "missing")")
                print("   - rating: \(data["rating"] ?? "missing")")
                print("   - duration: \(data["duration"] ?? "missing")")
                return nil
            }
            
            print("✅ Successfully parsed workout completion: \(workoutTitle)")
            
            return WorkoutCompletion(
                id: document.documentID,
                workoutTitle: workoutTitle,
                completedDate: completedDate,
                rating: rating,
                duration: duration,
                notes: data["notes"] as? String ?? ""
            )
        }
        
        print("🎯 ClientProgressService: Returning \(completions.count) valid workout completions")
        return completions
    }
    
    // MARK: - Helper Methods
    
    private func calculateConsistencyScore(completionDates: [Date]) -> Double {
        guard completionDates.count >= 2 else { return 0.0 }
        
        let sortedDates = completionDates.sorted()
        let totalDays = Calendar.current.dateComponents([.day], from: sortedDates.first!, to: sortedDates.last!).day ?? 1
        let workoutDays = completionDates.count
        
        return min(1.0, Double(workoutDays) / Double(totalDays) * 7.0) // Normalize to weekly frequency
    }
    
    private func calculateImprovementTrend(ratings: [Int]) -> String {
        guard ratings.count >= 3 else { return "stable" }
        
        let recentRatings = Array(ratings.prefix(5))
        let olderRatings = Array(ratings.suffix(5))
        
        let recentAverage = Double(recentRatings.reduce(0, +)) / Double(recentRatings.count)
        let olderAverage = Double(olderRatings.reduce(0, +)) / Double(olderRatings.count)
        
        if recentAverage > olderAverage + 0.3 {
            return "improving"
        } else if recentAverage < olderAverage - 0.3 {
            return "declining"
        } else {
            return "stable"
        }
    }
    
    private func generateAutomaticAchievements(for clientId: String) async throws -> [Achievement] {
        var achievements: [Achievement] = []
        
        // Check for workout streak achievements
        let completions = try await fetchRecentWorkoutCompletions(for: clientId)
        let streak = calculateCurrentStreak(completions: completions)
        
        if streak >= 7 {
            achievements.append(Achievement(
                id: "streak_7",
                title: "Week Warrior",
                description: "Completed workouts for 7 days straight!",
                achievedDate: Date(),
                category: "Consistency",
                icon: "flame.fill"
            ))
        } else if streak >= 3 {
            achievements.append(Achievement(
                id: "streak_3",
                title: "Getting Consistent",
                description: "3 days in a row - keep it up!",
                achievedDate: Date(),
                category: "Consistency",
                icon: "target"
            ))
        }
        
        return achievements
    }
    
    private func calculateCurrentStreak(completions: [WorkoutCompletion]) -> Int {
        guard !completions.isEmpty else { return 0 }
        
        let sortedCompletions = completions.sorted { $0.completedDate > $1.completedDate }
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())
        
        for completion in sortedCompletions {
            let completionDate = Calendar.current.startOfDay(for: completion.completedDate)
            
            if Calendar.current.isDate(completionDate, inSameDayAs: currentDate) ||
               Calendar.current.isDate(completionDate, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!) {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: completionDate)!
            } else {
                break
            }
        }
        
        return streak
    }
} 