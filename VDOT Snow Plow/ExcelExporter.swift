//
//  ExcelExporter.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 2/11/26.
//
import Foundation

struct ExcelExporter {
    static func buildTimesheetXLSX() throws -> URL {
        // TEMP: create an empty file so the Share Sheet works.
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Timesheet.xlsx")
        try Data().write(to: url, options: [.atomic])
        return url
    }
}
