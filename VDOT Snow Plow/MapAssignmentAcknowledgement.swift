//
//  MapAssignmentAcknowledgement.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation

struct MapAssignmentAcknowledgement:
    Identifiable,
    Codable,
    Equatable {

    var id = UUID()

    var assignmentID: UUID
    var driverID: UUID
    var mapNumber: String

    var acknowledgedAt = Date()
}
