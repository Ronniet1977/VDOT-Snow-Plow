//
//  CurrentUserStore.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/9/26.
//

import Foundation
import Combine

@MainActor
final class CurrentUserStore:
    ObservableObject {

    @Published var currentUserID:
        UUID?

    private let key =
        "CurrentAppUserID"

    init() {

        if
            let saved =
                UserDefaults.standard
                    .string(
                        forKey:
                            key
                    ),
            let id =
                UUID(
                    uuidString:
                        saved
                ) {

            currentUserID =
                id
        }
    }

    func select(
        _ user: AppUser
    ) {

        currentUserID =
            user.id

        UserDefaults.standard
            .set(
                user.id.uuidString,
                forKey:
                    key
            )
    }

    func clear() {

        currentUserID =
            nil

        UserDefaults.standard
            .removeObject(
                forKey:
                    key
            )
    }

    func currentUser(
        from users:
            [AppUser]
    ) -> AppUser? {

        guard
            let currentUserID
        else {
            return nil
        }

        return users.first {
            $0.id ==
            currentUserID
        }
    }
}
