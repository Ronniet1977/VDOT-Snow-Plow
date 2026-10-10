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
    ) {

        guard let index =
            assignments.firstIndex(
                where: {
                    $0.id ==
                        assignment.id
                }
            )
        else {
            return
        }

        assignments[index]
            .completedAt =
            Date()

        let updated =
            assignments[index]

        save()

        Task {

            do {

                try await cloud
                    .saveAssignment(
                        updated
                    )

                print(
                    "☁️ Map assignment finished:",
                    updated.mapNumber
                )

            } catch {

                print(
                    "❌ Map assignment finish sync failed:",
                    error
                )
            }
        }
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
}

