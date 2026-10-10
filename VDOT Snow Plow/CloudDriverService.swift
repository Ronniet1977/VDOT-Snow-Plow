//
//  CloudDriverService.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/9/26.
//

import Foundation
import CloudKit

@MainActor
final class CloudDriverService {

    static let shared =
        CloudDriverService()

    private let database =
        CKContainer.default()
            .privateCloudDatabase

    private init() {}

    // MARK: - Save Driver

    func saveDriver(
        _ driver: CrewDriver
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    driver.id.uuidString
            )

        let record =
            CKRecord(
                recordType:
                    "CrewDriver",
                recordID:
                    recordID
            )

        record["name"] =
            driver.name

        record["truckNumber"] =
            driver.truckNumber

        record["category"] =
            driver.category.rawValue

        record["isActive"] =
            driver.isActive

        try await database.save(
            record
        )
    }

    // MARK: - Fetch Drivers

    func fetchDrivers()
    async throws
    -> [CrewDriver] {

        let query =
            CKQuery(
                recordType:
                    "CrewDriver",
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

        var drivers:
            [CrewDriver] = []

        for (_, recordResult)
        in result.matchResults {

            guard
                case .success(
                    let record
                ) = recordResult
            else {
                continue
            }

            guard
                let id =
                    UUID(
                        uuidString:
                            record.recordID
                                .recordName
                    )
            else {
                continue
            }

            let name =
                record["name"]
                as? String
                ?? ""

            let truckNumber =
                record["truckNumber"]
                as? String
                ?? ""

            let categoryRaw =
                record["category"]
                as? String
                ?? CrewCategory
                    .plowOnly
                    .rawValue

            let category =
                CrewCategory(
                    rawValue:
                        categoryRaw
                )
                ?? .plowOnly

            let isActive =
                record["isActive"]
                as? Bool
                ?? false

            drivers.append(
                CrewDriver(
                    id:
                        id,
                    name:
                        name,
                    truckNumber:
                        truckNumber,
                    category:
                        category,
                    isActive:
                        isActive
                )
            )
        }

        return drivers
            .sorted {
                $0.name
                    .localizedCaseInsensitiveCompare(
                        $1.name
                    )
                ==
                .orderedAscending
            }
    }

    // MARK: - Delete Driver

    func deleteDriver(
        _ driver: CrewDriver
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    driver.id.uuidString
            )

        try await database.deleteRecord(
            withID:
                recordID
        )
    }
}
