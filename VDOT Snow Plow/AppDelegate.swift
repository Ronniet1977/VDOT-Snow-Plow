//
//  AppDelegate.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import UIKit
import UserNotifications
import CloudKit

final class AppDelegate:
    NSObject,
    UIApplicationDelegate,
    UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        UNUserNotificationCenter
            .current()
            .delegate = self

        application
            .registerForRemoteNotifications()

        return true
    }
    
    // willPresent

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {

        let category =
            notification.request
                .content
                .categoryIdentifier
        
        let userInfo =
            notification.request
                .content
                .userInfo

        if let cloudNotification =
            CKNotification(
                fromRemoteNotificationDictionary:
                    userInfo
            ),
           let queryNotification =
            cloudNotification
                as? CKQueryNotification {

            print(
                "☁️ PUSH RECORD ID:",
                queryNotification.recordID?
                    .recordName
                    ?? "none"
            )

            print(
                "☁️ PUSH REASON:",
                queryNotification.queryNotificationReason
                    .rawValue
            )
        }

        switch category {

        case "MAP_ACKNOWLEDGED":

            print(
                "📩 Map acknowledgement push received"
            )

            NotificationCenter.default.post(
                name:
                    .mapAcknowledgementNotificationReceived,
                object:
                    nil
            )

        case "MAP_ASSIGNED":

            print(
                "📩 Map assignment push received"
            )

            NotificationCenter.default.post(
                name:
                    .mapAssignmentNotificationReceived,
                object:
                    nil
            )

        case "ACCESS_REQUEST":

            print(
                "📩 Access request push received"
            )

            NotificationCenter.default.post(
                name:
                    .accessRequestNotificationReceived,
                object:
                    nil
            )
            
        case "USER_ROLE_CHANGED":

            print(
                "📩 User role change push received"
            )

            NotificationCenter.default.post(
                name:
                    .userRoleChangedNotificationReceived,
                object:
                    nil
            )
            
        case "MAP_REVIEW_REQUEST":

            print(
                "📩 Map review request push received"
            )

            NotificationCenter.default.post(
                name:
                    .mapReviewRequestNotificationReceived,
                object:
                    nil
            )
            
        case "MAP_REVIEW_INSPECTION":

            print(
                "📩 Map review inspection push received"
            )

            NotificationCenter.default.post(
                name:
                    .mapReviewInspectionNotificationReceived,
                object:
                    nil
            )
            
        case "MAP_DRAWING_CHANGED":

            print(
                "📩 Shared map drawing push received"
            )

            NotificationCenter.default.post(
                name:
                    .mapDrawingChangedNotificationReceived,
                object:
                    nil
            )
            
        case "MAP_ASSIGNMENT_CHANGED":

            print(
                "📩 Map assignment change push received"
            )

            NotificationCenter.default.post(
                name:
                    .mapAssignmentChangedNotificationReceived,
                object:
                    nil
            )
            
        case "USER_ROLE_ASSIGNMENT_CHANGED":

            print(
                "📩 User role assignment push received"
            )

            NotificationCenter.default.post(
                name:
                    .userRoleAssignmentChangedNotificationReceived,
                object:
                    nil
            )

        default:

            print(
                "📩 Unknown notification category:",
                category
            )
        }

        return [
            .banner,
            .sound,
            .badge
        ]
    }
    
    // notification-tap handler

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {

        let category =
            response.notification
                .request
                .content
                .categoryIdentifier

        switch category {

        case "MAP_ACKNOWLEDGED":

            print(
                "📩 Tapped map acknowledgement notification"
            )

            NotificationCenter.default.post(
                name:
                    .mapAcknowledgementNotificationReceived,
                object:
                    nil
            )

        case "MAP_ASSIGNED":

            print(
                "📩 Tapped map assignment notification"
            )

            NotificationCenter.default.post(
                name:
                    .mapAssignmentNotificationReceived,
                object:
                    nil
            )

        case "ACCESS_REQUEST":

            print(
                "📩 Tapped access request notification"
            )

            NotificationCenter.default.post(
                name:
                    .accessRequestNotificationReceived,
                object:
                    nil
            )
            
        case "USER_ROLE_CHANGED":

            print(
                "📩 Tapped user role change notification"
            )

            NotificationCenter.default.post(
                name:
                    .userRoleChangedNotificationReceived,
                object:
                    nil
            )
            
        case "MAP_REVIEW_REQUEST":

            print(
                "📩 Map review request push received"
            )

            NotificationCenter.default.post(
                name:
                    .mapReviewRequestNotificationReceived,
                object:
                    nil
            )
            
        case "MAP_REVIEW_INSPECTION":

            print(
                "📩 Tapped map review inspection notification"
            )

            NotificationCenter.default.post(
                name:
                    .mapReviewInspectionNotificationReceived,
                object:
                    nil
            )
            
        case "MAP_DRAWING_CHANGED":

            print(
                "📩 Tapped shared map drawing notification"
            )

            NotificationCenter.default.post(
                name:
                    .mapDrawingChangedNotificationReceived,
                object:
                    nil
            )
            
        case "MAP_ASSIGNMENT_CHANGED":

            NotificationCenter.default.post(
                name:
                    .mapAssignmentChangedNotificationReceived,
                object:
                    nil
            )
            
        case "USER_ROLE_ASSIGNMENT_CHANGED":

            print(
                "📩 User role assignment push received"
            )

            NotificationCenter.default.post(
                name:
                    .userRoleAssignmentChangedNotificationReceived,
                object:
                    nil
            )

        default:

            print(
                "📩 Tapped unknown notification category:",
                category
            )
        }
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {

        let token =
            deviceToken
                .map {
                    String(
                        format: "%02x",
                        $0
                    )
                }
                .joined()

        print(
            "📲 APNs registered:",
            token
        )
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {

        print(
            "❌ APNs registration failed:",
            error
        )
    }
    
    // background remote-notification switch
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo:
            [AnyHashable: Any],
        fetchCompletionHandler completionHandler:
            @escaping (UIBackgroundFetchResult) -> Void
    ) {

        let aps =
            userInfo["aps"]
                as? [String: Any]

        let category =
            aps?["category"]
                as? String

        switch category {

        case "MAP_ACKNOWLEDGED":

            print(
                "📩 Background map acknowledgement push"
            )

            NotificationCenter.default.post(
                name:
                    .mapAcknowledgementNotificationReceived,
                object:
                    nil
            )

        case "MAP_ASSIGNED":

            print(
                "📩 Background map assignment push"
            )

            NotificationCenter.default.post(
                name:
                    .mapAssignmentNotificationReceived,
                object:
                    nil
            )

        case "ACCESS_REQUEST":

            print(
                "📩 Background access request push"
            )

            NotificationCenter.default.post(
                name:
                    .accessRequestNotificationReceived,
                object:
                    nil
            )
            
        case "USER_ROLE_CHANGED":

            print(
                "📩 Background user role change push"
            )

            NotificationCenter.default.post(
                name:
                    .userRoleChangedNotificationReceived,
                object:
                    nil
            )
            
        case "MAP_REVIEW_REQUEST":

            print(
                "📩 Map review request push received"
            )

            NotificationCenter.default.post(
                name:
                    .mapReviewRequestNotificationReceived,
                object:
                    nil
            )
            
        case "MAP_REVIEW_INSPECTION":

            print(
                "📩 Background map review inspection push"
            )

            NotificationCenter.default.post(
                name:
                    .mapReviewInspectionNotificationReceived,
                object:
                    nil
            )
            
        case "MAP_DRAWING_CHANGED":

            print(
                "📩 Background shared map drawing push"
            )

            NotificationCenter.default.post(
                name:
                    .mapDrawingChangedNotificationReceived,
                object:
                    nil
            )
            
        case "MAP_ASSIGNMENT_CHANGED":

            print(
                "📩 Background map assignment change push"
            )

            NotificationCenter.default.post(
                name:
                    .mapAssignmentChangedNotificationReceived,
                object:
                    nil
            )
            
        case "USER_ROLE_ASSIGNMENT_CHANGED":

            print(
                "📩 User role assignment push received"
            )

            NotificationCenter.default.post(
                name:
                    .userRoleAssignmentChangedNotificationReceived,
                object:
                    nil
            )

        default:

            print(
                "📩 Background unknown notification category:",
                category ?? "none"
            )
        }

        completionHandler(
            .newData
        )
    }
}

extension Notification.Name {

    static let accessRequestNotificationReceived =
        Notification.Name(
            "accessRequestNotificationReceived"
        )

    static let mapAcknowledgementNotificationReceived =
        Notification.Name(
            "mapAcknowledgementNotificationReceived"
        )

    static let mapAssignmentNotificationReceived =
        Notification.Name(
            "mapAssignmentNotificationReceived"
        )
    
    static let userRoleChangedNotificationReceived =
        Notification.Name(
            "userRoleChangedNotificationReceived"
        )
    
    static let mapReviewRequestNotificationReceived =
        Notification.Name(
            "mapReviewRequestNotificationReceived"
        )
    
    static let mapReviewInspectionNotificationReceived =
        Notification.Name(
            "mapReviewInspectionNotificationReceived"
        )
    
    static let mapDrawingChangedNotificationReceived =
        Notification.Name(
            "mapDrawingChangedNotificationReceived"
        )
    
    static let mapAssignmentChangedNotificationReceived =
        Notification.Name(
            "mapAssignmentChangedNotificationReceived"
        )
    
    static let userRoleAssignmentChangedNotificationReceived =
        Notification.Name(
            "userRoleAssignmentChangedNotificationReceived"
        )
}
