
import Foundation
import CloudKit

@MainActor
final class CloudMapProgressResetService {
    
    static let shared = CloudMapProgressResetService()
    
    private let database =
    CKContainer.default().publicCloudDatabase
    
    private let recordType = "MapProgressReset"
    
    private init() {}
    
    // MARK: - Save Reset
    
    func saveReset(
        _ reset: MapProgressReset
    ) async throws {
        
        let record = CKRecord(
            recordType: recordType,
            recordID: CKRecord.ID(
                recordName: reset.id.uuidString
            )
        )
        
        record["stormID"] =
        reset.stormID.uuidString
        
        record["mapNumber"] =
        reset.mapNumber
        
        if let driverID = reset.driverID {
            record["driverID"] = driverID.uuidString
        }
        
        record["resetBy"] =
        reset.resetBy
        
        record["resetAt"] =
        reset.resetAt
        
        try await database.save(record)
        
        print(
            "☁️ Map progress reset saved:",
            reset.mapNumber
        )
    }
    
    // MARK: - Fetch Resets
    
    func fetchResets() async throws
    -> [MapProgressReset] {
        
        let query = CKQuery(
            recordType: recordType,
            predicate: NSPredicate(value: true)
        )
        
        var resets: [MapProgressReset] = []
        
        func appendResults(
            _ matches:
            [(CKRecord.ID, Result<CKRecord, Error>)]
        ) {
            
            for (_, result) in matches {
                
                guard case .success(let record) = result,
                      let id = UUID(
                        uuidString: record.recordID.recordName
                      ),
                      let stormString =
                        record["stormID"] as? String,
                      let stormID =
                        UUID(uuidString: stormString),
                      let mapNumber =
                        record["mapNumber"] as? String,
                      let resetBy =
                        record["resetBy"] as? String
                else {
                    continue
                }
                
                let driverID: UUID? = {
                    guard let value =
                            record["driverID"] as? String
                    else {
                        return nil
                    }
                    
                    return UUID(uuidString: value)
                }()
                
                resets.append(
                    MapProgressReset(
                        id: id,
                        stormID: stormID,
                        mapNumber: mapNumber,
                        driverID: driverID,
                        resetBy: resetBy,
                        resetAt:
                            record["resetAt"] as? Date
                        ?? .distantPast
                    )
                )
            }
        }
        
        let firstPage = try await database.records(
            matching: query,
            resultsLimit: 200
        )
        
        appendResults(firstPage.matchResults)
        
        var cursor = firstPage.queryCursor
        
        while let currentCursor = cursor {
            
            let nextPage = try await database.records(
                continuingMatchFrom: currentCursor,
                resultsLimit: 200
            )
            
            appendResults(nextPage.matchResults)
            
            cursor = nextPage.queryCursor
        }
        
        return resets
    }
}


