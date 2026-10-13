
import Foundation
import CloudKit

@MainActor
final class CloudMapProgressService {
    
    static let shared = CloudMapProgressService()
    
    private let database =
    CKContainer.default().publicCloudDatabase
    
    private let recordType = "MapProgressReport"
    
    private init() {}
    
    // MARK: - Save Driver Progress
    
    func saveReport(
        _ report: MapProgressReport
    ) async throws {
        
        let recordID = CKRecord.ID(
            recordName: report.id.uuidString
        )
        
        let record = CKRecord(
            recordType: recordType,
            recordID: recordID
        )
        
        record["stormID"] =
        report.stormID.uuidString
        
        record["mapNumber"] =
        report.mapNumber
        
        record["driverID"] =
        report.driverID.uuidString
        
        record["roadsOpened"] =
        NSNumber(value: report.roadsOpened)
        
        record["curbToCurbComplete"] =
        NSNumber(value: report.curbToCurbComplete)
        
        record["roadsOpenedAt"] =
        report.roadsOpenedAt
        
        record["curbToCurbCompletedAt"] =
        report.curbToCurbCompletedAt
        
        record["resetVersion"] =
        NSNumber(value: report.resetVersion)
        
        record["updatedAt"] =
        report.updatedAt
        
        try await database.save(record)
        
        print(
            "✅ Map progress saved:",
            report.mapNumber,
            report.stage.rawValue
        )
    }
    
    // MARK: - Fetch Reports
    
    func fetchReports() async throws
    -> [MapProgressReport] {
        
        let query = CKQuery(
            recordType: recordType,
            predicate: NSPredicate(value: true)
        )
        
        var reports: [MapProgressReport] = []
        
        func appendResults(
            _ matches:
            [(CKRecord.ID, Result<CKRecord, Error>)]
        ) {
            
            for (_, result) in matches {
                
                guard case .success(let record) = result,
                      let id = UUID(
                        uuidString: record.recordID.recordName
                      ),
                      let stormString = record["stormID"] as? String,
                      let stormID = UUID(uuidString: stormString),
                      let mapNumber = record["mapNumber"] as? String,
                      let driverString = record["driverID"] as? String,
                      let driverID = UUID(uuidString: driverString)
                else {
                    continue
                }
                
                let report = MapProgressReport(
                    id: id,
                    stormID: stormID,
                    mapNumber: mapNumber,
                    driverID: driverID,
                    roadsOpened: (record["roadsOpened"] as? NSNumber)?
                        .boolValue ?? false,
                    curbToCurbComplete:
                        (record["curbToCurbComplete"] as? NSNumber)?
                        .boolValue ?? false,
                    roadsOpenedAt:
                        record["roadsOpenedAt"] as? Date,
                    curbToCurbCompletedAt:
                        record["curbToCurbCompletedAt"] as? Date,
                    resetVersion:
                        (record["resetVersion"] as? NSNumber)?
                        .intValue ?? 0,
                    updatedAt:
                        record["updatedAt"] as? Date ?? .distantPast
                )
                
                reports.append(report)
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
        
        return reports
    }
}


