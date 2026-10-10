import Foundation
import SwiftUI
import Combine

@MainActor
final class CrewDriverStore: ObservableObject {
    
    @Published var drivers:
    [CrewDriver] = []
    
    private let fileName =
    "CrewDrivers.json"
    
    private let cloud =
        CloudDriverService.shared
    
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
        
        Task {

            do {

                try await cloud.saveDriver(
                    driver
                )

                print(
                    "☁️ Driver uploaded:",
                    driver.name
                )

            } catch {

                print(
                    "❌ Driver CloudKit save failed:",
                    error
                )
            }
        }
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
        
        Task {

            do {

                try await cloud.saveDriver(
                    driver
                )

                print(
                    "☁️ Driver updated:",
                    driver.name
                )

            } catch {

                print(
                    "❌ Driver CloudKit update failed:",
                    error
                )
            }
        }
    }
    
    func delete(
        _ driver: CrewDriver
    ) {
        
        drivers.removeAll {
            $0.id == driver.id
        }
        
        save()
        
        Task {

            do {

                try await cloud.deleteDriver(
                    driver
                )

                print(
                    "☁️ Driver deleted:",
                    driver.name
                )

            } catch {

                print(
                    "❌ Driver CloudKit delete failed:",
                    error
                )
            }
        }
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

        let updatedDriver =
            drivers[index]

        save()

        Task {

            do {

                try await cloud
                    .saveDriver(
                        updatedDriver
                    )

                print(
                    "☁️ Driver active updated:",
                    updatedDriver.name,
                    active
                )

            } catch {

                print(
                    "❌ Driver active CloudKit update failed:",
                    error
                )
            }
        }
    }
    
    func syncFromCloud() async {

        do {

            let cloudDrivers =
                try await cloud.fetchDrivers()

            for cloudDriver in cloudDrivers {

                if let index =
                    drivers.firstIndex(
                        where: {
                            $0.id ==
                            cloudDriver.id
                        }
                    ) {

                    drivers[index] =
                        cloudDriver

                } else {

                    drivers.append(
                        cloudDriver
                    )
                }
            }

            drivers.sort {
                $0.name
                    .localizedCaseInsensitiveCompare(
                        $1.name
                    )
                ==
                .orderedAscending
            }

            save()

            print(
                "☁️ Drivers merged from CloudKit:",
                cloudDrivers.count
            )

        } catch {

            print(
                "❌ Driver CloudKit fetch failed:",
                error
            )
        }
    }
}

