import Foundation
import SwiftUI
import Combine

@MainActor
final class DriverMapAssignmentStore: ObservableObject {
    
    @Published var assignments:
    [DriverMapAssignment] = []
    
    private let fileName =
    "DriverMapAssignments.json"
    
    init() {
        load()
    }
    
    func load() {
        assignments =
        LocalStore.shared.load(
            [DriverMapAssignment].self,
            fileName: fileName,
            defaultValue: []
        )
    }
    
    func save() {
        LocalStore.shared.save(
            assignments,
            fileName: fileName
        )
    }
    
    func currentAssignments(
        driverID: UUID,
        stormID: UUID
    ) -> [DriverMapAssignment] {
        
        assignments.filter {
            $0.driverID == driverID &&
            $0.stormID == stormID &&
            $0.completedAt == nil
        }
    }
    
    func assignMap(
        driverID: UUID,
        stormID: UUID,
        mapNumber: String
    ) {
        
        assignments.append(
            DriverMapAssignment(
                driverID: driverID,
                stormID: stormID,
                mapNumber: mapNumber
            )
        )
        
        save()
    }
    
    func finish(
        _ assignment: DriverMapAssignment
    ) {
        
        guard
            let index =
                assignments.firstIndex(
                    where: {
                        $0.id == assignment.id
                    }
                )
        else {
            return
        }
        
        assignments[index].completedAt =
        Date()
        
        save()
    }
}

