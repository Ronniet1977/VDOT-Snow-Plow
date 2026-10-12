//
//  UserAppStatusStore.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/12/26.
//

import Foundation
import Combine

@MainActor
final class UserAppStatusStore: ObservableObject {

    @Published var statuses:
        [UserAppStatus] = []

    private let cloud =
        CloudUserAppStatusService.shared

    func syncFromCloud() async {

        do {

            statuses =
                try await cloud
                    .fetchStatuses()

            print(
                "☁️ User app statuses loaded:",
                statuses.count
            )

        } catch {

            print(
                "❌ User app status fetch failed:",
                error
            )
        }
    }

    func updateCurrentUser(
        appleUserID: String
    ) async {

        let status =
            UserAppStatus(
                appleUserID:
                    appleUserID,
                appVersion:
                    AppVersionInfo.version,
                buildNumber:
                    Int(
                        AppVersionInfo.build
                    ) ?? 0,
                lastSeenAt:
                    Date()
            )

        do {

            try await cloud
                .saveStatus(
                    status
                )

            if let index =
                statuses.firstIndex(
                    where: {
                        $0.appleUserID ==
                            appleUserID
                    }
                ) {

                statuses[index] =
                    status

            } else {

                statuses.append(
                    status
                )
            }

            print(
                "✅ Current user app status updated"
            )

        } catch {

            print(
                "❌ User app status save failed:",
                error
            )
        }
    }

    func status(
        for appleUserID: String?
    ) -> UserAppStatus? {

        guard let appleUserID
        else {
            return nil
        }

        return statuses.first {
            $0.appleUserID ==
                appleUserID
        }
    }
}
