import SwiftUI

struct DriverStatusEditView: View {
    
    @Environment(\.dismiss)
    private var dismiss
    
    @State private var block:
    DriverStatusBlock
    
    let onSave:
    (DriverStatusBlock) -> Void
    
    init(
        block: DriverStatusBlock,
        onSave:
        @escaping
        (DriverStatusBlock) -> Void
    ) {
        
        _block =
        State(
            initialValue:
                block
        )
        
        self.onSave =
        onSave
    }
    
    var body: some View {
        
        NavigationStack {
            
            Form {
                
                Section("Status") {
                    
                    Picker(
                        "Status",
                        selection:
                            $block.status
                    ) {
                        
                        ForEach(
                            BlockType.allCases
                        ) { type in
                            
                            Text(
                                type.rawValue
                            )
                            .tag(type)
                        }
                    }
                }
                
                Section("Times") {
                    
                    DatePicker(
                        "Start",
                        selection:
                            $block.startTime
                    )
                    
                    if block.endTime != nil {
                        
                        DatePicker(
                            "End",
                            selection:
                                Binding(
                                    get: {
                                        block.endTime
                                        ?? Date()
                                    },
                                    set: {
                                        block.endTime =
                                        $0
                                    }
                                )
                        )
                    } else {
                        
                        Text(
                            "This status is currently running."
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                    }
                }
                
                Section("Notes") {
                    
                    TextField(
                        "Notes",
                        text:
                            $block.notes,
                        axis:
                                .vertical
                    )
                    .lineLimit(
                        3...6
                    )
                }
                
                Section {
                    
                    LabeledContent(
                        "Hours"
                    ) {
                        
                        Text(
                            "\(block.hours, specifier: "%.2f")"
                        )
                    }
                }
            }
            .navigationTitle(
                "Edit Time"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                
                ToolbarItem(
                    placement:
                            .cancellationAction
                ) {
                    
                    Button("Cancel") {
                        
                        dismiss()
                    }
                }
                
                ToolbarItem(
                    placement:
                            .confirmationAction
                ) {
                    
                    Button("Save") {
                        
                        onSave(
                            block
                        )
                        
                        dismiss()
                    }
                    .disabled(
                        block.endTime != nil &&
                        block.endTime! <
                        block.startTime
                    )
                }
            }
        }
    }
}

