import SwiftUI

struct CrewDriversView: View {
    
    @ObservedObject var store:
    CrewDriverStore
    
    @State private var showingAdd =
    false
    
    @State private var selectedDriver:
    CrewDriver?
    
    @State private var searchText = ""
    
    var body: some View {
        
        List {
            
            if store.drivers.isEmpty {
                
                ContentUnavailableView(
                    "No Drivers",
                    systemImage:
                        "person.3",
                    description:
                        Text(
                            "Add drivers to the crew dictionary."
                        )
                )
                
            } else {
                
                ForEach(
                    filteredDrivers
                ) { driver in
                    
                    HStack {
                        
                        Button {
                            
                            selectedDriver =
                            driver
                            
                        } label: {
                            
                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {
                                
                                Text(
                                    driver.name
                                )
                                .font(
                                    .headline
                                )
                                
                                Text(
                                    driver.truckNumber.isEmpty
                                    ? "No Truck"
                                    : "Truck \(driver.truckNumber)"
                                )
                                .font(
                                    .caption
                                )
                                .foregroundStyle(
                                    .secondary
                                )
                            }
                        }
                        .buttonStyle(
                            .plain
                        )
                        
                        Spacer()
                        
                        Toggle(
                            "",
                            isOn:
                                Binding(
                                    get: {
                                        driver.isActive
                                    },
                                    set: {
                                        store.setActive(
                                            driver,
                                            active: $0
                                        )
                                    }
                                )
                        )
                        .labelsHidden()
                    }
                }
                .onDelete { indexSet in
                    
                    for index in indexSet {
                        
                        store.delete(
                            filteredDrivers[index]
                        )
                    }
                }
            }
        }
        .searchable(
            text: $searchText,
            prompt: "Search driver or truck"
        )
        .navigationTitle(
            "Drivers"
        )
        .toolbar {
            
            ToolbarItem(
                placement:
                        .topBarTrailing
            ) {
                
                Button {
                    
                    showingAdd = true
                    
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
            
            CrewDriverEditView(
                driver:
                    CrewDriver(
                        name: "",
                        truckNumber: ""
                    )
            ) { driver in
                
                store.add(
                    name:
                        driver.name,
                    truckNumber:
                        driver.truckNumber
                )
            }
        }
        .sheet(
            item:
                $selectedDriver
        ) { driver in
            
            CrewDriverEditView(
                driver:
                    driver
            ) { changed in
                
                store.update(
                    changed
                )
            }
        }
    }
    
    private var filteredDrivers: [CrewDriver] {
        
        let text =
        searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        guard text.isEmpty == false else {
            return store.drivers
        }
        
        return store.drivers.filter { driver in
            
            driver.name.localizedCaseInsensitiveContains(
                text
            )
            ||
            driver.truckNumber.localizedCaseInsensitiveContains(
                text
            )
        }
    }
}

private struct CrewDriverEditView: View {
    
    @Environment(\.dismiss)
    private var dismiss
    
    @State private var driver:
    CrewDriver
    
    let onSave:
    (CrewDriver) -> Void
    
    init(
        driver: CrewDriver,
        onSave:
        @escaping
        (CrewDriver) -> Void
    ) {
        
        _driver =
        State(
            initialValue:
                driver
        )
        
        self.onSave =
        onSave
    }
    
    var body: some View {
        
        NavigationStack {
            
            Form {
                
                TextField(
                    "Driver Name",
                    text:
                        $driver.name
                )
                
                TextField(
                    "Truck Number",
                    text:
                        $driver.truckNumber
                )
            }
            .navigationTitle(
                "Driver"
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
                            driver
                        )
                        
                        dismiss()
                    }
                    .disabled(
                        driver.name
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

