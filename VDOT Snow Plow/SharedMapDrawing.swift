//
//  SharedMapDrawing.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/11/26.
//

import Foundation

struct SharedMapDrawing:
    Identifiable,
    Codable,
    Equatable {

    var id = UUID()

    var stormID: UUID
    var mapNumber: String

    var createdByUserID: UUID
    var createdByName: String
    var createdByRole: AppUserRole

    var coordinates:
        [SavedCoordinate]

    var createdAt =
        Date()
}
