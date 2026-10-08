import Foundation
import SwiftUI

@MainActor
final class AdminTimeStore: ObservableObject {
    
    @Published var entries:
    [DriverTimeEntry] = []
    
    private let fileName =
    "AdminDriverTimes.json"
    
    init() {
        load()
    }
    
    func load() {
        
        entries =
        LocalStore.shared.load(
            [DriverTimeEntry].self,
            fileName: fileName,
            defaultValue: []
        )
    }
    
    func save() {
        
        LocalStore.shared.save(
            entries,
            fileName: fileName
        )
    }
    
    func add(
        _ entry: DriverTimeEntry
    ) {
        
        entries.append(entry)
        
        entries.sort {
            $0.date > $1.date
        }
        
        save()
    }
    
    func update(
        _ entry: DriverTimeEntry
    ) {
        
        guard
            let index =
                entries.firstIndex(
                    where: {
                        $0.id == entry.id
                    }
                )
        else {
            return
        }
        
        entries[index] = entry
        
        save()
    }
    
    func delete(
        _ entry: DriverTimeEntry
    ) {
        
        entries.removeAll {
            $0.id == entry.id
        }
        
        save()
    }
}

