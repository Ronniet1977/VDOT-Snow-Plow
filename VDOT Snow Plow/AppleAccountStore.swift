//
//  AppleAccountStore.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation
import Combine

@MainActor
final class AppleAccountStore:
    ObservableObject {

    @Published private(set)
    var appleUserID: String?

    private let key =
        "SignedInAppleUserID"

    init() {

        appleUserID =
            UserDefaults.standard
                .string(
                    forKey: key
                )
    }

    func signIn(
        appleUserID: String
    ) {

        self.appleUserID =
            appleUserID

        UserDefaults.standard
            .set(
                appleUserID,
                forKey: key
            )
    }

    func signOut() {

        appleUserID = nil

        UserDefaults.standard
            .removeObject(
                forKey: key
            )
    }

    func matchingUser(
        from users: [AppUser]
    ) -> AppUser? {

        guard let appleUserID
        else {
            return nil
        }

        return users.first {
            $0.appleUserID ==
                appleUserID &&
            $0.isActive
        }
    }
}
