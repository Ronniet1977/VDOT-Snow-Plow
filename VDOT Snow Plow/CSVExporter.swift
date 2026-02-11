//
//  CSVExporter.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 2/11/26.
//
import SwiftUI
import Foundation

struct CSVExporter {
    static func makeCSV(rollups: [TimeViewModel.DailyRollup]) -> String {
        // Exact headers from your sheet row:
        // DATE | PUSH | STAND BY | BROKE | START | STOP | TOTAL HOURS
        var lines: [String] = []
        lines.append("DATE,PUSH,STAND BY,BROKE,START,STOP,TOTAL HOURS")
        
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "M/d/yyyy"
        
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "h:mm a"
        
        func fmtHours(_ h: Double) -> String {
            // Keep a clean decimal (2dp). We can switch to time format later if needed.
            String(format: "%.2f", h)
        }
        
        for r in rollups {
            let date = dateFmt.string(from: r.date)
            let push = fmtHours(r.pushHours)
            let standby = fmtHours(r.standbyHours)
            let broke = fmtHours(r.brokeHours)
            let start = r.start.map { timeFmt.string(from: $0) } ?? ""
            let stop  = r.stop.map { timeFmt.string(from: $0) } ?? ""
            let total = fmtHours(r.totalHours)
            
            let row = [date, push, standby, broke, start, stop, total].joined(separator: ",")
            lines.append(row)
        }
        return lines.joined(separator: "\n")
    }
    
    static func writeTempCSV(_ csv: String, fileName: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csv.data(using: .utf8)?.write(to: url, options: [.atomic])
        return url
    }
}
