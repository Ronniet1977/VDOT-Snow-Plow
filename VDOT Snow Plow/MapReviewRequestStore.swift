//
//  MapReviewRequestStore.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation
import Combine

@MainActor
final class MapReviewRequestStore:
    ObservableObject {

    @Published var requests:
        [MapReviewRequest] = []

    private let cloud =
        CloudMapReviewRequestService.shared

    func syncFromCloud() async {

        do {

            requests =
                try await cloud
                    .fetchRequests()

            print(
                "☁️ Map review requests synced:",
                requests.count
            )

        } catch {

            print(
                "❌ Map review request sync failed:",
                error
            )
        }
    }

    func requestReview(
        assignment: DriverMapAssignment
    ) async {

        let request =
            MapReviewRequest(
                assignmentID:
                    assignment.id,
                driverID:
                    assignment.driverID,
                mapNumber:
                    assignment.mapNumber
            )

        do {

            try await cloud
                .saveRequest(
                    request
                )

            requests.append(
                request
            )

            print(
                "✅ Supervisor review requested:",
                assignment.mapNumber
            )

        } catch {

            print(
                "❌ Supervisor review request failed:",
                error
            )
        }
    }

    func request(
        for assignmentID: UUID
    ) -> MapReviewRequest? {

        requests.first {
            $0.assignmentID ==
                assignmentID
        }
    }

    func hasRequestedReview(
        assignmentID: UUID
    ) -> Bool {

        request(
            for:
                assignmentID
        ) != nil
    }
}
