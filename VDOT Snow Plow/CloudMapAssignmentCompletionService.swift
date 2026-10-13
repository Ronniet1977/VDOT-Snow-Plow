
import Foundation
import CloudKit

@MainActor
final class CloudMapAssignmentCompletionService {
    
    static let shared =
    CloudMapAssignmentCompletionService()
    
    private let database =
    CKContainer.default().publicCloudDatabase
    
    private let recordType =
    "MapAssignmentCompletion"
    
    private init() {}
    
    // MARK: - Save Completion
    
    func saveCompletion(
        _ completion: MapAssignmentCompletion
    ) async throws {
        
        let record = CKRecord(
            recordType: recordType,
            recordID: CKRecord.ID(
                recordName: completion.id.uuidString
            )
        )
        
        record["assignmentID"] =
        completion.assignmentID.uuidString
        
        record["driverID"] =
        completion.driverID.uuidString
        
        record["stormID"] =
        completion.stormID.uuidString
        
        record["mapNumber"] =
        completion.mapNumber
        
        record["completedBy"] =
        completion.completedBy
        
        record["completedAt"] =
        completion.completedAt
        
        try await database.save(record)
        
        print(
            "✅ Map completion saved:",
            completion.mapNumber
        )
    }
    
    // MARK: - Fetch Completions
    
    func fetchCompletions() async throws
    -> [MapAssignmentCompletion] {
        
        let query = CKQuery(
            recordType: recordType,
            predicate: NSPredicate(value: true)
        )
        
        var completions: [MapAssignmentCompletion] = []
        
        func appendResults(
            _ matches:
            [(CKRecord.ID, Result<CKRecord, Error>)]
        ) throws {
            
            for (_, result) in matches {
                
                switch result {
                    
                case .failure(let error):
                    throw error
                    
                case .success(let record):
                    
                    guard
                        let id = UUID(
                            uuidString:
                                record.recordID.recordName
                        ),
                        let assignmentString =
                            record["assignmentID"] as? String,
                        let assignmentID =
                            UUID(uuidString: assignmentString),
                        let driverString =
                            record["driverID"] as? String,
                        let driverID =
                            UUID(uuidString: driverString),
                        let stormString =
                            record["stormID"] as? String,
                        let stormID =
                            UUID(uuidString: stormString),
                        let mapNumber =
                            record["mapNumber"] as? String,
                        let completedBy =
                            record["completedBy"] as? String,
                        let completedAt =
                            record["completedAt"] as? Date
                    else {
                        continue
                    }
                    
                    completions.append(
                        MapAssignmentCompletion(
                            id: id,
                            assignmentID: assignmentID,
                            driverID: driverID,
                            stormID: stormID,
                            mapNumber: mapNumber,
                            completedBy: completedBy,
                            completedAt: completedAt
                        )
                    )
                }
            }
        }
        
        let firstPage = try await database.records(
            matching: query,
            resultsLimit: 200
        )
        
        try appendResults(firstPage.matchResults)
        
        var cursor = firstPage.queryCursor
        
        while let currentCursor = cursor {
            
            let nextPage = try await database.records(
                continuingMatchFrom: currentCursor,
                resultsLimit: 200
            )
            
            try appendResults(nextPage.matchResults)
            cursor = nextPage.queryCursor
        }
        
        return completions
    }
}


