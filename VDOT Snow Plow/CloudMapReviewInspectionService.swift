//
//  CloudMapReviewInspectionService.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation
import CloudKit

final class CloudMapReviewInspectionService {

    static let shared =
        CloudMapReviewInspectionService()

    private init() {}

    private let database =
        CKContainer.default()
            .publicCloudDatabase

    private let recordType =
        "MapReviewInspection"

    func saveInspection(
        _ inspection: MapReviewInspection
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    inspection.id.uuidString
            )

        let record =
            CKRecord(
                recordType:
                    recordType,
                recordID:
                    recordID
            )

        record["requestID"] =
            inspection.requestID.uuidString

        record["assignmentID"] =
            inspection.assignmentID.uuidString

        record["supervisorUserID"] =
            inspection.supervisorUserID.uuidString

        record["mapNumber"] =
            inspection.mapNumber

        record["progress"] =
            inspection.progress.rawValue

        record["checkedAt"] =
            inspection.checkedAt

        try await database.save(
            record
        )

        print(
            "☁️ Map review inspection uploaded:",
            inspection.mapNumber,
            inspection.progress.rawValue
        )
    }

    func fetchInspections()
    async throws
    -> [MapReviewInspection] {

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

        var inspections:
            [MapReviewInspection] = []

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

                let requestIDString =
                    record["requestID"]
                        as? String,

                let requestID =
                    UUID(
                        uuidString:
                            requestIDString
                    ),

                let assignmentIDString =
                    record["assignmentID"]
                        as? String,

                let assignmentID =
                    UUID(
                        uuidString:
                            assignmentIDString
                    ),

                let supervisorUserIDString =
                    record["supervisorUserID"]
                        as? String,

                let supervisorUserID =
                    UUID(
                        uuidString:
                            supervisorUserIDString
                    ),

                let mapNumber =
                    record["mapNumber"]
                        as? String,

                let progressRaw =
                    record["progress"]
                        as? String,

                let progress =
                    MapReviewProgress(
                        rawValue:
                            progressRaw
                    ),

                let checkedAt =
                    record["checkedAt"]
                        as? Date

            else {
                continue
            }

            inspections.append(
                MapReviewInspection(
                    id:
                        id,
                    requestID:
                        requestID,
                    assignmentID:
                        assignmentID,
                    supervisorUserID:
                        supervisorUserID,
                    mapNumber:
                        mapNumber,
                    progress:
                        progress,
                    checkedAt:
                        checkedAt
                )
            )
        }

        return inspections.sorted {
            $0.checkedAt <
                $1.checkedAt
        }
    }
}
