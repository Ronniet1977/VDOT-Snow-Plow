//
//  MapReviewInspectionStore.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation
import Combine

@MainActor
final class MapReviewInspectionStore:
    ObservableObject {

    @Published var inspections:
        [MapReviewInspection] = []

    private let cloud =
        CloudMapReviewInspectionService.shared

    func syncFromCloud() async {

        do {

            inspections =
                try await cloud
                    .fetchInspections()

            print(
                "☁️ Map review inspections synced:",
                inspections.count
            )

        } catch {

            print(
                "❌ Map review inspection sync failed:",
                error
            )
        }
    }

    func saveInspection(
        request: MapReviewRequest,
        supervisorUserID: UUID,
        progress: MapReviewProgress
    ) async {

        let inspection =
            MapReviewInspection(
                requestID:
                    request.id,
                assignmentID:
                    request.assignmentID,
                supervisorUserID:
                    supervisorUserID,
                mapNumber:
                    request.mapNumber,
                progress:
                    progress
            )

        do {

            try await cloud
                .saveInspection(
                    inspection
                )

            inspections.append(
                inspection
            )

            print(
                "✅ Supervisor inspection saved:",
                request.mapNumber,
                progress.rawValue
            )

        } catch {

            print(
                "❌ Supervisor inspection save failed:",
                error
            )
        }
    }

    func latestInspection(
        for requestID: UUID
    ) -> MapReviewInspection? {

        inspections
            .filter {
                $0.requestID ==
                    requestID
            }
            .sorted {
                $0.checkedAt >
                    $1.checkedAt
            }
            .first
    }
}
