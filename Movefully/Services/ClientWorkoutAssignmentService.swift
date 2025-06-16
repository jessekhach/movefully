import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Client Workout Assignment Service
@MainActor
class ClientWorkoutAssignmentService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let workoutCache = WorkoutDataCacheService.shared
    private var currentClientId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Today's Workout Assignment
    
    /// Fetches today's workout assignment for the current client
    func getTodayWorkoutAssignment() async -> WorkoutAssignment? {
        guard let clientId = currentClientId else {
            print("❌ ClientWorkoutAssignmentService: No authenticated user found")
            return nil
        }
        

        
        do {
            // Get program data from cache
            let programData = try await workoutCache.fetchAndCacheProgram()
            
            // Calculate which day of the program the client is on
            let clientDoc = try await db.collection("clients").document(clientId).getDocument()
            guard let clientData = clientDoc.data() else { return nil }
            
            let planStartDate = (clientData["currentPlanStartDate"] as? Timestamp)?.dateValue() ?? Date()
            let planEndDate = (clientData["currentPlanEndDate"] as? Timestamp)?.dateValue()
            let today = Calendar.current.startOfDay(for: Date())
            let daysSinceStart = Calendar.current.dateComponents([.day], from: planStartDate, to: today).day ?? 0
            
            // Get today's workout assignment from the program
            if let todayWorkout = try await generateWorkoutAssignment(
                programData: programData,
                dayInProgram: daysSinceStart,
                clientId: clientId,
                forDate: today,
                planStartDate: planStartDate,
                planEndDate: planEndDate
            ) {
                print("✅ ClientWorkoutAssignmentService: Found today's workout: \(todayWorkout.title)")
                return todayWorkout
            } else {
    
                return nil
            }
        } catch {
            print("❌ ClientWorkoutAssignmentService: Error fetching today's workout: \(error)")
            errorMessage = "Failed to load today's workout"
            return nil
        }
    }
    
    /// Fetches weekly workout assignments for the current client
    func getWeeklyWorkoutAssignments() async -> [WorkoutAssignment] {
        return await getWeeklyWorkoutAssignments(weekOffset: 0)
    }
    
    /// Fetches weekly workout assignments for a specific week offset from current week
    func getWeeklyWorkoutAssignments(weekOffset: Int) async -> [WorkoutAssignment] {
        guard let clientId = currentClientId else {
            print("❌ ClientWorkoutAssignmentService: No authenticated user found")
            return []
        }
        
        print("🔍 ClientWorkoutAssignmentService: Fetching weekly workouts for client: \(clientId)")
        
        do {
            // Get program data from cache
            let programData = try await workoutCache.fetchAndCacheProgram()
            
            // Get client data for plan dates
            let clientDoc = try await db.collection("clients").document(clientId).getDocument()
            guard let clientData = clientDoc.data() else { return [] }
            
            let planStartDate = (clientData["currentPlanStartDate"] as? Timestamp)?.dateValue() ?? Date()
            let planEndDate = (clientData["currentPlanEndDate"] as? Timestamp)?.dateValue()
            let calendar = Calendar.current
            let today = Date()
            
            // Get the start of the target week (current week + offset)
            guard let targetWeek = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today),
                  let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: targetWeek)?.start else {
                return []
            }
            
            var weeklyAssignments: [WorkoutAssignment] = []
            
            // Generate assignments for each day of the week
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else {
                    continue
                }
                
                let daysSinceStart = calendar.dateComponents([.day], from: planStartDate, to: date).day ?? 0
                print("🔍 ClientWorkoutAssignmentService: Date=\(date), planStartDate=\(planStartDate), daysSinceStart=\(daysSinceStart)")
                
                if let workout = try await generateWorkoutAssignment(
                    programData: programData,
                    dayInProgram: daysSinceStart,
                    clientId: clientId,
                    forDate: date,
                    planStartDate: planStartDate,
                    planEndDate: planEndDate
                ) {
                    weeklyAssignments.append(workout)
                }
            }
            
            print("✅ ClientWorkoutAssignmentService: Generated \(weeklyAssignments.count) weekly assignments")
            return weeklyAssignments
            
        } catch {
            print("❌ ClientWorkoutAssignmentService: Error fetching weekly workouts: \(error)")
            errorMessage = "Failed to load weekly workouts"
            return []
        }
    }
    
    /// Completes a workout assignment and saves to Firestore
    func completeWorkout(_ assignment: WorkoutAssignment, rating: Int, notes: String, skippedExercises: Set<Int> = [], completedExercises: Set<Int> = [], actualDuration: Int? = nil) async throws {
        guard let clientId = currentClientId else {
            throw NSError(domain: "ClientWorkoutAssignmentService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        print("🔄 ClientWorkoutAssignmentService: Completing workout: \(assignment.title)")
        
        // Convert actualDuration from seconds to minutes if provided
        let actualDurationMinutes = actualDuration != nil ? (actualDuration! / 60) : nil
        
        // Generate comprehensive trainer feedback
        let trainerFeedback = generateTrainerFeedback(
            assignment: assignment,
            rating: rating,
            clientNotes: notes,
            skippedExercises: skippedExercises,
            completedExercises: completedExercises,
            actualDuration: actualDurationMinutes
        )
        
        // Use consistent workout identifier for completion tracking
        let consistentWorkoutId = "\(assignment.title)_\(Calendar.current.startOfDay(for: assignment.date).timeIntervalSince1970)"
        
        let completionData: [String: Any] = [
            "workoutId": consistentWorkoutId,
            "workoutTitle": assignment.title,
            "completedDate": Timestamp(date: Date()),
            "rating": rating,
            "notes": notes,
            "duration": actualDurationMinutes ?? assignment.estimatedDuration,
            "skippedExercises": Array(skippedExercises),
            "completedExercises": Array(completedExercises),
            "trainerFeedback": trainerFeedback
        ]
        
        // Save to client's workout completions using consistent ID
        try await db.collection("clients")
            .document(clientId)
            .collection("workoutCompletions")
            .document(consistentWorkoutId)
            .setData(completionData)
        
        // Update client's total workouts completed
        try await db.collection("clients")
            .document(clientId)
            .updateData([
                "totalWorkoutsCompleted": FieldValue.increment(Int64(1)),
                "lastWorkoutDate": Timestamp(date: Date()),
                "lastActivityDate": Timestamp(date: Date())
            ])
        
        // Create trainer note with comprehensive feedback
        try await createTrainerNote(
            clientId: clientId,
            workoutTitle: assignment.title,
            trainerFeedback: trainerFeedback
        )
        
        // Update the program data to mark a workout as completed
        try await updateProgramWorkoutCompletion(clientId: clientId, workoutId: consistentWorkoutId, date: Date())
        
        print("✅ ClientWorkoutAssignmentService: Workout completion saved with trainer feedback")
    }
    
    // MARK: - Trainer Feedback Generation
    
    /// Generates comprehensive trainer feedback based on workout completion data
    private func generateTrainerFeedback(
        assignment: WorkoutAssignment,
        rating: Int,
        clientNotes: String,
        skippedExercises: Set<Int>,
        completedExercises: Set<Int>,
        actualDuration: Int?
    ) -> String {
        var feedback: [String] = []
        
        // Header with workout info
        feedback.append("Workout Completion Summary")
        feedback.append("Workout: \(assignment.title)")
        feedback.append("Date: \(DateFormatter.shortDate.string(from: Date()))")
        feedback.append("")
        
        // Completion stats
        let totalExercises = assignment.exercises.count
        let completedCount = completedExercises.count
        let completionPercentage = totalExercises > 0 ? Int((Double(completedCount) / Double(totalExercises)) * 100) : 0
        
        feedback.append("Session Statistics:")
        feedback.append("• Completion Rate: \(completionPercentage)% (\(completedCount)/\(totalExercises) exercises)")
        
        if let actualDuration = actualDuration {
            let estimatedDuration = assignment.estimatedDuration
            let durationDiff = actualDuration - estimatedDuration
            if durationDiff > 0 {
                feedback.append("• Duration: \(actualDuration) min (+\(durationDiff) min over estimate)")
            } else if durationDiff < 0 {
                feedback.append("• Duration: \(actualDuration) min (\(abs(durationDiff)) min under estimate)")
            } else {
                feedback.append("• Duration: \(actualDuration) min (right on target!)")
            }
        }
        
        // Client satisfaction
        let ratingEmojis = ["😴", "😐", "🙂", "😊", "🤩"]
        let ratingDescriptions = ["Tired", "Okay", "Good", "Great", "Amazing"]
        if rating >= 1 && rating <= 5 {
            feedback.append("• Client Satisfaction: \(ratingEmojis[rating-1]) \(ratingDescriptions[rating-1])")
        }
        feedback.append("")
        
        // Skipped exercises details
        if !skippedExercises.isEmpty {
            feedback.append("Skipped Exercises:")
            for exerciseIndex in skippedExercises.sorted() {
                if exerciseIndex < assignment.exercises.count {
                    let exercise = assignment.exercises[exerciseIndex]
                    feedback.append("• \(exercise.title)")
                }
            }
            feedback.append("")
        }
        
        // Client feedback
        if !clientNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            feedback.append("Client Feedback:")
            feedback.append("\"\(clientNotes)\"")
            feedback.append("")
        }
        
        return feedback.joined(separator: "\n")
    }
    
    /// Creates a client note with workout completion feedback
    private func createTrainerNote(clientId: String, workoutTitle: String, trainerFeedback: String) async throws {
        // Get client info for the note
        let clientDoc = try await db.collection("clients").document(clientId).getDocument()
        guard let clientData = clientDoc.data(),
              let clientName = clientData["name"] as? String,
              let trainerId = clientData["trainerId"] as? String else {
            print("⚠️ Could not get client info for client note")
            return
        }
        
        // Create the client note
        let noteRef = db.collection("clientNotes").document()
        let noteData: [String: Any] = [
            "clientId": clientId,
            "trainerId": trainerId,
            "content": trainerFeedback,
            "type": "client_note",
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await noteRef.setData(noteData)
        print("✅ Created client note for \(clientName)'s \(workoutTitle) completion")
    }
    
    /// Updates the program data to mark a workout as completed
    private func updateProgramWorkoutCompletion(clientId: String, workoutId: String, date: Date) async throws {
        // Get client's current plan
        let clientDoc = try await db.collection("clients").document(clientId).getDocument()
        guard let clientData = clientDoc.data(),
              let currentPlanId = clientData["currentPlanId"] as? String else {
            print("⚠️ No current plan found for client")
            return
        }
        
        // Get the program document
        let programDoc = try await db.collection("programs").document(currentPlanId).getDocument()
        guard let programData = programDoc.data(),
              var scheduledWorkouts = programData["scheduledWorkouts"] as? [[String: Any]] else {
            print("⚠️ Could not get program data")
            return
        }
        
        // Find and update the matching workout
        var updated = false
        for i in 0..<scheduledWorkouts.count {
            if let workoutIdInProgram = scheduledWorkouts[i]["id"] as? String,
               workoutIdInProgram == workoutId {
                scheduledWorkouts[i]["isCompleted"] = true
                scheduledWorkouts[i]["completedDate"] = Timestamp(date: date)
                updated = true
                print("✅ Updated workout completion in program data")
                break
            }
        }
        
        if updated {
            // Update the program document
            try await db.collection("programs").document(currentPlanId).updateData([
                "scheduledWorkouts": scheduledWorkouts,
                "lastModified": Timestamp(date: Date())
            ])
            print("✅ Program updated with workout completion")
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Generates a workout assignment based on program data and day in program
    private func generateWorkoutAssignment(
        programData: [String: Any],
        dayInProgram: Int,
        clientId: String,
        forDate: Date = Date(),
        planStartDate: Date? = nil,
        planEndDate: Date? = nil
    ) async throws -> WorkoutAssignment? {
        // Check if the requested date falls within the plan's active period
        if let startDate = planStartDate {
            let calendar = Calendar.current
            let requestedDate = calendar.startOfDay(for: forDate)
            let planStart = calendar.startOfDay(for: startDate)
            
            if requestedDate < planStart {
                print("🔍 ClientWorkoutAssignmentService: Date \(forDate) is before plan start date \(startDate)")
                return nil
            }
        }
        
        if let endDate = planEndDate {
            let calendar = Calendar.current
            let requestedDate = calendar.startOfDay(for: forDate)
            let planEnd = calendar.startOfDay(for: endDate)
            
            if requestedDate > planEnd {
                print("🔍 ClientWorkoutAssignmentService: Date \(forDate) is after plan end date \(endDate)")
                return nil
            }
        }
        
        // Get scheduled workouts from the program
        guard let scheduledWorkouts = programData["scheduledWorkouts"] as? [[String: Any]] else {
            print("❌ ClientWorkoutAssignmentService: No scheduled workouts in program data")
            return nil
        }
        
        // Calculate which day of the program this calendar date represents
        guard let startDate = planStartDate else {
            print("❌ ClientWorkoutAssignmentService: No plan start date available")
            return nil
        }
        
        let calendar = Calendar.current
        let daysSinceStart = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: forDate)).day ?? 0
        
        // Program days are 1-indexed (Day 1, Day 2, etc.), so add 1
        let programDay = daysSinceStart + 1
        
        // Find if there's a scheduled workout for this program day
        let workoutForDay = scheduledWorkouts.first { workout in
            if let dayNumber = workout["day"] as? Int {
                return dayNumber == programDay
            }
            return false
        }
        
        guard let workoutData = workoutForDay else {
            // No workout scheduled for this day - it's a rest day
            print("🔍 ClientWorkoutAssignmentService: No workout scheduled for program day \(programDay) - rest day")
            return nil
        }
        
        // Extract workout information
        let workoutId = workoutData["id"] as? String ?? UUID().uuidString
        
        // Get workout title from template or custom workout
        var workoutTitle = "Daily Workout" // Default fallback
        var workoutDescription: String? = nil // Add description extraction
        if let templateName = workoutData["workoutTemplateName"] as? String, !templateName.isEmpty {
            workoutTitle = templateName
            // Try to fetch template description if we have a template ID
            if let templateId = workoutData["workoutTemplateId"] as? String, !templateId.isEmpty {
                do {
                    let templateData = try await workoutCache.fetchAndCacheTemplate(templateId: templateId)
                    workoutDescription = templateData["description"] as? String
                } catch {
                    print("⚠️ ClientWorkoutAssignmentService: Could not fetch template description: \(error)")
                }
            }
        }
        
        // Check if this workout was already completed using a consistent identifier
        // Use a combination of date and workout template/title for consistent checking
        let consistentWorkoutId = "\(workoutTitle)_\(Calendar.current.startOfDay(for: forDate).timeIntervalSince1970)"
        let isCompleted = await checkWorkoutCompletion(
            workoutId: consistentWorkoutId,
            clientId: clientId,
            date: forDate
        )
        
        // Generate exercises for this workout
        let exercises = try await generateExercisesForWorkout(workoutData: workoutData)
        
        // Get estimated duration from template
        var estimatedDuration = 30 // Default fallback
        if let templateId = workoutData["workoutTemplateId"] as? String, !templateId.isEmpty {
            do {
                let templateData = try await workoutCache.fetchAndCacheTemplate(templateId: templateId)
                estimatedDuration = templateData["estimatedDuration"] as? Int ?? 30
            } catch {
                print("⚠️ ClientWorkoutAssignmentService: Could not fetch template duration: \(error)")
            }
        }
        
        print("✅ ClientWorkoutAssignmentService: Generated workout assignment: \(workoutTitle)")
        
        let assignment = WorkoutAssignment(
            title: workoutTitle,
            description: workoutDescription,
            date: forDate,
            status: isCompleted ? .completed : .pending,
            exercises: exercises,
            trainerNotes: programData["coachingNotes"] as? String,
            estimatedDuration: estimatedDuration
        )
        
        // Apply missed workout detection to update status if needed
        return updateWorkoutStatusBasedOnDate(assignment)
    }
    
    /// Generates exercises for a workout based on workout template data
    private func generateExercisesForWorkout(workoutData: [String: Any]) async throws -> [AssignedExercise] {
        print("🔄 ClientWorkoutAssignmentService: Generating exercises for workout")
        
        // All workouts now reference templates, so fetch the template data
        guard let templateId = workoutData["workoutTemplateId"] as? String, !templateId.isEmpty else {
            print("⚠️ ClientWorkoutAssignmentService: No template ID found in workout data")
            return []
        }
        
        do {
            let templateData = try await workoutCache.fetchAndCacheTemplate(templateId: templateId)
            guard let exercisesData = templateData["exercises"] as? [[String: Any]] else {
                print("⚠️ ClientWorkoutAssignmentService: No exercises found in template")
                return []
            }
            
            return parseTemplateExercises(exercisesData)
        } catch {
            print("❌ ClientWorkoutAssignmentService: Error fetching template: \(error)")
            return []
        }
    }
    
    /// Parses template exercises
    private func parseTemplateExercises(_ exercisesData: [[String: Any]]) -> [AssignedExercise] {
        print("🔥 [DEBUG] Parsing template exercises: \(exercisesData)")
        return exercisesData.compactMap { exerciseData in
            guard let title = exerciseData["title"] as? String else {
                print("🔥 [DEBUG] Skipping exercise due to missing title: \(exerciseData)")
                return nil
            }
            
            let description = exerciseData["description"] as? String ?? ""
            let sets = exerciseData["sets"] as? Int
            let restTime = exerciseData["restTime"] as? Int
            let trainerTips = exerciseData["trainerTips"] as? String
            let categoryString = exerciseData["category"] as? String ?? "strength"
            let category = ExerciseCategory(rawValue: categoryString) ?? .strength
            
            // Extract exerciseType from Firestore data
            let exerciseTypeString = exerciseData["exerciseType"] as? String ?? "Duration"
            let exerciseType = ExerciseType(rawValue: exerciseTypeString) ?? .duration
            
            // Handle reps vs duration based on exerciseType
            // In your Firestore data, both reps and duration values are stored in the "duration" field
            let durationValue = exerciseData["duration"] as? Int
            let repsValue = exerciseData["reps"] as? String
            
            var finalReps: String?
            var finalDuration: Int?
            
            if exerciseType == .reps {
                // For reps-based exercises, check if there's a reps field first, otherwise use duration field
                if let repsString = repsValue {
                    finalReps = repsString
                } else if let durationInt = durationValue {
                    // Convert duration value to reps string for reps-based exercises
                    finalReps = "\(durationInt)"
                }
            } else {
                // For duration-based exercises, use the duration field
                finalDuration = durationValue
            }
            
            // Log missing workout prescription data
            if sets == nil {
                print("⚠️ [WARNING] Exercise '\(title)' is missing sets data - this should be specified in the workout template")
            }
            if exerciseType == .reps && finalReps == nil {
                print("⚠️ [WARNING] Reps-based exercise '\(title)' is missing reps data")
            }
            if exerciseType == .duration && finalDuration == nil {
                print("⚠️ [WARNING] Duration-based exercise '\(title)' is missing duration data")
            }
            
            print("🔥 [DEBUG] Exercise: \(title), Type: \(exerciseType), Sets: \(sets ?? 0), Reps: \(finalReps ?? "nil"), Duration: \(finalDuration ?? 0)")
            
            return AssignedExercise(
                title: title,
                description: description,
                sets: sets,
                reps: finalReps,
                duration: finalDuration,
                restTime: restTime,
                trainerTips: trainerTips,
                mediaUrl: exerciseData["mediaUrl"] as? String,
                category: category,
                exerciseType: exerciseType
            )
        }
    }
    
    /// Checks if a workout was already completed
    private func checkWorkoutCompletion(workoutId: String, clientId: String, date: Date) async -> Bool {
        do {
            let doc = try await db.collection("clients")
                .document(clientId)
                .collection("workoutCompletions")
                .document(workoutId)
                .getDocument()
            
            return doc.exists
        } catch {
            print("❌ ClientWorkoutAssignmentService: Error checking completion: \(error)")
            return false
        }
    }
    
    // MARK: - Missed Workout Detection
    
    /// Updates workout status based on current date - converts pending to skipped if past due
    private func updateWorkoutStatusBasedOnDate(_ assignment: WorkoutAssignment) -> WorkoutAssignment {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let workoutDate = calendar.startOfDay(for: assignment.date)
        
        // If workout is past due and not completed, mark as missed (using skipped status)
        if workoutDate < today && assignment.status == .pending {
            print("🔄 ClientWorkoutAssignmentService: Marking workout as missed: \(assignment.title) on \(workoutDate)")
            var updatedAssignment = assignment
            updatedAssignment.status = .skipped
            return updatedAssignment
        }
        
        return assignment
    }
    
    /// Detects and processes missed workouts for automatic trainer notifications
    func detectAndNotifyMissedWorkouts() async {
        guard let clientId = currentClientId else {
            print("❌ ClientWorkoutAssignmentService: No authenticated user for missed workout detection")
            return
        }
        
        print("🔍 ClientWorkoutAssignmentService: Starting missed workout detection for client: \(clientId)")
        
        do {
            // Get the last 7 days of workouts to check for missed ones
            let calendar = Calendar.current
            let today = Date()
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
            
            // Get program data
            let programData = try await workoutCache.fetchAndCacheProgram()
            let clientDoc = try await db.collection("clients").document(clientId).getDocument()
            guard let clientData = clientDoc.data() else { return }
            
            let planStartDate = (clientData["currentPlanStartDate"] as? Timestamp)?.dateValue() ?? Date()
            let planEndDate = (clientData["currentPlanEndDate"] as? Timestamp)?.dateValue()
            
            var missedWorkouts: [WorkoutAssignment] = []
            
            // Check each day in the past week for missed workouts
            for dayOffset in -7...(-1) {
                guard let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
                
                let daysSinceStart = calendar.dateComponents([.day], from: planStartDate, to: checkDate).day ?? 0
                
                if let workout = try await generateWorkoutAssignment(
                    programData: programData,
                    dayInProgram: daysSinceStart,
                    clientId: clientId,
                    forDate: checkDate,
                    planStartDate: planStartDate,
                    planEndDate: planEndDate
                ) {
                    // Check if this workout was missed (skipped status means it was past due and not completed)
                    if workout.status == .skipped {
                        missedWorkouts.append(workout)
                    }
                }
            }
            
            // Create trainer notifications for missed workouts
            for missedWorkout in missedWorkouts {
                try await createMissedWorkoutNote(clientId: clientId, missedWorkout: missedWorkout)
            }
            
            if !missedWorkouts.isEmpty {
                print("✅ ClientWorkoutAssignmentService: Processed \(missedWorkouts.count) missed workouts and created trainer notifications")
            } else {
                print("✅ ClientWorkoutAssignmentService: No missed workouts detected")
            }
            
        } catch {
            print("❌ ClientWorkoutAssignmentService: Error detecting missed workouts: \(error)")
        }
    }
    
    /// Creates a trainer note for a missed workout
    private func createMissedWorkoutNote(clientId: String, missedWorkout: WorkoutAssignment) async throws {
        // Get client info for the note
        let clientDoc = try await db.collection("clients").document(clientId).getDocument()
        guard let clientData = clientDoc.data(),
              let clientName = clientData["name"] as? String,
              let trainerId = clientData["trainerId"] as? String else {
            print("⚠️ Could not get client info for missed workout note")
            return
        }
        
        // Check if we already created a note for this missed workout to avoid duplicates
        let missedWorkoutId = "missed_\(missedWorkout.title)_\(Calendar.current.startOfDay(for: missedWorkout.date).timeIntervalSince1970)"
        
        let existingNotes = try await db.collection("clientNotes")
            .whereField("clientId", isEqualTo: clientId)
            .whereField("type", isEqualTo: "client_note")
            .whereField("workoutId", isEqualTo: missedWorkoutId)
            .getDocuments()
        
        if !existingNotes.documents.isEmpty {
            print("ℹ️ Missed workout note already exists for \(missedWorkout.title) on \(missedWorkout.date)")
            return
        }
        
        // Create comprehensive missed workout feedback
        let missedWorkoutFeedback = generateMissedWorkoutFeedback(
            clientName: clientName,
            missedWorkout: missedWorkout
        )
        
        // Create the missed workout alert note
        let noteRef = db.collection("clientNotes").document()
        let noteData: [String: Any] = [
            "clientId": clientId,
            "trainerId": trainerId,
            "content": missedWorkoutFeedback,
            "type": "client_note",
            "workoutId": missedWorkoutId,
            "workoutTitle": missedWorkout.title,
            "missedDate": Timestamp(date: missedWorkout.date),
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await noteRef.setData(noteData)
        print("✅ Created missed workout alert for \(clientName)'s \(missedWorkout.title) on \(DateFormatter.shortDate.string(from: missedWorkout.date))")
    }
    
    /// Generates comprehensive feedback for missed workout trainer notifications
    private func generateMissedWorkoutFeedback(clientName: String, missedWorkout: WorkoutAssignment) -> String {
        var feedback: [String] = []
        
        // Header
        feedback.append("Missed Workout Alert")
        feedback.append("")
        
        // Client and workout info
        feedback.append("Client: \(clientName)")
        feedback.append("Workout: \(missedWorkout.title)")
        feedback.append("Scheduled Date: \(DateFormatter.shortDate.string(from: missedWorkout.date))")
        feedback.append("Status: Missed")
        feedback.append("")
        
        // Workout details
        feedback.append("Workout Details:")
        feedback.append("• Duration: \(missedWorkout.estimatedDuration) minutes")
        feedback.append("• Exercises: \(missedWorkout.exercises.count)")
        feedback.append("")
        
        // Trainer guidance
        feedback.append("Recommended Actions:")
        feedback.append("• Check in with client about any barriers or challenges")
        feedback.append("• Consider adjusting workout schedule if needed")
        feedback.append("• Provide encouragement and support")
        feedback.append("• Review if workout difficulty is appropriate")
        feedback.append("")
        
        // Trainer notes if available
        if let trainerNotes = missedWorkout.trainerNotes, !trainerNotes.isEmpty {
            feedback.append("Original Trainer Notes:")
            feedback.append("\"\(trainerNotes)\"")
            feedback.append("")
        }
        
        feedback.append("This alert was automatically generated when the scheduled workout was not completed.")
        
        return feedback.joined(separator: "\n")
    }
} 