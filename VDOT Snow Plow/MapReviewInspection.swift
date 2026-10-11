//
//  MapReviewInspection.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation

enum MapReviewProgress: String, Codable, CaseIterable {
    case quarter = "1/4"
    case half = "1/2"
    case threeQuarter = "3/4"
    case done = "Done"
}

struct MapReviewInspection:
    Identifiable,
    Codable,
    Equatable {

    var id = UUID()

    var requestID: UUID
    var assignmentID: UUID
    var supervisorUserID: UUID

    var mapNumber: String
    var progress: MapReviewProgress

    var checkedAt = Date()
}
