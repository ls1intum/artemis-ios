//
//  AppDelegate.swift
//  Artemis
//
//  Created by Sven Andabaka on 16.02.23.
//  Copyright © 2023 orgName. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import UserStore
import PushNotifications
import Common

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        registerForPushNotifications()
        return true
    }

    private func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self        
    }
}

// MARK: Extension for Push Notifications
extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task {
            await PushNotificationServiceFactory.shared.register(deviceToken: String(deviceToken: deviceToken))
        }
        log.info("Device Token: \(String(deviceToken: deviceToken))")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        UserSession.shared.saveNotificationDeviceConfiguration(token: nil, encryptionKey: nil, skippedNotifications: true)
        log.error("Did Fail To Register For Remote Notifications With Error: \(error)")
    }

    // important to set the 'content_available' field, otherwise the method wont be called in the background
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification payload: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        log.debug(payload)

        defer {
            completionHandler(.newData)
        }

        guard let payloadString = payload["payload"] as? String,
              let initVector = payload["iv"] as? String else {
            return
        }

        PushNotificationHandler.handle(payload: payloadString, iv: initVector)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }
}

// Define initializer
private extension String {
    init(deviceToken: Data) {
        self = deviceToken.map { String(format: "%.2hhx", $0) }.joined()
    }
}
