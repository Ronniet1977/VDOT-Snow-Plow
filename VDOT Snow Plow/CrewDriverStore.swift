import Foundation
import SwiftUI
import Combine

@MainActor
final class CrewDriverStore: ObservableObject {
    
    @Published var drivers:
    [CrewDriver] = []
    
    private let fileName =
    "CrewDrivers.json"
    
    init() {
        load()
    }
    
    func load() {
        
        drivers =
        LocalStore.shared.load(
            [CrewDriver].self,
            fileName: fileName,
            defaultValue: []
        )
    }
    
    func save() {
        
        LocalStore.shared.save(
            drivers,
            fileName: fileName
        )
    }
    
    func add(
        name: String,
        truckNumber: String,
        category: CrewCategory
    ) {
        
        let driver =
        CrewDriver(
            name: name,
            truckNumber: truckNumber,
            category: category
        )
        
        drivers.append(driver)
        
        drivers.sort {
            $0.name.localizedCaseInsensitiveCompare(
                $1.name
            ) == .orderedAscending
        }
        
        save()
    }
    
    func update(
        _ driver: CrewDriver
    ) {
        
        guard
            let index =
                drivers.firstIndex(
                    where: {
                        $0.id == driver.id
                    }
                )
        else {
            return
        }
        
        drivers[index] = driver
        
        save()
    }
    
    func delete(
        _ driver: CrewDriver
    ) {
        
        drivers.removeAll {
            $0.id == driver.id
        }
        
        save()
    }
    
    func setActive(
        _ driver: CrewDriver,
        active: Bool
    ) {
        
        guard
            let index =
                drivers.firstIndex(
                    where: {
                        $0.id == driver.id
                    }
                )
        else {
            return
        }
        
        drivers[index].isActive =
        active
        
        save()
    }
}

