//
//  UserRoleSyncManager.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation

@MainActor
final class UserRoleSyncManager {

    static let shared =
        UserRoleSyncManager()

    private init() {}

    func syncRole(
        user: AppUser,
        oldUser: AppUser?,
        driverStore: CrewDriverStore,
        supervisorStore: SupervisorSettingsStore
    ) -> AppUser {

        var updatedUser =
            user

        let oldRole =
            oldUser?.role

        // MARK: - Remove Old Role

        if oldRole == .driver &&
            user.role != .driver {

            updatedUser.driverID =
                oldUser?.driverID

            if user.role != .supervisor,
               let driver =
                driverStore.drivers.first(
                    where: {
                        $0.id ==
                            oldUser?.driverID
                    }
                ) {

                driverStore.setActive(
                    driver,
                    active: false
                )
            }
        }

        if oldRole == .supervisor &&
            user.role != .supervisor {

            removeSupervisor(
                named:
                    oldUser?.name
                    ?? user.name,
                supervisorStore:
                    supervisorStore
            )
        }

        // MARK: - Apply New Role

        switch user.role {
            
        case .driver:
            
            if let existing =
                driverStore.drivers.first(
                    where: {
                        $0.id ==
                        user.driverID ||
                        $0.name
                            .localizedCaseInsensitiveCompare(
                                user.name
                            )
                        ==
                            .orderedSame
                    }
                ) {
                
                updatedUser.driverID =
                existing.id
                
                driverStore.setActive(
                    existing,
                    active: true
                )
                
            } else {
                
                driverStore.add(
                    name:
                        user.name,
                    truckNumber:
                        "",
                    category:
                            .plowOnly
                )
                
                updatedUser.driverID =
                driverStore.drivers.first(
                    where: {
                        $0.name
                            .localizedCaseInsensitiveCompare(
                                user.name
                            )
                        ==
                            .orderedSame
                    }
                )?.id
            }
            
        case .supervisor:
            
            let category =
            user.category
            ?? .plowOnly
            
            removeSupervisor(
                named:
                    user.name,
                supervisorStore:
                    supervisorStore
            )
            
            let supervisor =
            SupervisorContact(
                name:
                    user.name,
                phoneNumber:
                    user.phoneNumber
                ?? ""
            )
            
            supervisorStore.addSupervisor(
                supervisor,
                to:
                    category
            )
            
            updatedUser.driverID =
                oldUser?.driverID
                ?? user.driverID
            
        case .admin:

            guard user.isAlsoDriver
            else {

                updatedUser.driverID =
                    nil

                break
            }
            
            if let driverID =
                user.driverID,
               let existing =
                driverStore.drivers.first(
                    where: {
                        $0.id == driverID
                    }
                ) {
                
                updatedUser.driverID =
                existing.id
                
                driverStore.setActive(
                    existing,
                    active: true
                )
                
            } else if let existing =
                        driverStore.drivers.first(
                            where: {
                                $0.name
                                    .localizedCaseInsensitiveCompare(
                                        user.name
                                    )
                                ==
                                    .orderedSame
                            }
                        ) {
                
                updatedUser.driverID =
                existing.id
                
                driverStore.setActive(
                    existing,
                    active: true
                )
                
            } else {

                driverStore.add(
                    name:
                        user.name,
                    truckNumber:
                        "",
                    category:
                        .plowOnly
                )

                updatedUser.driverID =
                    driverStore.drivers.first(
                        where: {
                            $0.name
                                .localizedCaseInsensitiveCompare(
                                    user.name
                                )
                            ==
                                .orderedSame
                        }
                    )?.id
            }
        }
        
        print("🧪 ROLE SYNC RESULT")
        print(
            "name:", updatedUser.name,
            "| old role:", oldUser?.role.rawValue ?? "nil",
            "| new role:", updatedUser.role.rawValue,
            "| old driverID:", oldUser?.driverID?.uuidString ?? "nil",
            "| incoming driverID:", user.driverID?.uuidString ?? "nil",
            "| outgoing driverID:", updatedUser.driverID?.uuidString ?? "nil"
        )

        return updatedUser
    }

    private func removeSupervisor(
        named name: String,
        supervisorStore:
            SupervisorSettingsStore
    ) {

        for category
        in CrewCategory.allCases {

            let matches =
                supervisorStore
                    .supervisors(
                        for:
                            category
                    )
                    .filter {
                        $0.name
                            .localizedCaseInsensitiveCompare(
                                name
                            )
                        ==
                        .orderedSame
                    }

            for supervisor
            in matches {

                supervisorStore
                    .deleteSupervisor(
                        supervisor,
                        from:
                            category
                    )
            }
        }
    }
}
