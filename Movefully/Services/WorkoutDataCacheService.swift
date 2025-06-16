import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class WorkoutDataCacheService: ObservableObject {
    static let shared = WorkoutDataCacheService()
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
    private var cachedProgram: [String: Any]?
    private var cachedScheduledWorkouts: [[String: Any]]?
    private var cachedTemplates: [String: [String: Any]] = [:]  // templateId -> templateData
    private var lastCacheUpdate: Date?
    private var cacheExpirationInterval: TimeInterval = 300 // 5 minutes
    
    private let programCacheURL: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("cachedProgram.json")
    }()
    private let templatesCacheURL: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("cachedTemplates.json")
    }()
    
    // MARK: - Public Methods
    
    /// Fetches and caches the current program data
    func fetchAndCacheProgram() async throws -> [String: Any] {
        guard let clientId = currentClientId else {
            throw NSError(domain: "WorkoutDataCacheService", code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        // Check if cache is valid
        if let lastUpdate = lastCacheUpdate,
           Date().timeIntervalSince(lastUpdate) < cacheExpirationInterval,
           let cached = cachedProgram {
            print("📦 WorkoutDataCacheService: Using cached program data")
            return cached
        }
        
        print("🔍 WorkoutDataCacheService: Fetching fresh program data")
        
        // Fetch client's current program
        let clientDoc = try await db.collection("clients").document(clientId).getDocument()
        
        guard let clientData = clientDoc.data(),
              let currentPlanId = clientData["currentPlanId"] as? String else {
            throw NSError(domain: "WorkoutDataCacheService", code: 2,
                         userInfo: [NSLocalizedDescriptionKey: "No current plan assigned"])
        }
        
        // Fetch program details
        let programDoc = try await db.collection("programs").document(currentPlanId).getDocument()
        
        guard let programData = programDoc.data() else {
            throw NSError(domain: "WorkoutDataCacheService", code: 3,
                         userInfo: [NSLocalizedDescriptionKey: "Program not found"])
        }
        
        // Cache the data
        cachedProgram = programData
        cachedScheduledWorkouts = programData["scheduledWorkouts"] as? [[String: Any]]
        lastCacheUpdate = Date()
        saveCacheToDisk()
        
        print("✅ WorkoutDataCacheService: Program data cached successfully")
        return programData
    }
    
    /// Gets cached scheduled workouts
    func getCachedScheduledWorkouts() -> [[String: Any]]? {
        return cachedScheduledWorkouts
    }
    
        /// Fetches and caches a template
    func fetchAndCacheTemplate(templateId: String) async throws -> [String: Any] {
        // Check if template is already cached
        if let cachedTemplate = cachedTemplates[templateId] {
            print("📦 WorkoutDataCacheService: Using cached template data for \(templateId)")
            return cachedTemplate
        }

        print("🔍 WorkoutDataCacheService: Fetching fresh template data for \(templateId)")
        
        // Fetch template from Firestore
        let templateDoc = try await db.collection("templates").document(templateId).getDocument()
        
        guard let templateData = templateDoc.data() else {
            throw NSError(domain: "WorkoutDataCacheService", code: 4,
                         userInfo: [NSLocalizedDescriptionKey: "Template not found"])
        }
        
        // Cache the template data
        cachedTemplates[templateId] = templateData
        saveCacheToDisk()
        
        print("✅ WorkoutDataCacheService: Template data cached successfully")
        return templateData
    }
    
    /// Clears the cache
    func clearCache() {
        cachedProgram = nil
        cachedScheduledWorkouts = nil
        cachedTemplates.removeAll()
        lastCacheUpdate = nil
        do {
            try? FileManager.default.removeItem(at: programCacheURL)
            print("🧹 [DEBUG] Cleared program cache from disk at \(programCacheURL.path)")
        } catch {}
        do {
            try? FileManager.default.removeItem(at: templatesCacheURL)
            print("🧹 [DEBUG] Cleared templates cache from disk at \(templatesCacheURL.path)")
        } catch {}
        print("🧹 WorkoutDataCacheService: Cache cleared")
    }
    
    /// Clears all caches (alias for clearCache for consistency)
    func clearAllCaches() {
        clearCache()
    }
    
    /// Checks if cache is valid
    func isCacheValid() -> Bool {
        guard let lastUpdate = lastCacheUpdate else { return false }
        return Date().timeIntervalSince(lastUpdate) < cacheExpirationInterval
    }
    
    /// Refreshes all cache on app launch: clears cache, fetches fresh program and templates
    func refreshOnLaunch() async {
        print("🔄 [DEBUG] Refreshing cache on app launch...")
        clearCache()
        do {
            let program = try await fetchAndCacheProgram()
            print("🔄 [DEBUG] Fetched and cached program on launch")
            if let scheduledWorkouts = program["scheduledWorkouts"] as? [[String: Any]] {
                let templateIds = scheduledWorkouts.compactMap { $0["workoutTemplateId"] as? String }.filter { !$0.isEmpty }
                let uniqueTemplateIds = Set(templateIds)
                for templateId in uniqueTemplateIds {
                    do {
                        _ = try await fetchAndCacheTemplate(templateId: templateId)
                        print("🔄 [DEBUG] Fetched and cached template \(templateId) on launch")
                    } catch {
                        print("❌ [DEBUG] Failed to fetch template \(templateId) on launch: \(error)")
                    }
                }
            }
        } catch {
            print("❌ [DEBUG] Failed to fetch program on launch: \(error)")
        }
    }
    
    // MARK: - Disk Persistence
    private func sanitizeForJSON(_ value: Any) -> Any {
        if let timestamp = value as? Timestamp {
            return timestamp.dateValue().iso8601String
        } else if let dict = value as? [String: Any] {
            return dict.mapValues { sanitizeForJSON($0) }
        } else if let array = value as? [Any] {
            return array.map { sanitizeForJSON($0) }
        } else {
            return value
        }
    }
    private func saveCacheToDisk() {
        // Save program
        if let program = cachedProgram {
            do {
                let sanitized = sanitizeForJSON(program) as! [String: Any]
                let data = try JSONSerialization.data(withJSONObject: sanitized, options: [])
                try data.write(to: programCacheURL)
                print("💾 [DEBUG] Saved program cache to disk at \(programCacheURL.path)")
            } catch {
                print("❌ WorkoutDataCacheService: Failed to save program cache: \(error)")
            }
        }
        // Save templates
        do {
            let sanitized = cachedTemplates.mapValues { sanitizeForJSON($0) as! [String: Any] }
            let data = try JSONSerialization.data(withJSONObject: sanitized, options: [])
            try data.write(to: templatesCacheURL)
            print("💾 [DEBUG] Saved templates cache to disk at \(templatesCacheURL.path)")
        } catch {
            print("❌ WorkoutDataCacheService: Failed to save templates cache: \(error)")
        }
    }
    private func loadCacheFromDisk() {
        // Load program
        if let data = try? Data(contentsOf: programCacheURL),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            cachedProgram = obj
            cachedScheduledWorkouts = obj["scheduledWorkouts"] as? [[String: Any]]
            print("📦 [DEBUG] Loaded program cache from disk at \(programCacheURL.path)")
        } else {
            print("📦 [DEBUG] No program cache found on disk at \(programCacheURL.path)")
        }
        // Load templates
        if let data = try? Data(contentsOf: templatesCacheURL),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] {
            cachedTemplates = obj
            print("📦 [DEBUG] Loaded templates cache from disk at \(templatesCacheURL.path)")
        } else {
            print("📦 [DEBUG] No templates cache found on disk at \(templatesCacheURL.path)")
        }
    }
}

extension Date {
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
} 