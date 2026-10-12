//
//  AppVersionControl.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/12/26.
//

import Foundation

struct AppVersionControl:
    Codable,
    Equatable {

    var minimumVersion: String
    var minimumBuild: Int
    var message: String
}
