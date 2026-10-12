//
//  AppVersionControl.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/12/26.
//

import Foundation

struct AppVersionControl:
    Identifiable,
    Codable,
    Equatable {

    var id = UUID()

    var minimumVersion: String
    var minimumBuild: Int
    var message: String

    var updatedAt: Date = Date()
}
