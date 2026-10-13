
import Foundation

struct MapAssignmentCompletion:
    Identifiable,
    Codable,
    Equatable {
    
    var id = UUID()
    
    var assignmentID: UUID
    var driverID: UUID
    var stormID: UUID
    var mapNumber: String
    
    var completedBy: String
    var completedAt: Date = Date()
}


