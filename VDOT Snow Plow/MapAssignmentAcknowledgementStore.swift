//
//  MapAssignmentAcknowledgementStore.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation
import Combine

@MainActor
final class MapAssignmentAcknowledgementStore:
    ObservableObject {

    @Published var acknowledgements:
        [MapAssignmentAcknowledgement] = []

    private let cloud =
        CloudMapAssignmentAcknowledgementService.shared

    func syncFromCloud() async {

        do {

            acknowledgements =
                try await cloud
                    .fetchAcknowledgements()

            print(
                "☁️ Map acknowledgements synced:",
                acknowledgements.count
            )

        } catch {

            print(
                "❌ Map acknowledgement sync failed:",
                error
            )
        }
    }

    func acknowledgement(
        for assignmentID: UUID
    ) -> MapAssignmentAcknowledgement? {

        acknowledgements.first {
            $0.assignmentID ==
                assignmentID
        }
    }

    func isAcknowledged(
        assignmentID: UUID
    ) -> Bool {

        acknowledgement(
            for: assignmentID
        ) != nil
    }
    
    
    func acknowledge(
        _ assignment: DriverMapAssignment
    ) async throws {
        
        // Prevent duplicate acknowledgements already loaded.
        guard !isAcknowledged(
            assignmentID: assignment.id
        ) else {
            return
        }
        
        let acknowledgement =
        MapAssignmentAcknowledgement(
            assignmentID: assignment.id,
            driverID: assignment.driverID,
            mapNumber: assignment.mapNumber
        )
        
        // Wait for CloudKit to finish saving.
        try await cloud.saveAcknowledgement(
            acknowledgement
        )
        
        // Update the screen immediately after success.
        acknowledgements.append(acknowledgement)
        
        print(
            "✅ Acknowledgement updated on screen:",
            assignment.mapNumber
        )
    }
}
