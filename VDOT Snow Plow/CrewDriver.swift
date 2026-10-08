import Foundation

enum CrewCategory: String, Codable, CaseIterable, Identifiable {
    
    case plowOnly = "Plow Only"
    case nineFoot = "9' Trucks"
    case bigTrucks = "Big Trucks"
    case equipment = "Equipment"
    
    var id: String {
        rawValue
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

