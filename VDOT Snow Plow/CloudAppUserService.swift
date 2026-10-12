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
        
        record["isAlsoDriver"] =
            NSNumber(
                value:
                    user.isAlsoDriver
            )
        
        record["isAlsoSupervisor"] =
            NSNumber(
                value:
                    user.isAlsoSupervisor
            )

        record["isActive"] =
            NSNumber(
                value:
                    user.isActive
            )
        
        record["category"] =
            user.category?.rawValue

        record["driverID"] =
            user.driverID?.uuidString

        record["appleUserID"] =
            user.appleUserID

        record["companyName"] =
            user.companyName

        record["truckVINLast4"] =
            user.truckVINLast4
        
        record["phoneNumber"] =
            user.phoneNumber
        
        print(
            "☁️ SAVING APP USER:",
            user.name,
            "| role:",
            user.role.rawValue,
            "| driverID:",
            user.driverID?.uuidString ?? "nil",
            "| record:",
            user.id.uuidString
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
                (record["category"] as? String)
                    .flatMap {
                        CrewCategory(
                            rawValue: $0
                        )
                    }

            let driverID =
                (record["driverID"] as? String)
                    .flatMap {
                        UUID(
                            uuidString: $0
                        )
                    }
            
            print(
                "☁️ FETCHED APP USER:",
                name,
                "| role:",
                role.rawValue,
                "| raw driverID:",
                record["driverID"] as? String ?? "nil",
                "| parsed driverID:",
                driverID?.uuidString ?? "nil"
            )

            let appleUserID =
                record["appleUserID"]
                    as? String

            let companyName =
                record["companyName"]
                    as? String

            let truckVINLast4 =
                record["truckVINLast4"]
                    as? String
            
            let phoneNumber =
                record["phoneNumber"]
                    as? String
            
            let isAlsoDriver =
                (
                    record["isAlsoDriver"]
                        as? NSNumber
                )?.boolValue
                ??
                (
                    role == .admin &&
                    driverID != nil
                )
            
            let isAlsoSupervisor =
                (
                    record["isAlsoSupervisor"]
                        as? NSNumber
                )?.boolValue
                ?? false

            let isActive =
                (
                    record["isActive"]
                    as? NSNumber
                )?.boolValue
                ?? true

            users.append(
                AppUser(
                    id: id,
                    name: name,
                    role: role,
                    category: category,
                    driverID: driverID,
                    appleUserID: appleUserID,
                    companyName: companyName,
                    truckVINLast4: truckVINLast4,
                    phoneNumber:
                        phoneNumber,
                    isAlsoDriver:
                        isAlsoDriver,
                    isAlsoSupervisor:
                        isAlsoSupervisor,
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
