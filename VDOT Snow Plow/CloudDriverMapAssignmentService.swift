//
//  CloudDriverMapAssignmentService.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation
import CloudKit

final class CloudDriverMapAssignmentService {

    static let shared =
        CloudDriverMapAssignmentService()

    private init() {}

    private let database =
        CKContainer.default()
            .publicCloudDatabase

    private let recordType =
        "DriverMapAssignment"

    func saveAssignment(
        _ assignment: DriverMapAssignment
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    assignment.id.uuidString
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
                        recordType,
                    recordID:
                        recordID
                )
        }

        record["driverID"] =
            assignment.driverID.uuidString

        record["stormID"] =
            assignment.stormID.uuidString

        record["mapNumber"] =
            assignment.mapNumber

        record["assignedAt"] =
            assignment.assignedAt

        record["acknowledgedAt"] =
            assignment.acknowledgedAt

        record["completedAt"] =
            assignment.completedAt

        record["notes"] =
            assignment.notes

        try await database.save(
            record
        )
    }

    
    func fetchAssignments() async throws
    -> [DriverMapAssignment] {
        
        let query = CKQuery(
            recordType: recordType,
            predicate: NSPredicate(value: true)
        )
        
        var assignments: [DriverMapAssignment] = []
        
        // Decode records from each CloudKit page.
        func appendResults(
            _ matches: [
                (CKRecord.ID, Result<CKRecord, Error>)
            ]
        ) throws {
            
            for (_, matchResult) in matches {
                
                switch matchResult {
                    
                case .failure(let error):
                    throw error
                    
                case .success(let record):
                    
                    guard
                        let id = UUID(
                            uuidString: record.recordID.recordName
                        ),
                        let driverIDString =
                            record["driverID"] as? String,
                        let driverID = UUID(
                            uuidString: driverIDString
                        ),
                        let stormIDString =
                            record["stormID"] as? String,
                        let stormID = UUID(
                            uuidString: stormIDString
                        ),
                        let mapNumber =
                            record["mapNumber"] as? String,
                        let assignedAt =
                            record["assignedAt"] as? Date
                    else {
                        print(
                            "⚠️ Skipping invalid map assignment:",
                            record.recordID.recordName
                        )
                        continue
                    }
                    
                    assignments.append(
                        DriverMapAssignment(
                            id: id,
                            driverID: driverID,
                            stormID: stormID,
                            mapNumber: mapNumber,
                            assignedAt: assignedAt,
                            acknowledgedAt:
                                record["acknowledgedAt"] as? Date,
                            completedAt:
                                record["completedAt"] as? Date,
                            notes:
                                record["notes"] as? String ?? ""
                        )
                    )
                }
            }
        }
        
        // Fetch the first page.
        let firstPage = try await database.records(
            matching: query,
            resultsLimit: 200
        )
        
        try appendResults(firstPage.matchResults)
        
        var cursor = firstPage.queryCursor
        
        // Continue until CloudKit has no more pages.
        while let currentCursor = cursor {
            
            let nextPage = try await database.records(
                continuingMatchFrom: currentCursor,
                resultsLimit: 200
            )
            
            try appendResults(nextPage.matchResults)
            
            cursor = nextPage.queryCursor
        }
        
        return assignments.sorted {
            $0.assignedAt < $1.assignedAt
        }
    }

    func deleteAssignment(
        _ assignment:
            DriverMapAssignment
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    assignment.id.uuidString
            )

        try await database
            .deleteRecord(
                withID:
                    recordID
            )
    }
}

