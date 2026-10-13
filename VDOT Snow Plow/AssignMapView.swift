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
    @State private var isAssigning = false
    @State private var assignmentError: String?
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

                    NavigationLink {

                        List(
                            mapNumbers,
                            id: \.self
                        ) { number in

                            Button {

                                selectedMap =
                                    number

                            } label: {

                                HStack {

                                    Text(number)

                                    Spacer()

                                    if selectedMap ==
                                        number {

                                        Image(
                                            systemName:
                                                "checkmark"
                                        )
                                    }
                                }
                            }
                            .buttonStyle(
                                .plain
                            )
                        }
                        .navigationTitle(
                            "Select Map"
                        )

                    } label: {

                        HStack {

                            Text("Map")

                            Spacer()

                            Text(selectedMap)
                                .foregroundStyle(
                                    .secondary
                                )
                        }
                    }
                }
            }
            .navigationTitle(
                "Assign Map"
            )
            
            .alert(
                "Map Assignment",
                isPresented: Binding(
                    get: { assignmentError != nil },
                    set: {
                        if !$0 {
                            assignmentError = nil
                        }
                    }
                )
            ) {
                Button("OK") {
                    assignmentError = nil
                }
            } message: {
                Text(assignmentError ?? "")
            }
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
                    
                    
                    Button {
                        
                        guard !isAssigning else {
                            return
                        }
                        
                        isAssigning = true
                        
                        Task {
                            
                            defer {
                                isAssigning = false
                            }
                            
                            do {
                                let success = try await assignmentStore
                                    .assignMapSafely(
                                        driverID: driver.id,
                                        stormID: stormID,
                                        mapNumber: selectedMap
                                    )
                                
                                if success {
                                    dismiss()
                                } else {
                                    assignmentError =
                                    "Map \(selectedMap) is already assigned to \(driver.name) for this storm."
                                }
                                
                            } catch {
                                assignmentError =
                                error.localizedDescription
                            }
                        }
                        
                    } label: {
                        
                        if isAssigning {
                            ProgressView()
                        } else {
                            Text("Assign")
                        }
                    }
                    .disabled(isAssigning)
                }
            }
        }
    }
}

