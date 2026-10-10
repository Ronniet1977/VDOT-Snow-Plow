//
//  AccessRequestDecision.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation

struct AccessRequestDecision:
    Identifiable,
    Codable,
    Equatable {

    var id = UUID()

    var requestID: UUID
    var appleUserID: String

    var decision: String

    var decidedAt = Date()
}
