import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: TimeViewModel
    
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
            
            Section("Optional") {
                TextField("Event #", text: $eventNumber)
                TextField("Site Label (e.g., LAKE RIDGE)", text: $siteLabel)
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
