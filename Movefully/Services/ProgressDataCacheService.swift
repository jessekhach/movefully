import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ProgressDataCacheService: ObservableObject {
    static let shared = ProgressDataCacheService()
    private init() {
        loadCacheFromDisk()
    }
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var currentClientId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // Cache storage
    @Published private var progressEntriesCache: [String: (data: [ProgressEntry], timestamp: Date)] = [:]
    @Published private var milestonesCache: [String: (data: [Milestone], timestamp: Date)] = [:]
    @Published private var workoutCompletionsCache: [String: (data: [ClientProgressService.WorkoutCompletion], timestamp: Date)] = [:]
    
    private let cacheExpirationTime: TimeInterval = 5 * 60 // 5 minutes
    
    private let progressCacheURL: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("cachedProgressData.json")
    }()
    
    // MARK: - Public Methods
    
    /// Fetches and caches all progress data
    func fetchAndCacheProgressData() async throws -> (progressEntries: [ProgressEntry], milestones: [Milestone], workoutCompletions: [ClientProgressService.WorkoutCompletion]) {
        guard let clientId = currentClientId else {
            throw NSError(domain: "ProgressDataCacheService", code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        // Check if cache is valid
        if let cachedEntries = getCachedProgressEntries(for: clientId),
           let cachedMilestones = getCachedMilestones(for: clientId),
           let cachedCompletions = getCachedWorkoutCompletions(for: clientId) {
            print("📦 ProgressDataCacheService: Using cached progress data")
            return (cachedEntries, cachedMilestones, cachedCompletions)
        }
        
        print("🔍 ProgressDataCacheService: Fetching fresh progress data")
        
        // Fetch all progress data concurrently
        let progressService = ProgressHistoryService()
        let clientProgressService = ClientProgressService()
        
        async let progressEntries = progressService.fetchProgressEntries(for: clientId)
        async let milestones = progressService.fetchMilestones(for: clientId)
        async let workoutCompletions = clientProgressService.fetchRecentWorkoutCompletions(for: clientId)
        
        let (entries, milestonesList, completions) = try await (progressEntries, milestones, workoutCompletions)
        
        // Cache the data
        let timestamp = Date()
        progressEntriesCache[clientId] = (entries, timestamp)
        milestonesCache[clientId] = (milestonesList, timestamp)
        workoutCompletionsCache[clientId] = (completions, timestamp)
        
        saveCacheToDisk()
        
        print("✅ ProgressDataCacheService: Progress data cached successfully")
        return (entries, milestonesList, completions)
    }
    
    /// Gets cached progress data if available
    func getCachedProgressData() -> (progressEntries: [ProgressEntry], milestones: [Milestone], workoutCompletions: [ClientProgressService.WorkoutCompletion])? {
        guard let clientId = currentClientId else { return nil }
        if let cachedEntries = getCachedProgressEntries(for: clientId),
           let cachedMilestones = getCachedMilestones(for: clientId),
           let cachedCompletions = getCachedWorkoutCompletions(for: clientId) {
            return (cachedEntries, cachedMilestones, cachedCompletions)
        }
        return nil
    }
    
    /// Clears the progress cache
    func clearCache() {
        progressEntriesCache.removeAll()
        milestonesCache.removeAll()
        workoutCompletionsCache.removeAll()
        
        do {
            try? FileManager.default.removeItem(at: progressCacheURL)
            print("🧹 [DEBUG] Cleared progress cache from disk at \(progressCacheURL.path)")
        } catch {}
        
        print("🧹 ProgressDataCacheService: Cache cleared")
    }
    
    /// Checks if cache is valid
    func isCacheValid() -> Bool {
        guard let clientId = currentClientId else { return false }
        guard let cached = progressEntriesCache[clientId] else { return false }
        return Date().timeIntervalSince(cached.timestamp) < cacheExpirationTime
    }
    
    /// Refreshes progress cache on app launch
    func refreshOnLaunch() async {
        print("🔄 [DEBUG] Refreshing progress cache on app launch...")
        do {
            _ = try await fetchAndCacheProgressData()
            print("🔄 [DEBUG] Fetched and cached progress data on launch")
        } catch {
            print("❌ [DEBUG] Failed to fetch progress data on launch: \(error)")
        }
    }
    
    /// Invalidates cache when new progress is added
    func invalidateCache() {
        print("🔄 ProgressDataCacheService: Cache invalidated - will refresh on next access")
        progressEntriesCache.removeAll()
        milestonesCache.removeAll()
        workoutCompletionsCache.removeAll()
    }
    
    /// Clears all caches (alias for clearCache for consistency)
    func clearAllCaches() {
        clearCache()
    }
    
    // MARK: - Cache Management
    
    private func getCachedProgressEntries(for clientId: String) -> [ProgressEntry]? {
        guard let cached = progressEntriesCache[clientId],
              Date().timeIntervalSince(cached.timestamp) < cacheExpirationTime else {
            return nil
        }
        return cached.data
    }
    
    private func getCachedMilestones(for clientId: String) -> [Milestone]? {
        guard let cached = milestonesCache[clientId],
              Date().timeIntervalSince(cached.timestamp) < cacheExpirationTime else {
            return nil
        }
        return cached.data
    }
    
    private func getCachedWorkoutCompletions(for clientId: String) -> [ClientProgressService.WorkoutCompletion]? {
        guard let cached = workoutCompletionsCache[clientId],
              Date().timeIntervalSince(cached.timestamp) < cacheExpirationTime else {
            return nil
        }
        return cached.data
    }
    
    // MARK: - Disk Persistence
    
    private func saveCacheToDisk() {
        do {
            let cacheData = CacheData(
                progressEntries: progressEntriesCache.mapValues { (entries, timestamp) in
                    CachedProgressEntries(
                        entries: entries.map { entry in
                            CachedProgressEntry(
                                id: entry.id,
                                clientId: entry.clientId,
                                fieldRawValue: entry.field.rawValue,
                                fieldDisplayName: entry.field.displayName,
                                oldValue: entry.oldValue,
                                newValue: entry.newValue,
                                changedBy: entry.changedBy,
                                changedByName: entry.changedByName,
                                timestamp: entry.timestamp,
                                note: entry.note,
                                sessionId: entry.sessionId
                            )
                        },
                        cacheTimestamp: timestamp
                    )
                },
                milestones: milestonesCache.mapValues { (milestones, timestamp) in
                    CachedMilestones(
                        milestones: milestones.map { milestone in
                            CachedMilestone(
                                id: milestone.id,
                                clientId: milestone.clientId,
                                title: milestone.title,
                                description: milestone.description,
                                achievedDate: milestone.achievedDate,
                                createdBy: milestone.createdBy,
                                createdByName: milestone.createdByName,
                                categoryRawValue: milestone.category.rawValue,
                                isAutomatic: milestone.isAutomatic
                            )
                        },
                        cacheTimestamp: timestamp
                    )
                },
                workoutCompletions: workoutCompletionsCache.mapValues { (completions, timestamp) in
                    CachedWorkoutCompletions(
                        completions: completions.map { completion in
                            CachedWorkoutCompletion(
                                id: completion.id,
                                workoutTitle: completion.workoutTitle,
                                completedDate: completion.completedDate,
                                rating: completion.rating,
                                duration: completion.duration,
                                notes: completion.notes
                            )
                        },
                        cacheTimestamp: timestamp
                    )
                }
            )
            
            let data = try JSONEncoder().encode(cacheData)
            try data.write(to: progressCacheURL)
        } catch {
            print("❌ ProgressDataCacheService: Failed to save progress cache: \(error)")
        }
    }
    
    private func loadCacheFromDisk() {
        do {
            let url = progressCacheURL
            let data = try Data(contentsOf: url)
            let cacheData = try JSONDecoder().decode(CacheData.self, from: data)
            
            // Restore progress entries cache
            progressEntriesCache = cacheData.progressEntries.compactMapValues { cached in
                let entries = cached.entries.compactMap { cachedEntry -> ProgressEntry? in
                    guard let field = ProgressField(rawValue: cachedEntry.fieldRawValue) else {
                        return nil
                    }
                    return ProgressEntry(
                        id: cachedEntry.id,
                        clientId: cachedEntry.clientId,
                        field: field,
                        oldValue: cachedEntry.oldValue,
                        newValue: cachedEntry.newValue,
                        changedBy: cachedEntry.changedBy,
                        changedByName: cachedEntry.changedByName,
                        timestamp: cachedEntry.timestamp,
                        note: cachedEntry.note,
                        sessionId: cachedEntry.sessionId
                    )
                }
                return (entries, cached.cacheTimestamp)
            }
            
            // Restore milestones cache
            milestonesCache = cacheData.milestones.compactMapValues { cached in
                let milestones = cached.milestones.compactMap { cachedMilestone -> Milestone? in
                    guard let category = MilestoneCategory(rawValue: cachedMilestone.categoryRawValue) else {
                        return nil
                    }
                    return Milestone(
                        id: cachedMilestone.id,
                        clientId: cachedMilestone.clientId,
                        title: cachedMilestone.title,
                        description: cachedMilestone.description,
                        achievedDate: cachedMilestone.achievedDate,
                        createdBy: cachedMilestone.createdBy,
                        createdByName: cachedMilestone.createdByName,
                        category: category,
                        isAutomatic: cachedMilestone.isAutomatic
                    )
                }
                return (milestones, cached.cacheTimestamp)
            }
            
            // Restore workout completions cache
            workoutCompletionsCache = cacheData.workoutCompletions.mapValues { cached in
                let completions = cached.completions.map { cachedCompletion in
                    ClientProgressService.WorkoutCompletion(
                        id: cachedCompletion.id,
                        workoutTitle: cachedCompletion.workoutTitle,
                        completedDate: cachedCompletion.completedDate,
                        rating: cachedCompletion.rating,
                        duration: cachedCompletion.duration,
                        notes: cachedCompletion.notes
                    )
                }
                return (completions, cached.cacheTimestamp)
            }
            
        } catch {
            // Cache file doesn't exist or is corrupted, start fresh
            progressEntriesCache = [:]
            milestonesCache = [:]
            workoutCompletionsCache = [:]
        }
        
        print("📦 [DEBUG] Loaded progress cache from disk at \(progressCacheURL.path)")
    }
}

// MARK: - Cache Data Models

private struct CacheData: Codable {
    let progressEntries: [String: CachedProgressEntries]
    let milestones: [String: CachedMilestones]
    let workoutCompletions: [String: CachedWorkoutCompletions]
}

private struct CachedProgressEntries: Codable {
    let entries: [CachedProgressEntry]
    let cacheTimestamp: Date
}

private struct CachedProgressEntry: Codable {
    let id: String
    let clientId: String
    let fieldRawValue: String
    let fieldDisplayName: String
    let oldValue: String?
    let newValue: String
    let changedBy: String
    let changedByName: String
    let timestamp: Date
    let note: String?
    let sessionId: String?
}

private struct CachedMilestones: Codable {
    let milestones: [CachedMilestone]
    let cacheTimestamp: Date
}

private struct CachedMilestone: Codable {
    let id: String
    let clientId: String
    let title: String
    let description: String?
    let achievedDate: Date
    let createdBy: String
    let createdByName: String
    let categoryRawValue: String
    let isAutomatic: Bool
}

private struct CachedWorkoutCompletions: Codable {
    let completions: [CachedWorkoutCompletion]
    let cacheTimestamp: Date
}

private struct CachedWorkoutCompletion: Codable {
    let id: String
    let workoutTitle: String
    let completedDate: Date
    let rating: Int
    let duration: Int
    let notes: String
} 