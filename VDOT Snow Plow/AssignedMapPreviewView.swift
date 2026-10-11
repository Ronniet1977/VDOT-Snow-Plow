//
//  AssignedMapPreviewView.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import SwiftUI
import MapKit

struct AssignedMapPreviewView: View {

    let mapNumber: String

    @State private var routes:
        [VDOTSnowRoute] = []

    @State private var isLoading =
        false

    private let ahqName =
        "Lake Ridge"

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            ZStack {

                VDOTDrawingMapView(
                    routes: routes,
                    mapNumber: mapNumber,
                    drawingEnabled:
                        .constant(false),
                    strokes:
                        .constant([])
                )

                if isLoading {

                    ProgressView()
                        .padding()
                        .background(
                            .ultraThinMaterial
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 10
                            )
                        )
                }
            }
            .frame(
                height: 180
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12
                )
            )

            if let primaryRoute {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Label(
                        streetName,
                        systemImage:
                            "road.lanes"
                    )
                    .font(
                        .headline
                    )

                    if !primaryRoute.route.isEmpty {

                        Text(
                            "Route \(primaryRoute.route)"
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }
                }
            }

            Button {

                openInAppleMaps()

            } label: {

                Label(
                    "Open in Apple Maps",
                    systemImage:
                        "arrow.triangle.turn.up.right.diamond.fill"
                )
            }
            .buttonStyle(
                .borderedProminent
            )
            .disabled(
                routeCoordinate == nil
            )
        }
        .task(
            id: mapNumber
        ) {

            await loadRoutes()
        }
    }
    
    private var primaryRoute:
        VDOTSnowRoute? {

        routes.first {
            !$0.routeName.isEmpty &&
            !$0.polylines.isEmpty
        }
    }

    private var streetName: String {

        primaryRoute?.routeName
            ?? "Snow Route"
    }

    private var routeCoordinate:
        CLLocationCoordinate2D? {

        guard
            let polyline =
                primaryRoute?
                    .polylines
                    .first,
            polyline.pointCount > 0
        else {
            return nil
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

    private func loadRoutes() async {

        guard mapNumber.isEmpty == false
        else {
            return
        }

        isLoading = true

        do {

            routes =
                try await
                    VDOTSnowRouteService
                        .shared
                        .fetchRoutes(
                            ahqName:
                                ahqName,
                            mapNumber:
                                mapNumber,
                            limit:
                                1000
                        )

            print(
                "🗺️ Driver preview map",
                mapNumber,
                "routes:",
                routes.count
            )

        } catch {

            print(
                "❌ Driver preview map error:",
                error
            )
        }

        isLoading = false
    }
    
    private func openInAppleMaps() {

        guard let coordinate =
            routeCoordinate
        else {
            return
        }

        let placemark =
            MKPlacemark(
                coordinate:
                    coordinate
            )

        let mapItem =
            MKMapItem(
                placemark:
                    placemark
            )

        mapItem.name =
            streetName

        mapItem.openInMaps(
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey:
                    MKLaunchOptionsDirectionsModeDriving
            ]
        )
    }
}
