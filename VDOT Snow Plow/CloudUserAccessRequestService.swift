//
//  CloudUserAccessRequestService.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation
import CloudKit

final class CloudUserAccessRequestService {

    static let shared =
        CloudUserAccessRequestService()

    private init() {}

    private let database =
        CKContainer.default()
            .publicCloudDatabase

    private let recordType =
        "UserAccessRequest"

    func saveRequest(
        _ request: UserAccessRequest
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    request.id.uuidString
            )

        let record: CKRecord

        do {

            record =
                try await database.record(
                    for: recordID
                )

        } catch let error as CKError
        where error.code == .unknownItem {

            record =
                CKRecord(
                    recordType: recordType,
                    recordID: recordID
                )
        }

        record["appleUserID"] =
            request.appleUserID

        record["name"] =
            request.name

        record["companyName"] =
            request.companyName

        record["truckVINLast4"] =
            request.truckVINLast4

        record["requestedAt"] =
            request.requestedAt

        record["status"] =
            request.status

        try await database.save(
            record
        )
    }

    func fetchRequests()
    async throws
    -> [UserAccessRequest] {

        let query =
            CKQuery(
                recordType: recordType,
                predicate:
                    NSPredicate(
                        value: true
                    )
            )

        let result =
            try await database.records(
                matching: query
            )

        var requests:
        [UserAccessRequest] = []

        for (_, matchResult) in
            result.matchResults {

            switch matchResult {

            case .success(let record):

                guard
                    let id =
                        UUID(
                            uuidString:
                                record.recordID
                                    .recordName
                        ),
                    let appleUserID =
                        record[
                            "appleUserID"
                        ] as? String,
                    let name =
                        record[
                            "name"
                        ] as? String,
                    let companyName =
                        record[
                            "companyName"
                        ] as? String,
                    let truckVINLast4 =
                        record[
                            "truckVINLast4"
                        ] as? String,
                    let requestedAt =
                        record[
                            "requestedAt"
                        ] as? Date,
                    let status =
                        record[
                            "status"
                        ] as? String
                else {
                    continue
                }

                requests.append(
                    UserAccessRequest(
                        id: id,
                        appleUserID:
                            appleUserID,
                        name: name,
                        companyName:
                            companyName,
                        truckVINLast4:
                            truckVINLast4,
                        requestedAt:
                            requestedAt,
                        status:
                            status
                    )
                )

            case .failure(let error):

                print(
                    "❌ Request fetch error:",
                    error
                )
            }
        }

        return requests
            .sorted {
                $0.requestedAt >
                    $1.requestedAt
            }
    }

    func deleteRequest(
        _ request: UserAccessRequest
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    request.id.uuidString
            )

        try await database.deleteRecord(
            withID: recordID
        )
    }
}
