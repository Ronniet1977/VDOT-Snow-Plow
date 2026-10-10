import SwiftUI

struct AdminTimeHomeView: View {
    
    @StateObject private var driverStore =
    CrewDriverStore()
    @StateObject private var supervisorStore =
    SupervisorSettingsStore()
    
    @StateObject private var userStore =
        AppUserStore()
    
    @StateObject private var requestStore =
        UserAccessRequestStore()
    @StateObject private var appleAccountStore =
        AppleAccountStore()
    
    private var appleUser: AppUser? {
        appleAccountStore.matchingUser(
            from: userStore.users
        )
    }
    
    var body: some View {

        Group {

            if let appleUser {

                if appleUser.role == .driver {

                    DriverHomeView(
                        user: appleUser,
                        driverStore: driverStore,
                        appleAccountStore: appleAccountStore
                    )

                } else {

                    adminHome
                }

            } else if appleAccountStore.appleUserID != nil {

                adminHome

            } else {

                AppleSignInView(
                    requestStore: requestStore,
                    appleAccountStore: appleAccountStore,
                    userStore: userStore
                )
            }
        }
        .task {

            await driverStore
                .syncFromCloud()

            await supervisorStore
                .syncFromCloud()

            await userStore
                .syncFromCloud()

            await requestStore
                .syncFromCloud()
        }
    }
        
    @ViewBuilder
    private var adminHome: some View {

        NavigationStack {

            List {
                
                Section("Time Control") {
                    
                    if appleUser?.role == .admin ||
                        appleUser?.role == .supervisor {

                        NavigationLink {

                            AdminStatusBoardView(
                                driverStore: driverStore,
                                canEdit: appleUser?.role == .admin,
                                supervisorCategory:
                                    appleUser?.role == .supervisor
                                    ? appleUser?.category
                                    : nil
                            )

                        } label: {

                            Label(
                                "Status Board",
                                systemImage:
                                    "clock.arrow.circlepath"
                            )
                        }
                    }
                }
                
                Section("Crew") {
                    
                    if appleUser?.role == .admin ||
                       appleAccountStore.appleUserID != nil {
                        NavigationLink {

                            CrewDriversView(
                                store:
                                    driverStore
                            )

                        } label: {

                            HStack {

                                Label(
                                    "Drivers",
                                    systemImage:
                                        "person.3"
                                )

                                Spacer()

                                Text(
                                    "\(driverStore.drivers.count)"
                                )
                                .foregroundStyle(
                                    .secondary
                                )
                            }
                        }

                        NavigationLink {

                            SupervisorSettingsView(
                                store:
                                    supervisorStore
                            )

                        } label: {

                            Label(
                                "Supervisors",
                                systemImage:
                                    "person.2.badge.gearshape"
                            )
                        }

                        NavigationLink {

                            AppUsersView(
                                store:
                                    userStore
                            )

                        } label: {

                            Label(
                                "Users",
                                systemImage:
                                    "person.crop.circle.badge.checkmark"
                            )
                        }
                        
                        NavigationLink {

                            UserAccessRequestsView(
                                requestStore: requestStore,
                                userStore: userStore,
                                driverStore: driverStore
                            )

                        } label: {

                            HStack {

                                Label(
                                    "Access Requests",
                                    systemImage:
                                        "person.crop.circle.badge.questionmark"
                                )

                                Spacer()

                                let pendingCount =
                                    requestStore.requests
                                        .filter {
                                            $0.status == "pending"
                                        }
                                        .count

                                if pendingCount > 0 {

                                    Text(
                                        "\(pendingCount)"
                                    )
                                    .foregroundStyle(
                                        .secondary
                                    )
                                }
                            }
                        }
                    }
                    
                    HStack {
                        
                        Text(
                            "Active Drivers"
                        )
                        
                        Spacer()
                        
                        Text(
                            "\(driverStore.drivers.filter { $0.isActive }.count)"
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }
                }
                
                Section("Account") {

                    if let appleUser {

                        HStack {

                            Text("Signed In As")

                            Spacer()

                            Text(appleUser.name)
                                .foregroundStyle(.secondary)
                        }
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
                "Admin Time"
            )
        }
    }
}

