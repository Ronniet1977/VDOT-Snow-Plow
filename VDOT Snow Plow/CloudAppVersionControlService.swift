//
//  CloudAppVersionControlService.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/12/26.
//

import Foundation
import CloudKit

@MainActor
final class CloudAppVersionControlService {

    static let shared =
        CloudAppVersionControlService()

    private let database =
        CKContainer.default()
            .publicCloudDatabase

    private let recordType =
        "AppVersionControl"

    private init() {}

    func saveControl(
        _ control:
            AppVersionControl
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    control.id.uuidString
            )

        let record =
            CKRecord(
                recordType:
                    recordType,
                recordID:
                    recordID
            )

        record["minimumVersion"] =
            control.minimumVersion

        record["minimumBuild"] =
            NSNumber(
                value:
                    control.minimumBuild
            )

        record["message"] =
            control.message

        record["updatedAt"] =
            control.updatedAt

        try await database.save(
            record
        )

        print(
            "☁️ Version control saved:",
            control.minimumBuild
        )
    }

    func fetchControl()
    async throws
    -> AppVersionControl? {

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

        var controls:
            [AppVersionControl] = []

        for (_, match)
        in result.matchResults {

            guard
                case .success(
                    let record
                ) = match,
                let id =
                    UUID(
                        uuidString:
                            record.recordID
                                .recordName
                    )
            else {
                continue
            }

            let minimumVersion =
                record["minimumVersion"]
                    as? String
                ?? "1.0"

            let minimumBuild =
                (
                    record["minimumBuild"]
                        as? NSNumber
                )?.intValue
                ?? 0

            let message =
                record["message"]
                    as? String
                ?? "Please update VDOT Snow Plow to continue."

            let updatedAt =
                record["updatedAt"]
                    as? Date
                ?? .distantPast

            controls.append(
                AppVersionControl(
                    id:
                        id,
                    minimumVersion:
                        minimumVersion,
                    minimumBuild:
                        minimumBuild,
                    message:
                        message,
                    updatedAt:
                        updatedAt
                )
            )
        }

        return controls
            .sorted {
                $0.updatedAt >
                    $1.updatedAt
            }
            .first
    }
}
