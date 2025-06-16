import Foundation
import Firebase
import FirebaseFirestore

@MainActor
class ProgressHistoryService: ObservableObject {
    private let db = Firestore.firestore()
    
    // MARK: - Progress Entry Operations
    
    func addProgressEntry(_ entry: ProgressEntry) async throws {
        print("📊 Adding progress entry: \(entry.field.displayName) = \(entry.newValue)")
        
        let data: [String: Any] = [
            "clientId": entry.clientId,
            "field": entry.field.rawValue,
            "oldValue": entry.oldValue as Any,
            "newValue": entry.newValue,
            "changedBy": entry.changedBy,
            "changedByName": entry.changedByName,
            "timestamp": entry.timestamp,
            "note": entry.note as Any,
            "sessionId": entry.sessionId as Any
        ]
        
        try await db.collection("progressHistory").document(entry.id).setData(data)
        print("✅ Progress entry added successfully")
    }
    
    func fetchProgressEntries(for clientId: String, field: ProgressField? = nil, limit: Int? = nil) async throws -> [ProgressEntry] {
        print("📊 Fetching progress entries for client: \(clientId)")
        
        var query: Query = db.collection("progressHistory")
            .whereField("clientId", isEqualTo: clientId)
            .order(by: "timestamp", descending: true)
        
        if let field = field {
            query = query.whereField("field", isEqualTo: field.rawValue)
        }
        
        if let limit = limit {
            query = query.limit(to: limit)
        }
        
        let snapshot = try await query.getDocuments()
        let entries = try snapshot.documents.compactMap { document -> ProgressEntry? in
            let data = document.data()
            
            guard let clientId = data["clientId"] as? String,
                  let fieldRaw = data["field"] as? String,
                  let field = ProgressField(rawValue: fieldRaw),
                  let newValue = data["newValue"] as? String,
                  let changedBy = data["changedBy"] as? String,
                  let changedByName = data["changedByName"] as? String,
                  let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
                print("❌ Failed to decode progress entry: \(document.documentID)")
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
        
        print("✅ Fetched \(entries.count) progress entries")
        return entries
    }
    
    func fetchRecentProgressSummary(for clientId: String, days: Int = 30) async throws -> [ProgressEntry] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let snapshot = try await db.collection("progressHistory")
            .whereField("clientId", isEqualTo: clientId)
            .whereField("timestamp", isGreaterThan: cutoffDate)
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
            .getDocuments()
        
        let entries = try snapshot.documents.compactMap { document -> ProgressEntry? in
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
        
        return entries
    }
    
    // MARK: - Milestone Operations
    
    func addMilestone(_ milestone: Milestone) async throws {
        print("🏆 Adding milestone: \(milestone.title)")
        
        let data: [String: Any] = [
            "clientId": milestone.clientId,
            "title": milestone.title,
            "description": milestone.description as Any,
            "achievedDate": milestone.achievedDate,
            "createdBy": milestone.createdBy,
            "createdByName": milestone.createdByName,
            "category": milestone.category.rawValue,
            "isAutomatic": milestone.isAutomatic
        ]
        
        try await db.collection("milestones").document(milestone.id).setData(data)
        print("✅ Milestone added successfully")
    }
    
    func fetchMilestones(for clientId: String, limit: Int? = nil) async throws -> [Milestone] {
        print("🏆 Fetching milestones for client: \(clientId)")
        
        var query: Query = db.collection("milestones")
            .whereField("clientId", isEqualTo: clientId)
            .order(by: "achievedDate", descending: true)
        
        if let limit = limit {
            query = query.limit(to: limit)
        }
        
        let snapshot = try await query.getDocuments()
        let milestones = try snapshot.documents.compactMap { document -> Milestone? in
            let data = document.data()
            
            guard let clientId = data["clientId"] as? String,
                  let title = data["title"] as? String,
                  let achievedDate = (data["achievedDate"] as? Timestamp)?.dateValue(),
                  let createdBy = data["createdBy"] as? String,
                  let createdByName = data["createdByName"] as? String,
                  let categoryRaw = data["category"] as? String,
                  let category = MilestoneCategory(rawValue: categoryRaw),
                  let isAutomatic = data["isAutomatic"] as? Bool else {
                print("❌ Failed to decode milestone: \(document.documentID)")
                return nil
            }
            
            return Milestone(
                id: document.documentID,
                clientId: clientId,
                title: title,
                description: data["description"] as? String,
                achievedDate: achievedDate,
                createdBy: createdBy,
                createdByName: createdByName,
                category: category,
                isAutomatic: isAutomatic
            )
        }
        
        print("✅ Fetched \(milestones.count) milestones")
        return milestones
    }
    
    // MARK: - Utility Methods
    
    func generateAutomaticMilestones(for clientId: String, field: ProgressField, oldValue: String?, newValue: String) async {
        // Generate automatic milestones for significant progress
        if field == .weight, let old = Double(oldValue ?? "0"), let new = Double(newValue) {
            let weightLoss = old - new
            
            if weightLoss >= 5 {
                let milestone = Milestone(
                    clientId: clientId,
                    title: "Lost \(Int(weightLoss)) lbs!",
                    description: "Congratulations on your weight loss progress!",
                    createdBy: "system",
                    createdByName: "Movefully",
                    category: .weightLoss,
                    isAutomatic: true
                )
                
                do {
                    try await addMilestone(milestone)
                } catch {
                    print("❌ Failed to add automatic milestone: \(error)")
                }
            }
        }
    }
    
    func deleteProgressEntry(_ entryId: String) async throws {
        try await db.collection("progressHistory").document(entryId).delete()
        print("✅ Progress entry deleted: \(entryId)")
    }
    
    func deleteMilestone(_ milestoneId: String) async throws {
        try await db.collection("milestones").document(milestoneId).delete()
        print("✅ Milestone deleted: \(milestoneId)")
    }
    
    // MARK: - Analytics Methods
    
    func getProgressAnalytics(for clientId: String, days: Int = 90) async throws -> ProgressAnalytics {
        let entries = try await fetchProgressEntries(for: clientId)
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentEntries = entries.filter { $0.timestamp >= cutoffDate }
        
        var fieldCounts: [ProgressField: Int] = [:]
        var weeklyActivity: [String: Int] = [:]
        
        for entry in recentEntries {
            fieldCounts[entry.field, default: 0] += 1
            
            let weekOfYear = Calendar.current.component(.weekOfYear, from: entry.timestamp)
            let year = Calendar.current.component(.year, from: entry.timestamp)
            let weekKey = "\(year)-W\(weekOfYear)"
            weeklyActivity[weekKey, default: 0] += 1
        }
        
        return ProgressAnalytics(
            totalEntries: recentEntries.count,
            mostTrackedField: fieldCounts.max(by: { $0.value < $1.value })?.key,
            averageEntriesPerWeek: calculateAverageEntriesPerWeek(weeklyActivity),
            fieldBreakdown: fieldCounts,
            weeklyActivity: weeklyActivity
        )
    }
    
    func getProgressChartData(for clientId: String, field: ProgressField, days: Int = 90) async throws -> [ProgressChartDataPoint] {
        let entries = try await fetchProgressEntries(for: clientId, field: field)
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentEntries = entries.filter { $0.timestamp >= cutoffDate }
        
        return recentEntries.compactMap { entry in
            guard let value = Double(entry.newValue) else { return nil }
            return ProgressChartDataPoint(
                date: entry.timestamp,
                value: value,
                field: field,
                note: entry.note
            )
        }.sorted { $0.date < $1.date }
    }
    
    func exportProgressData(for clientId: String, format: ExportFormat = .csv) async throws -> String {
        let entries = try await fetchProgressEntries(for: clientId)
        let milestones = try await fetchMilestones(for: clientId)
        
        switch format {
        case .csv:
            return generateCSVExport(entries: entries, milestones: milestones)
        case .json:
            return try generateJSONExport(entries: entries, milestones: milestones)
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func calculateAverageEntriesPerWeek(_ weeklyActivity: [String: Int]) -> Double {
        guard !weeklyActivity.isEmpty else { return 0 }
        let totalEntries = weeklyActivity.values.reduce(0, +)
        return Double(totalEntries) / Double(weeklyActivity.count)
    }
    
    private func generateCSVExport(entries: [ProgressEntry], milestones: [Milestone]) -> String {
        var csv = "Progress Entries\n"
        csv += "Date,Field,Old Value,New Value,Changed By,Note\n"
        
        for entry in entries {
            let dateString = DateFormatter.shortDate.string(from: entry.timestamp)
            csv += "\(dateString),\(entry.field.displayName),\(entry.oldValue ?? ""),\(entry.newValue),\(entry.changedByName),\"\(entry.note ?? "")\"\n"
        }
        
        csv += "\n\nMilestones\n"
        csv += "Date,Title,Description,Category,Created By\n"
        
        for milestone in milestones {
            let dateString = DateFormatter.shortDate.string(from: milestone.achievedDate)
            csv += "\(dateString),\"\(milestone.title)\",\"\(milestone.description ?? "")\",\(milestone.category.displayName),\(milestone.createdByName)\n"
        }
        
        return csv
    }
    
    private func generateJSONExport(entries: [ProgressEntry], milestones: [Milestone]) throws -> String {
        let exportData = ProgressExportData(
            exportDate: Date(),
            progressEntries: entries.map { entry in
                ProgressExportEntry(
                    date: entry.timestamp,
                    field: entry.field.displayName,
                    oldValue: entry.oldValue,
                    newValue: entry.newValue,
                    changedBy: entry.changedByName,
                    note: entry.note
                )
            },
            milestones: milestones.map { milestone in
                MilestoneExportEntry(
                    date: milestone.achievedDate,
                    title: milestone.title,
                    description: milestone.description,
                    category: milestone.category.displayName,
                    createdBy: milestone.createdByName
                )
            }
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(exportData)
        return String(data: data, encoding: .utf8) ?? ""
    }
} 