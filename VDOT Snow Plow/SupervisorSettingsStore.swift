import Foundation
import SwiftUI
import Combine

@MainActor
final class SupervisorSettingsStore:
    ObservableObject {
    
    @Published var settings =
    SupervisorSettings()
    
    private let fileName =
    "SupervisorSettings.json"
    
    init() {
        load()
    }
    
    func load() {
        
        settings =
        LocalStore.shared.load(
            SupervisorSettings.self,
            fileName:
                fileName,
            defaultValue:
                SupervisorSettings()
        )
    }
    
    func save() {
        
        LocalStore.shared.save(
            settings,
            fileName:
                fileName
        )
    }
    
    func supervisors(
        for category:
        CrewCategory
    ) -> [SupervisorContact] {
        
        switch category {
            
        case .plowOnly:
            return settings.plowOnly
            
        case .littleTrucks:
            return settings.littleTrucks
            
        case .bigTrucks:
            return settings.bigTrucks
            
        case .equipment:
            return settings.equipment
        }
    }
}

