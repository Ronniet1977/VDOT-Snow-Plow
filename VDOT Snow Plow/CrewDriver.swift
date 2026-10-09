import Foundation

enum CrewCategory:
    String,
    Codable,
    CaseIterable,
    Identifiable {
    
    case plowOnly = "Plow Only"
    
    // Keep the OLD saved value so existing drivers still decode
    case littleTrucks = "9' Trucks"
    
    case bigTrucks = "Big Trucks"
    case equipment = "Equipment"
    
    var id: String {
        rawValue
    }
    
    var displayName: String {
        
        switch self {
            
        case .plowOnly:
            return "Plow Only"
            
        case .littleTrucks:
            return "Little Trucks"
            
        case .bigTrucks:
            return "Big Trucks"
            
        case .equipment:
            return "Equipment"
        }
    }
}

struct CrewDriver: Identifiable, Codable, Equatable {
    
    var id = UUID()
    
    var name: String
    var truckNumber: String
    
    var category:
    CrewCategory = .plowOnly
    
    var isActive: Bool = false
}

