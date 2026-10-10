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
}
