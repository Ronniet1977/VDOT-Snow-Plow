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
            "MapAssignment-\(driverID.uuidString)"

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
                    .firesOnRecordCreation
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
            "MapAcknowledgementSubscriptionV2"

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

            // Create below.

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

        let notificationInfo =
            CKSubscription.NotificationInfo()

        notificationInfo.alertBody =
            "A driver acknowledged a map assignment."

        notificationInfo.soundName =
            "default"

        notificationInfo.shouldSendContentAvailable =
            true

        notificationInfo.desiredKeys = [
            "driverID",
            "mapNumber",
            "acknowledgedAt"
        ]

        notificationInfo.category =
            "MAP_ACKNOWLEDGED"

        subscription.notificationInfo =
            notificationInfo

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
}
