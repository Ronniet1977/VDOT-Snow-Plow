//
//  ExportView.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 2/11/26.
//
import SwiftUI

struct ExportView: View {

    @EnvironmentObject var vm: TimeViewModel

    let currentUser: AppUser?

    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate: Date = Date()

    @State private var shareURL: URL? = nil
    @State private var showingShare = false
    
    @State private var exportError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker("Start", selection: $startDate, displayedComponents: [.date])
                    DatePicker("End", selection: $endDate, displayedComponents: [.date])
                }

                Section("Export") {
                    
                    Button("Generate Timesheet (.csv)") {
                        let cal = Calendar.current
                        let s = cal.startOfDay(for: startDate)
                        let e = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: endDate)) ?? endDate
                        let interval = DateInterval(start: s, end: e)
                        
                        do {
                            let url =
                                try CSVExporter.buildDetailedCSV(
                                    blocks:
                                        vm.blocks,
                                    ownerName:
                                        vm.ownerName,
                                    truckNumber:
                                        vm.truckNumber,
                                    driverName:
                                        currentUser?.name
                                        ?? "",
                                    eventNumber:
                                        vm.eventNumber,
                                    siteLabel:
                                        vm.siteLabel,
                                    dateRange:
                                        interval
                                )
                            shareURL = url
                            showingShare = true
                            exportError = nil
                        } catch {
                            exportError = "Export failed: \(error.localizedDescription)"
                            shareURL = nil
                        }
                    }
                    
                    if let url = shareURL {
                        ShareLink(item: url) {
                            Text("Share CSV")
                                .font(.headline)
                        }
                    }
                    
                    if let msg = exportError {
                        Text(msg)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section("Sheet Columns") {
                    Text("DATE | PUSH | STAND BY | BROKE | START | STOP | TOTAL HOURS")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Export")
            .sheet(isPresented: $vm.showStormSummary) {
                StormSummaryView(summary: vm.lastStormSummary) {
                    do {
                        let url =
                            try vm.exportLastStormDetailedCSV(
                                driverName:
                                    currentUser?.name
                                    ?? ""
                            )
                        shareURL = url
                        showingShare = true
                    } catch {
                        exportError = error.localizedDescription
                    }
                }
            }
            .sheet(isPresented: $showingShare) {
                if let url = shareURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
}
