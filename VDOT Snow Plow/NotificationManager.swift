//
//  NotificationManager.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import Foundation
import CloudKit
import UserNotifications

final class NotificationManager {

    static let shared =
        NotificationManager()

    private init() {}

    private let database =
        CKContainer.default()
            .publicCloudDatabase

    // MARK: - Permission

    func requestPermission() async {

        do {

            let granted =
                try await UNUserNotificationCenter
                    .current()
                    .requestAuthorization(
                        options: [
                            .alert,
                            .sound,
                            .badge
                        ]
                    )

            print(
                granted
                ? "🔔 Notification permission granted"
                : "🔕 Notification permission denied"
            )

        } catch {

            print(
                "❌ Notification permission error:",
                error
            )
        }
    }

    // MARK: - Admin Subscriptions

    func subscribeForAccessRequests() async {

        let subscriptionID =
            "NewUserAccessRequestSubscription"

        do {

            _ = try await database
                .subscription(
                    for: subscriptionID
                )

            print(
                "🔔 Access request subscription already exists"
            )

            return

        } catch let error as CKError
        where error.code == .unknownItem {

            // Create it below.

        } catch {

            print(
                "❌ Subscription check failed:",
                error
            )

            return
        }

        let subscription =
            CKQuerySubscription(
                recordType:
                    "UserAccessRequest",
                predicate:
                    NSPredicate(
                        value: true
                    ),
                subscriptionID:
                    subscriptionID,
                options: [
                    .firesOnRecordCreation
                ]
            )

        let notificationInfo =
            CKSubscription.NotificationInfo()

        notificationInfo.alertBody =
            "A new user is requesting access."

        notificationInfo.soundName =
            "default"

        notificationInfo.shouldBadge =
            true

        notificationInfo.shouldSendContentAvailable =
            true
        
        notificationInfo.desiredKeys = [
            "name",
            "companyName",
            "status"
        ]
        
        notificationInfo.category =
            "ACCESS_REQUEST"

        subscription.notificationInfo =
            notificationInfo

        do {

            try await database.save(
                subscription
            )

            print(
                "🔔 Access request notifications enabled"
            )

        } catch {

            print(
                "❌ Access request subscription failed:",
                error
            )
        }
    }
    
    func subscribeForMapAssignments(
        driverID: UUID
    ) async {

        let subscriptionID =
            "MapAssignmentV2-\(driverID.uuidString)"

        do {

            _ = try await database
                .subscription(
                    for: subscriptionID
                )

            print(
                "🔔 Map assignment subscription already exists"
            )

            return

        } catch let error as CKError
        where error.code == .unknownItem {

            // Create below.

        } catch {

            print(
                "❌ Map assignment subscription check failed:",
                error
            )

            return
        }

        let predicate =
            NSPredicate(
                format:
                    "driverID == %@",
                driverID.uuidString
            )

        let subscription =
            CKQuerySubscription(
                recordType:
                    "DriverMapAssignment",
                predicate:
                    predicate,
                subscriptionID:
                    subscriptionID,
                options: [
                    .firesOnRecordCreation,
                    .firesOnRecordUpdate
                ]
            )

        let notificationInfo =
            CKSubscription.NotificationInfo()

        notificationInfo.alertBody =
            "You have a new map assignment."

        notificationInfo.soundName =
            "default"

        notificationInfo.shouldSendContentAvailable =
            true

        notificationInfo.desiredKeys = [
            "driverID",
            "mapNumber",
            "assignedAt"
        ]

        notificationInfo.category =
            "MAP_ASSIGNED"

        subscription.notificationInfo =
            notificationInfo

        do {

            try await database.save(
                subscription
            )

            print(
                "🔔 Driver map assignment notifications enabled"
            )

        } catch {

            print(
                "❌ Driver map assignment subscription failed:",
                error
            )
        }
    }
    
    func subscribeForMapAcknowledgements() async {

        let subscriptionID =
            "MapAcknowledgementSubscriptionV3"

        do {

            _ = try await database
                .subscription(
                    for: subscriptionID
                )

            print(
                "🔔 Map acknowledgement subscription already exists"
            )

            return

        } catch let error as CKError
        where error.code == .unknownItem {

            // Subscription does not exist yet.

        } catch {

            print(
                "❌ Map acknowledgement subscription check failed:",
                error
            )

            return
        }

        let subscription =
            CKQuerySubscription(
                recordType:
                    "MapAssignmentAcknowledgement",
                predicate:
                    NSPredicate(
                        value: true
                    ),
                subscriptionID:
                    subscriptionID,
                options: [
                    .firesOnRecordCreation
                ]
            )

        let info =
            CKSubscription.NotificationInfo()

        info.alertBody =
            "A driver acknowledged a map assignment."

        info.soundName =
            "default"

        info.shouldSendContentAvailable =
            true

        info.desiredKeys = [
            "assignmentID",
            "driverID",
            "mapNumber",
            "acknowledgedAt"
        ]

        info.category =
            "MAP_ACKNOWLEDGED"

        subscription.notificationInfo =
            info

        do {

            try await database.save(
                subscription
            )

            print(
                "🔔 Map acknowledgement notifications enabled"
            )

        } catch {

            print(
                "❌ Map acknowledgement subscription failed:",
                error
            )
        }
    }
    
    func subscribeForUserChanges(
        appleUserID: String
    ) async {

        let subscriptionID =
            "AppUserChange-\(appleUserID)"

        do {

            _ = try await database
                .subscription(
                    for: subscriptionID
                )

            print(
                "🔔 User change subscription already exists"
            )

            return

        } catch let error as CKError
        where error.code == .unknownItem {

            // Create below.

        } catch {

            print(
                "❌ User change subscription check failed:",
                error
            )

            return
        }

        let predicate =
            NSPredicate(
                format:
                    "appleUserID == %@",
                appleUserID
            )

        let subscription =
            CKQuerySubscription(
                recordType:
                    "AppUser",
                predicate:
                    predicate,
                subscriptionID:
                    subscriptionID,
                options: [
                    .firesOnRecordUpdate
                ]
            )

        let info =
            CKSubscription.NotificationInfo()

        info.alertBody =
            "Your app access has been updated."

        info.soundName =
            "default"

        info.shouldSendContentAvailable =
            true

        info.category =
            "USER_ROLE_CHANGED"

        subscription.notificationInfo =
            info

        do {

            try await database.save(
                subscription
            )

            print(
                "🔔 User role change notifications enabled"
            )

        } catch {

            print(
                "❌ User role subscription failed:",
                error
            )
        }
    }
    
    func subscribeForMapReviewRequests() async {

        let subscriptionID =
            "MapReviewRequestSubscriptionV1"

        do {

            _ = try await database
                .subscription(
                    for: subscriptionID
                )

            print(
                "🔔 Map review request subscription already exists"
            )

            return

        } catch let error as CKError
        where error.code == .unknownItem {

            // Create below.

        } catch {

            print(
                "❌ Map review subscription check failed:",
                error
            )

            return
        }

        let subscription =
            CKQuerySubscription(
                recordType:
                    "MapReviewRequest",
                predicate:
                    NSPredicate(
                        value: true
                    ),
                subscriptionID:
                    subscriptionID,
                options: [
                    .firesOnRecordCreation
                ]
            )

        let info =
            CKSubscription.NotificationInfo()

        info.alertBody =
            "A snow map needs a supervisor check."

        info.soundName =
            "default"

        info.shouldSendContentAvailable =
            true

        info.desiredKeys = [
            "assignmentID",
            "driverID",
            "mapNumber",
            "requestedAt",
            "status"
        ]

        info.category =
            "MAP_REVIEW_REQUEST"

        subscription.notificationInfo =
            info

        do {

            try await database.save(
                subscription
            )

            print(
                "🔔 Supervisor map review notifications enabled"
            )

        } catch {

            print(
                "❌ Map review notification subscription failed:",
                error
            )
        }
    }
    
    func subscribeForMapReviewInspections() async {

        let subscriptionID =
            "MapReviewInspectionSubscriptionV1"

        do {

            _ = try await database
                .subscription(
                    for: subscriptionID
                )

            print(
                "🔔 Map review inspection subscription already exists"
            )

            return

        } catch let error as CKError
        where error.code == .unknownItem {

            // Create below.

        } catch {

            print(
                "❌ Map review inspection subscription check failed:",
                error
            )

            return
        }

        let subscription =
            CKQuerySubscription(
                recordType:
                    "MapReviewInspection",
                predicate:
                    NSPredicate(
                        value: true
                    ),
                subscriptionID:
                    subscriptionID,
                options: [
                    .firesOnRecordCreation
                ]
            )

        let info =
            CKSubscription.NotificationInfo()

        info.alertBody =
            "A supervisor updated a map check."

        info.soundName =
            "default"

        info.shouldSendContentAvailable =
            true

        info.category =
            "MAP_REVIEW_INSPECTION"

        subscription.notificationInfo =
            info

        do {

            try await database.save(
                subscription
            )

            print(
                "🔔 Admin map review inspection notifications enabled"
            )

        } catch {

            print(
                "❌ Map review inspection notification subscription failed:",
                error
            )
        }
    }
    
    func subscribeForSharedMapDrawings() async {

        let subscriptionID =
            "SharedMapDrawingSubscriptionV1"

        do {

            _ = try await database
                .subscription(
                    for: subscriptionID
                )

            print(
                "🔔 Shared map drawing subscription already exists"
            )

            return

        } catch let error as CKError
        where error.code == .unknownItem {

            // Create below.

        } catch {

            print(
                "❌ Shared drawing subscription check failed:",
                error
            )

            return
        }

        let subscription =
            CKQuerySubscription(
                recordType:
                    "SharedMapDrawing",
                predicate:
                    NSPredicate(
                        value: true
                    ),
                subscriptionID:
                    subscriptionID,
                options: [
                    .firesOnRecordCreation,
                    .firesOnRecordDeletion
                ]
            )

        let info =
            CKSubscription.NotificationInfo()

        info.shouldSendContentAvailable =
            true

        info.category =
            "MAP_DRAWING_CHANGED"

        subscription.notificationInfo =
            info

        do {

            try await database
                .save(
                    subscription
                )

            print(
                "🔔 Shared map drawing notifications enabled"
            )

        } catch {

            print(
                "❌ Shared map drawing subscription failed:",
                error
            )
        }
    }
    
    func subscribeForMapAssignmentUpdates() async {

        let subscriptionID =
            "MapAssignmentUpdatesV1"

        do {

            _ = try await database
                .subscription(
                    for: subscriptionID
                )

            print(
                "🔔 Map assignment update subscription already exists"
            )

            return

        } catch let error as CKError
        where error.code == .unknownItem {

            // Create below.

        } catch {

            print(
                "❌ Map assignment update subscription check failed:",
                error
            )

            return
        }

        let subscription =
            CKQuerySubscription(
                recordType:
                    "DriverMapAssignment",
                predicate:
                    NSPredicate(
                        value: true
                    ),
                subscriptionID:
                    subscriptionID,
                options: [
                    .firesOnRecordUpdate
                ]
            )

        let info =
            CKSubscription.NotificationInfo()

        info.shouldSendContentAvailable =
            true

        info.category =
            "MAP_ASSIGNMENT_CHANGED"

        subscription.notificationInfo =
            info

        do {

            try await database
                .save(
                    subscription
                )

            print(
                "🔔 Map assignment update notifications enabled"
            )

        } catch {

            print(
                "❌ Map assignment update subscription failed:",
                error
            )
        }
    }
    
    func subscribeForUserRoleAssignments(
        appleUserID: String
    ) async {

        let subscriptionID =
            "UserRoleAssignment-\(appleUserID)"

        do {

            _ = try await database
                .subscription(
                    for: subscriptionID
                )

            print(
                "🔔 User role assignment subscription already exists"
            )

            return

        } catch let error as CKError
        where error.code == .unknownItem {

            // Create below.

        } catch {

            print(
                "❌ User role assignment subscription check failed:",
                error
            )

            return
        }

        let predicate =
            NSPredicate(
                format:
                    "appleUserID == %@",
                appleUserID
            )

        let subscription =
            CKQuerySubscription(
                recordType:
                    "UserRoleAssignment",
                predicate:
                    predicate,
                subscriptionID:
                    subscriptionID,
                options: [
                    .firesOnRecordCreation,
                    .firesOnRecordUpdate
                ]
            )

        let info =
            CKSubscription.NotificationInfo()

        info.alertBody =
            "Your app permissions have been updated."

        info.soundName =
            "default"

        info.shouldSendContentAvailable =
            true

        info.category =
            "USER_ROLE_ASSIGNMENT_CHANGED"

        subscription.notificationInfo =
            info

        do {

            try await database.save(
                subscription
            )

            print(
                "🔔 User role assignment notifications enabled"
            )

        } catch {

            print(
                "❌ User role assignment subscription failed:",
                error
            )
        }
    }
    
    func resetAllSubscriptions() async {

        do {

            let subscriptions =
                try await database
                    .allSubscriptions()

            print(
                "🧹 Found subscriptions:",
                subscriptions.map {
                    $0.subscriptionID
                }
            )

            for subscription in subscriptions {

                _ = try await database
                    .deleteSubscription(
                        withID:
                            subscription.subscriptionID
                    )

                print(
                    "🗑️ Deleted subscription:",
                    subscription.subscriptionID
                )
            }

            print(
                "✅ CloudKit subscriptions reset"
            )

        } catch {

            print(
                "❌ Subscription reset failed:",
                error
            )
        }
    }
    
    func printSubscriptions() async {

        do {

            let subscriptions =
                try await database
                    .allSubscriptions()

            print("🔎 CLOUDKIT SUBSCRIPTIONS:")

            for subscription in subscriptions {

                if let query =
                    subscription
                        as? CKQuerySubscription {

                    print(
                        "🔎 ID:",
                        query.subscriptionID
                    )

                    print(
                        "🔎 RECORD TYPE:",
                        query.recordType
                    )

                    print(
                        "🔎 CATEGORY:",
                        query.notificationInfo?
                            .category
                            ?? "none"
                    )

                } else {

                    print(
                        "🔎 ID:",
                        subscription.subscriptionID,
                        "not query subscription"
                    )
                }
            }

        } catch {

            print(
                "❌ Could not read subscriptions:",
                error
            )
        }
    }
    
    func printCloudKitUser(
        label: String
    ) async {

        do {

            let userID =
                try await CKContainer.default()
                    .userRecordID()

            print(
                "👤 \(label) CloudKit user:",
                userID.recordName
            )

        } catch {

            print(
                "❌ CloudKit user lookup failed:",
                error
            )
        }
    }
}
