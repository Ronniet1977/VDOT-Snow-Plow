//
//  AddEditBlockView.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 2/11/26.
//
import SwiftUI

struct AddEditBlockView: View {
    @EnvironmentObject var vm: TimeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State var block: TimeBlock
    
    @State private var mapEnabled: Bool = false
    @State private var mapValue: Int = 1
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Block Type", selection: $block.type) {
                        ForEach(BlockType.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    Picker("Entry Mode", selection: $block.mode) {
                        ForEach(EntryMode.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                }
                
                Section("Map (optional)") {
                    Toggle("Attach Map #", isOn: $mapEnabled)
                        .onChange(of: mapEnabled) { _, on in
                            if on {
                                block.mapNumber = mapValue
                            } else {
                                block.mapNumber = nil
                            }
                        }
                    
                    if mapEnabled {
                        Picker("Map #", selection: $mapValue) {
                            ForEach(1...100, id: \.self) { n in
                                let label = vm.labelForMap(n) ?? ""
                                Text(label.isEmpty ? "\(n)" : "\(n) – \(label)").tag(n)
                            }
                        }
                        .onChange(of: mapValue) { _, newValue in
                            block.mapNumber = newValue
                        }
                    }
                }
                
                Section("Time") {
                    switch block.mode {
                    case .startEnd:
                        DatePicker("Start", selection: Binding(
                            get: { block.startDateTime ?? Date() },
                            set: { block.startDateTime = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                        
                        DatePicker("End", selection: Binding(
                            get: { block.endDateTime ?? (block.startDateTime ?? Date()) },
                            set: { block.endDateTime = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                        
                        Text("Hours: \(block.hours, specifier: "%.2f")")
                            .foregroundStyle(.secondary)
                        
                    case .manualHours:
                        HStack {
                            Text("Hours")
                            Spacer()
                            TextField("0.00", value: Binding(
                                get: { block.manualHours ?? 0 },
                                set: { block.manualHours = $0 }
                            ), format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Optional notes…", text: $block.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Time Block")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        // Sync map toggle state
                        if mapEnabled {
                            block.mapNumber = mapValue
                        } else {
                            block.mapNumber = nil
                        }
                        vm.upsert(block)
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let n = block.mapNumber {
                    mapEnabled = true
                    mapValue = n
                } else {
                    mapEnabled = false
                    mapValue = 1
                }
            }
        }
    }
}
