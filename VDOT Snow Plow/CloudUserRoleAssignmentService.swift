//
//  CloudUserRoleAssignmentService.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/12/26.
//

import Foundation
import CloudKit

@MainActor
final class CloudUserRoleAssignmentService {

    static let shared =
        CloudUserRoleAssignmentService()

    private let database =
        CKContainer.default()
            .publicCloudDatabase

    private let recordType =
        "UserRoleAssignment"

    private init() {}

    func saveAssignment(
        _ assignment:
            UserRoleAssignment
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    assignment.id.uuidString
            )

        let record =
            CKRecord(
                recordType:
                    recordType,
                recordID:
                    recordID
            )

        record["appleUserID"] =
            assignment.appleUserID

        record["role"] =
            assignment.role.rawValue

        record["category"] =
            assignment.category?.rawValue

        record["driverID"] =
            assignment.driverID?
                .uuidString

        record["isAlsoDriver"] =
            NSNumber(
                value:
                    assignment.isAlsoDriver
            )

        record["isAlsoSupervisor"] =
            NSNumber(
                value:
                    assignment.isAlsoSupervisor
            )

        record["isActive"] =
            NSNumber(
                value:
                    assignment.isActive
            )

        record["updatedAt"] =
            assignment.updatedAt

        try await database.save(
            record
        )

        print(
            "☁️ User role assignment saved:",
            assignment.appleUserID
        )
    }

    func fetchAssignments()
    async throws
    -> [UserRoleAssignment] {

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

        var assignments:
            [UserRoleAssignment] = []

        for (_, match)
        in result.matchResults {

            guard
                case .success(
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
                let appleUserID =
                    record[
                        "appleUserID"
                    ] as? String,
                let roleRaw =
                    record[
                        "role"
                    ] as? String,
                let role =
                    AppUserRole(
                        rawValue:
                            roleRaw
                    )
            else {
                continue
            }

            let category =
                (
                    record[
                        "category"
                    ] as? String
                )
                .flatMap {
                    CrewCategory(
                        rawValue:
                            $0
                    )
                }

            let driverID =
                (
                    record[
                        "driverID"
                    ] as? String
                )
                .flatMap {
                    UUID(
                        uuidString:
                            $0
                    )
                }

            let isAlsoDriver =
                (
                    record[
                        "isAlsoDriver"
                    ] as? NSNumber
                )?.boolValue
                ?? false

            let isAlsoSupervisor =
                (
                    record[
                        "isAlsoSupervisor"
                    ] as? NSNumber
                )?.boolValue
                ?? false

            let isActive =
                (
                    record[
                        "isActive"
                    ] as? NSNumber
                )?.boolValue
                ?? true

            let updatedAt =
                record[
                    "updatedAt"
                ] as? Date
                ?? .distantPast

            assignments.append(
                UserRoleAssignment(
                    id:
                        id,
                    appleUserID:
                        appleUserID,
                    role:
                        role,
                    category:
                        category,
                    driverID:
                        driverID,
                    isAlsoDriver:
                        isAlsoDriver,
                    isAlsoSupervisor:
                        isAlsoSupervisor,
                    isActive:
                        isActive,
                    updatedAt:
                        updatedAt
                )
            )
        }

        return assignments
            .sorted {
                $0.updatedAt >
                    $1.updatedAt
            }
    }
}
