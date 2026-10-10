import SwiftUI

struct SupervisorSettingsView: View {
    
    @ObservedObject var store:
    SupervisorSettingsStore
    
    @State private var selectedCategory:
    CrewCategory?
    
    var body: some View {
        
        List {
            
            ForEach(
                CrewCategory.allCases
            ) { category in
                
                Section(
                    category.displayName
                ) {
                    
                    let supervisors =
                    store.supervisors(
                        for:
                            category
                    )
                    
                    if supervisors.isEmpty {
                        
                        Text(
                            "No supervisors added"
                        )
                        .foregroundStyle(
                            .secondary
                        )
                        
                    } else {
                        
                        ForEach(
                            supervisors
                        ) { supervisor in
                            
                            VStack(
                                alignment:
                                        .leading,
                                spacing:
                                    4
                            ) {
                                
                                Text(
                                    supervisor.name
                                )
                                .font(
                                    .headline
                                )
                                
                                Text(
                                    supervisor
                                        .phoneNumber
                                )
                                .foregroundStyle(
                                    .secondary
                                )
                            }
                        }
                        .onDelete { offsets in
                            
                            deleteSupervisors(
                                at: offsets,
                                category:
                                    category
                            )
                        }
                    }
                    
                    Button {
                        
                        selectedCategory =
                        category
                        
                    } label: {
                        
                        Label(
                            "Add Supervisor",
                            systemImage:
                                "person.badge.plus"
                        )
                    }
                }
            }
        }
        .navigationTitle(
            "Supervisors"
        )
        .sheet(
            item:
                $selectedCategory
        ) { category in
            
            AddSupervisorView(
                category:
                    category,
                store:
                    store
            )
        }
    }
    
    private func deleteSupervisors(
        at offsets: IndexSet,
        category: CrewCategory
    ) {

        let supervisors =
            store.supervisors(
                for: category
            )

        let toDelete =
            offsets.map {
                supervisors[$0]
            }

        for supervisor in toDelete {

            store.deleteSupervisor(
                supervisor,
                from: category
            )
        }
    }
}

private struct AddSupervisorView:
    View {
    
    let category:
    CrewCategory
    
    @ObservedObject var store:
    SupervisorSettingsStore
    
    @Environment(\.dismiss)
    private var dismiss
    
    @State private var name = ""
    @State private var phoneNumber = ""
    
    var body: some View {
        
        NavigationStack {
            
            Form {
                
                Section(
                    category.displayName
                ) {
                    
                    TextField(
                        "Supervisor Name",
                        text:
                            $name
                    )
                    
                    TextField(
                        "Phone Number",
                        text:
                            $phoneNumber
                    )
                    .keyboardType(
                        .phonePad
                    )
                }
            }
            .navigationTitle(
                "Add Supervisor"
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
                        
                        saveSupervisor()
                    }
                    .disabled(
                        name
                            .trimmingCharacters(
                                in:
                                        .whitespacesAndNewlines
                            )
                            .isEmpty ||
                        phoneNumber
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
    
    private func saveSupervisor() {
        
        let contact =
        SupervisorContact(
            name:
                name
                .trimmingCharacters(
                    in:
                            .whitespacesAndNewlines
                ),
            phoneNumber:
                phoneNumber
                .trimmingCharacters(
                    in:
                            .whitespacesAndNewlines
                )
        )
        
        store.addSupervisor(
            contact,
            to: category
        )

        dismiss()
    }
}

