//
//  UserAccessRequestStore.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class UserAccessRequestStore:
    ObservableObject {

    @Published var requests:
        [UserAccessRequest] = []

    private let cloud =
        CloudUserAccessRequestService.shared

    func syncFromCloud() async {

        do {

            let cloudRequests =
                try await cloud.fetchRequests()

            requests =
                cloudRequests

            print(
                "☁️ Access requests loaded:",
                requests.count
            )

        } catch {

            print(
                "❌ Access request sync failed:",
                error
            )
        }
    }

    func add(
        _ request:
            UserAccessRequest
    ) {

        requests.append(
            request
        )

        Task {

            do {

                try await cloud
                    .saveRequest(
                        request
                    )

                print(
                    "☁️ Access request uploaded:",
                    request.name
                )

            } catch {

                print(
                    "❌ Access request upload failed:",
                    error
                )
            }
        }
    }

    func update(
        _ request:
            UserAccessRequest
    ) {

        guard let index =
                requests.firstIndex(
                    where: {
                        $0.id ==
                            request.id
                    }
                )
        else {
            return
        }

        requests[index] =
            request

        Task {

            do {

                try await cloud
                    .saveRequest(
                        request
                    )

            } catch {

                print(
                    "❌ Access request update failed:",
                    error
                )
            }
        }
    }

    func delete(
        _ request:
            UserAccessRequest
    ) {

        requests.removeAll {
            $0.id ==
                request.id
        }

        Task {

            do {

                try await cloud
                    .deleteRequest(
                        request
                    )

                print(
                    "☁️ Access request deleted:",
                    request.name
                )

            } catch {

                print(
                    "❌ Access request delete failed:",
                    error
                )
            }
        }
    }
}
