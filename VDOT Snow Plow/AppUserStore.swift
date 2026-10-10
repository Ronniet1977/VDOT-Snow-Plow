//
//  AppUserStore.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/9/26.
//

import Foundation
import Combine

@MainActor
final class AppUserStore:
    ObservableObject {

    @Published var users:
        [AppUser] = []
    @Published var adminProtectionMessage:
        String?

    private let fileName =
        "AppUsers.json"

    private let cloud =
        CloudAppUserService.shared

    init() {
        load()
    }

    func load() {

        users =
            LocalStore.shared.load(
                [AppUser].self,
                fileName:
                    fileName,
                defaultValue:
                    []
            )
    }

    func save() {

        LocalStore.shared.save(
            users,
            fileName:
                fileName
        )
    }
    
    func saveAndWait(
        _ user: AppUser
    ) async throws {

        if let index =
            users.firstIndex(
                where: {
                    $0.id == user.id
                }
            ) {

            users[index] =
                user

        } else {

            users.append(
                user
            )
        }

        users.sort {
            $0.name
                .localizedCaseInsensitiveCompare(
                    $1.name
                )
            ==
            .orderedAscending
        }

        save()

        try await cloud
            .saveUser(
                user
            )

        print(
            "☁️ User saved:",
            user.name
        )
    }

    func add(
        _ user: AppUser
    ) {

        users.append(
            user
        )

        users.sort {
            $0.name
                .localizedCaseInsensitiveCompare(
                    $1.name
                )
            ==
            .orderedAscending
        }

        save()

        Task {

            do {

                try await cloud
                    .saveUser(
                        user
                    )

                print(
                    "☁️ User uploaded:",
                    user.name
                )

            } catch {

                print(
                    "❌ User CloudKit save failed:",
                    error
                )
            }
        }
    }

    func update(
        _ user: AppUser
    ) {

        guard
            let index =
                users.firstIndex(
                    where: {
                        $0.id ==
                        user.id
                    }
                )
        else {
            return
        }

        let oldUser =
            users[index]

        let activeAdminCount =
            users.filter {
                $0.role == .admin &&
                $0.isActive
            }
            .count

        let removingLastAdmin =
            oldUser.role == .admin &&
            oldUser.isActive &&
            (
                user.role != .admin ||
                !user.isActive
            ) &&
            activeAdminCount <= 1

        if removingLastAdmin {
            
            adminProtectionMessage =
                "At least one active Admin is required."

            print(
                "🛑 Cannot remove the last active Admin"
            )

            return
        }

        users[index] =
            user

        save()

        Task {

            do {

                try await cloud
                    .saveUser(
                        user
                    )

                print(
                    "☁️ User updated:",
                    user.name
                )

            } catch {

                print(
                    "❌ User CloudKit update failed:",
                    error
                )
            }
        }
    }

    func delete(
        _ user: AppUser
    ) {

        if user.role == .admin &&
            user.isActive &&
            activeAdminCount <= 1 {
            
            adminProtectionMessage =
                "At least one active Admin is required."

            print(
                "🛑 Cannot delete the last active Admin"
            )

            return
        }

        users.removeAll {
            $0.id ==
                user.id
        }

        save()

        Task {

            do {

                try await cloud
                    .deleteUser(
                        user
                    )

                print(
                    "☁️ User deleted:",
                    user.name
                )

            } catch {

                print(
                    "❌ User CloudKit delete failed:",
                    error
                )
            }
        }
    }

    func syncFromCloud() async {

        do {

            let cloudUsers =
                try await cloud
                    .fetchUsers()

            users =
                cloudUsers.sorted {
                    $0.name
                        .localizedCaseInsensitiveCompare(
                            $1.name
                        )
                    ==
                    .orderedAscending
                }

            save()

            print(
                "☁️ Users synced from CloudKit:",
                users.count
            )

        } catch {

            print(
                "❌ User CloudKit fetch failed:",
                error
            )
        }
    }
    
    private var activeAdminCount: Int {

        users.filter {
            $0.role == .admin &&
            $0.isActive
        }
        .count
    }
}
