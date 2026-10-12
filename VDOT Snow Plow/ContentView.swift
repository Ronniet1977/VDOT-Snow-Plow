import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: TimeViewModel
    
    @StateObject private var userStore =
    AppUserStore()
    
    @StateObject private var appleAccountStore =
    AppleAccountStore()
    
    @StateObject private var mapAssignmentStore =
    DriverMapAssignmentStore()
    @StateObject private var versionControlStore =
    AppVersionControlStore()
    
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
        
        Group {
            
            if versionControlStore.isChecking {
                
                ProgressView(
                    "Checking app version..."
                )
                
            } else if versionControlStore.requiresUpdate {
                
                updateRequiredView
                
            } else {
                
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
                    
                    ExportView(
                        currentUser: currentUser
                    )
                    .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
                    
                    NavigationStack {
                        SettingsView(isSetupMode: false, onContinue: nil)
                    }
                    .tabItem { Label("Settings", systemImage: "gear") }
                }
                .task(
                    id:
                        appleAccountStore
                        .appleUserID
                ) {
                    
                    await userStore
                        .syncFromCloud()
                    
                    await userStore
                        .createDefaultAdminIfNeeded(
                            appleUserID:
                                appleAccountStore
                                .appleUserID
                        )
                    
                    await mapAssignmentStore
                        .syncFromCloud()
                }
            }
        }
        .task {
            
            await versionControlStore
                .checkVersion()
        }
    }
    
    @ViewBuilder
    private var updateRequiredView: some View {

        VStack(
            spacing: 20
        ) {

            Image(
                systemName:
                    "arrow.down.circle.fill"
            )
            .font(
                .system(size: 70)
            )

            Text(
                "Update Required"
            )
            .font(
                .largeTitle.bold()
            )

            Text(
                versionControlStore
                    .control?
                    .message
                ??
                "Please update VDOT Snow Plow to continue."
            )
            .multilineTextAlignment(
                .center
            )
            .foregroundStyle(
                .secondary
            )

            Text(
                AppVersionInfo.display
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )
        }
        .padding()
    }
}
