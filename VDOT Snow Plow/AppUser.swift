//
//  AppUser.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/9/26.
//

import Foundation

enum AppUserRole:
    String,
    Codable,
    CaseIterable,
    Identifiable {

    case admin
    case supervisor
    case driver

    var id: String {
        rawValue
    }

    var displayName: String {

        switch self {

        case .admin:
            return "Admin"

        case .supervisor:
            return "Supervisor"

        case .driver:
            return "Driver"
        }
    }
}

struct AppUser: Identifiable, Codable, Equatable {

    var id = UUID()

    var name: String
    var role: AppUserRole

    var category: CrewCategory?

    var driverID: UUID?
    var appleUserID: String?

    var companyName: String?
    var truckVINLast4: String?
    var phoneNumber: String?
    
    var isAlsoDriver: Bool = false
    var isAlsoSupervisor: Bool = false
    var isActive: Bool = true
}
