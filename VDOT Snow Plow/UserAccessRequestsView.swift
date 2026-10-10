//
//  UserAccessRequestsView.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import SwiftUI

struct UserAccessRequestsView: View {

    @ObservedObject var requestStore:
        UserAccessRequestStore

    @ObservedObject var userStore:
        AppUserStore

    @ObservedObject var driverStore:
        CrewDriverStore
    
    @State private var selectedRoles:
        [UUID: AppUserRole] = [:]

    var body: some View {

        List {

            let pending =
                requestStore.requests
                    .filter {
                        $0.status == "pending"
                    }

            if pending.isEmpty {

                ContentUnavailableView(
                    "No Pending Requests",
                    systemImage:
                        "person.crop.circle.badge.checkmark"
                )

            } else {

                ForEach(
                    pending
                ) { request in

                    requestCard(
                        request
                    )
                }
            }
        }
        .navigationTitle(
            "Access Requests"
        )
        .task {

            await requestStore
                .syncFromCloud()
        }
    }

    @ViewBuilder
    private func requestCard(
        _ request:
            UserAccessRequest
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text(
                request.name
            )
            .font(.headline)

            Text(
                "Company: \(request.companyName)"
            )

            Text(
                "Truck VIN: ••••\(request.truckVINLast4)"
            )

            if let matchingDriver =
                matchingDriver(
                    for: request
                ) {

                Divider()

                Text(
                    "Possible Driver Match"
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

                Text(
                    matchingDriver.name
                )

                Text(
                    "Truck \(matchingDriver.truckNumber)"
                )
                .foregroundStyle(
                    .secondary
                )
            }
            
            Picker(
                "Role",
                selection:
                    Binding(
                        get: {
                            selectedRoles[
                                request.id
                            ] ?? .driver
                        },
                        set: {
                            selectedRoles[
                                request.id
                            ] = $0
                        }
                    )
            ) {

                ForEach(
                    AppUserRole.allCases
                ) { role in

                    Text(
                        role.displayName
                    )
                    .tag(
                        role
                    )
                }
            }
            .pickerStyle(
                .segmented
            )

            HStack {

                Button(
                    "Approve"
                ) {

                    approve(
                        request
                    )
                }
                .buttonStyle(
                    .borderedProminent
                )

                Button(
                    "Deny",
                    role: .destructive
                ) {

                    deny(
                        request
                    )
                }
                .buttonStyle(
                    .bordered
                )
            }
        }
        .padding(
            .vertical,
            6
        )
    }

    private func matchingDriver(
        for request:
            UserAccessRequest
    ) -> CrewDriver? {

        driverStore.drivers.first {

            $0.name
                .localizedCaseInsensitiveCompare(
                    request.name
                )
            ==
            .orderedSame
        }
    }

    private func approve(
        _ request:
            UserAccessRequest
    ) {

        let driver =
            matchingDriver(
                for: request
            )

        let user =
            AppUser(
                name:
                    request.name,
                role:
                    selectedRoles[
                        request.id
                    ] ?? .driver,
                category:
                    driver?.category,
                driverID:
                    driver?.id,
                appleUserID:
                    request.appleUserID,
                companyName:
                    request.companyName,
                truckVINLast4:
                    request.truckVINLast4,
                isActive:
                    true
            )

        userStore.add(
            user
        )

        requestStore.delete(
            request
        )
    }

    private func deny(
        _ request:
            UserAccessRequest
    ) {

        requestStore.delete(
            request
        )
    }
}
