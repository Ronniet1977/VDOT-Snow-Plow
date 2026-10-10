//
//  CloudAccessRequestDecisionService.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation
import CloudKit

final class CloudAccessRequestDecisionService {

    static let shared =
        CloudAccessRequestDecisionService()

    private init() {}

    private let database =
        CKContainer.default()
            .publicCloudDatabase

    private let recordType =
        "AccessRequestDecision"

    func saveDecision(
        _ decision: AccessRequestDecision
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    decision.id.uuidString
            )

        let record =
            CKRecord(
                recordType:
                    recordType,
                recordID:
                    recordID
            )

        record["requestID"] =
            decision.requestID.uuidString

        record["appleUserID"] =
            decision.appleUserID

        record["decision"] =
            decision.decision

        record["decidedAt"] =
            decision.decidedAt

        try await database.save(
            record
        )

        print(
            "☁️ Access decision saved:",
            decision.decision
        )
    }

    func fetchDecisions(
        for appleUserID: String
    ) async throws
        -> [AccessRequestDecision] {

        let predicate =
            NSPredicate(
                format:
                    "appleUserID == %@",
                appleUserID
            )

        let query =
            CKQuery(
                recordType:
                    recordType,
                predicate:
                    predicate
            )

        let result =
            try await database.records(
                matching:
                    query
            )

        var decisions:
            [AccessRequestDecision] = []

        for (_, matchResult)
        in result.matchResults {

            guard
                case .success(
                    let record
                ) = matchResult,

                let id =
                    UUID(
                        uuidString:
                            record.recordID
                                .recordName
                    ),

                let requestIDString =
                    record["requestID"]
                        as? String,

                let requestID =
                    UUID(
                        uuidString:
                            requestIDString
                    ),

                let storedAppleUserID =
                    record["appleUserID"]
                        as? String,

                let decision =
                    record["decision"]
                        as? String,

                let decidedAt =
                    record["decidedAt"]
                        as? Date

            else {
                continue
            }

            decisions.append(
                AccessRequestDecision(
                    id:
                        id,
                    requestID:
                        requestID,
                    appleUserID:
                        storedAppleUserID,
                    decision:
                        decision,
                    decidedAt:
                        decidedAt
                )
            )
        }

        return decisions
    }
}
