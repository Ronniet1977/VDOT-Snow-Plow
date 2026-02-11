//
//  TimesView.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 2/11/26.
//
import SwiftUI
import Combine

struct TimesView: View {
    @EnvironmentObject var vm: TimeViewModel
    
    @State private var showingAdd = false
    @State private var editBlock: TimeBlock? = nil
    @State private var now = Date()
    @State private var summaryShareURL: URL? = nil
    @State private var showingSummaryShare = false
    @State private var confirmOffDuty = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var rollups: [TimeViewModel.DailyRollup] {
        vm.rollups()
    }
    
    private let dayFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()
    
    var body: some View {
        NavigationStack {
            List {
                Section("Time Clock") {
                    if let active = vm.activeBlock(),
                       let start = active.startDateTime
                    {
                        let elapsed = max(0, now.timeIntervalSince(start))
                        let hours = elapsed / 3600.0

                        Text("RUNNING: \(active.type.rawValue)")
                            .font(.headline)
                            .foregroundStyle(
                                active.type == .push ? .green :
                                active.type == .standby ? .orange :
                                .red
                            )


                        Text("Started \(start.formatted(date: .omitted, time: .shortened)) • \(hours, specifier: "%.2f")h")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("OFF DUTY")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Button("PUSH") { vm.startClock(.push) }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)

                        Button("STANDBY") { vm.startClock(.standby) }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                    }


                    HStack {
                        Button("BROKE") { vm.startClock(.broke) }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)

                        Button("OFF DUTY / DONE") { confirmOffDuty = true }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                    }
                }
                Section {
                    ForEach(rollups) { r in
                        NavigationLink {
                            DayDetailView(date: r.date)
                                .environmentObject(vm)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(dayFmt.string(from: r.date))
                                    .font(.headline)
                                
                                Text("Push \(r.pushHours, specifier: "%.2f") • Standby \(r.standbyHours, specifier: "%.2f") • Broke \(r.brokeHours, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Text("Total \(r.totalHours, specifier: "%.2f") hours")
                                    .font(.subheadline)
                            }
                        }
                    }
                } header: {
                    Text("Daily Totals")
                }
                
                Section {
                    if vm.blocks.isEmpty {
                        Text("No blocks yet. Tap + to add your first time block.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.blocks.sorted(by: { ($0.startDateTime ?? .distantPast) > ($1.startDateTime ?? .distantPast) })) { b in
                            TimeBlockRow(block: b)
                                .contentShape(Rectangle())
                                .onTapGesture { editBlock = b }
                        }
                        .onDelete { idxSet in
                            let sorted = vm.blocks.sorted(by: { ($0.startDateTime ?? .distantPast) > ($1.startDateTime ?? .distantPast) })
                            for idx in idxSet {
                                vm.delete(sorted[idx])
                            }
                        }
                    }
                } header: {
                    Text("All Blocks")
                }
            }
            .navigationTitle("Time Blocks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onReceive(ticker) { now = $0 }
            .confirmationDialog(
                "End storm and go Off Duty?",
                isPresented: $confirmOffDuty,
                titleVisibility: .visible
            ) {
                Button("End Storm (Off Duty)", role: .destructive) {
                    vm.offDuty()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will stop the current clock and show your Storm Summary.")
            }
            .sheet(isPresented: $showingAdd) {
                AddEditBlockView(block: TimeBlock())
                    .environmentObject(vm)
            }
            .sheet(item: $editBlock) { b in
                AddEditBlockView(block: b)
                    .environmentObject(vm)
            }
            .sheet(isPresented: $vm.showStormSummary) {
                StormSummaryView(
                    summary: vm.lastStormSummary,
                    onExport: {
                        guard let s = vm.lastStormSummary else { return }
                        let interval = DateInterval(start: s.start, end: s.end)
                        let _ = vm.rollups(in: interval) // you’ll feed this to your real XLSX exporter later

                        // TEMP: just share a placeholder file if you haven’t wired XLSX yet
                        do {
                            let url = try ExcelExporter.buildTimesheetXLSX() // or your real signature
                            summaryShareURL = url
                            showingSummaryShare = true
                        } catch {
                            print(error)
                        }
                    }
                )
                .environmentObject(vm)
            }
            .sheet(isPresented: $showingSummaryShare) {
                if let url = summaryShareURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
}

private struct TimeBlockRow: View {
    @EnvironmentObject var vm: TimeViewModel
    let block: TimeBlock
    
    private let dtFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(block.type.rawValue)
                    .font(.headline)
                Spacer()
                Text("\(block.hours, specifier: "%.2f")h")
                    .font(.headline)
            }
            
            if let map = block.mapNumber {
                let label = vm.labelForMap(map) ?? ""
                Text(label.isEmpty ? "Map #\(map)" : "Map #\(map) • \(label)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("No Map #")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            switch block.mode {
            case .manualHours:
                Text("Manual hours")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .startEnd:
                let s = block.startDateTime.map(dtFmt.string(from:)) ?? "—"
                let e = block.endDateTime.map(dtFmt.string(from:)) ?? "—"
                Text("\(s) → \(e)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if !block.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(block.notes)
                    .font(.caption)
            }
        }
    }
}
