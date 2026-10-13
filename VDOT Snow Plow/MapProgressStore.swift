
import Foundation
import Combine

@MainActor
final class MapProgressStore: ObservableObject {
    
    @Published var reports: [MapProgressReport] = []
    @Published var resets: [MapProgressReset] = []
    
    private let resetCloud =
    CloudMapProgressResetService.shared
    
    private let cloud = CloudMapProgressService.shared
    
    // MARK: - Load CloudKit Reports
    
    
    func syncFromCloud() async {
        
        do {
            let fetchedReports =
            try await cloud.fetchReports()
            
            let fetchedResets =
            try await resetCloud.fetchResets()
            
            reports = fetchedReports
            resets = fetchedResets
            
            print(
                "☁️ Map progress loaded:",
                reports.count,
                "reports,",
                resets.count,
                "resets"
            )
            
        } catch {
            print(
                "❌ Map progress sync failed:",
                error
            )
        }
    }
    
    // Refresh that reports errors to the caller.
    // Used before confirming driver progress.
    private func refreshBeforeConfirmation()
    async throws {
        
        let fetchedReports =
        try await cloud.fetchReports()
        
        let fetchedResets =
        try await resetCloud.fetchResets()
        
        reports = fetchedReports
        resets = fetchedResets
    }
    
    // MARK: - Driver Confirms Roads Opened
    
    
    // MARK: - Driver Confirms Roads Opened
    
    func confirmRoadsOpened(
        stormID: UUID,
        mapNumber: String,
        driverID: UUID,
        resetVersion: Int
    ) async throws {
        
        try await refreshBeforeConfirmation()
        
        guard currentProgress(
            stormID: stormID,
            mapNumber: mapNumber,
            driverID: driverID
        )?.roadsOpened != true else {
            
            print("✅ Roads already confirmed")
            return
        }
        
        let report = MapProgressReport(
            stormID: stormID,
            mapNumber: mapNumber,
            driverID: driverID,
            roadsOpened: true,
            roadsOpenedAt: Date(),
            resetVersion: resetVersion
        )
        
        try await cloud.saveReport(report)
        
        reports.append(report)
    }
    
    // MARK: - Driver Confirms Curb To Curb
    
    func confirmCurbToCurb(
        stormID: UUID,
        mapNumber: String,
        driverID: UUID,
        resetVersion: Int
    ) async throws {
        
        try await refreshBeforeConfirmation()
        
        guard let latest = currentProgress(
            stormID: stormID,
            mapNumber: mapNumber,
            driverID: driverID
        ), latest.roadsOpened else {
            return
        }
        
        let report = MapProgressReport(
            stormID: stormID,
            mapNumber: mapNumber,
            driverID: driverID,
            roadsOpened: true,
            curbToCurbComplete: true,
            roadsOpenedAt: latest.roadsOpenedAt,
            curbToCurbCompletedAt: Date(),
            resetVersion: resetVersion
        )
        
        try await cloud.saveReport(report)
        
        reports.append(report)
    }
    
    // MARK: - Latest Driver Report
    
    func latestReport(
        stormID: UUID,
        mapNumber: String,
        driverID: UUID,
        resetVersion: Int
    ) -> MapProgressReport? {
        
        let resetDate = latestResetDate(
            stormID: stormID,
            mapNumber: mapNumber,
            driverID: driverID
        )
        
        return reports
            .filter { report in
                
                report.stormID == stormID &&
                report.mapNumber == mapNumber &&
                report.driverID == driverID &&
                report.resetVersion == resetVersion &&
                (
                    resetDate == nil ||
                    report.updatedAt > resetDate!
                )
            }
            .max {
                $0.updatedAt < $1.updatedAt
            }
    }
    
    // MARK: - Overall Map Status
    
    
    func mapStage(
        stormID: UUID,
        mapNumber: String,
        assignedDriverIDs: [UUID],
        resetVersion: Int
    ) -> MapProgressStage {
        
        let driverIDs = Set(assignedDriverIDs)
        
        guard !driverIDs.isEmpty else {
            return .notStarted
        }
        
        let stages = driverIDs.map { driverID in
            
            currentProgress(
                stormID: stormID,
                mapNumber: mapNumber,
                driverID: driverID
            )?.stage ?? .notStarted
        }
        
        if stages.allSatisfy({ $0 == .done }) {
            return .done
        }
        
        if stages.allSatisfy({
            $0 == .openedUp || $0 == .done
        }) {
            return .openedUp
        }
        
        return .notStarted
    }
    
    // MARK: - Latest Applicable Admin Reset
    
    func latestResetDate(
        stormID: UUID,
        mapNumber: String,
        driverID: UUID
    ) -> Date? {
        
        resets
            .filter { reset in
                reset.stormID == stormID &&
                reset.mapNumber == mapNumber &&
                (
                    reset.driverID == nil ||
                    reset.driverID == driverID
                )
            }
            .map(\.resetAt)
            .max()
    }
    
    
    func currentProgress(
        stormID: UUID,
        mapNumber: String,
        driverID: UUID
    ) -> MapProgressReport? {
        
        let resetDate = latestResetDate(
            stormID: stormID,
            mapNumber: mapNumber,
            driverID: driverID
        )
        
        return reports
            .filter { report in
                report.stormID == stormID &&
                report.mapNumber == mapNumber &&
                report.driverID == driverID &&
                (
                    resetDate == nil ||
                    report.updatedAt > resetDate!
                )
            }
            .max {
                $0.updatedAt < $1.updatedAt
            }
    }
    
    // MARK: - Admin Clear Progress
    
    func clearProgress(
        stormID: UUID,
        mapNumber: String,
        driverID: UUID? = nil,
        resetBy: String
    ) async throws {
        
        let reset = MapProgressReset(
            stormID: stormID,
            mapNumber: mapNumber,
            driverID: driverID,
            resetBy: resetBy,
            resetAt: Date()
        )
        
        // Save first, then update the screen.
        try await resetCloud.saveReset(reset)
        
        resets.append(reset)
        
        print(
            "✅ Admin cleared map progress:",
            mapNumber,
            driverID?.uuidString ?? "All drivers",
            "by:",
            resetBy
        )
    }
}


