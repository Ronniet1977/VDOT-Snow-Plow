//
//  UserRoleAssignment.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/12/26.
//

import Foundation

struct UserRoleAssignment:
    Identifiable,
    Codable,
    Equatable {

    var id = UUID()

    var appleUserID: String

    var role: AppUserRole

    var category: CrewCategory?

    var driverID: UUID?

    var isAlsoDriver: Bool = false

    var isAlsoSupervisor: Bool = false

    var isActive: Bool = true

    var updatedAt: Date = Date()
}
