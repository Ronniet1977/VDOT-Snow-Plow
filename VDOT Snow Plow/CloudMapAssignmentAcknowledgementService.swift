//
//  CloudMapAssignmentAcknowledgementService.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation
import CloudKit

final class CloudMapAssignmentAcknowledgementService {

    static let shared =
        CloudMapAssignmentAcknowledgementService()

    private init() {}

    private let database =
        CKContainer.default()
            .publicCloudDatabase

    private let recordType =
        "MapAssignmentAcknowledgement"

    func saveAcknowledgement(
        _ acknowledgement:
            MapAssignmentAcknowledgement
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    acknowledgement.id.uuidString
            )

        let record =
            CKRecord(
                recordType:
                    recordType,
                recordID:
                    recordID
            )

        record["assignmentID"] =
            acknowledgement.assignmentID.uuidString

        record["driverID"] =
            acknowledgement.driverID.uuidString

        record["mapNumber"] =
            acknowledgement.mapNumber

        record["acknowledgedAt"] =
            acknowledgement.acknowledgedAt

        try await database.save(
            record
        )

        print(
            "☁️ Map acknowledgement uploaded:",
            acknowledgement.mapNumber,
            "record:",
            record.recordID.recordName
        )
    }

    func fetchAcknowledgements()
    async throws
    -> [MapAssignmentAcknowledgement] {

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

        var acknowledgements:
            [MapAssignmentAcknowledgement] = []

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

                let acknowledgedAt =
                    record["acknowledgedAt"]
                        as? Date

            else {
                continue
            }

            acknowledgements.append(
                MapAssignmentAcknowledgement(
                    id:
                        id,
                    assignmentID:
                        assignmentID,
                    driverID:
                        driverID,
                    mapNumber:
                        mapNumber,
                    acknowledgedAt:
                        acknowledgedAt
                )
            )
        }

        return acknowledgements
            .sorted {
                $0.acknowledgedAt <
                    $1.acknowledgedAt
            }
    }
}
