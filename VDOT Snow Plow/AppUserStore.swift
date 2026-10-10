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

            for cloudUser
            in cloudUsers {

                if let index =
                    users.firstIndex(
                        where: {
                            $0.id ==
                            cloudUser.id
                        }
                    ) {

                    users[index] =
                        cloudUser

                } else {

                    users.append(
                        cloudUser
                    )
                }
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

            print(
                "☁️ Users merged from CloudKit:",
                cloudUsers.count
            )

        } catch {

            print(
                "❌ User CloudKit fetch failed:",
                error
            )
        }
    }
}
