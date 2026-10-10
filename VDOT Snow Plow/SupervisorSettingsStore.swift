import Foundation
import SwiftUI
import Combine

@MainActor
final class SupervisorSettingsStore:
    ObservableObject {
    
    @Published var settings =
    SupervisorSettings()
    
    private let cloud =
        CloudSupervisorService.shared
    
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
    
    func addSupervisor(
        _ supervisor: SupervisorContact,
        to category: CrewCategory
    ) {

        switch category {

        case .plowOnly:
            settings.plowOnly.append(
                supervisor
            )

        case .littleTrucks:
            settings.littleTrucks.append(
                supervisor
            )

        case .bigTrucks:
            settings.bigTrucks.append(
                supervisor
            )

        case .equipment:
            settings.equipment.append(
                supervisor
            )
        }

        save()

        Task {

            do {

                try await cloud
                    .saveSupervisor(
                        supervisor,
                        category:
                            category
                    )

                print(
                    "☁️ Supervisor uploaded:",
                    supervisor.name
                )

            } catch {

                print(
                    "❌ Supervisor CloudKit save failed:",
                    error
                )
            }
        }
    }
    
    func deleteSupervisor(
        _ supervisor: SupervisorContact,
        from category: CrewCategory
    ) {

        switch category {

        case .plowOnly:
            settings.plowOnly.removeAll {
                $0.id == supervisor.id
            }

        case .littleTrucks:
            settings.littleTrucks.removeAll {
                $0.id == supervisor.id
            }

        case .bigTrucks:
            settings.bigTrucks.removeAll {
                $0.id == supervisor.id
            }

        case .equipment:
            settings.equipment.removeAll {
                $0.id == supervisor.id
            }
        }

        save()

        Task {

            do {

                try await cloud
                    .deleteSupervisor(
                        supervisor
                    )

                print(
                    "☁️ Supervisor deleted:",
                    supervisor.name
                )

            } catch {

                print(
                    "❌ Supervisor CloudKit delete failed:",
                    error
                )
            }
        }
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
    
    func syncFromCloud() async {

        do {

            let cloudSupervisors =
                try await cloud
                    .fetchSupervisors()

            for (
                cloudSupervisor,
                category
            ) in cloudSupervisors {

                switch category {

                case .plowOnly:

                    if let index =
                        settings.plowOnly
                            .firstIndex(
                                where: {
                                    $0.id ==
                                    cloudSupervisor.id
                                }
                            ) {

                        settings.plowOnly[index] =
                            cloudSupervisor

                    } else {

                        settings.plowOnly
                            .append(
                                cloudSupervisor
                            )
                    }

                case .littleTrucks:

                    if let index =
                        settings.littleTrucks
                            .firstIndex(
                                where: {
                                    $0.id ==
                                    cloudSupervisor.id
                                }
                            ) {

                        settings.littleTrucks[index] =
                            cloudSupervisor

                    } else {

                        settings.littleTrucks
                            .append(
                                cloudSupervisor
                            )
                    }

                case .bigTrucks:

                    if let index =
                        settings.bigTrucks
                            .firstIndex(
                                where: {
                                    $0.id ==
                                    cloudSupervisor.id
                                }
                            ) {

                        settings.bigTrucks[index] =
                            cloudSupervisor

                    } else {

                        settings.bigTrucks
                            .append(
                                cloudSupervisor
                            )
                    }

                case .equipment:

                    if let index =
                        settings.equipment
                            .firstIndex(
                                where: {
                                    $0.id ==
                                    cloudSupervisor.id
                                }
                            ) {

                        settings.equipment[index] =
                            cloudSupervisor

                    } else {

                        settings.equipment
                            .append(
                                cloudSupervisor
                            )
                    }
                }
            }

            save()

            print(
                "☁️ Supervisors merged from CloudKit:",
                cloudSupervisors.count
            )

        } catch {

            print(
                "❌ Supervisor CloudKit fetch failed:",
                error
            )
        }
    }
}

