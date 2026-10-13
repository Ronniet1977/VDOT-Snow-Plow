
import SwiftUI

struct AdminMapProgressView: View {
    let adminName: String
    
    @StateObject private var assignmentStore =
    DriverMapAssignmentStore()
    
    @StateObject private var progressStore =
    MapProgressStore()
    
    @State private var isLoading = true
    @State private var mapToClear: MapProgressGroup?
    @State private var clearError: String?
    
    private var activeAssignments: [DriverMapAssignment] {
        assignmentStore.assignments.filter {
            !$0.isCompleted
        }
    }
    
    private var mapGroups: [MapProgressGroup] {
        
        let grouped = Dictionary(
            grouping: activeAssignments,
            by: {
                MapProgressKey(
                    stormID: $0.stormID,
                    mapNumber: $0.mapNumber
                )
            }
        )
        
        return grouped.map { key, assignments in
            
            MapProgressGroup(
                stormID: key.stormID,
                mapNumber: key.mapNumber,
                driverIDs: Array(
                    Set(assignments.map(\.driverID))
                )
            )
        }
        .sorted {
            if $0.stormID == $1.stormID {
                return $0.mapNumber.localizedStandardCompare(
                    $1.mapNumber
                ) == .orderedAscending
            }
            
            return $0.stormID.uuidString <
                $1.stormID.uuidString
        }
    }
    
    var body: some View {
        
        List {
            
            Section {
                
                HStack {
                    Text("Map #")
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("Open or Done")
                        .fontWeight(.bold)
                }
                
                ForEach(mapGroups) { map in
                    
                    let stage = progressStore.mapStage(
                        stormID: map.stormID,
                        mapNumber: map.mapNumber,
                        assignedDriverIDs: map.driverIDs,
                        resetVersion: 0
                    )
                    
                    HStack {
                        
                        Text("Map \(map.mapNumber)")
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Label(
                            stage.rawValue,
                            systemImage:
                                stage == .done
                            ? "checkmark.circle.fill"
                            : "circle.fill"
                        )
                    }
                    .foregroundStyle(
                        stage == .notStarted
                        ? Color.primary
                        : Color.white
                    )
                    .padding(12)
                    .background(
                        stage == .done
                        ? Color.green
                        : stage == .openedUp
                        ? Color.blue
                        : Color.white
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 10
                        )
                    )
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing) {
                        
                        Button("Clear", role: .destructive) {
                            mapToClear = map
                        }
                    }
                }
            }
        }
        .navigationTitle("Map Progress")
        .confirmationDialog(
            "Clear Map Progress?",
            isPresented: Binding(
                get: { mapToClear != nil },
                set: { if !$0 { mapToClear = nil } }
            ),
            titleVisibility: .visible
        ) {
            
            Button(
                "Clear Entire Map",
                role: .destructive
            ) {
                
                guard let map = mapToClear else {
                    return
                }
                
                mapToClear = nil
                
                Task {
                    do {
                        try await progressStore.clearProgress(
                            stormID: map.stormID,
                            mapNumber: map.mapNumber,
                            resetBy: adminName
                        )
                    } catch {
                        clearError = error.localizedDescription
                    }
                }
            }
            
            Button("Cancel", role: .cancel) {
                mapToClear = nil
            }
            
        } message: {
            
            Text(
                "All assigned drivers will need to confirm their road progress again."
            )
        }
        .alert(
            "Unable to Clear Progress",
            isPresented: Binding(
                get: { clearError != nil },
                set: { if !$0 { clearError = nil } }
            )
        ) {
            Button("OK") {
                clearError = nil
            }
        } message: {
            Text(clearError ?? "")
        }
        .overlay {
            
            if isLoading {
                ProgressView("Loading map progress...")
            }
        }
        .task {
            await refresh()
        }
        .refreshable {
            await refresh()
        }
    }
    
    private func refresh() async {
        
        isLoading = true
        
        await assignmentStore.syncFromCloud()
        await progressStore.syncFromCloud()
        
        isLoading = false
    }
}

// MARK: - Group Maps

private struct MapProgressKey: Hashable {
    
    let stormID: UUID
    let mapNumber: String
}

private struct MapProgressGroup: Identifiable {
    
    let stormID: UUID
    let mapNumber: String
    let driverIDs: [UUID]
    
    var id: String {
        "\(stormID.uuidString)-\(mapNumber)"
    }
}


