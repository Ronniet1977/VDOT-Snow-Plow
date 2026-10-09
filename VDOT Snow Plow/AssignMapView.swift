import SwiftUI

struct AssignMapView: View {
    
    @Environment(\.dismiss)
    private var dismiss
    
    let driver:
    CrewDriver
    
    let stormID:
    UUID
    
    @ObservedObject var assignmentStore:
    DriverMapAssignmentStore
    
    @State private var selectedMap =
    "05"
    
    private let mapNumbers =
    (5...44).map {
        String(
            format: "%02d",
            $0
        )
    }
    +
    [
        "Minor Chemical",
        "VOIS/M6 Chemical"
    ]
    
    var body: some View {
        
        NavigationStack {
            
            Form {
                
                Section("Driver") {
                    
                    Text(driver.name)
                    
                    if driver.truckNumber
                        .isEmpty == false {
                        
                        Text(
                            "Truck \(driver.truckNumber)"
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }
                }
                
                Section("VDOT Snow Map") {
                    
                    Picker(
                        "Map",
                        selection:
                            $selectedMap
                    ) {
                        
                        ForEach(
                            mapNumbers,
                            id: \.self
                        ) { number in
                            
                            Text(number)
                                .tag(number)
                        }
                    }
                }
            }
            .navigationTitle(
                "Assign Map"
            )
            .toolbar {
                
                ToolbarItem(
                    placement:
                            .cancellationAction
                ) {
                    
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(
                    placement:
                            .confirmationAction
                ) {
                    
                    Button("Assign") {
                        
                        assignmentStore
                            .assignMap(
                                driverID:
                                    driver.id,
                                stormID:
                                    stormID,
                                mapNumber:
                                    selectedMap
                            )
                        
                        dismiss()
                    }
                }
            }
        }
    }
}

