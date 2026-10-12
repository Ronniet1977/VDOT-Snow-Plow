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

        for (_, match)
        in result.matchResults {

            guard
                case .success(
                    let record
                ) = match
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
                ?? "Please update the app to continue."

            return AppVersionControl(
                minimumVersion:
                    minimumVersion,
                minimumBuild:
                    minimumBuild,
                message:
                    message
            )
        }

        return nil
    }
}
