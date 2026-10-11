import SwiftUI

struct VDOTSnowMapNativeView: View {
    
    @State private var routes:
    [VDOTSnowRoute] = []
    
    @State private var mapNumbers:
    [String] = []
    
    @State private var selectedMap =
    ""
    
    @State private var isLoading =
    false
    
    @State private var isLoadingMaps =
    false
    
    @State private var errorMessage:
    String?
    
    @State private var drawingEnabled =
    false
    
    @State private var drawingsByMap:
    [String: [VDOTDrawingStroke]] = [:]
    
    @State private var loadedMap =
    ""
    
    let initialMapNumber: String?
    let stormID: UUID?
    let currentUser: AppUser?

    @StateObject private var sharedDrawingStore =
        SharedMapDrawingStore()
    
    init(
        initialMapNumber: String? = nil,
        stormID: UUID? = nil,
        currentUser: AppUser? = nil
    ) {

        self.initialMapNumber =
            initialMapNumber

        self.stormID =
            stormID

        self.currentUser =
            currentUser

        _selectedMap =
            State(
                initialValue:
                    initialMapNumber ?? ""
            )
    }
    
    private let ahqName =
    "Lake Ridge"
    
    private let mapNumberCacheKey =
        "LakeRidgeMapNumbers"
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            Form {
                
                Section("Area Headquarters") {
                    
                    HStack {
                        
                        Text("AHQ")
                        
                        Spacer()
                        
                        Text(ahqName)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Snow Map") {
                    
                    if isLoadingMaps {
                        
                        HStack {
                            
                            ProgressView()
                            
                            Text(
                                "Loading maps..."
                            )
                        }
                        
                    } else {
                        
                        Picker(
                            "Map",
                            selection:
                                $selectedMap
                        ) {

                            Text(
                                "Choose Map"
                            )
                            .tag("")

                            ForEach(
                                mapNumbers,
                                id: \.self
                            ) { number in

                                Text(number)
                                    .tag(number)
                            }
                        }
                        .onChange(
                            of: selectedMap
                        ) { _, newValue in

                            guard newValue.isEmpty == false
                            else {
                                return
                            }

                            Task {
                                await loadRoutes()
                            }
                        }
                    }
                }
            }
            .frame(
                height: 255
            )
            
            ZStack {
                
                VDOTDrawingMapView(
                    routes: routes,
                    mapNumber: loadedMap,
                    sharedDrawings:
                        sharedDrawingStore.drawings,
                    drawingEnabled:
                        $drawingEnabled,
                    strokes:
                        currentDrawingBinding
                )
                
                if routes.isEmpty &&
                    isLoading == false {
                    
                    VStack(
                        spacing: 8
                    ) {
                        
                        Image(
                            systemName:
                                "snowflake"
                        )
                        .font(
                            .largeTitle
                        )
                        
                        Text(
                            selectedMap.isEmpty
                            ? "Choose a Snow Map"
                            : "No routes loaded"
                        )
                        .font(
                            .headline
                        )
                    }
                    .padding()
                    .background(
                        .ultraThinMaterial
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 12
                        )
                    )
                }
                
                if let errorMessage {
                    
                    VStack(
                        spacing: 6
                    ) {
                        
                        Text(
                            "Could not load map"
                        )
                        .font(
                            .headline
                        )
                        
                        Text(
                            errorMessage
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }
                    .padding()
                    .background(
                        .ultraThinMaterial
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 12
                        )
                    )
                }
                VStack {
                    
                    HStack(spacing: 10) {
                        
                        Button {
                            
                            drawingEnabled.toggle()
                            
                        } label: {
                            
                            Label(
                                drawingEnabled
                                ? "Move"
                                : "Draw",
                                systemImage:
                                    drawingEnabled
                                ? "hand.draw"
                                : "pencil.tip"
                            )
                        }
                        .buttonStyle(
                            .borderedProminent
                        )
                        .tint(
                            drawButtonColor
                        )
                        
                        Button {

                            guard
                                let stormID,
                                let currentUser,
                                loadedMap.isEmpty == false
                            else {
                                return
                            }

                            Task {

                                await sharedDrawingStore
                                    .clearMyDrawings(
                                        stormID:
                                            stormID,
                                        mapNumber:
                                            loadedMap,
                                        user:
                                            currentUser
                                    )

                                drawingsByMap[loadedMap] = []
                            }

                        } label: {

                            Label(
                                "Clear My Drawing",
                                systemImage:
                                    "trash"
                            )
                        }
                        .buttonStyle(
                            .bordered
                        )
                        .disabled(
                            sharedDrawingStore
                                .drawings
                                .contains {
                                    $0.stormID ==
                                        stormID &&
                                    $0.mapNumber ==
                                        loadedMap &&
                                    $0.createdByUserID ==
                                        currentUser?.id
                                } == false
                        )
                        
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                }
            }
        }
        .navigationTitle(
            "VDOT Snow Routes"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .task {
            
            await loadMapNumbers()
            
            if initialMapNumber != nil {
                
                await loadRoutes()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: .vdotDrawingChanged
            )
        ) { _ in

            guard
                let stormID,
                let currentUser,
                loadedMap.isEmpty == false,
                let latestStroke =
                    currentDrawingBinding
                        .wrappedValue
                        .last
            else {
                return
            }

            let savedCoordinates =
                latestStroke.coordinates
                    .map {
                        SavedCoordinate($0)
                    }

            Task {

                let saved =
                    await sharedDrawingStore
                        .addStroke(
                            stormID:
                                stormID,
                            mapNumber:
                                loadedMap,
                            user:
                                currentUser,
                            coordinates:
                                savedCoordinates
                        )

                if saved {

                    // Remove the temporary local copy.
                    // The CloudKit shared copy now draws it.
                    if drawingsByMap[loadedMap]?.isEmpty == false {

                        drawingsByMap[loadedMap]?
                            .removeLast()
                    }

                    print(
                        "☁️ Drawing is now shared:",
                        loadedMap,
                        currentUser.name,
                        currentUser.role.rawValue
                    )
                }
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: .mapDrawingChangedNotificationReceived
            )
        ) { _ in

            guard
                let stormID,
                loadedMap.isEmpty == false
            else {
                return
            }

            Task {

                print(
                    "🔄 Refreshing shared drawings:",
                    loadedMap
                )

                for attempt in 1...4 {

                    let previousCount =
                        sharedDrawingStore
                            .drawings
                            .count

                    await sharedDrawingStore
                        .sync(
                            stormID:
                                stormID,
                            mapNumber:
                                loadedMap
                        )

                    let newCount =
                        sharedDrawingStore
                            .drawings
                            .count

                    print(
                        "✏️ Shared drawing count:",
                        newCount,
                        "attempt:",
                        attempt
                    )

                    if newCount != previousCount {
                        print(
                            "✅ Shared drawings updated"
                        )
                        break
                    }

                    try? await Task.sleep(
                        for:
                            .seconds(2)
                    )
                }
            }
        }
    }
    
    private var drawButtonColor: Color {

        switch currentUser?.role {

        case .driver:
            return .red

        case .supervisor:
            return .orange

        case .admin:
            return .purple

        case nil:
            return .blue
        }
    }
    
    private func loadMapNumbers() async {

        isLoadingMaps = true
        errorMessage = nil

        let cached =
            UserDefaults.standard
                .stringArray(
                    forKey:
                        mapNumberCacheKey
                )
            ?? []

        if cached.isEmpty == false {

            mapNumbers =
                cached

            print(
                "🗺️ Lake Ridge maps from cache:",
                cached.count
            )

            isLoadingMaps = false
            return
        }

        do {

            let values =
                try await
                VDOTSnowRouteService
                    .shared
                    .fetchDistinctValues(
                        field:
                            "MAPNUMBER",
                        whereClause:
                            "AHQNAME='Lake Ridge'"
                    )

            mapNumbers =
                values

            if values.isEmpty == false {

                UserDefaults.standard
                    .set(
                        values,
                        forKey:
                            mapNumberCacheKey
                    )
            }

            print(
                "🗺️ Lake Ridge maps:",
                values.count
            )

        } catch {

            errorMessage =
                error.localizedDescription

            print(
                "❌ Map list error:",
                error
            )
        }

        isLoadingMaps = false
    }
    
    private func loadRoutes() async {
        
        guard
            selectedMap.isEmpty == false
        else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            
            let loadedRoutes =
            try await
            VDOTSnowRouteService
                .shared
                .fetchRoutes(
                    ahqName:
                        ahqName,
                    mapNumber:
                        selectedMap,
                    limit:
                        1000
                )
            
            routes =
            loadedRoutes
            
            loadedMap =
            selectedMap
            
            if let stormID {

                await sharedDrawingStore
                    .sync(
                        stormID:
                            stormID,
                        mapNumber:
                            selectedMap
                    )
            }
            
            drawingsByMap[loadedMap] = []
            
            print(
                "🗺️ Loaded Lake Ridge map",
                selectedMap,
                "routes:",
                routes.count
            )
            
            if routes.isEmpty {
                
                errorMessage =
                "No routes found for map \(selectedMap)."
            }
            
        } catch {
            
            errorMessage =
            error.localizedDescription
            
            print(
                "❌ Route load error:",
                error
            )
        }
        
        isLoading = false
    }
    
    private var currentDrawingBinding:
    Binding<[VDOTDrawingStroke]> {
        
        Binding(
            get: {
                drawingsByMap[loadedMap] ?? []
            },
            set: { newValue in
                guard loadedMap.isEmpty == false else {
                    return
                }
                
                drawingsByMap[loadedMap] =
                newValue
            }
        )
    }
}
