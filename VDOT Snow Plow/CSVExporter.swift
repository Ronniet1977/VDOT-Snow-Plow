import Foundation

enum CSVExporter {
    
    static func buildDetailedCSV(
        blocks: [TimeBlock],
        ownerName: String,
        truckNumber: String,
        driverName: String,
        eventNumber: String,
        siteLabel: String,
        dateRange: DateInterval? = nil
    ) throws -> URL {
        
        let cal = Calendar.current
        
        // Filter blocks to date range (optional)
        let filtered: [TimeBlock] = blocks.filter { b in
            // Use start if possible, else day
            let d = b.startDateTime ?? b.day
            if let r = dateRange { return r.contains(d) }
            return true
        }
            .sorted { ($0.startDateTime ?? .distantPast) < ($1.startDateTime ?? .distantPast) }
        
        // Formatters
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "M/d/yyyy"
        
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "h:mm a"
        
        // Summary totals (hours by type)
        func sum(_ t: BlockType) -> Double {
            filtered.filter { $0.type == t }.reduce(0) { $0 + $1.hours }
        }
        let pushTotal = sum(.push)
        let standbyTotal = sum(.standby)
        let brokeTotal = sum(.broke)
        let grandTotal = pushTotal + standbyTotal + brokeTotal
        
        // Storm range from data (optional)
        let firstStart = filtered.compactMap { $0.startDateTime }.min()
        let lastStop   = filtered.compactMap { $0.endDateTime }.max()
        
        // CSV escaping (quotes/commas/newlines)
        func csv(_ s: String) -> String {
            if s.contains(",") || s.contains("\"") || s.contains("\n") {
                return "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\""
            }
            return s
        }
        
        var lines: [String] = []
        
        // Header
        lines.append("SITE,\(csv(siteLabel))")
        lines.append("OWNER,\(csv(ownerName))")
        lines.append("TRUCK,\(csv(truckNumber))")
        lines.append("DRIVER,\(csv(driverName))")
        lines.append("EVENT,\(csv(eventNumber))")
        lines.append("")
        
        // Small summary
        
        
        // Detailed table
        lines.append("DATE,TYPE,START,STOP,HOURS,MAP,NOTES")
        
        for b in filtered {
            let d = dateFmt.string(from: b.startDateTime ?? b.day)
            
            let start = b.startDateTime.map { timeFmt.string(from: $0) } ?? ""
            let stop  = b.endDateTime.map { timeFmt.string(from: $0) } ?? ""
            
            let mapString = b.mapNumber.map(String.init) ?? ""
            
            lines.append(
                "\(d)," +
                "\(csv(b.type.rawValue))," +
                "\(csv(start))," +
                "\(csv(stop))," +
                "\(String(format: "%.2f", b.hours))," +
                "\(csv(mapString))," +
                "\(csv(b.notes))"
            )
        }
        
        let csvText = lines.joined(separator: "\n")
        
        // Safe filename (no slashes)
        let fileDateFmt = DateFormatter()
        fileDateFmt.dateFormat = "yyyy_MM_dd"
        let baseDate = (firstStart ?? Date())
        let timestamp = Int(Date().timeIntervalSince1970)
        
        let filename = "VDOT_Detail_\(fileDateFmt.string(from: baseDate))_\(timestamp).csv"
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try csvText.write(to: url, atomically: true, encoding: .utf8)
        
        return url
    }
}
