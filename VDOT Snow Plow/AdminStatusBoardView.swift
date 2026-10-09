import SwiftUI
import Combine
import MessageUI

struct AdminStatusBoardView: View {
    private enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case push = "Push"
        case standby = "Standby"
        case broke = "Broke"
        case offDuty = "Off Duty"
        
        var id: String { rawValue }
    }
    
    private enum CrewGroupFilter:
        String,
        CaseIterable,
        Identifiable {
        
        case all = "All"
        case plowOnly = "Plow"
        case littleTrucks = "Little"
        case bigTrucks = "Big"
        case equipment = "Equip."
        
        var id: String {
            rawValue
        }
    }
    
    @ObservedObject var driverStore:
    CrewDriverStore
    
    @StateObject private var statusStore =
    DriverStatusStore()
    
    @State private var historyDriver:
    CrewDriver?
    
    @StateObject private var stormStore =
    AdminStormStore()
    
    @State private var showingNewStorm =
    false
    
    @State private var now =
    Date()
    @State private var searchText = ""
    @State private var statusFilter:
    StatusFilter = .all
    @State private var crewGroupFilter:
    CrewGroupFilter = .all
    
    @StateObject private var mapAssignmentStore =
    DriverMapAssignmentStore()
    
    @State private var assigningDriver:
    CrewDriver?
    
    @State private var openingMap:
    MapNumberSelection?
    @State private var mapCheckMessage:
    MapCheckMessage?
    
    @StateObject private var supervisorStore =
    SupervisorSettingsStore()
    
    private let supervisorPhone =
    ""
    
    private let timer =
    Timer.publish(
        every: 1,
        on: .main,
        in: .common
    )
    .autoconnect()
    
    private var activeDrivers:
    [CrewDriver] {
        
        driverStore.drivers
            .filter {
                $0.isActive
            }
            .sorted {
                $0.name <
                    $1.name
            }
    }
    
    private var filteredActiveDrivers:
    [CrewDriver] {
        
        let text =
        searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        return activeDrivers.filter { driver in
            
            let matchesSearch =
            text.isEmpty ||
            driver.name
                .localizedCaseInsensitiveContains(
                    text
                ) ||
            driver.truckNumber
                .localizedCaseInsensitiveContains(
                    text
                )
            
            guard matchesSearch else {
                return false
            }
            
            let matchesGroup: Bool
            
            switch crewGroupFilter {
                
            case .all:
                matchesGroup = true
                
            case .plowOnly:
                matchesGroup =
                driver.category ==
                    .plowOnly
                
            case .littleTrucks:
                matchesGroup =
                driver.category ==
                    .littleTrucks
                
            case .bigTrucks:
                matchesGroup =
                driver.category ==
                    .bigTrucks
                
            case .equipment:
                matchesGroup =
                driver.category ==
                    .equipment
            }
            
            guard matchesGroup else {
                return false
            }
            
            let block =
            statusStore.activeBlock(
                for: driver.id
            )
            
            switch statusFilter {
                
            case .all:
                return true
                
            case .push:
                return block?.status == .push
                
            case .standby:
                return block?.status == .standby
                
            case .broke:
                return block?.status == .broke
                
            case .offDuty:
                return block == nil
            }
        }
    }
    
    private var crewPushHours: Double {
        
        activeDrivers.reduce(0) { total, driver in
            
            let totals =
            stormStore.activeStormID.map {
                
                statusStore.totals(
                    for: driver.id,
                    stormID: $0
                )
                
            } ?? (
                push: 0,
                standby: 0,
                broke: 0
            )
            
            return total + totals.push
        }
    }
    
    private var crewStandbyHours: Double {
        
        activeDrivers.reduce(0) { total, driver in
            
            let totals =
            stormStore.activeStormID.map {
                
                statusStore.totals(
                    for: driver.id,
                    stormID: $0
                )
                
            } ?? (
                push: 0,
                standby: 0,
                broke: 0
            )
            
            return total + totals.standby
        }
    }
    
    private var crewBrokeHours: Double {
        
        activeDrivers.reduce(0) { total, driver in
            
            let totals =
            stormStore.activeStormID.map {
                
                statusStore.totals(
                    for: driver.id,
                    stormID: $0
                )
                
            } ?? (
                push: 0,
                standby: 0,
                broke: 0
            )
            
            return total + totals.broke
        }
    }
    
    private var crewTotalHours: Double {
        
        crewPushHours +
        crewStandbyHours +
        crewBrokeHours
    }
    
    var body: some View {
        
        List {
            Section("Current Storm") {
                
                if let storm =
                    stormStore.activeStorm {
                    
                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {
                        
                        Text(
                            storm.name
                        )
                        .font(.headline)
                        
                        Text(
                            "Started \(storm.start.formatted(date: .abbreviated, time: .shortened))"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        
                        if let end =
                            storm.end {
                            
                            Text(
                                "Ended \(end.formatted(date: .abbreviated, time: .shortened))"
                            )
                            .font(.caption)
                        }
                    }
                    
                    Button(
                        "End Storm",
                        role: .destructive
                    ) {
                        
                        stormStore.endStorm()
                    }
                    
                } else {
                    
                    Text(
                        "No active storm"
                    )
                    .foregroundStyle(.secondary)
                    
                    Button(
                        "Start New Storm"
                    ) {
                        
                        showingNewStorm =
                        true
                    }
                }
            }
            
            Section {
                
                HStack {
                    
                    Image(
                        systemName: "magnifyingglass"
                    )
                    .foregroundStyle(.secondary)
                    
                    TextField(
                        "Search driver or truck",
                        text: $searchText
                    )
                    
                    if searchText.isEmpty == false {
                        
                        Button {
                            
                            searchText = ""
                            
                        } label: {
                            
                            Image(
                                systemName:
                                    "xmark.circle.fill"
                            )
                            .foregroundStyle(
                                .secondary
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
            } header: {
                
                Text("Drivers")
            }
            
            Picker(
                "Crew Group",
                selection: $crewGroupFilter
            ) {
                
                ForEach(
                    CrewGroupFilter.allCases
                ) { group in
                    
                    Text(group.rawValue)
                        .tag(group)
                }
            }
            .pickerStyle(.segmented)
            
            if crewGroupFilter != .all {
                
                HStack {
                    
                    Button("PUSH") {
                        setFilteredGroupStatus(
                            .push
                        )
                    }
                    
                    Button("STANDBY") {
                        setFilteredGroupStatus(
                            .standby
                        )
                    }
                    
                    Button("BROKE") {
                        setFilteredGroupStatus(
                            .broke
                        )
                    }
                    
                    Button("OFF DUTY") {
                        setFilteredGroupOffDuty()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(
                    filteredActiveDrivers.isEmpty
                )
            }
            
            Picker(
                "Status",
                selection: $statusFilter
            ) {
                
                ForEach(
                    StatusFilter.allCases
                ) { filter in
                    
                    Text(filter.rawValue)
                        .tag(filter)
                }
            }
            .pickerStyle(.segmented)
            
            if activeDrivers.isEmpty {
                
                ContentUnavailableView(
                    "No Active Drivers",
                    systemImage:
                        "person.crop.circle.badge.clock",
                    description:
                        Text(
                            "Turn drivers on in the Drivers screen."
                        )
                )
                
            } else {
                
                ForEach(
                    filteredActiveDrivers
                ) { driver in
                    
                    DriverStatusCard(
                        driver:
                            driver,
                        activeBlock:
                            statusStore
                            .activeBlock(
                                for:
                                    driver.id
                            ),
                        totals:
                            stormStore.activeStormID.map {
                                
                                statusStore.totals(
                                    for: driver.id,
                                    stormID: $0
                                )
                                
                            } ?? (
                                push: 0,
                                standby: 0,
                                broke: 0
                            ),
                        now:
                            now,
                        
                        hasActiveStorm:
                            stormStore.activeStormID != nil,
                        
                        mapAssignments:
                            stormStore.activeStormID.map { stormID in
                                
                                mapAssignmentStore
                                    .currentAssignments(
                                        driverID:
                                            driver.id,
                                        stormID:
                                            stormID
                                    )
                                
                            } ?? [],
                        
                        onAssignMap: {
                            
                            assigningDriver =
                            driver
                        },
                        
                        onFinishMap: { assignment in
                            
                            mapAssignmentStore
                                .finish(
                                    assignment
                                )
                            
                            let contacts =
                            supervisorStore
                                .supervisors(
                                    for:
                                        driver.category
                                )
                            
                            let recipients =
                            contacts
                                .map {
                                    $0.phoneNumber
                                }
                                .filter {
                                    $0.isEmpty == false
                                }
                            
                            mapCheckMessage =
                            MapCheckMessage(
                                mapNumber:
                                    assignment.mapNumber,
                                recipients:
                                    recipients
                            )
                        },
                        
                        onOpenMap: { mapNumber in
                            
                            openingMap =
                            MapNumberSelection(
                                number: mapNumber
                            )
                        },
                        
                        onPush: {
                            
                            if let stormID =
                                stormStore.activeStormID {
                                
                                statusStore.changeStatus(
                                    driverID: driver.id,
                                    stormID: stormID,
                                    to: .push
                                )
                            }
                        },
                        onStandby: {
                            
                            if let stormID =
                                stormStore.activeStormID {
                                
                                statusStore.changeStatus(
                                    driverID: driver.id,
                                    stormID: stormID,
                                    to: .standby
                                )
                            }
                        },
                        onBroke: {
                            
                            if let stormID =
                                stormStore.activeStormID {
                                
                                statusStore.changeStatus(
                                    driverID: driver.id,
                                    stormID: stormID,
                                    to: .broke
                                )
                            }
                        },
                        onOffDuty: {
                            
                            statusStore
                                .offDuty(
                                    driverID:
                                        driver.id
                                )
                        }
                    )
                    
                    Button {
                        
                        historyDriver =
                        driver
                        
                    } label: {
                        
                        Label(
                            "View / Edit Time History",
                            systemImage:
                                "clock.arrow.circlepath"
                        )
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if activeDrivers.isEmpty == false {
                
                Section("Crew Totals") {
                    
                    LabeledContent("Active Drivers") {
                        
                        Text(
                            "\(activeDrivers.count)"
                        )
                    }
                    
                    LabeledContent("Push") {
                        
                        Text(
                            "\(crewPushHours, specifier: "%.2f") hrs"
                        )
                    }
                    
                    LabeledContent("Standby") {
                        
                        Text(
                            "\(crewStandbyHours, specifier: "%.2f") hrs"
                        )
                    }
                    
                    LabeledContent("Broke") {
                        
                        Text(
                            "\(crewBrokeHours, specifier: "%.2f") hrs"
                        )
                    }
                    
                    LabeledContent("Total Crew Hours") {
                        
                        Text(
                            "\(crewTotalHours, specifier: "%.2f") hrs"
                        )
                        .fontWeight(.bold)
                    }
                }
            }
        }
        .navigationTitle(
            "Status Board"
        )
        .onReceive(
            timer
        ) {
            now = $0
        }
        .sheet(
            isPresented:
                $showingNewStorm
        ) {
            
            NewStormView(
                onSave: { name in
                    
                    stormStore.startStorm(
                        name: name
                    )
                }
            )
        }
        .sheet(
            item:
                $historyDriver
        ) { driver in
            
            NavigationStack {
                
                DriverHistoryView(
                    driver:
                        driver,
                    statusStore:
                        statusStore
                )
            }
        }
        .sheet(
            item: $openingMap
        ) { selection in
            
            NavigationStack {
                
                VDOTSnowMapNativeView(
                    initialMapNumber:
                        selection.number
                )
            }
        }
        .sheet(
            item: $mapCheckMessage
        ) { item in
            
            if MFMessageComposeViewController
                .canSendText() {
                
                MessageComposer(
                    recipients:
                        item.recipients,
                    
                    body:
                        "Can you please go check Map #\(item.mapNumber)?"
                )
                
            } else {
                
                ContentUnavailableView(
                    "Messages Unavailable",
                    systemImage:
                        "message.slash",
                    description:
                        Text(
                            "This device cannot send text messages."
                        )
                )
            }
        }
        .sheet(
            item:
                $assigningDriver
        ) { driver in
            
            if let stormID =
                stormStore.activeStormID {
                
                AssignMapView(
                    driver:
                        driver,
                    stormID:
                        stormID,
                    assignmentStore:
                        mapAssignmentStore
                )
            }
        }
    }
    
    private func setFilteredGroupStatus(
        _ status: BlockType
    ) {
        
        guard
            let stormID =
                stormStore.activeStormID
        else {
            return
        }
        
        for driver in filteredActiveDrivers {
            
            statusStore.changeStatus(
                driverID: driver.id,
                stormID: stormID,
                to: status
            )
        }
    }
    
    private func setFilteredGroupOffDuty() {
        
        for driver in filteredActiveDrivers {
            
            statusStore.offDuty(
                driverID: driver.id
            )
        }
    }
}

private struct MapCheckMessage:
    Identifiable {
    
    let id = UUID()
    
    let mapNumber: String
    let recipients: [String]
}

private struct MapNumberSelection:
    Identifiable {
    
    let id = UUID()
    
    let number: String
}

private struct NewStormView: View {
    
    @Environment(\.dismiss)
    private var dismiss
    
    @State private var name =
    ""
    
    let onSave:
    (String) -> Void
    
    var body: some View {
        
        NavigationStack {
            
            Form {
                
                TextField(
                    "Storm Name",
                    text: $name
                )
            }
            .navigationTitle(
                "New Storm"
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
                        "Start"
                    ) {
                        
                        onSave(
                            name
                        )
                        
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct DriverStatusCard: View {
    
    let driver:
    CrewDriver
    
    let activeBlock:
    DriverStatusBlock?
    
    let totals: (
        push: Double,
        standby: Double,
        broke: Double
    )
    
    let now:
    Date
    
    let hasActiveStorm: Bool
    
    let mapAssignments:
    [DriverMapAssignment]
    
    let onAssignMap:
    () -> Void
    
    let onFinishMap:
    (DriverMapAssignment) -> Void
    
    let onOpenMap:
    (String) -> Void
    
    let onPush:
    () -> Void
    
    let onStandby:
    () -> Void
    
    let onBroke:
    () -> Void
    
    let onOffDuty:
    () -> Void
    
    private var elapsedHours:
    Double {
        
        guard
            let activeBlock
        else {
            return 0
        }
        
        return max(
            0,
            now.timeIntervalSince(
                activeBlock.startTime
            ) / 3600
        )
    }
    
    private var totalHours: Double {
        totals.push +
        totals.standby +
        totals.broke
    }
    
    var body: some View {
        
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            
            HStack {
                
                VStack(
                    alignment: .leading
                ) {
                    
                    Text(driver.name)
                        .font(.headline)
                    
                    Text(
                        driver.truckNumber.isEmpty
                        ? "No Truck"
                        : "Truck \(driver.truckNumber)"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let activeBlock {
                    
                    VStack(
                        alignment: .trailing
                    ) {
                        
                        Text(
                            activeBlock.status.rawValue
                        )
                        .font(.headline)
                        
                        Text(
                            "\(elapsedHours, specifier: "%.2f") hrs"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    
                } else {
                    
                    Text("OFF DUTY")
                        .foregroundStyle(.secondary)
                }
            }
            
            if hasActiveStorm {
                
                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {
                    
                    HStack {
                        
                        if mapAssignments.isEmpty == false {
                            
                            Text("Assigned Maps")
                                .font(.caption.bold())
                        }
                        
                        Spacer()
                        
                        Button {
                            
                            onAssignMap()
                            
                        } label: {
                            
                            Label(
                                "Assign Map",
                                systemImage:
                                    "map.badge.plus"
                            )
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    ForEach(
                        mapAssignments
                    ) { assignment in
                        
                        HStack {
                            
                            Button {
                                
                                onOpenMap(
                                    assignment.mapNumber
                                )
                                
                            } label: {
                                
                                Label(
                                    "Map \(assignment.mapNumber)",
                                    systemImage: "map"
                                )
                                .font(.subheadline)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            Button("Finish") {
                                
                                onFinishMap(
                                    assignment
                                )
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            
            HStack {
                
                if activeBlock?.status == .push {
                    
                    Button("PUSH") {
                        onPush()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        hasActiveStorm == false
                    )
                    
                } else {
                    
                    Button("PUSH") {
                        onPush()
                    }
                    .buttonStyle(.bordered)
                    .disabled(
                        hasActiveStorm == false
                    )
                }
                
                if activeBlock?.status == .standby {
                    
                    Button("STANDBY") {
                        onStandby()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        hasActiveStorm == false
                    )
                    
                } else {
                    
                    Button("STANDBY") {
                        onStandby()
                    }
                    .buttonStyle(.bordered)
                    .disabled(
                        hasActiveStorm == false
                    )
                }
                
                if activeBlock?.status == .broke {
                    
                    Button("BROKE") {
                        onBroke()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        hasActiveStorm == false
                    )
                    
                } else {
                    
                    Button("BROKE") {
                        onBroke()
                    }
                    .buttonStyle(.bordered)
                    .disabled(
                        hasActiveStorm == false
                    )
                }
                
                if activeBlock == nil {
                    
                    Button("OFF DUTY") {
                        onOffDuty()
                    }
                    .buttonStyle(.borderedProminent)
                    
                } else {
                    
                    Button("OFF DUTY") {
                        onOffDuty()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                
                Text(
                    "Push \(totals.push, specifier: "%.2f") • Standby \(totals.standby, specifier: "%.2f") • Broke \(totals.broke, specifier: "%.2f")"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                
                Text(
                    "Total \(totalHours, specifier: "%.2f") hrs"
                )
                .font(.caption.bold())
            }
        }
        .padding(
            .vertical,
            6
        )
    }
}

