//
//  DriverLocationManager.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class DriverLocationManager:
    NSObject,
    ObservableObject,
    CLLocationManagerDelegate {

    @Published var location:
        CLLocation?

    @Published var authorizationStatus:
        CLAuthorizationStatus

    private let manager =
        CLLocationManager()

    override init() {

        authorizationStatus =
            manager.authorizationStatus

        super.init()

        manager.delegate =
            self

        manager.desiredAccuracy =
            kCLLocationAccuracyHundredMeters
    }

    func requestLocation() {

        switch manager.authorizationStatus {

        case .notDetermined:

            manager.requestWhenInUseAuthorization()

        case .authorizedAlways,
             .authorizedWhenInUse:

            manager.requestLocation()

        default:

            break
        }
    }

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {

        authorizationStatus =
            manager.authorizationStatus

        if manager.authorizationStatus ==
            .authorizedAlways ||
            manager.authorizationStatus ==
            .authorizedWhenInUse {

            manager.requestLocation()
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations:
            [CLLocation]
    ) {

        location =
            locations.last

        if let location {

            print(
                "📍 Driver location:",
                location.coordinate.latitude,
                location.coordinate.longitude
            )
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {

        print(
            "❌ Driver location error:",
            error
        )
    }
}
