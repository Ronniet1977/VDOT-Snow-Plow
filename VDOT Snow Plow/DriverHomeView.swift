//
//  DriverHomeView.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import SwiftUI

struct DriverHomeView: View {

    let user: AppUser

    @ObservedObject var driverStore: CrewDriverStore
    @ObservedObject var appleAccountStore:
        AppleAccountStore

    @StateObject private var statusStore =
        DriverStatusStore()

    @StateObject private var mapAssignmentStore =
        DriverMapAssignmentStore()
    

    private var driver: CrewDriver? {
        driverStore.drivers.first {
            $0.name == user.name
        }
    }

    var body: some View {

        NavigationStack {

            List {

                Section("Driver") {

                    Text(user.name)

                    if let driver {

                        if !driver.truckNumber.isEmpty {
                            Text(
                                "Truck \(driver.truckNumber)"
                            )
                            .foregroundStyle(.secondary)
                        }

                        Text(
                            driver.category.displayName
                        )
                        .foregroundStyle(.secondary)
                    }
                }

                if let driver {

                    statusSection(
                        for: driver
                    )

                    mapsSection(
                        for: driver
                    )
                } else {

                    Section {

                        Text(
                            "No driver record is linked to this user."
                        )
                        .foregroundStyle(.secondary)
                    }
                }
                
                Section("Account") {

                    HStack {

                        Text("Signed In As")

                        Spacer()

                        Text(user.name)
                            .foregroundStyle(.secondary)
                    }

                    Button(
                        "Sign Out",
                        role: .destructive
                    ) {

                        appleAccountStore.signOut()
                    }
                }
            }
            .navigationTitle(
                "My Snow Plow"
            )
        }
    }
    
    private func statusSection(
        for driver: CrewDriver
    ) -> some View {

        Section("Current Status") {

            if let block =
                statusStore.activeBlock(
                    for: driver.id
                ) {

                Text(block.status.rawValue)
                    .font(.headline)

                Text(
                    "Started \(block.startTime.formatted(date: .omitted, time: .shortened))"
                )
                .foregroundStyle(.secondary)

            } else {

                Text("OFF DUTY")
                    .font(.headline)
            }
        }
    }
    
    private func mapsSection(
        for driver: CrewDriver
    ) -> some View {

        let assignments =
            mapAssignmentStore.assignments
                .filter {
                    $0.driverID == driver.id &&
                    !$0.isCompleted
                }
                .sorted {
                    $0.assignedAt < $1.assignedAt
                }

        return Section("Assigned Maps") {

            if assignments.isEmpty {

                Text("No active map assignments")
                    .foregroundStyle(.secondary)

            } else {

                ForEach(assignments) { assignment in

                    NavigationLink {

                        VDOTSnowMapNativeView(
                            initialMapNumber:
                                assignment.mapNumber
                        )

                    } label: {

                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {

                            Text(
                                "Map \(assignment.mapNumber)"
                            )
                            .font(.headline)

                            Text(
                                assignment.assignedAt.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                            )
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
