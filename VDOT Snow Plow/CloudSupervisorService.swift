//
//  CloudSupervisorService.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/9/26.
//

import Foundation
import CloudKit

@MainActor
final class CloudSupervisorService {

    static let shared =
        CloudSupervisorService()

    private let database =
        CKContainer.default()
            .publicCloudDatabase

    private init() {}

    // MARK: - Save

    func saveSupervisor(
        _ supervisor: SupervisorContact,
        category: CrewCategory
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    supervisor.id.uuidString
            )

        let record =
            CKRecord(
                recordType:
                    "SupervisorContact",
                recordID:
                    recordID
            )

        record["name"] =
            supervisor.name

        record["phoneNumber"] =
            supervisor.phoneNumber

        record["category"] =
            category.rawValue

        try await database.save(
            record
        )
    }

    // MARK: - Fetch

    func fetchSupervisors()
    async throws
    -> [(SupervisorContact, CrewCategory)] {

        let query =
            CKQuery(
                recordType:
                    "SupervisorContact",
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

        var supervisors:
            [(SupervisorContact, CrewCategory)] = []

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

            let phoneNumber =
                record["phoneNumber"]
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

            let supervisor =
                SupervisorContact(
                    id:
                        id,
                    name:
                        name,
                    phoneNumber:
                        phoneNumber
                )

            supervisors.append(
                (
                    supervisor,
                    category
                )
            )
        }

        return supervisors
    }

    // MARK: - Delete

    func deleteSupervisor(
        _ supervisor:
            SupervisorContact
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    supervisor.id.uuidString
            )

        try await database
            .deleteRecord(
                withID:
                    recordID
            )
    }
}
