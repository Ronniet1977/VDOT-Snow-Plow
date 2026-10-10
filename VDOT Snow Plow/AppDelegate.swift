//
//  AppDelegate.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import UIKit
import UserNotifications

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

    func userNotificationCenter(
        _ center:
            UNUserNotificationCenter,
        willPresent notification:
            UNNotification
    ) async
        -> UNNotificationPresentationOptions {

        NotificationCenter.default.post(
            name:
                .accessRequestNotificationReceived,
            object:
                nil
        )

        return [
            .banner,
            .sound,
            .badge
        ]
    }

    func userNotificationCenter(
        _ center:
            UNUserNotificationCenter,
        didReceive response:
            UNNotificationResponse
    ) async {

        NotificationCenter.default.post(
            name:
                .accessRequestNotificationReceived,
            object:
                nil
        )
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
}

extension Notification.Name {

    static let accessRequestNotificationReceived =
        Notification.Name(
            "accessRequestNotificationReceived"
        )
}
