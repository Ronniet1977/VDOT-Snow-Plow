//
//  CloudUserAppStatusService.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/12/26.
//

import Foundation
import CloudKit

@MainActor
final class CloudUserAppStatusService {

    static let shared =
        CloudUserAppStatusService()

    private let database =
        CKContainer.default()
            .publicCloudDatabase

    private let recordType =
        "UserAppStatus"

    private init() {}

    func saveStatus(
        _ status: UserAppStatus
    ) async throws {

        let safeAppleUserID =
            status.appleUserID
                .replacingOccurrences(
                    of: "/",
                    with: "_"
                )

        let recordID =
            CKRecord.ID(
                recordName:
                    "UserAppStatus-\(safeAppleUserID)"
            )

        let record: CKRecord

        do {

            record =
                try await database
                    .record(
                        for:
                            recordID
                    )

            print(
                "☁️ Updating existing app status"
            )

        } catch let error as CKError
            where error.code == .unknownItem {

            record =
                CKRecord(
                    recordType:
                        recordType,
                    recordID:
                        recordID
                )

            print(
                "☁️ Creating new app status"
            )
        }

        record["appleUserID"] =
            status.appleUserID

        record["appVersion"] =
            status.appVersion

        record["buildNumber"] =
            NSNumber(
                value:
                    status.buildNumber
            )

        record["lastSeenAt"] =
            status.lastSeenAt

        try await database.save(
            record
        )

        print(
            "☁️ User app status saved:",
            status.appleUserID,
            "build:",
            status.buildNumber
        )
    }

    func fetchStatuses()
    async throws
    -> [UserAppStatus] {

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

        var statuses:
            [UserAppStatus] = []

        for (_, match)
        in result.matchResults {

            guard
                case .success(
                    let record
                ) = match,
                let appleUserID =
                    record["appleUserID"]
                        as? String
            else {
                continue
            }

            let appVersion =
                record["appVersion"]
                    as? String
                ?? "Unknown"

            let buildNumber =
                (
                    record["buildNumber"]
                        as? NSNumber
                )?.intValue
                ?? 0

            let lastSeenAt =
                record["lastSeenAt"]
                    as? Date
                ?? .distantPast

            statuses.append(
                UserAppStatus(
                    appleUserID:
                        appleUserID,
                    appVersion:
                        appVersion,
                    buildNumber:
                        buildNumber,
                    lastSeenAt:
                        lastSeenAt
                )
            )
        }

        return statuses
    }
}
