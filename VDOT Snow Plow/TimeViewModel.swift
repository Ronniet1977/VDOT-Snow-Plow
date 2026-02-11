//
//  TimeViewModel.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 2/11/26.
//
import Foundation
import SwiftUI
import Combine

@MainActor
final class TimeViewModel: ObservableObject {
    @Published var blocks: [TimeBlock] = []
    @Published var maps: [MapItem] = []
    
    // Optional header fields (we can place them into the export later if needed)
    @Published var ownerName: String = ""
    @Published var truckNumber: String = ""
    @Published var driverName: String = ""
    @Published var eventNumber: String = ""
    @Published var siteLabel: String = ""   // e.g., "LAKE RIDGE"
    @Published var activeBlockID: UUID? = nil
    @Published var stormStart: Date? = nil
    @Published var lastStormSummary: StormSummary? = nil
    @Published var showStormSummary: Bool = false

    private let blocksFile = "TimeBlocks.json"
    private let mapsFile = "MapItems.json"
    private let headerFile = "HeaderFields.json"
    
    struct StormSummary {
        let start: Date
        let end: Date
        let push: Double
        let standby: Double
        let broke: Double

        var total: Double { push + standby + broke }
    }

    struct HeaderFields: Codable {
        var ownerName: String
        var truckNumber: String
        var driverName: String
        var eventNumber: String
        var siteLabel: String

        var activeBlockID: UUID?
        var stormStart: Date?
    }

    
    init() {
        load()
    }
    
    func load() {
        blocks = LocalStore.shared.load([TimeBlock].self, fileName: blocksFile, defaultValue: [])
        maps = LocalStore.shared.load([MapItem].self, fileName: mapsFile, defaultValue: Self.defaultMaps())
        
        let headers = LocalStore.shared.load(HeaderFields.self, fileName: headerFile,
                                             defaultValue: HeaderFields(
                                                 ownerName: "", truckNumber: "", driverName: "", eventNumber: "", siteLabel: "",
                                                 activeBlockID: nil, stormStart: nil
                                             ))
        ownerName = headers.ownerName
        truckNumber = headers.truckNumber
        driverName = headers.driverName
        eventNumber = headers.eventNumber
        siteLabel = headers.siteLabel
        
        activeBlockID = headers.activeBlockID
        stormStart = headers.stormStart
        
        // If the saved active block doesn't exist or already ended, clear it.
        if let id = activeBlockID {
            if let idx = blocks.firstIndex(where: { $0.id == id }) {
                if blocks[idx].endDateTime != nil {
                    activeBlockID = nil
                }
            } else {
                activeBlockID = nil
            }
        }
        save()
    }
    
    
    func save() {
        LocalStore.shared.save(blocks, fileName: blocksFile)
        LocalStore.shared.save(maps, fileName: mapsFile)
        LocalStore.shared.save(
            HeaderFields(
                ownerName: ownerName,
                truckNumber: truckNumber,
                driverName: driverName,
                eventNumber: eventNumber,
                siteLabel: siteLabel,
                activeBlockID: activeBlockID,
                stormStart: stormStart
            ),
            fileName: headerFile
        )
    }
    
    func upsert(_ block: TimeBlock) {
        if let idx = blocks.firstIndex(where: { $0.id == block.id }) {
            blocks[idx] = block
        } else {
            blocks.append(block)
        }
        blocks.sort { ($0.startDateTime ?? Date.distantPast) < ($1.startDateTime ?? Date.distantPast) }
        save()
    }
    
    func delete(_ block: TimeBlock) {
        blocks.removeAll { $0.id == block.id }
        save()
    }
    
    func labelForMap(_ number: Int?) -> String? {
        guard let n = number else { return nil }
        return maps.first(where: { $0.number == n })?.label
    }
    
    func activeBlock() -> TimeBlock? {
        guard let id = activeBlockID else { return nil }
        return blocks.first(where: { $0.id == id })
    }

    func startClock(_ type: BlockType) {
        if let active = activeBlock(), active.type == type, active.endDateTime == nil {
            return
        }
        let now = Date()
        
        // If we were off duty, this is the start of the storm/shift.
        if stormStart == nil {
            stormStart = now
        }

        // 1) Stop current running block (if any)
        if let id = activeBlockID, let idx = blocks.firstIndex(where: { $0.id == id }) {
            // Only stop it if it doesn't have an end time yet
            if blocks[idx].endDateTime == nil {
                blocks[idx].endDateTime = now
            }
            activeBlockID = nil
        }

        // 2) Start a new block
        var newBlock = TimeBlock()
        newBlock.type = type
        newBlock.mode = .startEnd
        newBlock.startDateTime = now
        newBlock.endDateTime = nil
        newBlock.manualHours = nil
        // mapNumber stays optional
        blocks.append(newBlock)
        activeBlockID = newBlock.id

        save()
    }

    func offDuty() {
        let now = Date()

        // stop current running block
        if let id = activeBlockID, let idx = blocks.firstIndex(where: { $0.id == id }) {
            if blocks[idx].endDateTime == nil {
                blocks[idx].endDateTime = now
            }
        }
        activeBlockID = nil

        // Build summary for this storm/shift
        if let start = stormStart {
            let interval = DateInterval(start: start, end: now)
            let rollups = rollups(in: interval)

            let push = rollups.reduce(0) { $0 + $1.pushHours }
            let standby = rollups.reduce(0) { $0 + $1.standbyHours }
            let broke = rollups.reduce(0) { $0 + $1.brokeHours }

            lastStormSummary = StormSummary(start: start, end: now, push: push, standby: standby, broke: broke)
            showStormSummary = true
        }

        // reset storm start so the next "PUSH/STANDBY" begins a new storm
        stormStart = nil

        save()
    }


    // MARK: - Rollups
    
    struct DailyRollup: Identifiable {
        var id: Date { date }
        let date: Date
        
        let pushHours: Double
        let standbyHours: Double
        let brokeHours: Double
        
        // Overall shift window (earliest of any block that day, latest of any block that day)
        let start: Date?
        let stop: Date?
        
        var totalHours: Double { pushHours + standbyHours + brokeHours }
    }
    
    func rollups(in range: DateInterval? = nil) -> [DailyRollup] {
        let cal = Calendar.current
        
        let filtered = blocks.filter { block in
            let day = cal.startOfDay(for: block.day)
            if let r = range {
                return r.contains(day) || r.contains(day.addingTimeInterval(12*3600)) // loose include
            }
            return true
        }
        
        let grouped = Dictionary(grouping: filtered) { cal.startOfDay(for: $0.day) }
        let days = grouped.keys.sorted()
        
        return days.map { day in
            let items = grouped[day] ?? []
            
            func sum(_ type: BlockType) -> Double {
                items.filter { $0.type == type }.reduce(0) { $0 + $1.hours }
            }
            
            let start = items.compactMap { $0.startDateTime }.min()
            let stop  = items.compactMap { $0.endDateTime }.max()
            
            return DailyRollup(
                date: day,
                pushHours: sum(.push),
                standbyHours: sum(.standby),
                brokeHours: sum(.broke),
                start: start,
                stop: stop
            )
        }
    }
    
    // MARK: - Default Maps
    
    static func defaultMaps() -> [MapItem] {
        (1...100).map { MapItem(number: $0, label: "") }
    }
}
