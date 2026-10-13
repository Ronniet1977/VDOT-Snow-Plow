//
//  DriverHomeView.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import SwiftUI
import CoreLocation
import UIKit
import MapKit

struct DriverHomeView: View {

    let user: AppUser

    @ObservedObject var driverStore: CrewDriverStore
    @ObservedObject var appleAccountStore:
        AppleAccountStore

    @StateObject private var statusStore =
        DriverStatusStore()

    @StateObject private var mapAssignmentStore =
        DriverMapAssignmentStore()
    @StateObject private var mapProgressStore =
    MapProgressStore()
    @State private var isSavingMapProgress = false
    @StateObject private var acknowledgementStore =
        MapAssignmentAcknowledgementStore()
    @State private var selectedAssignmentID:
        UUID?
    @StateObject private var locationManager =
        DriverLocationManager()
    @State private var recommendedMap:
        AssignedMapRouteOption?

    @State private var isFindingClosestMap =
        false
    @StateObject private var reviewRequestStore =
        MapReviewRequestStore()

    private var driver: CrewDriver? {

        if let driverID =
            user.driverID {

            if let linked =
                driverStore.drivers.first(
                    where: {
                        $0.id == driverID
                    }
                ) {

                return linked
            }
        }

        return driverStore.drivers.first {
            $0.name == user.name
        }
    }

    var body: some View {

        NavigationStack {

            List {

                Section("Driver") {

                    Text(user.name)

                    if let driver {

                        if !driver.truckNumber.isEmpty {
                            Text(
                                "Truck \(driver.truckNumber)"
                            )
                            .foregroundStyle(.secondary)
                        }

                        Text(
                            driver.category.displayName
                        )
                        .foregroundStyle(.secondary)
                    }
                }

                if let driver {
                    currentAssignmentSection(
                        for: driver
                    )
                    
                    recommendedMapSection(
                        for: driver
                    )

                    statusSection(
                        for: driver
                    )

                    mapsSection(
                        for: driver
                    )
                } else {

                    Section {

                        Text(
                            "No driver record is linked to this user."
                        )
                        .foregroundStyle(.secondary)
                    }
                }
                
                Section("Account") {

                    HStack {

                        Text("Signed In As")

                        Spacer()

                        Text(user.name)
                            .foregroundStyle(.secondary)
                    }

                    Button(
                        "Sign Out",
                        role: .destructive
                    ) {

                        appleAccountStore.signOut()
                    }
                }
            }
            .navigationTitle(
                "My Snow Plow"
            )
            .task {

                locationManager
                    .requestLocation()

                if let driver {

                    await NotificationManager.shared
                        .requestPermission()

                    await NotificationManager.shared
                        .subscribeForMapAssignments(
                            driverID: driver.id
                        )
                }

                // Initial load only
                await mapAssignmentStore
                    .syncFromCloud()
                
                await mapProgressStore
                    .syncFromCloud()

                await acknowledgementStore
                    .syncFromCloud()
                
                await reviewRequestStore
                    .syncFromCloud()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.didBecomeActiveNotification
                )
            ) { _ in
                
                Task {
                    await mapProgressStore.syncFromCloud()
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for:
                        .mapAssignmentNotificationReceived
                )
            ) { _ in

                Task {

                    guard let driver
                    else {
                        return
                    }

                    let previousActiveCount =
                        mapAssignmentStore
                            .assignments
                            .filter {
                                $0.driverID ==
                                    driver.id &&
                                !$0.isCompleted
                            }
                            .count

                    print(
                        "🔄 Refreshing driver map assignments after push"
                    )

                    for attempt in 1...4 {

                        await mapAssignmentStore
                            .syncFromCloud()

                        let activeCount =
                            mapAssignmentStore
                                .assignments
                                .filter {
                                    $0.driverID ==
                                        driver.id &&
                                    !$0.isCompleted
                                }
                                .count

                        print(
                            "🚜 Active driver maps:",
                            activeCount,
                            "attempt:",
                            attempt
                        )

                        if activeCount !=
                            previousActiveCount {

                            print(
                                "✅ Driver map assignments updated"
                            )

                            break
                        }

                        try? await Task.sleep(
                            for: .seconds(2)
                        )
                    }
                }
            }
        }
    }
    
    private func statusSection(
        for driver: CrewDriver
    ) -> some View {

        Section("Current Status") {

            if let block =
                statusStore.activeBlock(
                    for: driver.id
                ) {

                Text(block.status.rawValue)
                    .font(.headline)

                Text(
                    "Started \(block.startTime.formatted(date: .omitted, time: .shortened))"
                )
                .foregroundStyle(.secondary)

            } else {

                Text("OFF DUTY")
                    .font(.headline)
            }
        }
    }
    
    private func mapsSection(
        for driver: CrewDriver
    ) -> some View {

        let assignments =
            mapAssignmentStore.assignments
                .filter {
                    $0.driverID == driver.id &&
                    !$0.isCompleted
                }
                .sorted {
                    $0.assignedAt < $1.assignedAt
                }

        return Section("Assigned Maps") {

            if assignments.isEmpty {

                Text("No active map assignments")
                    .foregroundStyle(.secondary)

            } else {

                ForEach(assignments) { assignment in

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        NavigationLink {

                            VDOTSnowMapNativeView(
                                initialMapNumber:
                                    assignment.mapNumber,
                                stormID:
                                    assignment.stormID,
                                currentUser:
                                    user
                            )

                        } label: {

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {

                                Text(
                                    "Map \(assignment.mapNumber)"
                                )
                                .font(.headline)

                                Text(
                                    assignment.assignedAt.formatted(
                                        date: .abbreviated,
                                        time: .shortened
                                    )
                                )
                                .foregroundStyle(
                                    .secondary
                                )
                            }
                        }

                        if let acknowledgement =
                            acknowledgementStore
                                .acknowledgement(
                                    for: assignment.id
                                ) {

                            Label(
                                "Acknowledged \(acknowledgement.acknowledgedAt.formatted(date: .omitted, time: .shortened))",
                                systemImage:
                                    "checkmark.circle.fill"
                            )
                            .foregroundStyle(
                                .green
                            )

                        } else {

                            Button(
                                "Acknowledge"
                            ) {

                                mapAssignmentStore
                                    .acknowledge(
                                        assignment
                                    )

                                Task {

                                    try? await Task.sleep(
                                        for: .seconds(1)
                                    )

                                    await acknowledgementStore
                                        .syncFromCloud()
                                }
                            }
                            .buttonStyle(
                                .borderedProminent
                            )
                        }
                        
                        if reviewRequestStore
                            .hasRequestedReview(
                                assignmentID:
                                    assignment.id
                            ) {

                            Label(
                                "Supervisor check requested",
                                systemImage:
                                    "person.badge.clock"
                            )
                            .font(
                                .caption
                            )
                            .foregroundStyle(
                                .orange
                            )

                        } else {

                            Button {

                                Task {

                                    await reviewRequestStore
                                        .requestReview(
                                            assignment:
                                                assignment
                                        )
                                }

                            } label: {

                                Label(
                                    "Request Supervisor Check",
                                    systemImage:
                                        "person.badge.shield.checkmark"
                                )
                            }
                            .buttonStyle(
                                .bordered
                            )
                        }
                    }
                    .padding(
                        .vertical,
                        4
                    )
                }
            }
        }
    }
    
    private func updateRecommendedMap(
        for driver: CrewDriver
    ) async {

        guard
            let currentLocation =
                locationManager.location
        else {
            return
        }

        let assignments =
            mapAssignmentStore.assignments
                .filter {
                    $0.driverID == driver.id &&
                    !$0.isCompleted
                }

        guard assignments.count > 1
        else {
            recommendedMap = nil
            return
        }

        isFindingClosestMap = true

        var options:
            [AssignedMapRouteOption] = []

        for assignment in assignments {

            do {

                let routes =
                    try await
                        VDOTSnowRouteService
                            .shared
                            .fetchRoutes(
                                ahqName:
                                    "Lake Ridge",
                                mapNumber:
                                    assignment.mapNumber,
                                limit:
                                    1000
                            )

                guard
                    let destination =
                        AssignedMapRoutingService
                            .shared
                            .startCoordinate(
                                for:
                                    routes
                            )
                else {
                    continue
                }

                let option =
                    try await
                        AssignedMapRoutingService
                            .shared
                            .drivingOption(
                                mapNumber:
                                    assignment.mapNumber,
                                destination:
                                    destination,
                                from:
                                    currentLocation.coordinate
                            )

                options.append(
                    option
                )

            } catch {

                print(
                    "❌ Route comparison failed for map",
                    assignment.mapNumber,
                    error
                )
            }
        }

        recommendedMap =
            AssignedMapRoutingService
                .shared
                .sortByClosest(
                    options
                )
                .first

        if let recommendedMap {

            print(
                "🚜 Closest assigned map:",
                recommendedMap.mapNumber,
                String(
                    format:
                        "%.1f miles",
                    recommendedMap.distanceMiles
                ),
                "\(recommendedMap.travelMinutes) min"
            )
        }

        isFindingClosestMap = false
    }
    
    private func recommendedMapSection(
        for driver: CrewDriver
    ) -> some View {

        Section(
            "Recommended Next"
        ) {

            if isFindingClosestMap {

                HStack {

                    ProgressView()

                    Text(
                        "Finding closest assigned map..."
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

            } else {

                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {

                    if let recommendedMap {

                        Text(
                            "Map \(recommendedMap.mapNumber)"
                        )
                        .font(
                            .title3.bold()
                        )

                        Text(
                            String(
                                format:
                                    "%.1f miles • %d min",
                                recommendedMap.distanceMiles,
                                recommendedMap.travelMinutes
                            )
                        )
                        .foregroundStyle(
                            .secondary
                        )

                        Button {

                            openRecommendedMap(
                                recommendedMap
                            )

                        } label: {

                            Label(
                                "Navigate to Map \(recommendedMap.mapNumber)",
                                systemImage:
                                    "location.fill"
                            )
                        }
                        .buttonStyle(
                            .borderedProminent
                        )

                    } else {

                        Text(
                            "Tap below to find the closest assigned map."
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }

                    Button {

                        Task {

                            locationManager
                                .requestLocation()

                            try? await Task.sleep(
                                for: .seconds(1)
                            )

                            await updateRecommendedMap(
                                for: driver
                            )
                        }

                    } label: {

                        Label(
                            self.recommendedMap == nil
                                ? "Find Closest Map"
                                : "Recalculate Closest Map",
                            systemImage:
                                "location.magnifyingglass"
                        )
                    }
                    .buttonStyle(
                        .bordered
                    )
                }
                .padding(
                    .vertical,
                    4
                )
            }
        }
    }
    
    private func openRecommendedMap(
        _ option: AssignedMapRouteOption
    ) {

        let mapItem =
            MKMapItem(
                location:
                    CLLocation(
                        latitude:
                            option.coordinate.latitude,
                        longitude:
                            option.coordinate.longitude
                    ),
                address:
                    nil
            )

        mapItem.name =
            "Snow Map \(option.mapNumber)"

        mapItem.openInMaps(
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey:
                    MKLaunchOptionsDirectionsModeDriving
            ]
        )
    }
    
    private func currentAssignmentSection(
        for driver: CrewDriver
    ) -> some View {

        let assignments =
            mapAssignmentStore.assignments
                .filter {
                    $0.driverID == driver.id &&
                    !$0.isCompleted
                }
                .sorted {
                    $0.assignedAt < $1.assignedAt
                }
        
        let selectedAssignment =
            assignments.first {
                $0.id == selectedAssignmentID
            }
            ?? assignments.first

        return Section(
            "Current Assignment"
        ) {

            if let assignment =
                selectedAssignment {

                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {

                    Text(
                        "Map \(assignment.mapNumber)"
                    )
                    .font(
                        .title3.bold()
                    )
                    
                    if assignments.count > 1 {

                        Picker(
                            "Assigned Map",
                            selection:
                                Binding(
                                    get: {
                                        selectedAssignmentID
                                            ?? assignment.id
                                    },
                                    set: {
                                        selectedAssignmentID =
                                            $0
                                    }
                                )
                        ) {

                            ForEach(
                                assignments
                            ) { item in

                                Text(
                                    "Map \(item.mapNumber)"
                                )
                                .tag(
                                    item.id
                                )
                            }
                        }
                        .pickerStyle(
                            .segmented
                        )
                    }

                    Text(
                        assignment.assignedAt.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    
                    AssignedMapPreviewView(
                        mapNumber:
                            assignment.mapNumber
                    )

                    NavigationLink {

                        VDOTSnowMapNativeView(
                            initialMapNumber:
                                assignment.mapNumber,
                            stormID:
                                assignment.stormID,
                            currentUser:
                                user
                        )

                    } label: {

                        Label(
                            "Open Snow Map",
                            systemImage:
                                "map.fill"
                        )
                    }
                    
                    
                    Divider()
                    
                    Text("Road Progress")
                        .font(.headline)
                    
                    let progress = mapProgressStore.currentProgress(
                        stormID: assignment.stormID,
                        mapNumber: assignment.mapNumber,
                        driverID: driver.id
                    )
                    
                    if progress?.roadsOpened == true {
                        
                        Label(
                            "Every road opened ✅",
                            systemImage: "checkmark.circle.fill"
                        )
                        .foregroundStyle(.blue)
                        
                    } else {
                        
                        Text("Did you open every road?")
                            .font(.subheadline)
                        
                        
                        Button {
                            
                            guard !isSavingMapProgress else {
                                return
                            }
                            
                            isSavingMapProgress = true
                            
                            Task {
                                
                                defer {
                                    isSavingMapProgress = false
                                }
                                
                                do {
                                    try await mapProgressStore
                                        .confirmRoadsOpened(
                                            stormID: assignment.stormID,
                                            mapNumber: assignment.mapNumber,
                                            driverID: driver.id,
                                            resetVersion: 0
                                        )
                                } catch {
                                    print("❌ Roads opened error:", error)
                                }
                            }
                            
                        } label: {
                            
                            if isSavingMapProgress {
                                ProgressView()
                            } else {
                                Label(
                                    "Yes — Every Road Opened",
                                    systemImage: "checkmark"
                                )
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSavingMapProgress)
                    }
                    
                    if progress?.curbToCurbComplete == true {
                        
                        Label(
                            "Curb to curb complete ✅",
                            systemImage: "checkmark.circle.fill"
                        )
                        .foregroundStyle(.green)
                        
                    } else if progress?.roadsOpened == true {
                        
                        Text("Is every road curb to curb?")
                            .font(.subheadline)
                        
                        
                        Button {
                            
                            guard !isSavingMapProgress else {
                                return
                            }
                            
                            isSavingMapProgress = true
                            
                            Task {
                                
                                defer {
                                    isSavingMapProgress = false
                                }
                                
                                do {
                                    try await mapProgressStore
                                        .confirmCurbToCurb(
                                            stormID: assignment.stormID,
                                            mapNumber: assignment.mapNumber,
                                            driverID: driver.id,
                                            resetVersion: 0
                                        )
                                } catch {
                                    print("❌ Curb to curb error:", error)
                                }
                            }
                            
                        } label: {
                            
                            if isSavingMapProgress {
                                ProgressView()
                            } else {
                                Label(
                                    "Yes — Curb to Curb Complete",
                                    systemImage: "checkmark.circle.fill"
                                )
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSavingMapProgress)
                    }
                }
                .padding(
                    .vertical,
                    4
                )

            } else {

                Text(
                    "No active assignment"
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
    }
}
