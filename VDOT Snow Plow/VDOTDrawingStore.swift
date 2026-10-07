import Foundation
import CoreLocation

struct SavedCoordinate: Codable {
    
    let latitude: Double
    let longitude: Double
    
    init(_ coordinate: CLLocationCoordinate2D) {
        latitude = coordinate.latitude
        longitude = coordinate.longitude
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
    }
}

struct SavedDrawingStroke: Codable {
    
    let coordinates: [SavedCoordinate]
    
    init(_ stroke: VDOTDrawingStroke) {
        coordinates =
        stroke.coordinates.map {
            SavedCoordinate($0)
        }
    }
    
    var drawingStroke: VDOTDrawingStroke {
        
        VDOTDrawingStroke(
            coordinates:
                coordinates.map {
                    $0.coordinate
                }
        )
    }
}

final class VDOTDrawingStore {
    
    static let shared = VDOTDrawingStore()
    
    private init() {}
    
    private func key(
        ahqName: String,
        mapNumber: String
    ) -> String {
        
        "VDOT_DRAWING_\(ahqName)_\(mapNumber)"
    }
    
    func save(
        strokes: [VDOTDrawingStroke],
        ahqName: String,
        mapNumber: String
    ) {
        
        let saved =
        strokes.map {
            SavedDrawingStroke($0)
        }
        
        do {
            
            let data =
            try JSONEncoder()
                .encode(saved)
            
            UserDefaults.standard.set(
                data,
                forKey:
                    key(
                        ahqName: ahqName,
                        mapNumber: mapNumber
                    )
            )
            
            print(
                "💾 Saved drawing:",
                ahqName,
                mapNumber,
                "strokes:",
                strokes.count
            )
            
        } catch {
            
            print(
                "❌ Drawing save error:",
                error
            )
        }
    }
    
    func load(
        ahqName: String,
        mapNumber: String
    ) -> [VDOTDrawingStroke] {
        
        guard
            let data =
                UserDefaults.standard.data(
                    forKey:
                        key(
                            ahqName: ahqName,
                            mapNumber: mapNumber
                        )
                )
        else {
            return []
        }
        
        do {
            
            let saved =
            try JSONDecoder()
                .decode(
                    [SavedDrawingStroke].self,
                    from: data
                )
            
            let strokes =
            saved.map {
                $0.drawingStroke
            }
            
            print(
                "📂 Loaded drawing:",
                ahqName,
                mapNumber,
                "strokes:",
                strokes.count
            )
            
            return strokes
            
        } catch {
            
            print(
                "❌ Drawing load error:",
                error
            )
            
            return []
        }
    }
    
    func delete(
        ahqName: String,
        mapNumber: String
    ) {
        
        UserDefaults.standard.removeObject(
            forKey:
                key(
                    ahqName: ahqName,
                    mapNumber: mapNumber
                )
        )
        
        print(
            "🗑️ Deleted drawing:",
            ahqName,
            mapNumber
        )
    }
}

