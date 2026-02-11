//
//  Models.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 2/11/26.
//
import Foundation
import Combine

enum BlockType: String, Codable, CaseIterable, Identifiable {
    case push = "PUSH"
    case standby = "STAND BY"
    case broke = "BROKE"
    var id: String { rawValue }
}

enum EntryMode: String, Codable, CaseIterable, Identifiable {
    case startEnd = "Start/End"
    case manualHours = "Manual Hours"
    var id: String { rawValue }
}

struct TimeBlock: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    
    // Optional map reference (not used for billing)
    var mapNumber: Int? = nil   // 1...100 or nil
    
    var type: BlockType = .push
    var mode: EntryMode = .startEnd
    
    // Start/End mode
    var startDateTime: Date? = nil
    var endDateTime: Date? = nil
    
    // Manual mode
    var manualHours: Double? = nil
    
    var notes: String = ""
    
    /// A "display date" for grouping. Prefer startDateTime; fallback to endDateTime; else "today".
    nonisolated var day: Date {
        let cal = Calendar.current
        if let s = startDateTime { return cal.startOfDay(for: s) }
        if let e = endDateTime { return cal.startOfDay(for: e) }
        return cal.startOfDay(for: Date())
    }

    nonisolated var hours: Double {
        switch mode {
        case .manualHours:
            return max(0, manualHours ?? 0)
        case .startEnd:
            guard let s = startDateTime, let e = endDateTime else { return 0 }
            return max(0, e.timeIntervalSince(s) / 3600.0)
        }
    }
}

struct MapItem: Identifiable, Codable, Equatable {
    var id: Int { number }
    let number: Int          // 1...100
    var label: String        // editable
}
