import Foundation
import MapKit

struct VDOTSnowRoute: Identifiable {
    
    let id = UUID()
    
    let route: String
    let routeName: String
    let residency: String
    let area: String
    let zone: String
    let priority: String
    
    let polylines: [MKPolyline]
}

final class VDOTSnowRouteService {
    
    static let shared = VDOTSnowRouteService()
    
    private init() {}
    
    private let serviceURL =
    "https://services.arcgis.com/p5v98VHDX9Atv3l7/ArcGIS/rest/services/NoVaSnowRoutes/FeatureServer/0/query"
    
    // MARK: - Fetch Routes
    func fetchDistinctValues(
        field: String,
        whereClause: String = "1=1"
    ) async throws -> [String] {
        
        var components =
        URLComponents(
            string: serviceURL
        )!
        
        components.queryItems = [
            
            URLQueryItem(
                name: "where",
                value: whereClause
            ),
            
            URLQueryItem(
                name: "outFields",
                value: field
            ),
            
            URLQueryItem(
                name: "returnGeometry",
                value: "false"
            ),
            
            URLQueryItem(
                name: "returnDistinctValues",
                value: "true"
            ),
            
            URLQueryItem(
                name: "orderByFields",
                value: field
            ),
            
            URLQueryItem(
                name: "f",
                value: "json"
            )
        ]
        
        guard let url = components.url else {
            throw VDOTSnowRouteError.invalidURL
        }
        
        let (data, response) =
        try await URLSession.shared.data(
            from: url
        )
        
        guard
            let http =
                response as? HTTPURLResponse,
            (200...299).contains(
                http.statusCode
            )
        else {
            throw VDOTSnowRouteError.badResponse
        }
        
        let object =
        try JSONSerialization
            .jsonObject(
                with: data
            )
        
        guard
            let dictionary =
                object as? [String: Any],
            let features =
                dictionary["features"]
                as? [[String: Any]]
        else {
            return []
        }
        
        var values: [String] = []
        
        for feature in features {
            
            guard
                let attributes =
                    feature["attributes"]
                    as? [String: Any],
                let value =
                    attributes[field]
            else {
                continue
            }
            
            if value is NSNull {
                continue
            }
            
            let text =
            String(
                describing: value
            )
            
            if text.isEmpty == false {
                values.append(text)
            }
        }
        
        return Array(
            Set(values)
        )
        .sorted()
    }
    
    func fetchRoutes(
        ahqName: String? = nil,
        mapNumber: String? = nil,
        limit: Int = 1000
    ) async throws -> [VDOTSnowRoute] {
        
        var whereParts: [String] = ["1=1"]
        
        if let ahqName,
           ahqName.isEmpty == false {
            
            let safeAHQ =
            ahqName.replacingOccurrences(
                of: "'",
                with: "''"
            )
            
            whereParts.append(
                "AHQNAME='\(safeAHQ)'"
            )
        }
        
        if let mapNumber,
           mapNumber.isEmpty == false {
            
            let safeMapNumber =
            mapNumber.replacingOccurrences(
                of: "'",
                with: "''"
            )
            
            whereParts.append(
                "MAPNUMBER='\(safeMapNumber)'"
            )
        }
        
        let whereClause =
        whereParts.joined(
            separator: " AND "
        )
        
        var components =
        URLComponents(
            string: serviceURL
        )!
        
        components.queryItems = [
            
            URLQueryItem(
                name: "where",
                value: whereClause
            ),
            
            URLQueryItem(
                name: "outFields",
                value: "*"
            ),
            
            URLQueryItem(
                name: "returnGeometry",
                value: "true"
            ),
            
            URLQueryItem(
                name: "outSR",
                value: "4326"
            ),
            
            URLQueryItem(
                name: "resultRecordCount",
                value: "\(limit)"
            ),
            
            URLQueryItem(
                name: "f",
                value: "geojson"
            )
        ]
        
        guard let url = components.url else {
            throw VDOTSnowRouteError.invalidURL
        }
        
        print(
            "🌨️ Loading NoVA routes:",
            url.absoluteString
        )
        
        let (data, response) =
        try await URLSession.shared.data(
            from: url
        )
        
        guard
            let http =
                response as? HTTPURLResponse,
            (200...299).contains(
                http.statusCode
            )
        else {
            throw VDOTSnowRouteError.badResponse
        }
        
        let objects =
        try MKGeoJSONDecoder()
            .decode(data)
        
        var routes:
        [VDOTSnowRoute] = []
        
        for object in objects {
            
            guard
                let feature =
                    object as? MKGeoJSONFeature
            else {
                continue
            }
            
            let attributes =
            decodeProperties(
                feature.properties
            )
            
            var polylines:
            [MKPolyline] = []
            
            for geometry in feature.geometry {
                
                if let polyline =
                    geometry as? MKPolyline {
                    
                    polylines.append(
                        polyline
                    )
                }
                
                if let multiPolyline =
                    geometry as? MKMultiPolyline {
                    
                    polylines.append(
                        contentsOf:
                            multiPolyline.polylines
                    )
                }
            }
            
            guard polylines.isEmpty == false else {
                continue
            }
            
            routes.append(
                VDOTSnowRoute(
                    route:
                        stringValue(
                            attributes,
                            key: "ROUTENUMBER"
                        ),
                    
                    routeName:
                        buildStreetName(
                            attributes
                        ),
                    
                    residency:
                        stringValue(
                            attributes,
                            key: "AHQNAME"
                        ),
                    
                    area:
                        stringValue(
                            attributes,
                            key: "MAPNUMBER"
                        ),
                    
                    zone:
                        stringValue(
                            attributes,
                            key: "COUNTY"
                        ),
                    
                    priority: "",
                    
                    polylines:
                        polylines
                )
            )
        }
        
        print(
            "✅ NoVA routes loaded:",
            routes.count
        )
        
        return routes
    }
    
    // MARK: - Properties
    private func buildStreetName(
        _ attributes: [String: Any]
    ) -> String {
        
        let street =
        stringValue(
            attributes,
            key: "STNAME"
        )
        
        let type =
        stringValue(
            attributes,
            key: "STTYPE"
        )
        
        return [
            street,
            type
        ]
            .filter {
                $0.isEmpty == false
            }
            .joined(
                separator: " "
            )
    }
    
    private func decodeProperties(
        _ data: Data?
    ) -> [String: Any] {
        
        guard
            let data,
            let object =
                try? JSONSerialization
                .jsonObject(
                    with: data
                ),
            let dictionary =
                object as?
                [String: Any]
        else {
            return [:]
        }
        
        return dictionary
    }
    
    private func stringValue(
        _ dictionary: [String: Any],
        key: String
    ) -> String {
        
        guard
            let value =
                dictionary[key]
        else {
            return ""
        }
        
        if value is NSNull {
            return ""
        }
        
        return String(
            describing: value
        )
    }
}

enum VDOTSnowRouteError: Error {
    
    case invalidURL
    case badResponse
}

