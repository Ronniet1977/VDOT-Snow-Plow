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
    @ObservedObject var supervisorStore:
        SupervisorSettingsStore
    
    @State private var selectedRoles:
        [UUID: AppUserRole] = [:]
    @State private var deniedRequestIDs:
        Set<UUID> = []
    @State private var alsoDrivers:
        [UUID: Bool] = [:]

    var body: some View {

        List {

            let pending =
                requestStore.requests
                    .filter { request in

                        request.status == "pending" &&

                        !userStore.users.contains {
                            $0.appleUserID ==
                                request.appleUserID
                        } &&

                        !deniedRequestIDs.contains(
                            request.id
                        )
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

            var deniedIDs:
                Set<UUID> = []

            for request
            in requestStore.requests {

                do {

                    let decisions =
                        try await
                            CloudAccessRequestDecisionService
                                .shared
                                .fetchDecisions(
                                    for:
                                        request.appleUserID
                                )

                    if decisions.contains(
                        where: {
                            $0.requestID ==
                                request.id &&
                            $0.decision ==
                                "denied"
                        }
                    ) {

                        deniedIDs.insert(
                            request.id
                        )
                    }

                } catch {

                    print(
                        "❌ Failed loading denial decisions:",
                        error
                    )
                }
            }

            deniedRequestIDs =
                deniedIDs
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
            
            if (
                selectedRoles[
                    request.id
                ] ?? .driver
            ) == .supervisor {

                Toggle(
                    "Also a Driver",
                    isOn:
                        Binding(
                            get: {
                                alsoDrivers[
                                    request.id
                                ] ?? false
                            },
                            set: {
                                alsoDrivers[
                                    request.id
                                ] = $0
                            }
                        )
                )
            }

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
        _ request: UserAccessRequest
    ) {

        Task {

            var driver =
                matchingDriver(
                    for: request
                )

            let selectedRole =
                selectedRoles[
                    request.id
                ] ?? .driver
            
            let shouldAlsoDrive =
                selectedRole == .supervisor &&
                (
                    alsoDrivers[
                        request.id
                    ] ?? false
                )

            if (
                selectedRole == .driver ||
                shouldAlsoDrive
            ) &&
                driver == nil {

                driverStore.add(
                    name: request.name,
                    truckNumber: request.truckVINLast4,
                    category: .plowOnly
                )

                driver =
                    driverStore.drivers.first {
                        $0.name
                            .localizedCaseInsensitiveCompare(
                                request.name
                            )
                        ==
                        .orderedSame
                    }
            }

            let userToSave: AppUser

            if var existingUser =
                userStore.users.first(
                    where: {
                        $0.appleUserID ==
                            request.appleUserID
                    }
                ) {

                existingUser.name =
                    request.name

                existingUser.role =
                    selectedRole

                existingUser.category =
                    driver?.category

                existingUser.driverID =
                    (
                        selectedRole == .driver ||
                        shouldAlsoDrive
                    )
                    ? driver?.id
                    : nil

                existingUser.companyName =
                    request.companyName

                existingUser.truckVINLast4 =
                    request.truckVINLast4
                
                existingUser.phoneNumber =
                    request.phoneNumber
                
                existingUser.isAlsoDriver =
                    shouldAlsoDrive

                existingUser.isActive =
                    true

                userToSave =
                    existingUser

            } else {

                userToSave =
                    AppUser(
                        name:
                            request.name,
                        role:
                            selectedRole,
                        category:
                            driver?.category,
                        driverID:
                            (
                                selectedRole == .driver ||
                                shouldAlsoDrive
                            )
                            ? driver?.id
                            : nil,
                        appleUserID:
                            request.appleUserID,
                        companyName:
                            request.companyName,
                        truckVINLast4:
                            request.truckVINLast4,
                        phoneNumber:
                            request.phoneNumber,
                        isAlsoDriver:
                            shouldAlsoDrive,
                        isActive:
                            true
                    )
            }
            
            let syncedUser =
                UserRoleSyncManager.shared
                    .syncRole(
                        user: userToSave,
                        oldUser:
                            userStore.users.first(
                                where: {
                                    $0.appleUserID ==
                                        request.appleUserID
                                }
                            ),
                        driverStore:
                            driverStore,
                        supervisorStore:
                            supervisorStore
                    )

            do {

                try await userStore
                    .saveAndWait(
                        syncedUser
                    )

                print(
                    "✅ Access approved:",
                    request.name
                )

            } catch {

                print(
                    "❌ Approval failed:",
                    error
                )
            }
        }
    }

    private func deny(
        _ request:
            UserAccessRequest
    ) {

        Task {

            let decision =
                AccessRequestDecision(
                    requestID:
                        request.id,
                    appleUserID:
                        request.appleUserID,
                    decision:
                        "denied"
                )

            do {

                try await
                    CloudAccessRequestDecisionService
                        .shared
                        .saveDecision(
                            decision
                        )
                
                deniedRequestIDs.insert(
                    request.id
                )

                print(
                    "🚫 Access denied:",
                    request.name
                )

            } catch {

                print(
                    "❌ Denial save failed:",
                    error
                )
            }
        }
    }
}
