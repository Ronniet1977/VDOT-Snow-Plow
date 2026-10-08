import SwiftUI

struct AdminTimeView: View {
    
    @StateObject private var store =
    AdminTimeStore()
    
    @State private var selectedDate =
    Date()
    
    @State private var showingAdd =
    false
    
    @State private var selectedEntry:
    DriverTimeEntry?
    
    private var entriesForSelectedDate:
    [DriverTimeEntry] {
        
        let calendar =
        Calendar.current
        
        return store.entries
            .filter {
                calendar.isDate(
                    $0.date,
                    inSameDayAs:
                        selectedDate
                )
            }
            .sorted {
                $0.driverName
                    .localizedCaseInsensitiveCompare(
                        $1.driverName
                    )
                == .orderedAscending
            }
    }
    
    private var totalPush: Double {
        
        entriesForSelectedDate
            .reduce(0) {
                $0 + $1.pushHours
            }
    }
    
    private var totalStandby: Double {
        
        entriesForSelectedDate
            .reduce(0) {
                $0 + $1.standbyHours
            }
    }
    
    private var totalBroke: Double {
        
        entriesForSelectedDate
            .reduce(0) {
                $0 + $1.brokeHours
            }
    }
    
    private var totalCrewHours: Double {
        
        entriesForSelectedDate
            .reduce(0) {
                $0 + $1.totalHours
            }
    }
    
    var body: some View {
        
        NavigationStack {
            
            List {
                
                Section(
                    "Daily Crew Sheet"
                ) {
                    
                    DatePicker(
                        "Work Date",
                        selection:
                            $selectedDate,
                        displayedComponents:
                                .date
                    )
                }
                
                Section(
                    "Drivers"
                ) {
                    
                    if entriesForSelectedDate
                        .isEmpty {
                        
                        Text(
                            "No driver time entered for this date."
                        )
                        .foregroundStyle(
                            .secondary
                        )
                        
                    } else {
                        
                        ForEach(
                            entriesForSelectedDate
                        ) { entry in
                            
                            Button {
                                
                                selectedEntry =
                                entry
                                
                            } label: {
                                
                                DriverTimeRow(
                                    entry:
                                        entry
                                )
                            }
                            .buttonStyle(
                                .plain
                            )
                        }
                        .onDelete {
                            indexSet in
                            
                            for index in indexSet {
                                
                                let entry =
                                entriesForSelectedDate[
                                    index
                                ]
                                
                                store.delete(
                                    entry
                                )
                            }
                        }
                    }
                }
                
                if entriesForSelectedDate
                    .isEmpty == false {
                    
                    Section(
                        "Daily Totals"
                    ) {
                        
                        LabeledContent(
                            "Drivers"
                        ) {
                            
                            Text(
                                "\(entriesForSelectedDate.count)"
                            )
                        }
                        
                        LabeledContent(
                            "Push"
                        ) {
                            
                            Text(
                                "\(totalPush, specifier: "%.2f") hrs"
                            )
                        }
                        
                        LabeledContent(
                            "Standby"
                        ) {
                            
                            Text(
                                "\(totalStandby, specifier: "%.2f") hrs"
                            )
                        }
                        
                        LabeledContent(
                            "Broke"
                        ) {
                            
                            Text(
                                "\(totalBroke, specifier: "%.2f") hrs"
                            )
                        }
                        
                        LabeledContent(
                            "Total Crew Hours"
                        ) {
                            
                            Text(
                                "\(totalCrewHours, specifier: "%.2f") hrs"
                            )
                            .fontWeight(
                                .bold
                            )
                        }
                    }
                }
            }
            .navigationTitle(
                "Admin Time"
            )
            .toolbar {
                
                ToolbarItem(
                    placement:
                            .topBarTrailing
                ) {
                    
                    Button {
                        
                        showingAdd =
                        true
                        
                    } label: {
                        
                        Image(
                            systemName:
                                "plus"
                        )
                    }
                }
            }
            .sheet(
                isPresented:
                    $showingAdd
            ) {
                
                var newEntry =
                DriverTimeEntry()
                
                let _ =
                newEntry.date =
                selectedDate
                
                AdminTimeEditView(
                    entry:
                        newEntry
                ) { entry in
                    
                    store.add(
                        entry
                    )
                }
            }
            .sheet(
                item:
                    $selectedEntry
            ) { entry in
                
                AdminTimeEditView(
                    entry:
                        entry
                ) { changedEntry in
                    
                    store.update(
                        changedEntry
                    )
                }
            }
        }
    }
}

private struct AdminTimeEditView: View {
    
    @Environment(\.dismiss)
    private var dismiss
    
    @State private var entry:
    DriverTimeEntry
    
    let onSave:
    (DriverTimeEntry) -> Void
    
    init(
        entry: DriverTimeEntry,
        onSave:
        @escaping
        (DriverTimeEntry) -> Void
    ) {
        
        _entry =
        State(
            initialValue:
                entry
        )
        
        self.onSave =
        onSave
    }
    
    var body: some View {
        
        NavigationStack {
            
            Form {
                
                Section(
                    "Driver"
                ) {
                    
                    TextField(
                        "Driver Name",
                        text:
                            $entry.driverName
                    )
                    
                    TextField(
                        "Truck Number",
                        text:
                            $entry.truckNumber
                    )
                }
                
                Section(
                    "Date & Time"
                ) {
                    
                    DatePicker(
                        "Date",
                        selection:
                            $entry.date,
                        displayedComponents:
                                .date
                    )
                    
                    DatePicker(
                        "Start",
                        selection:
                            $entry.startTime,
                        displayedComponents:
                                .hourAndMinute
                    )
                    
                    DatePicker(
                        "Stop",
                        selection:
                            $entry.stopTime,
                        displayedComponents:
                                .hourAndMinute
                    )
                }
                
                Section(
                    "Hours"
                ) {
                    
                    HourField(
                        title: "Push",
                        value:
                            $entry.pushHours
                    )
                    
                    HourField(
                        title: "Standby",
                        value:
                            $entry.standbyHours
                    )
                    
                    HourField(
                        title: "Broke",
                        value:
                            $entry.brokeHours
                    )
                    
                    LabeledContent(
                        "Total"
                    ) {
                        
                        Text(
                            "\(entry.totalHours, specifier: "%.2f") hrs"
                        )
                        .fontWeight(
                            .semibold
                        )
                    }
                }
                
                Section(
                    "Notes"
                ) {
                    
                    TextField(
                        "Notes",
                        text:
                            $entry.notes,
                        axis:
                                .vertical
                    )
                    .lineLimit(
                        3...6
                    )
                }
            }
            .navigationTitle(
                "Driver Time"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                
                ToolbarItem(
                    placement:
                            .cancellationAction
                ) {
                    
                    Button(
                        "Cancel"
                    ) {
                        
                        dismiss()
                    }
                }
                
                ToolbarItem(
                    placement:
                            .confirmationAction
                ) {
                    
                    Button(
                        "Save"
                    ) {
                        
                        onSave(
                            entry
                        )
                        
                        dismiss()
                    }
                    .disabled(
                        entry.driverName
                            .trimmingCharacters(
                                in:
                                        .whitespacesAndNewlines
                            )
                            .isEmpty
                    )
                }
            }
        }
    }
}

private struct HourField: View {
    
    let title: String
    
    @Binding var value:
    Double
    
    var body: some View {
        
        HStack {
            
            Text(title)
            
            Spacer()
            
            TextField(
                "0.00",
                value:
                    $value,
                format:
                        .number
                    .precision(
                        .fractionLength(
                            0...2
                        )
                    )
            )
            .keyboardType(
                .decimalPad
            )
            .multilineTextAlignment(
                .trailing
            )
            .frame(
                width: 90
            )
            
            Text("hrs")
                .foregroundStyle(
                    .secondary
                )
        }
    }
}

private struct DriverTimeRow: View {
    
    let entry:
    DriverTimeEntry
    
    var body: some View {
        
        VStack(
            alignment: .leading,
            spacing: 6
        ) {
            
            HStack {
                
                Text(
                    entry.driverName.isEmpty
                    ? "Unnamed Driver"
                    : entry.driverName
                )
                .font(
                    .headline
                )
                
                Spacer()
                
                Text(
                    "\(entry.totalHours, specifier: "%.2f") hrs"
                )
                .font(
                    .headline
                )
            }
            
            HStack {
                
                Label(
                    entry.truckNumber.isEmpty
                    ? "No Truck"
                    : "Truck \(entry.truckNumber)",
                    systemImage:
                        "truck.box"
                )
                
                Spacer()
                
                Text(
                    entry.date.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                )
            }
            .font(
                .subheadline
            )
            .foregroundStyle(
                .secondary
            )
            
            Text(
                "\(entry.startTime.formatted(date: .omitted, time: .shortened)) – \(entry.stopTime.formatted(date: .omitted, time: .shortened))"
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )
            
            HStack {
                
                Text(
                    "Push \(entry.pushHours, specifier: "%.2f")"
                )
                
                Text(
                    "Standby \(entry.standbyHours, specifier: "%.2f")"
                )
                
                Text(
                    "Broke \(entry.brokeHours, specifier: "%.2f")"
                )
            }
            .font(
                .caption
            )
        }
        .padding(
            .vertical,
            4
        )
    }
}

