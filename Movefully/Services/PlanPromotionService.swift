import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class PlanPromotionService: ObservableObject {
    private let db = Firestore.firestore()
    private let assignmentService = ClientPlanAssignmentService()
    
    /// Checks all trainer's clients for plan promotions when app becomes active
    func checkAllClientsForPromotions() async {
        guard let trainerId = Auth.auth().currentUser?.uid else {
            print("🔄 PlanPromotionService: No authenticated user found")
            return
        }
        
        print("🔄 PlanPromotionService: Checking for plan promotions for trainer: \(trainerId)")
        
        do {
            // Fetch all trainer's clients
            let snapshot = try await db.collection("clients")
                .whereField("trainerId", isEqualTo: trainerId)
                .getDocuments()
            
            print("🔄 PlanPromotionService: Found \(snapshot.documents.count) clients to check")
            
            var promotionsCount = 0
            
            for document in snapshot.documents {
                let data = document.data()
                
                do {
                    let client = try Client.from(data, documentId: document.documentID)
                    
                    if client.shouldPromoteNextPlan {
                        print("🔄 PlanPromotionService: Promoting plan for client: \(client.name)")
                        _ = try await assignmentService.promoteNextPlanToCurrent(client)
                        promotionsCount += 1
                    }
                } catch {
                    print("❌ PlanPromotionService: Error parsing client \(document.documentID): \(error)")
                }
            }
            
            if promotionsCount > 0 {
                print("✅ PlanPromotionService: Successfully promoted \(promotionsCount) plans")
            } else {
                print("✅ PlanPromotionService: No plans needed promotion")
            }
            
        } catch {
            print("❌ PlanPromotionService: Error checking for promotions: \(error)")
        }
    }
    
    /// Check a specific client for plan promotion
    func checkClientForPromotion(_ clientId: String) async {
        do {
            let client = try await assignmentService.fetchClient(clientId)
            
            if client.shouldPromoteNextPlan {
                print("🔄 PlanPromotionService: Promoting plan for client: \(client.name)")
                _ = try await assignmentService.promoteNextPlanToCurrent(client)
                print("✅ PlanPromotionService: Successfully promoted plan for \(client.name)")
            }
        } catch {
            print("❌ PlanPromotionService: Error checking client \(clientId): \(error)")
        }
    }
} 