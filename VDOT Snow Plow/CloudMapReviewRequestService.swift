//
//  CloudMapReviewRequestService.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation
import CloudKit

final class CloudMapReviewRequestService {

    static let shared =
        CloudMapReviewRequestService()

    private init() {}

    private let database =
        CKContainer.default()
            .publicCloudDatabase

    private let recordType =
        "MapReviewRequest"

    func saveRequest(
        _ request: MapReviewRequest
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    request.id.uuidString
            )

        let record =
            CKRecord(
                recordType:
                    recordType,
                recordID:
                    recordID
            )

        record["assignmentID"] =
            request.assignmentID.uuidString

        record["driverID"] =
            request.driverID.uuidString

        record["mapNumber"] =
            request.mapNumber

        record["requestedAt"] =
            request.requestedAt

        record["status"] =
            request.status

        try await database.save(
            record
        )

        print(
            "☁️ Map review request uploaded:",
            request.mapNumber
        )
    }

    func fetchRequests()
    async throws
    -> [MapReviewRequest] {

        let query =
            CKQuery(
                recordType:
                    recordType,
                predicate:
                    NSPredicate(
                        value: true
                    )
            )

        let result =
            try await database.records(
                matching:
                    query
            )

        var requests:
            [MapReviewRequest] = []

        for (_, matchResult)
        in result.matchResults {

            guard
                case .success(
                    let record
                ) = matchResult,

                let id =
                    UUID(
                        uuidString:
                            record.recordID
                                .recordName
                    ),

                let assignmentIDString =
                    record["assignmentID"]
                        as? String,

                let assignmentID =
                    UUID(
                        uuidString:
                            assignmentIDString
                    ),

                let driverIDString =
                    record["driverID"]
                        as? String,

                let driverID =
                    UUID(
                        uuidString:
                            driverIDString
                    ),

                let mapNumber =
                    record["mapNumber"]
                        as? String,

                let requestedAt =
                    record["requestedAt"]
                        as? Date,

                let status =
                    record["status"]
                        as? String

            else {
                continue
            }

            requests.append(
                MapReviewRequest(
                    id:
                        id,
                    assignmentID:
                        assignmentID,
                    driverID:
                        driverID,
                    mapNumber:
                        mapNumber,
                    requestedAt:
                        requestedAt,
                    status:
                        status
                )
            )
        }

        return requests.sorted {
            $0.requestedAt <
                $1.requestedAt
        }
    }
}
