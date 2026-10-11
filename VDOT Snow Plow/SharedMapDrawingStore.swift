//
//  SharedMapDrawingStore.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/11/26.
//

import Foundation
import Combine

@MainActor
final class SharedMapDrawingStore:
    ObservableObject {

    @Published var drawings:
        [SharedMapDrawing] = []

    private let cloud =
        CloudSharedMapDrawingService.shared

    func sync(
        stormID: UUID,
        mapNumber: String
    ) async {

        do {

            drawings =
                try await cloud
                    .fetchDrawings(
                        stormID:
                            stormID,
                        mapNumber:
                            mapNumber
                    )

            print(
                "☁️ Shared drawings synced:",
                mapNumber,
                drawings.count
            )

        } catch {

            print(
                "❌ Shared drawing sync failed:",
                error
            )
        }
    }

    func addStroke(
        stormID: UUID,
        mapNumber: String,
        user: AppUser,
        coordinates:
            [SavedCoordinate]
    ) async -> Bool {

        let drawing =
            SharedMapDrawing(
                stormID:
                    stormID,
                mapNumber:
                    mapNumber,
                createdByUserID:
                    user.id,
                createdByName:
                    user.name,
                createdByRole:
                    user.role,
                coordinates:
                    coordinates
            )

        do {

            try await cloud
                .saveDrawing(
                    drawing
                )

            drawings.append(
                drawing
            )

            drawings.sort {
                $0.createdAt <
                    $1.createdAt
            }
            
            print(
                "✅ Shared stroke saved:",
                mapNumber,
                user.name
            )
            
            return true

        } catch {

            print(
                "❌ Shared stroke save failed:",
                error
            )
            
            return false
        }
    }

    func drawings(
        for role: AppUserRole
    ) -> [SharedMapDrawing] {

        drawings.filter {
            $0.createdByRole ==
                role
        }
    }
    
    func clearMyDrawings(
        stormID: UUID,
        mapNumber: String,
        user: AppUser
    ) async {

        let mine =
            drawings.filter {
                $0.stormID == stormID &&
                $0.mapNumber == mapNumber &&
                $0.createdByUserID == user.id
            }

        guard mine.isEmpty == false
        else {
            print(
                "ℹ️ No shared drawings to clear for",
                user.name,
                mapNumber
            )
            return
        }

        for drawing in mine {

            do {

                try await cloud
                    .deleteDrawing(
                        drawing
                    )

                drawings.removeAll {
                    $0.id == drawing.id
                }

            } catch {

                print(
                    "❌ Shared drawing delete failed:",
                    drawing.mapNumber,
                    error
                )
            }
        }

        print(
            "✅ Cleared my shared drawings:",
            mapNumber,
            user.name
        )
    }
}
