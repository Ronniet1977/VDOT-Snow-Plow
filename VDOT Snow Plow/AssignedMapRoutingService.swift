//
//  AssignedMapRoutingService.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation
import MapKit

struct AssignedMapRouteOption:
    Identifiable {

    let id = UUID()

    let mapNumber: String

    let coordinate:
        CLLocationCoordinate2D

    let distanceMeters:
        CLLocationDistance

    let travelTime:
        TimeInterval

    var distanceMiles: Double {
        distanceMeters / 1609.344
    }

    var travelMinutes: Int {
        Int(
            travelTime / 60
        )
    }
}

final class AssignedMapRoutingService {

    static let shared =
        AssignedMapRoutingService()

    private init() {}

    func startCoordinate(
        for routes: [VDOTSnowRoute]
    ) -> CLLocationCoordinate2D? {

        for route in routes {

            for polyline in route.polylines {

                guard polyline.pointCount > 0
                else {
                    continue
                }

                var coordinate =
                    CLLocationCoordinate2D()

                polyline.getCoordinates(
                    &coordinate,
                    range:
                        NSRange(
                            location: 0,
                            length: 1
                        )
                )

                return coordinate
            }
        }

        return nil
    }

    func drivingOption(
        mapNumber: String,
        destination:
            CLLocationCoordinate2D,
        from origin:
            CLLocationCoordinate2D
    ) async throws
    -> AssignedMapRouteOption {

        let request =
            MKDirections.Request()

        request.source =
            MKMapItem(
                placemark:
                    MKPlacemark(
                        coordinate:
                            origin
                    )
            )

        request.destination =
            MKMapItem(
                placemark:
                    MKPlacemark(
                        coordinate:
                            destination
                    )
            )

        request.transportType =
            .automobile

        let response =
            try await MKDirections(
                request:
                    request
            )
            .calculate()

        guard let route =
            response.routes.first
        else {
            throw AssignedMapRoutingError
                .noRouteFound
        }

        return AssignedMapRouteOption(
            mapNumber:
                mapNumber,
            coordinate:
                destination,
            distanceMeters:
                route.distance,
            travelTime:
                route.expectedTravelTime
        )
    }

    func sortByClosest(
        _ options:
            [AssignedMapRouteOption]
    ) -> [AssignedMapRouteOption] {

        options.sorted {
            $0.travelTime <
                $1.travelTime
        }
    }
}

enum AssignedMapRoutingError:
    Error {

    case noRouteFound
}
