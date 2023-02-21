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

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        registerForPushNotifications()
        return true
    }

    private func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            // 1. Check to see if permission is granted
            guard granted else { return }
            // 2. Attempt registration for remote notifications on the main thread
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}

// MARK: Extension for Push Notifications
extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UserSession.shared.apnsDeviceToken = String(deviceToken: deviceToken)
        print(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        UserSession.shared.apnsDeviceToken = nil
        print(error)
    }

    // important to set the 'content_available' field, otherwise the method wont be called in the background
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification payload: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print(payload)

        defer {
            completionHandler(.newData)
        }

        guard let payloadString = payload["payload"] as? String,
              let iv = payload["iv"] as? String else {
            return
        }

        PushNotificationHandler.handle(payload: payloadString, iv: iv)
    }
}

// Define initializer
private extension String {
    init(deviceToken: Data) {
        self = deviceToken.map { String(format: "%.2hhx", $0) }.joined()
    }
}
