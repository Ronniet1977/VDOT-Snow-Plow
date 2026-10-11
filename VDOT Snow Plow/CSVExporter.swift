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
    
    static func buildStormStatusCSV(
        stormName: String,
        stormStart: Date,
        stormEnd: Date,
        drivers: [CrewDriver],
        users: [AppUser],
        blocks: [DriverStatusBlock],
        assignments: [DriverMapAssignment],
        acknowledgements: [MapAssignmentAcknowledgement],
        inspections: [MapReviewInspection],
        stormID: UUID
    ) throws -> URL {

        let dateFormatter =
            DateFormatter()

        dateFormatter.dateFormat =
            "M/d/yyyy h:mm a"

        func csv(
            _ value: String
        ) -> String {

            if value.contains(",") ||
                value.contains("\"") ||
                value.contains("\n") {

                return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
            }

            return value
        }

        func companyName(
            for driver: CrewDriver
        ) -> String {

            users
                .first {
                    $0.driverID ==
                        driver.id
                }?
                .companyName?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .nonEmpty
                ?? "No Company"
        }

        let groupedDrivers =
            Dictionary(
                grouping:
                    drivers
            ) {
                companyName(
                    for: $0
                )
            }

        var lines: [String] = []

        lines.append(
            "STORM,\(csv(stormName))"
        )

        lines.append(
            "START,\(dateFormatter.string(from: stormStart))"
        )

        lines.append(
            "END,\(dateFormatter.string(from: stormEnd))"
        )

        lines.append("")

        for company in
            groupedDrivers.keys.sorted() {

            lines.append(
                "COMPANY,\(csv(company))"
            )

            lines.append("")

            let companyDrivers =
                groupedDrivers[company]?
                    .sorted {
                        $0.name <
                            $1.name
                    }
                ?? []

            for driver in companyDrivers {

                let driverBlocks =
                    blocks
                        .filter {
                            $0.driverID ==
                                driver.id &&
                            $0.stormID ==
                                stormID
                        }
                        .sorted {
                            $0.startTime <
                                $1.startTime
                        }

                lines.append(
                    "DRIVER,\(csv(driver.name))"
                )

                lines.append(
                    "TRUCK,\(csv(driver.truckNumber))"
                )

                lines.append(
                    "CATEGORY,\(csv(driver.category.displayName))"
                )

                lines.append("")

                lines.append(
                    "STATUS,START,STOP,HOURS"
                )

                for block in driverBlocks {

                    let start =
                        dateFormatter.string(
                            from:
                                block.startTime
                        )

                    let stop =
                        block.endTime.map {
                            dateFormatter.string(
                                from: $0
                            )
                        }
                        ?? ""

                    lines.append(
                        "\(csv(block.status.rawValue))," +
                        "\(csv(start))," +
                        "\(csv(stop))," +
                        "\(String(format: "%.2f", block.hours))"
                    )
                }

                let push =
                    driverBlocks
                        .filter {
                            $0.status ==
                                .push
                        }
                        .reduce(0) {
                            $0 + $1.hours
                        }

                let standby =
                    driverBlocks
                        .filter {
                            $0.status ==
                                .standby
                        }
                        .reduce(0) {
                            $0 + $1.hours
                        }

                let broke =
                    driverBlocks
                        .filter {
                            $0.status ==
                                .broke
                        }
                        .reduce(0) {
                            $0 + $1.hours
                        }

                let total =
                    push +
                    standby +
                    broke
                
                let driverAssignments =
                    assignments
                        .filter {
                            $0.driverID == driver.id &&
                            $0.stormID == stormID
                        }
                        .sorted {
                            $0.assignedAt <
                                $1.assignedAt
                        }

                if driverAssignments.isEmpty == false {

                    lines.append("")
                    lines.append(
                        "MAP,ASSIGNED,ACKNOWLEDGED,SUPERVISOR STATUS,COMPLETED"
                    )

                    for assignment in driverAssignments {

                        let acknowledged =
                            acknowledgements
                                .contains {
                                    $0.assignmentID ==
                                        assignment.id
                                }

                        let latestInspection =
                            inspections
                                .filter {
                                    $0.assignmentID ==
                                        assignment.id
                                }
                                .sorted {
                                    $0.checkedAt >
                                        $1.checkedAt
                                }
                                .first

                        let assignedText =
                            dateFormatter.string(
                                from:
                                    assignment.assignedAt
                            )

                        let completedText =
                            assignment.completedAt.map {
                                dateFormatter.string(
                                    from: $0
                                )
                            }
                            ?? ""

                        let supervisorStatus =
                            latestInspection?
                                .progress
                                .rawValue
                            ?? "Not Checked"

                        lines.append(
                            "\(csv(assignment.mapNumber))," +
                            "\(csv(assignedText))," +
                            "\(acknowledged ? "Yes" : "No")," +
                            "\(csv(supervisorStatus))," +
                            "\(csv(completedText))"
                        )
                    }
                }

                lines.append("")

                lines.append(
                    "TOTAL PUSH,,,\(String(format: "%.2f", push))"
                )

                lines.append(
                    "TOTAL STANDBY,,,\(String(format: "%.2f", standby))"
                )

                lines.append(
                    "TOTAL BROKE,,,\(String(format: "%.2f", broke))"
                )

                lines.append(
                    "TOTAL HOURS,,,\(String(format: "%.2f", total))"
                )

                lines.append("")
            }

            lines.append("")
        }

        let csvText =
            lines.joined(
                separator: "\n"
            )

        let fileFormatter =
            DateFormatter()

        fileFormatter.dateFormat =
            "yyyy_MM_dd"

        let fileName =
            "VDOT_Storm_\(fileFormatter.string(from: stormStart)).csv"

        let url =
            FileManager.default
                .temporaryDirectory
                .appendingPathComponent(
                    fileName
                )

        try csvText.write(
            to: url,
            atomically: true,
            encoding: .utf8
        )

        return url
    }
}

private extension String {

    var nonEmpty: String? {
        isEmpty
        ? nil
        : self
    }
}
