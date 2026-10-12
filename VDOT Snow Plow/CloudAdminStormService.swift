//
//  CloudAdminStormService.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/11/26.
//

import Foundation
import CloudKit

@MainActor
final class CloudAdminStormService {

    static let shared =
        CloudAdminStormService()

    private let database =
        CKContainer.default()
            .publicCloudDatabase

    private let recordType =
        "AdminStorm"

    private init() {}

    func saveStorm(
        _ storm: Storm,
        isActive: Bool
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    storm.id.uuidString
            )

        let record: CKRecord

        do {

            record =
                try await database.record(
                    for:
                        recordID
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
        }

        record["name"] =
            storm.name

        record["start"] =
            storm.start

        record["end"] =
            storm.end

        record["isActive"] =
            NSNumber(
                value:
                    isActive
            )

        try await database.save(
            record
        )
    }

    func fetchStorms()
    async throws
    -> [(storm: Storm, isActive: Bool)] {

        let query =
            CKQuery(
                recordType:
                    recordType,
                predicate:
                    NSPredicate(
                        value:
                            true
                    )
            )

        let result =
            try await database.records(
                matching:
                    query
            )

        var storms:
            [(Storm, Bool)] = []

        for (_, match)
        in result.matchResults {

            guard case .success(
                let record
            ) = match
            else {
                continue
            }

            guard
                let id =
                    UUID(
                        uuidString:
                            record.recordID
                                .recordName
                    ),
                let name =
                    record["name"]
                    as? String,
                let start =
                    record["start"]
                    as? Date
            else {
                continue
            }

            let end =
                record["end"]
                as? Date

            let isActive =
                (
                    record["isActive"]
                    as? NSNumber
                )?.boolValue
                ?? false

            let storm =
                Storm(
                    id:
                        id,
                    name:
                        name,
                    start:
                        start,
                    end:
                        end
                )

            storms.append(
                (
                    storm,
                    isActive
                )
            )
        }

        return storms
    }
}
