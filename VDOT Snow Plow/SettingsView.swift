import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: TimeViewModel
    
    @StateObject private var supervisorStore =
    SupervisorSettingsStore()
    
    // When true, we show a Continue button that saves + exits setup
    let isSetupMode: Bool
    let onContinue: (() -> Void)?
    
    // Draft fields (do NOT save while typing)
    @State private var ownerName = ""
    @State private var truckNumber = ""
    @State private var driverName = ""
    @State private var eventNumber = ""
    @State private var siteLabel = ""
    
    private var isDraftComplete: Bool {
        !ownerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !truckNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !driverName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        Form {
            Section("Required") {
                TextField("Owner Name", text: $ownerName)
                TextField("Truck #", text: $truckNumber)
                TextField("Driver Name", text: $driverName)
            }
            
            Section("Administration") {
                
                NavigationLink {
                    
                    SupervisorSettingsView(
                        store:
                            supervisorStore
                    )
                    
                } label: {
                    
                    Label(
                        "Supervisors",
                        systemImage:
                            "person.2.fill"
                    )
                }
            }
            
            Section {
                Button("Save Settings") {
                    applyDraftToViewModelAndSave()
                }
            }
        }
        .navigationTitle(isSetupMode ? "Required Setup" : "Settings")
        .onAppear {
            // Load drafts from saved VM values
            ownerName = vm.ownerName
            truckNumber = vm.truckNumber
            driverName = vm.driverName
            eventNumber = vm.eventNumber
            siteLabel = vm.siteLabel
        }
        .toolbar {
            if isSetupMode {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Continue") {
                        applyDraftToViewModelAndSave()
                        onContinue?()
                    }
                    .disabled(!isDraftComplete)
                }
            }
        }
    }
    
    private func applyDraftToViewModelAndSave() {
        vm.ownerName = ownerName
        vm.truckNumber = truckNumber
        vm.driverName = driverName
        vm.eventNumber = eventNumber
        vm.siteLabel = siteLabel
        vm.save()
    }
}
