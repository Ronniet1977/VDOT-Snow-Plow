import SwiftUI
import MapKit

struct VDOTDrawingStroke: Identifiable {
    let id = UUID()
    var coordinates: [CLLocationCoordinate2D]
}

struct VDOTDrawingMapView: UIViewRepresentable {
    
    let routes: [VDOTSnowRoute]
    let mapNumber: String
    
    @Binding var drawingEnabled: Bool
    @Binding var strokes: [VDOTDrawingStroke]
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            drawingEnabled: $drawingEnabled,
            strokes: $strokes
        )
    }
    
    func makeUIView(
        context: Context
    ) -> MKMapView {
        
        let mapView = MKMapView()
        
        mapView.delegate =
        context.coordinator
        
        context.coordinator.mapView =
        mapView
        
        let pan =
        UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(
                Coordinator.handleDrawingPan(_:)
            )
        )
        
        pan.maximumNumberOfTouches = 1
        
        context.coordinator.drawingGesture =
        pan
        
        mapView.addGestureRecognizer(
            pan
        )
        
        return mapView
    }
    
    func updateUIView(
        _ mapView: MKMapView,
        context: Context
    ) {
        
        context.coordinator.drawingEnabled =
        $drawingEnabled
        
        context.coordinator.strokes =
        $strokes
        
        if drawingEnabled {
            
            mapView.isScrollEnabled = false
            mapView.isZoomEnabled = false
            mapView.isRotateEnabled = false
            mapView.isPitchEnabled = false
            
        } else {
            
            mapView.isScrollEnabled = true
            mapView.isZoomEnabled = true
            mapView.isRotateEnabled = true
            mapView.isPitchEnabled = true
        }
        
        mapView.removeOverlays(
            mapView.overlays
        )
        
        var routeOverlays:
        [MKPolyline] = []
        
        for route in routes {
            
            routeOverlays.append(
                contentsOf:
                    route.polylines
            )
        }
        
        mapView.addOverlays(
            routeOverlays,
            level: .aboveRoads
        )
        
        for stroke in strokes {
            
            guard
                stroke.coordinates.count > 1
            else {
                continue
            }
            
            let polyline =
            MKPolyline(
                coordinates:
                    stroke.coordinates,
                count:
                    stroke.coordinates.count
            )
            
            polyline.title =
            "USER_DRAWING"
            
            mapView.addOverlay(
                polyline,
                level: .aboveLabels
            )
        }
        
        if context.coordinator.lastMapNumber != mapNumber {
            
            context.coordinator.lastMapNumber =
            mapNumber
            
            context.coordinator.hasZoomed =
            false
        }
        
        if context.coordinator.hasZoomed == false,
           routeOverlays.isEmpty == false {
            
            let mapRect =
            routeOverlays.reduce(
                MKMapRect.null
            ) {
                $0.union(
                    $1.boundingMapRect
                )
            }
            
            mapView.setVisibleMapRect(
                mapRect,
                edgePadding:
                    UIEdgeInsets(
                        top: 60,
                        left: 40,
                        bottom: 60,
                        right: 40
                    ),
                animated: true
            )
            
            context.coordinator.hasZoomed =
            true
        }
    }
    
    final class Coordinator:
        NSObject,
        MKMapViewDelegate {
        
        weak var mapView: MKMapView?
        
        var lastMapNumber = ""
        
        var drawingEnabled:
        Binding<Bool>
        
        var strokes:
        Binding<[VDOTDrawingStroke]>
        
        var drawingGesture:
        UIPanGestureRecognizer?
        
        var activeCoordinates:
        [CLLocationCoordinate2D] = []
        
        var hasZoomed = false
        
        init(
            drawingEnabled: Binding<Bool>,
            strokes:
            Binding<[VDOTDrawingStroke]>
        ) {
            
            self.drawingEnabled =
            drawingEnabled
            
            self.strokes =
            strokes
        }
        
        @objc
        func handleDrawingPan(
            _ gesture:
            UIPanGestureRecognizer
        ) {
            
            guard
                drawingEnabled.wrappedValue,
                let mapView
            else {
                return
            }
            
            let point =
            gesture.location(
                in: mapView
            )
            
            let coordinate =
            mapView.convert(
                point,
                toCoordinateFrom:
                    mapView
            )
            
            switch gesture.state {
                
            case .began:
                
                activeCoordinates = [
                    coordinate
                ]
                
            case .changed:
                
                activeCoordinates.append(
                    coordinate
                )
                
            case .ended,
                    .cancelled:
                
                activeCoordinates.append(
                    coordinate
                )
                
                if activeCoordinates.count > 1 {
                    
                    strokes.wrappedValue.append(
                        VDOTDrawingStroke(
                            coordinates:
                                activeCoordinates
                        )
                    )
                    
                    NotificationCenter.default.post(
                        name: .vdotDrawingChanged,
                        object: nil
                    )
                }
                
                activeCoordinates = []
                
            default:
                
                break
            }
        }
        
        func mapView(
            _ mapView: MKMapView,
            rendererFor overlay:
            MKOverlay
        ) -> MKOverlayRenderer {
            
            guard
                let polyline =
                    overlay as? MKPolyline
            else {
                return MKOverlayRenderer(
                    overlay: overlay
                )
            }
            
            let renderer =
            MKPolylineRenderer(
                polyline: polyline
            )
            
            if polyline.title ==
                "USER_DRAWING" {
                
                renderer.strokeColor =
                    .systemRed
                
                renderer.lineWidth =
                7
                
                renderer.lineCap =
                    .round
                
                renderer.lineJoin =
                    .round
                
            } else {
                
                renderer.strokeColor =
                    .systemBlue
                
                renderer.lineWidth =
                5
                
                renderer.alpha =
                0.9
            }
            
            return renderer
        }
    }
}

extension Notification.Name {
    
    static let vdotDrawingChanged =
    Notification.Name(
        "vdotDrawingChanged"
    )
}
