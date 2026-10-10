//
//  UserAccessRequest.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation

struct UserAccessRequest: Identifiable, Codable, Equatable {

    var id = UUID()

    var appleUserID: String

    var name: String

    var companyName: String

    var truckVINLast4: String
    
    var phoneNumber: String

    var requestedAt = Date()

    var status: String = "pending"
}
