//
//  UserRoleAssignmentStore.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/12/26.
//

import Foundation
import Combine

@MainActor
final class UserRoleAssignmentStore:
    ObservableObject {

    @Published var assignments:
        [UserRoleAssignment] = []

    private let cloud =
        CloudUserRoleAssignmentService.shared

    func syncFromCloud() async {

        do {

            assignments =
                try await cloud
                    .fetchAssignments()

            print(
                "☁️ User role assignments synced:",
                assignments.count
            )

        } catch {

            print(
                "❌ User role assignment sync failed:",
                error
            )
        }
    }

    func latestAssignment(
        for appleUserID: String
    ) -> UserRoleAssignment? {

        assignments
            .filter {
                $0.appleUserID ==
                    appleUserID
            }
            .sorted {
                $0.updatedAt >
                    $1.updatedAt
            }
            .first
    }

    func effectiveUser(
        from user: AppUser
    ) -> AppUser {

        guard
            let appleUserID =
                user.appleUserID,
            let assignment =
                latestAssignment(
                    for:
                        appleUserID
                )
        else {
            return user
        }

        var effective =
            user

        effective.role =
            assignment.role

        effective.category =
            assignment.category

        effective.driverID =
            assignment.driverID

        effective.isAlsoDriver =
            assignment.isAlsoDriver

        effective.isAlsoSupervisor =
            assignment.isAlsoSupervisor

        effective.isActive =
            assignment.isActive

        return effective
    }

    func saveAssignment(
        for user: AppUser
    ) async throws {

        guard let appleUserID =
            user.appleUserID
        else {
            return
        }

        let assignment =
            UserRoleAssignment(
                appleUserID:
                    appleUserID,
                role:
                    user.role,
                category:
                    user.category,
                driverID:
                    user.driverID,
                isAlsoDriver:
                    user.isAlsoDriver,
                isAlsoSupervisor:
                    user.isAlsoSupervisor,
                isActive:
                    user.isActive,
                updatedAt:
                    Date()
            )

        try await cloud
            .saveAssignment(
                assignment
            )

        assignments.insert(
            assignment,
            at: 0
        )

        print(
            "✅ Role assignment saved for:",
            user.name
        )
    }
}
