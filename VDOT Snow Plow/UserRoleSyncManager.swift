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

            if let driver =
                driverStore.drivers.first(
                    where: {
                        $0.id ==
                            oldUser?.driverID ||
                        $0.name
                            .localizedCaseInsensitiveCompare(
                                oldUser?.name ?? ""
                            )
                        ==
                        .orderedSame
                    }
                ) {

                driverStore.delete(
                    driver
                )
            }

            updatedUser.driverID =
                nil
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
                nil

        case .admin:

            updatedUser.driverID =
                nil
        }

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
