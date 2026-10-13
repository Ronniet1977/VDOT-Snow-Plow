import Foundation
import SwiftUI
import Combine

@MainActor
final class DriverMapAssignmentStore: ObservableObject {
    
    @Published var assignments:
    [DriverMapAssignment] = []
    
    private let fileName =
    "DriverMapAssignments.json"
    
    private let cloud =
        CloudDriverMapAssignmentService.shared
    
    init() {
        load()
    }
    
    func load() {
        assignments =
        LocalStore.shared.load(
            [DriverMapAssignment].self,
            fileName: fileName,
            defaultValue: []
        )
    }
    
    func save() {
        LocalStore.shared.save(
            assignments,
            fileName: fileName
        )
    }
    
    func currentAssignments(
        driverID: UUID,
        stormID: UUID
    ) -> [DriverMapAssignment] {
        
        assignments.filter {
            $0.driverID == driverID &&
            $0.stormID == stormID &&
            $0.completedAt == nil
        }
    }
    
    func assignMap(
        driverID: UUID,
        stormID: UUID,
        mapNumber: String
    ) {
        
        let alreadyAssigned = assignments.contains { assignment in
            
            assignment.driverID == driverID &&
            assignment.stormID == stormID &&
            assignment.mapNumber == mapNumber &&
            !assignment.isCompleted
        }
        
        guard !alreadyAssigned else {
            
            print(
                "⚠️ Map \(mapNumber) is already assigned to this driver."
            )
            
            return
        }

        let assignment =
            DriverMapAssignment(
                driverID: driverID,
                stormID: stormID,
                mapNumber: mapNumber
            )

        assignments.append(
            assignment
        )

        save()

        Task {

            do {

                try await cloud
                    .saveAssignment(
                        assignment
                    )

                print(
                    "☁️ Map assignment uploaded:",
                    assignment.mapNumber
                )

            } catch {

                print(
                    "❌ Map assignment CloudKit save failed:",
                    error
                )
            }
        }
    }
    
    
    func finish(
        _ assignment: DriverMapAssignment
    ) async throws {
        
        guard let index = assignments.firstIndex(
            where: { $0.id == assignment.id }
        ) else {
            throw NSError(
                domain: "MapAssignment",
                code: 404,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Map assignment was not found."
                ]
            )
        }
        
        var updated = assignments[index]
        updated.completedAt = Date()
        
        // CloudKit must confirm before changing local state.
        try await cloud.saveAssignment(updated)
        
        assignments[index] = updated
        save()
        
        print(
            "✅ Map assignment finished in CloudKit:",
            updated.mapNumber
        )
    }
    
    func acknowledge(
        _ assignment: DriverMapAssignment
    ) {

        let acknowledgement =
            MapAssignmentAcknowledgement(
                assignmentID:
                    assignment.id,
                driverID:
                    assignment.driverID,
                mapNumber:
                    assignment.mapNumber
            )

        Task {

            do {

                try await
                    CloudMapAssignmentAcknowledgementService
                        .shared
                        .saveAcknowledgement(
                            acknowledgement
                        )

                print(
                    "✅ Map acknowledged:",
                    assignment.mapNumber
                )

            } catch {

                print(
                    "❌ Map acknowledgement upload failed:",
                    error
                )
            }
        }
    }
    
    func syncFromCloud() async {

        do {

            let cloudAssignments =
                try await cloud
                    .fetchAssignments()

            assignments =
                cloudAssignments

            save()

            print(
                "☁️ Map assignments synced:",
                assignments.count
            )

        } catch {

            print(
                "❌ Map assignment sync failed:",
                error
            )
        }
    }
    
    func reassignDriver(
        from oldDriverID: UUID,
        to newDriverID: UUID
    ) async {

        for index in assignments.indices {

            guard
                assignments[index].driverID ==
                    oldDriverID
            else {
                continue
            }

            assignments[index].driverID =
                newDriverID

            let updated =
                assignments[index]

            do {

                try await cloud
                    .saveAssignment(
                        updated
                    )

                print(
                    "🔄 Reassigned map",
                    updated.mapNumber,
                    "to new driver ID"
                )

            } catch {

                print(
                    "❌ Map reassignment failed:",
                    updated.mapNumber,
                    error
                )
            }
        }

        save()
    }
    
    func finishAssignments(
        for stormID: UUID
    ) async {

        let activeAssignments =
            assignments.filter {
                $0.stormID == stormID &&
                $0.completedAt == nil
            }

        for assignment in activeAssignments {

            guard let index =
                assignments.firstIndex(
                    where: {
                        $0.id == assignment.id
                    }
                )
            else {
                continue
            }

            assignments[index].completedAt =
                Date()

            let updated =
                assignments[index]

            do {

                try await cloud
                    .saveAssignment(
                        updated
                    )

                print(
                    "✅ Storm map finished:",
                    updated.mapNumber
                )

            } catch {

                print(
                    "❌ Storm map finish failed:",
                    updated.mapNumber,
                    error
                )
            }
        }

        save()
    }
    
    
    
    func assignMapSafely(
        driverID: UUID,
        stormID: UUID,
        mapNumber: String
    ) async throws -> Bool {
        
        // Fetch the latest assignments.
        let cloudAssignments =
        try await cloud.fetchAssignments()
        
        // Fetch creator-safe completion records.
        let completions =
        try await
        CloudMapAssignmentCompletionService
            .shared
            .fetchCompletions()
        
        let completedIDs = Set(
            completions.map(\.assignmentID)
        )
        
        // Check for an existing unfinished assignment.
        let alreadyAssigned = cloudAssignments.contains {
            assignment in
            
            assignment.driverID == driverID &&
            assignment.stormID == stormID &&
            assignment.mapNumber == mapNumber &&
            !assignment.isCompleted &&
            !completedIDs.contains(assignment.id)
        }
        
        guard !alreadyAssigned else {
            
            print(
                "⚠️ Map \(mapNumber) is already assigned to this driver."
            )
            
            return false
        }
        
        // Create a new assignment.
        let assignment = DriverMapAssignment(
            driverID: driverID,
            stormID: stormID,
            mapNumber: mapNumber
        )
        
        // Wait for CloudKit to confirm the save.
        try await cloud.saveAssignment(assignment)
        
        // Update the local assignments.
        assignments.append(assignment)
        save()
        
        print(
            "✅ Map assigned successfully:",
            mapNumber
        )
        
        return true
    }
}

