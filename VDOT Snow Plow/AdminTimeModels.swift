import Foundation

struct DriverTimeEntry: Identifiable, Codable, Equatable {
    
    var id = UUID()
    
    var stormID: UUID?
    var date = Date()
    
    var driverName = ""
    var truckNumber = ""
    
    var startTime = Date()
    var stopTime = Date()
    
    var pushHours: Double = 0
    var standbyHours: Double = 0
    var brokeHours: Double = 0
    
    var notes = ""
    
    var totalHours: Double {
        pushHours +
        standbyHours +
        brokeHours
    }
}
