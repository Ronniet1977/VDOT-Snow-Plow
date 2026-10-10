import SwiftUI

struct AdminTimeHomeView: View {
    
    @StateObject private var driverStore =
    CrewDriverStore()
    @StateObject private var supervisorStore =
    SupervisorSettingsStore()
    
    @StateObject private var userStore =
        AppUserStore()
    
    @StateObject private var currentUserStore =
        CurrentUserStore()
    
    private var currentUser: AppUser? {
        currentUserStore.currentUser(
            from: userStore.users
        )
    }
    
    var body: some View {
        
        NavigationStack {
            
            List {
                
                Section("Time Control") {
                    
                    if currentUser?.role == .admin ||
                       currentUser?.role == .supervisor {

                        NavigationLink {

                            AdminStatusBoardView(
                                driverStore: driverStore,
                                canEdit:
                                    currentUser?.role == .admin
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
                    NavigationLink {

                        CurrentUserPickerView(
                            userStore:
                                userStore,
                            currentUserStore:
                                currentUserStore
                        )

                    } label: {

                        HStack {

                            Label(
                                "Current User",
                                systemImage:
                                    "person.crop.circle"
                            )

                            Spacer()

                            if let user =
                                currentUserStore
                                    .currentUser(
                                        from:
                                            userStore.users
                                    ) {

                                Text(
                                    user.name
                                )
                                .foregroundStyle(
                                    .secondary
                                )

                            } else {

                                Text(
                                    "Choose"
                                )
                                .foregroundStyle(
                                    .secondary
                                )
                            }
                        }
                    }
                    
                    if currentUser?.role == .admin {

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
            }
            .navigationTitle(
                "Admin Time"
            )
            .task {

                await driverStore
                    .syncFromCloud()

                await supervisorStore
                    .syncFromCloud()

                await userStore
                    .syncFromCloud()
            }
        }
    }
}

