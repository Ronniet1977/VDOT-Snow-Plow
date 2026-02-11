//
//  DayDetailView.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 2/11/26.
//
import SwiftUI

struct DayDetailView: View {
    @EnvironmentObject var vm: TimeViewModel
    let date: Date
    
    @State private var editBlock: TimeBlock? = nil
    @State private var showingAdd = false
    
    private var blocksForDay: [TimeBlock] {
        let cal = Calendar.current
        return vm.blocks
            .filter { cal.isDate($0.day, inSameDayAs: date) }
            .sorted { ($0.startDateTime ?? .distantPast) < ($1.startDateTime ?? .distantPast) }
    }
    
    private var rollup: TimeViewModel.DailyRollup? {
        vm.rollups().first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
    }
    
    private let dayFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        return f
    }()
    
    var body: some View {
        List {
            if let r = rollup {
                Section("Totals") {
                    Text("Push: \(r.pushHours, specifier: "%.2f")h")
                    Text("Standby: \(r.standbyHours, specifier: "%.2f")h")
                    Text("Broke: \(r.brokeHours, specifier: "%.2f")h")
                    Text("Total: \(r.totalHours, specifier: "%.2f")h")
                }
            }
            
            Section("Blocks") {
                if blocksForDay.isEmpty {
                    Text("No blocks for this date.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(blocksForDay) { b in
                        VStack(alignment: .leading) {
                            Text("\(b.type.rawValue) • \(b.hours, specifier: "%.2f")h")
                                .font(.headline)
                            if let map = b.mapNumber {
                                Text("Map #\(map)")
                                    .foregroundStyle(.secondary)
                            }
                            if !b.notes.isEmpty {
                                Text(b.notes).font(.caption)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { editBlock = b }
                    }
                    .onDelete { idxSet in
                        for idx in idxSet {
                            vm.delete(blocksForDay[idx])
                        }
                    }
                }
            }
        }
        .navigationTitle(dayFmt.string(from: date))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddEditBlockView(
                block: TimeBlock(
                    startDateTime: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date),
                    endDateTime: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: date)
                )
            )
            .environmentObject(vm)
        }
        .sheet(item: $editBlock) { b in
            AddEditBlockView(block: b)
                .environmentObject(vm)
        }
    }
}
