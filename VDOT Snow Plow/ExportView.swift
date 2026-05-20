//
//  ExportView.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 2/11/26.
//
import SwiftUI

struct ExportView: View {
    @EnvironmentObject var vm: TimeViewModel

    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate: Date = Date()

    @State private var shareURL: URL? = nil
    @State private var showingShare = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker("Start", selection: $startDate, displayedComponents: [.date])
                    DatePicker("End", selection: $endDate, displayedComponents: [.date])
                }

                Section("Export") {
                    Button("Generate & Share Excel (.xlsx)") {
                        let cal = Calendar.current
                        let s = cal.startOfDay(for: startDate)
                        let e = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: endDate)) ?? endDate
                        let interval = DateInterval(start: s, end: e)

                        _ = vm.rollups(in: interval)

                        do {
                            // TEMP: call your exporter here
                            let url = try ExcelExporter.buildTimesheetXLSX() // replace if your signature differs
                            shareURL = url
                            showingShare = true
                        } catch {
                            print("XLSX export failed:", error)
                        }
                    }
                }

                Section("Sheet Columns") {
                    Text("DATE | PUSH | STAND BY | BROKE | START | STOP | TOTAL HOURS")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Export")
            .sheet(isPresented: $showingShare) {
                if let url = shareURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
}
