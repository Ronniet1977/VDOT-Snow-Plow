import Foundation

struct CrewDriver: Identifiable, Codable, Equatable {
    
    var id = UUID()
    
    var name: String
    var truckNumber: String
    
    var isActive: Bool = false
}

