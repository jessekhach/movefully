import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class ProgressHistoryViewModel: ObservableObject {
    @Published var recentEntries: [ProgressEntry] = []
    @Published var allEntries: [ProgressEntry] = []
    @Published var milestones: [Milestone] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let progressService = ProgressHistoryService()
    private var currentClientId: String = ""
    
    // MARK: - Computed Properties
    
    var thisWeekCount: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return recentEntries.filter { $0.timestamp >= startOfWeek }.count
    }
    
    var lastUpdateText: String {
        guard let lastEntry = recentEntries.first else { return "None" }
        
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: lastEntry.timestamp, relativeTo: Date())
    }
    
    // MARK: - Data Loading
    
    func loadProgressData(for clientId: String) {
        guard !clientId.isEmpty else { return }
        
        currentClientId = clientId
        
        Task {
            await loadRecentEntries()
            await loadMilestones()
        }
    }
    
    private func loadRecentEntries() async {
        do {
            isLoading = true
            let entries = try await progressService.fetchRecentProgressSummary(for: currentClientId, days: 30)
            recentEntries = entries
            print("✅ Loaded \(entries.count) recent progress entries")
        } catch {
            errorMessage = "Failed to load progress data"
            print("❌ Failed to load progress entries: \(error)")
        }
        isLoading = false
    }
    
    func loadAllEntries() async {
        do {
            isLoading = true
            let entries = try await progressService.fetchProgressEntries(for: currentClientId)
            allEntries = entries
            print("✅ Loaded \(entries.count) total progress entries")
        } catch {
            errorMessage = "Failed to load progress history"
            print("❌ Failed to load all entries: \(error)")
        }
        isLoading = false
    }
    
    private func loadMilestones() async {
        do {
            let milestones = try await progressService.fetchMilestones(for: currentClientId, limit: 10)
            self.milestones = milestones
            print("✅ Loaded \(milestones.count) milestones")
        } catch {
            print("❌ Failed to load milestones: \(error)")
        }
    }
    
    // MARK: - Progress Entry Operations
    
    func addProgressEntry(field: ProgressField, oldValue: String?, newValue: String, note: String?, changedBy: String, changedByName: String) async {
        let entry = ProgressEntry(
            clientId: currentClientId,
            field: field,
            oldValue: oldValue,
            newValue: newValue,
            changedBy: changedBy,
            changedByName: changedByName,
            note: note
        )
        
        do {
            try await progressService.addProgressEntry(entry)
            
            // Generate automatic milestones if applicable
            await progressService.generateAutomaticMilestones(
                for: currentClientId,
                field: field,
                oldValue: oldValue,
                newValue: newValue
            )
            
            successMessage = "Progress updated successfully"
            
            // Refresh data
            await loadRecentEntries()
            await loadMilestones()
            
            // Clear message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.successMessage = nil
            }
            
        } catch {
            errorMessage = "Failed to add progress entry"
            print("❌ Failed to add progress entry: \(error)")
        }
    }
    
    func deleteProgressEntry(_ entry: ProgressEntry) async {
        do {
            try await progressService.deleteProgressEntry(entry.id)
            
            // Remove from local arrays
            recentEntries.removeAll { $0.id == entry.id }
            allEntries.removeAll { $0.id == entry.id }
            
            successMessage = "Progress entry deleted"
            
            // Clear message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.successMessage = nil
            }
            
        } catch {
            errorMessage = "Failed to delete progress entry"
            print("❌ Failed to delete progress entry: \(error)")
        }
    }
    
    // MARK: - Milestone Operations
    
    func addMilestone(title: String, description: String?, category: MilestoneCategory, createdBy: String, createdByName: String) async {
        let milestone = Milestone(
            clientId: currentClientId,
            title: title,
            description: description,
            createdBy: createdBy,
            createdByName: createdByName,
            category: category
        )
        
        do {
            try await progressService.addMilestone(milestone)
            successMessage = "Milestone added successfully"
            
            // Refresh milestones
            await loadMilestones()
            
            // Clear message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.successMessage = nil
            }
            
        } catch {
            errorMessage = "Failed to add milestone"
            print("❌ Failed to add milestone: \(error)")
        }
    }
    
    func deleteMilestone(_ milestone: Milestone) async {
        do {
            try await progressService.deleteMilestone(milestone.id)
            
            // Remove from local array
            milestones.removeAll { $0.id == milestone.id }
            
            successMessage = "Milestone deleted"
            
            // Clear message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.successMessage = nil
            }
            
        } catch {
            errorMessage = "Failed to delete milestone"
            print("❌ Failed to delete milestone: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    func getEntriesForField(_ field: ProgressField) -> [ProgressEntry] {
        return allEntries.filter { $0.field == field }
    }
    
    func getEntriesForCategory(_ category: ProgressCategory) -> [ProgressEntry] {
        return allEntries.filter { $0.field.category == category }
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
} 