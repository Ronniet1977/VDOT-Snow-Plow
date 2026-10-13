
import Foundation

enum MapProgressStage: String, Codable, CaseIterable {
    case notStarted = "Not Started"
    case openedUp = "Opened Up"
    case done = "Done"
}

struct MapProgressReport: Identifiable, Codable, Equatable {
    
    var id = UUID()
    
    // Identifies the storm and map
    var stormID: UUID
    var mapNumber: String
    
    // The driver reporting progress
    var driverID: UUID
    
    // Two confirmation steps
    var roadsOpened: Bool = false
    var curbToCurbComplete: Bool = false
    
    // When confirmations happened
    var roadsOpenedAt: Date?
    var curbToCurbCompletedAt: Date?
    
    // Used when an admin clears progress
    var resetVersion: Int = 0
    
    var updatedAt: Date = Date()
    
    var stage: MapProgressStage {
        if curbToCurbComplete && roadsOpened {
            return .done
        }
        
        if roadsOpened {
            return .openedUp
        }
        
        return .notStarted
    }
}


