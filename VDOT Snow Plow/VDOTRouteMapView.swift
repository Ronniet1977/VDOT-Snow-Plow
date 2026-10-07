import SwiftUI
import MapKit

struct VDOTRouteMapView: UIViewRepresentable {
    
    let routes: [VDOTSnowRoute]
    
    func makeUIView(
        context: Context
    ) -> MKMapView {
        
        let mapView = MKMapView()
        
        mapView.delegate =
        context.coordinator
        
        mapView.showsUserLocation = true
        
        mapView.pointOfInterestFilter =
            .excludingAll
        
        return mapView
    }
    
    func updateUIView(
        _ mapView: MKMapView,
        context: Context
    ) {
        
        mapView.removeOverlays(
            mapView.overlays
        )
        
        var overlays:
        [MKPolyline] = []
        
        for route in routes {
            
            overlays.append(
                contentsOf:
                    route.polylines
            )
        }
        
        mapView.addOverlays(
            overlays
        )
        
        guard
            overlays.isEmpty == false
        else {
            return
        }
        
        let mapRect =
        overlays.reduce(
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
    }
    
    func makeCoordinator()
    -> Coordinator {
        
        Coordinator()
    }
    
    final class Coordinator:
        NSObject,
        MKMapViewDelegate {
        
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
            
            renderer.strokeColor =
                .systemBlue
            
            renderer.lineWidth = 5
            
            renderer.alpha = 0.9
            
            return renderer
        }
    }
}

