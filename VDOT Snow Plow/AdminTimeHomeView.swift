import SwiftUI

struct AdminTimeHomeView: View {
    
    @StateObject private var driverStore =
    CrewDriverStore()
    @StateObject private var supervisorStore =
    SupervisorSettingsStore()
    
    var body: some View {
        
        NavigationStack {
            
            List {
                
                Section("Time Control") {
                    
                    NavigationLink {
                        
                        AdminStatusBoardView(
                            driverStore:
                                driverStore
                        )
                        
                    } label: {
                        
                        Label(
                            "Status Board",
                            systemImage:
                                "clock.arrow.circlepath"
                        )
                    }
                }
                
                Section("Crew") {
                    
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
            }
        }
    }
}

