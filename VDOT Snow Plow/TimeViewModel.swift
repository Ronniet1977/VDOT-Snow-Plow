import Foundation
import SwiftUI
import Combine

@MainActor
final class TimeViewModel: ObservableObject {
    @Published var blocks: [TimeBlock] = []
    @Published var maps: [MapItem] = []
    
    // Header fields
    @Published var ownerName: String = ""
    @Published var truckNumber: String = ""
    @Published var driverName: String = ""
    @Published var eventNumber: String = ""
    @Published var siteLabel: String = ""
    
    // Time clock state
    @Published var activeBlockID: UUID? = nil
    @Published var stormStart: Date? = nil
    @Published var lastStormSummary: StormSummary? = nil
    @Published var showStormSummary: Bool = false
    
    // Storm picker state
    @Published var storms: [Storm] = []
    @Published var activeStormID: UUID? = nil
    @Published var selectedStormID: UUID? = nil
    
    private let blocksFile = "TimeBlocks.json"
    private let mapsFile = "MapItems.json"
    private let headerFile = "HeaderFields.json"
    private let stormsFile = "Storms.json"
    
    var isSetupComplete: Bool {
        !ownerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !truckNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !driverName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isClockRunning: Bool {
        guard let id = activeBlockID,
              let b = blocks.first(where: { $0.id == id }) else { return false }
        return b.endDateTime == nil
    }
    
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
        
        var activeStormID: UUID?
        var selectedStormID: UUID?
    }
    
    init() {
        load()
    }
    
    // MARK: - Load / Save
    
    func load() {
        blocks = LocalStore.shared.load([TimeBlock].self, fileName: blocksFile, defaultValue: [])
        maps = LocalStore.shared.load([MapItem].self, fileName: mapsFile, defaultValue: Self.defaultMaps())
        storms = LocalStore.shared.load([Storm].self, fileName: stormsFile, defaultValue: [])
        
        let headers = LocalStore.shared.load(
            HeaderFields.self,
            fileName: headerFile,
            defaultValue: HeaderFields(
                ownerName: "",
                truckNumber: "",
                driverName: "",
                eventNumber: "",
                siteLabel: "",
                activeBlockID: nil,
                stormStart: nil,
                activeStormID: nil,
                selectedStormID: nil
            )
        )
        
        ownerName = headers.ownerName
        truckNumber = headers.truckNumber
        driverName = headers.driverName
        eventNumber = headers.eventNumber
        siteLabel = headers.siteLabel
        
        activeBlockID = headers.activeBlockID
        stormStart = headers.stormStart
        activeStormID = headers.activeStormID
        selectedStormID = headers.selectedStormID
        
        // Validate active block
        if let id = activeBlockID {
            if let idx = blocks.firstIndex(where: { $0.id == id }) {
                if blocks[idx].endDateTime != nil {
                    activeBlockID = nil
                }
            } else {
                activeBlockID = nil
            }
        }
        
        // Validate storm IDs (if storms were deleted/empty)
        if let sid = activeStormID, storms.first(where: { $0.id == sid }) == nil {
            activeStormID = nil
        }
        if let sid = selectedStormID, storms.first(where: { $0.id == sid }) == nil {
            selectedStormID = nil
        }
        
        // If there are storms but nothing selected, default to most recent
        if selectedStormID == nil, let newest = storms.sorted(by: { $0.start > $1.start }).first {
            selectedStormID = newest.id
        }
        
        // IMPORTANT: do NOT call save() here (prevents “saving while typing” vibe)
    }
    
    func save() {
        LocalStore.shared.save(blocks, fileName: blocksFile)
        LocalStore.shared.save(maps, fileName: mapsFile)
        LocalStore.shared.save(storms, fileName: stormsFile)
        
        LocalStore.shared.save(
            HeaderFields(
                ownerName: ownerName,
                truckNumber: truckNumber,
                driverName: driverName,
                eventNumber: eventNumber,
                siteLabel: siteLabel,
                activeBlockID: activeBlockID,
                stormStart: stormStart,
                activeStormID: activeStormID,
                selectedStormID: selectedStormID
            ),
            fileName: headerFile
        )
    }
    
    // MARK: - Storm helpers
    
    // MARK: - Storm helpers
    
    var selectedStorm: Storm? {
        guard let id = selectedStormID else { return nil }
        return storms.first(where: { $0.id == id })
    }
    
    var selectedStormName: String {
        guard let sid = selectedStormID,
              let s = storms.first(where: { $0.id == sid }) else {
            return "All Storms"
        }
        return s.name
    }
    
    func selectStorm(_ id: UUID?) {
        // ✅ Option 1: block switching while clock is running
        guard !isClockRunning else { return }
        
        selectedStormID = id
        save()
    }
    
    func createStorm(name: String? = nil) {
        let now = Date()
        let title = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = (title?.isEmpty == false) ? title! : "Storm \(storms.count + 1)"
        let s = Storm(name: finalName, start: now, end: nil, notes: "")
        storms.append(s)
        activeStormID = s.id
        selectedStormID = s.id
        save()
    }
    
    func startNewStorm(name: String? = nil, at date: Date = Date()) {
        let clean = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let stormName = clean.isEmpty ? "Storm \(storms.count + 1)" : clean
        
        let s = Storm(name: stormName, start: date)
        storms.append(s)
        activeStormID = s.id
        selectedStormID = s.id
        
        save()
    }
    
    func endActiveStorm(at date: Date = Date()) {
        guard let sid = activeStormID,
              let idx = storms.firstIndex(where: { $0.id == sid }) else {
            activeStormID = nil
            save()
            return
        }
        
        if storms[idx].end == nil {
            storms[idx].end = date
        }
        activeStormID = nil
        save()
    }
    
    // MARK: - Blocks (storm filtered)
    
    var blocksForSelectedStorm: [TimeBlock] {
        guard let sid = selectedStormID else { return blocks }
        return blocks.filter { $0.stormID == sid }
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
    
    // MARK: - Time clock
    
    func startClock(_ type: BlockType) {
        if let active = activeBlock(), active.type == type, active.endDateTime == nil {
            return
        }
        
        let now = Date()
        
        // Start storm/shift timer (your existing summary system)
        if stormStart == nil {
            stormStart = now
        }
        
        // Stop current running block
        if let id = activeBlockID, let idx = blocks.firstIndex(where: { $0.id == id }) {
            if blocks[idx].endDateTime == nil {
                blocks[idx].endDateTime = now
            }
            activeBlockID = nil
        }
        
        // Ensure we have an active stormID
        if activeStormID == nil {
            let now = Date()
            let newStorm = Storm(
                name: "Storm \(storms.count + 1)",
                start: now
            )
            storms.append(newStorm)
            activeStormID = newStorm.id
            selectedStormID = newStorm.id
        }
        
        // Start a new block
        var newBlock = TimeBlock()
        newBlock.stormID = activeStormID   // ✅ stamp storm
        newBlock.type = type
        newBlock.mode = .startEnd
        newBlock.startDateTime = now
        newBlock.endDateTime = nil
        newBlock.manualHours = nil
        
        blocks.append(newBlock)
        activeBlockID = newBlock.id
        
        save()
    }
    
    func offDuty() {
        let now = Date()
        
        // Stop current running block
        if let id = activeBlockID, let idx = blocks.firstIndex(where: { $0.id == id }) {
            if blocks[idx].endDateTime == nil {
                blocks[idx].endDateTime = now
            }
        }
        activeBlockID = nil
        
        if let sid = activeStormID,
           let idx = storms.firstIndex(where: { $0.id == sid }),
           storms[idx].end == nil {
            storms[idx].end = now
        }
        activeStormID = nil
        
        // End the storm (Storm picker)
        endActiveStorm(at: now)
        
        // Build summary for this shift
        if let start = stormStart {
            let interval = DateInterval(start: start, end: now)
            let rollups = rollups(in: interval)
            
            let push = rollups.reduce(0) { $0 + $1.pushHours }
            let standby = rollups.reduce(0) { $0 + $1.standbyHours }
            let broke = rollups.reduce(0) { $0 + $1.brokeHours }
            
            lastStormSummary = StormSummary(start: start, end: now, push: push, standby: standby, broke: broke)
            showStormSummary = true
        }
        
        stormStart = nil
        save()
    }
    
    // MARK: - Export
    
    func exportLastStormDetailedCSV(
        driverName: String
    ) throws -> URL {
        guard let s = lastStormSummary else {
            throw NSError(domain: "Export", code: 1, userInfo: [NSLocalizedDescriptionKey: "No storm summary found."])
        }
        
        let interval = DateInterval(start: s.start, end: s.end)
        
        return try CSVExporter.buildDetailedCSV(
            blocks: blocks,
            ownerName: ownerName,
            truckNumber: truckNumber,
            driverName: driverName,
            eventNumber: eventNumber,
            siteLabel: siteLabel,
            dateRange: interval
        )
    }
    
    // MARK: - Rollups
    
    /// Rollups default to ONLY selected storm if one is selected (so the UI matches the storm picker).
    func rollups(in range: DateInterval? = nil) -> [DailyRollup] {
        let cal = Calendar.current
        
        let sourceBlocks = blocksForSelectedStorm
        
        let filtered = sourceBlocks.filter { block in
            let day = cal.startOfDay(for: block.day)
            if let r = range {
                return r.contains(day) || r.contains(day.addingTimeInterval(12 * 3600))
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
                startTime: start,
                stopTime: stop
            )
        }
    }
    
    // MARK: - Default Maps
    
    // MARK: - Default Maps
    nonisolated static func defaultMaps() -> [MapItem] {
        (1...100).map { MapItem(number: $0, label: "") }
    }
}

