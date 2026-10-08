import Foundation
import SwiftUI
import Combine

@MainActor
final class DriverStatusStore: ObservableObject {
    
    @Published var blocks:
    [DriverStatusBlock] = []
    
    private let fileName =
    "DriverStatusBlocks.json"
    
    init() {
        load()
    }
    
    func load() {
        
        blocks =
        LocalStore.shared.load(
            [DriverStatusBlock].self,
            fileName: fileName,
            defaultValue: []
        )
    }
    
    func save() {
        
        LocalStore.shared.save(
            blocks,
            fileName: fileName
        )
    }
    
    func activeBlock(
        for driverID: UUID
    ) -> DriverStatusBlock? {
        
        blocks.first {
            $0.driverID == driverID &&
            $0.endTime == nil
        }
    }
    
    func changeStatus(
        driverID: UUID,
        stormID: UUID,
        to newStatus: BlockType
    ) {
        
        let now = Date()
        
        if let index =
            blocks.firstIndex(
                where: {
                    $0.driverID == driverID &&
                    $0.endTime == nil
                }
            ) {
            
            if blocks[index].status == newStatus {
                return
            }
            
            blocks[index].endTime = now
        }
        
        blocks.append(
            DriverStatusBlock(
                driverID: driverID,
                stormID: stormID,
                status: newStatus,
                startTime: now
            )
        )
        
        save()
    }
    
    func offDuty(
        driverID: UUID
    ) {
        
        guard
            let index =
                blocks.firstIndex(
                    where: {
                        $0.driverID == driverID &&
                        $0.endTime == nil
                    }
                )
        else {
            return
        }
        
        blocks[index].endTime =
        Date()
        
        save()
    }
    
    func update(
        _ block: DriverStatusBlock
    ) {
        
        guard
            let index =
                blocks.firstIndex(
                    where: {
                        $0.id == block.id
                    }
                )
        else {
            return
        }
        
        blocks[index] =
        block
        
        save()
    }
    
    func totals(
        for driverID: UUID,
        stormID: UUID
    ) -> (
        push: Double,
        standby: Double,
        broke: Double
    ) {
        
        let items =
        blocks.filter {
            $0.driverID == driverID &&
            $0.stormID == stormID
        }
        
        let push =
        items
            .filter { $0.status == .push }
            .reduce(0) { $0 + $1.hours }
        
        let standby =
        items
            .filter { $0.status == .standby }
            .reduce(0) { $0 + $1.hours }
        
        let broke =
        items
            .filter { $0.status == .broke }
            .reduce(0) { $0 + $1.hours }
        
        return (
            push,
            standby,
            broke
        )
    }
}

