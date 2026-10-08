import Foundation
import SwiftUI

@MainActor
final class AdminStormStore: ObservableObject {
    
    @Published var storms: [Storm] = []
    
    @Published var activeStormID: UUID?
    
    private let fileName =
    "AdminStorms.json"
    
    private let activeStormFile =
    "ActiveAdminStorm.json"
    
    init() {
        load()
    }
    
    var activeStorm: Storm? {
        
        guard let activeStormID else {
            return nil
        }
        
        return storms.first {
            $0.id == activeStormID
        }
    }
    
    func load() {
        
        storms =
        LocalStore.shared.load(
            [Storm].self,
            fileName: fileName,
            defaultValue: []
        )
        
        activeStormID =
        LocalStore.shared.load(
            UUID?.self,
            fileName: activeStormFile,
            defaultValue: nil
        )
    }
    
    func save() {
        
        LocalStore.shared.save(
            storms,
            fileName: fileName
        )
        
        LocalStore.shared.save(
            activeStormID,
            fileName: activeStormFile
        )
    }
    
    func startStorm(
        name: String
    ) {
        
        let clean =
        name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        let storm =
        Storm(
            name:
                clean.isEmpty
            ? "Storm \(storms.count + 1)"
            : clean,
            start: Date()
        )
        
        storms.append(
            storm
        )
        
        activeStormID =
        storm.id
        
        save()
    }
    
    func endStorm() {
        
        guard
            let activeStormID,
            let index =
                storms.firstIndex(
                    where: {
                        $0.id ==
                        activeStormID
                    }
                )
        else {
            return
        }
        
        storms[index].end =
        Date()
        
        self.activeStormID =
        nil
        
        save()
    }
}

