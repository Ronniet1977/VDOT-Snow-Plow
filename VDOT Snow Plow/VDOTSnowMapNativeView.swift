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
    
    init(
        initialMapNumber: String? = nil
    ) {
        
        self.initialMapNumber =
        initialMapNumber
        
        _selectedMap =
        State(
            initialValue:
                initialMapNumber ?? ""
        )
    }
    
    private let ahqName =
    "Lake Ridge"
    
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
                    }
                    
                    Button {
                        
                        Task {
                            await loadRoutes()
                        }
                        
                    } label: {
                        
                        HStack {
                            
                            Spacer()
                            
                            if isLoading {
                                
                                ProgressView()
                                    .padding(
                                        .trailing,
                                        8
                                    )
                            }
                            
                            Text("Load Map")
                            
                            Spacer()
                        }
                    }
                    .disabled(
                        selectedMap.isEmpty ||
                        isLoading
                    )
                }
            }
            .frame(
                height: 255
            )
            
            ZStack {
                
                VDOTDrawingMapView(
                    routes: routes,
                    mapNumber: loadedMap,
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
                        
                        Button {
                            
                            guard loadedMap.isEmpty == false else {
                                return
                            }
                            
                            drawingsByMap[loadedMap] = []
                            
                            VDOTDrawingStore
                                .shared
                                .save(
                                    strokes: [],
                                    ahqName: ahqName,
                                    mapNumber: loadedMap
                                )
                            
                        } label: {
                            
                            Label(
                                "Clear",
                                systemImage: "trash"
                            )
                        }
                        .buttonStyle(
                            .bordered
                        )
                        .disabled(
                            currentDrawingBinding
                                .wrappedValue
                                .isEmpty
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
                loadedMap.isEmpty == false
            else {
                return
            }
            
            VDOTDrawingStore
                .shared
                .save(
                    strokes:
                        currentDrawingBinding
                        .wrappedValue,
                    ahqName:
                        ahqName,
                    mapNumber:
                        loadedMap
                )
        }
    }
    
    private func loadMapNumbers() async {
        
        isLoadingMaps = true
        errorMessage = nil
        
        do {
            
            mapNumbers =
            try await
            VDOTSnowRouteService
                .shared
                .fetchDistinctValues(
                    field: "MAPNUMBER",
                    whereClause:
                        "AHQNAME='Lake Ridge'"
                )
            
            print(
                "🗺️ Lake Ridge maps:",
                mapNumbers
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
            
            drawingsByMap[loadedMap] =
            VDOTDrawingStore
                .shared
                .load(
                    ahqName: ahqName,
                    mapNumber: loadedMap
                )
            
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
