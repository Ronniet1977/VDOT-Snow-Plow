import Foundation

struct DriverStatusBlock: Identifiable, Codable, Equatable {
    
    var id = UUID()
    
    var driverID: UUID
    var stormID: UUID?
    
    var status: BlockType
    
    var startTime: Date
    var endTime: Date?
    
    var notes = ""
    
    var hours: Double {
        
        let end =
        endTime ?? Date()
        
        return max(
            0,
            end.timeIntervalSince(
                startTime
            ) / 3600
        )
    }
}

