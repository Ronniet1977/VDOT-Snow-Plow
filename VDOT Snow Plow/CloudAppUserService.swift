//
//  CloudAppUserService.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/9/26.
//

import Foundation
import CloudKit

@MainActor
final class CloudAppUserService {

    static let shared =
        CloudAppUserService()

    private let database =
        CKContainer.default()
            .publicCloudDatabase

    private init() {}

    func saveUser(
        _ user: AppUser
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    user.id.uuidString
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
                    recordType:
                        "AppUser",
                    recordID:
                        recordID
                )
        }

        record["name"] =
            user.name

        record["role"] =
            user.role.rawValue

        record["category"] =
            user.category?.rawValue

        record["isActive"] =
            NSNumber(
                value:
                    user.isActive
            )

        try await database.save(
            record
        )
    }

    func fetchUsers()
    async throws
    -> [AppUser] {

        let query =
            CKQuery(
                recordType:
                    "AppUser",
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

        var users:
            [AppUser] = []

        for (_, result)
        in result.matchResults {

            guard
                case .success(
                    let record
                ) = result
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

            let roleRaw =
                record["role"]
                as? String
                ?? AppUserRole
                    .driver
                    .rawValue

            let role =
                AppUserRole(
                    rawValue:
                        roleRaw
                )
                ?? .driver

            let categoryRaw =
                record["category"]
                as? String

            let category =
                categoryRaw.flatMap {
                    CrewCategory(
                        rawValue:
                            $0
                    )
                }

            let isActive =
                (
                    record["isActive"]
                    as? NSNumber
                )?.boolValue
                ?? true

            users.append(
                AppUser(
                    id:
                        id,
                    name:
                        name,
                    role:
                        role,
                    category:
                        category,
                    isActive:
                        isActive
                )
            )
        }

        return users.sorted {
            $0.name
                .localizedCaseInsensitiveCompare(
                    $1.name
                )
            ==
            .orderedAscending
        }
    }

    func deleteUser(
        _ user: AppUser
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    user.id.uuidString
            )

        try await database
            .deleteRecord(
                withID:
                    recordID
            )
    }
}
