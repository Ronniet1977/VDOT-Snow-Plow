import SwiftUI

struct ContentView: View {
    @State private var showSetup = false
    @EnvironmentObject var vm: TimeViewModel
    
    @StateObject private var userStore =
        AppUserStore()

    @StateObject private var appleAccountStore =
        AppleAccountStore()

    @StateObject private var mapAssignmentStore =
        DriverMapAssignmentStore()
    
    private var currentUser: AppUser? {
        appleAccountStore.matchingUser(
            from: userStore.users
        )
    }

    private var shouldShowMapsTab: Bool {

        guard let currentUser else {
            return true
        }

        guard currentUser.role == .driver else {
            return true
        }

        guard let driverID =
            currentUser.driverID
        else {
            return true
        }

        let hasActiveAssignment =
            mapAssignmentStore
                .assignments
                .contains {
                    $0.driverID == driverID &&
                    $0.completedAt == nil
                }

        return hasActiveAssignment == false
    }
    
    var body: some View {
        TabView {
            AdminTimeHomeView()
                .tabItem {
                    Label(
                        "Times",
                        systemImage:
                            "clock"
                    )
                }
            
            if shouldShowMapsTab {

                MapsView()
                    .tabItem {
                        Label(
                            "Maps",
                            systemImage:
                                "map"
                        )
                    }
            }
            
            ExportView()
                .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
            
            NavigationStack {
                SettingsView(isSetupMode: false, onContinue: nil)
            }
            .tabItem { Label("Settings", systemImage: "gear") }
        }
        .task {

            await userStore
                .syncFromCloud()

            await mapAssignmentStore
                .syncFromCloud()
        }
        .onAppear {
            showSetup = !vm.isSetupComplete
        }
        .fullScreenCover(isPresented: $showSetup) {
            NavigationStack {
                SettingsView(isSetupMode: true) {
                    // Continue pressed inside SettingsView
                    showSetup = false
                }
            }
            .interactiveDismissDisabled(true)
        }
    }
}
