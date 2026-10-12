//
//  UserAppStatus.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/12/26.
//

import Foundation

struct UserAppStatus:
    Identifiable,
    Codable,
    Equatable {

    var id: String {
        appleUserID
    }

    var appleUserID: String
    var appVersion: String
    var buildNumber: Int
    var lastSeenAt: Date
}
