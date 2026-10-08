import SwiftUI

struct DriverHistoryView: View {
    
    let driver: CrewDriver
    
    @ObservedObject var statusStore:
    DriverStatusStore
    
    @State private var selectedBlock:
    DriverStatusBlock?
    
    private var driverBlocks:
    [DriverStatusBlock] {
        
        statusStore.blocks
            .filter {
                $0.driverID == driver.id
            }
            .sorted {
                $0.startTime > $1.startTime
            }
    }
    
    var body: some View {
        
        List {
            
            Section {
                
                HStack {
                    
                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {
                        
                        Text(driver.name)
                            .font(.headline)
                        
                        Text(
                            driver.truckNumber.isEmpty
                            ? "No Truck"
                            : "Truck \(driver.truckNumber)"
                        )
                        .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
            } header: {
                
                Text("Driver")
            }
            
            Section("Time History") {
                
                if driverBlocks.isEmpty {
                    
                    Text(
                        "No time records yet."
                    )
                    .foregroundStyle(.secondary)
                    
                } else {
                    
                    ForEach(
                        driverBlocks
                    ) { block in
                        
                        Button {
                            
                            selectedBlock =
                            block
                            
                        } label: {
                            
                            DriverHistoryRow(
                                block: block
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle(
            "Driver History"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .sheet(
            item:
                $selectedBlock
        ) { block in
            
            DriverStatusEditView(
                block:
                    block
            ) { changedBlock in
                
                statusStore.update(
                    changedBlock
                )
            }
        }
    }
}

private struct DriverHistoryRow: View {
    
    let block:
    DriverStatusBlock
    
    var body: some View {
        
        VStack(
            alignment: .leading,
            spacing: 6
        ) {
            
            HStack {
                
                Text(
                    block.status.rawValue
                )
                .font(.headline)
                
                Spacer()
                
                Text(
                    "\(block.hours, specifier: "%.2f") hrs"
                )
                .font(.subheadline)
            }
            
            Text(
                block.startTime.formatted(
                    date: .abbreviated,
                    time: .shortened
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            
            if let end =
                block.endTime {
                
                Text(
                    "Ended \(end.formatted(date: .omitted, time: .shortened))"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                
            } else {
                
                Text(
                    "Currently running"
                )
                .font(.caption)
                .foregroundStyle(.green)
            }
            
            if block.notes
                .trimmingCharacters(
                    in:
                            .whitespacesAndNewlines
                )
                    .isEmpty == false {
                
                Text(
                    block.notes
                )
                .font(.caption)
            }
        }
        .padding(
            .vertical,
            4
        )
    }
}

