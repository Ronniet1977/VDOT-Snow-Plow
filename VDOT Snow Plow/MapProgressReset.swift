
import Foundation

struct MapProgressReset: Identifiable, Codable, Equatable {
    
    var id = UUID()
    
    // Which storm and map are being reset
    var stormID: UUID
    var mapNumber: String
    
    // Nil means reset the entire map.
    // A driver ID means reset only that driver.
    var driverID: UUID?
    
    // Who performed the reset
    var resetBy: String
    
    var resetAt: Date = Date()
}


