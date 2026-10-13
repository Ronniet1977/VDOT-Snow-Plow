
import Foundation
import Combine

@MainActor
final class MapAssignmentCompletionStore: ObservableObject {
    
    @Published var completions:
    [MapAssignmentCompletion] = []
    
    private let cloud =
    CloudMapAssignmentCompletionService.shared
    
    // MARK: - Load Completions
    
    func syncFromCloud() async {
        
        do {
            completions = try await cloud.fetchCompletions()
            
            print(
                "☁️ Map completions loaded:",
                completions.count
            )
            
        } catch {
            print(
                "❌ Map completions sync failed:",
                error
            )
        }
    }
    
    // MARK: - Check Completion
    
    func isCompleted(
        assignmentID: UUID
    ) -> Bool {
        
        completions.contains {
            $0.assignmentID == assignmentID
        }
    }
    
    // MARK: - Finish Map
    
    func finish(
        _ assignment: DriverMapAssignment,
        completedBy: String
    ) async throws {
        
        // Refresh first to avoid duplicate completions.
        let cloudCompletions =
        try await cloud.fetchCompletions()
        
        completions = cloudCompletions
        
        guard !isCompleted(
            assignmentID: assignment.id
        ) else {
            print("✅ Map already finished")
            return
        }
        
        let completion = MapAssignmentCompletion(
            assignmentID: assignment.id,
            driverID: assignment.driverID,
            stormID: assignment.stormID,
            mapNumber: assignment.mapNumber,
            completedBy: completedBy,
            completedAt: Date()
        )
        
        // Create an admin-owned record.
        try await cloud.saveCompletion(completion)
        
        // Update the screen after CloudKit confirms.
        completions.append(completion)
        
        print(
            "✅ Map finished:",
            assignment.mapNumber,
            "by:",
            completedBy
        )
    }
}


