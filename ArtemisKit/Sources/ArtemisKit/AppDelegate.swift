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
import Navigation
import Common

public class AppDelegate: UIResponder, UIApplicationDelegate {

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        registerForPushNotifications()
        return true
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    private func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
    }
}

// MARK: Extension for Push Notifications
extension AppDelegate: UNUserNotificationCenterDelegate {
    public func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task {
            await PushNotificationServiceFactory.shared.register(deviceToken: String(deviceToken: deviceToken))
        }
        log.info("Device Token: \(String(deviceToken: deviceToken))")
    }

    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        UserSessionFactory.shared.saveNotificationDeviceConfiguration(token: nil, encryptionKey: nil, skippedNotifications: true)
        log.error("Did Fail To Register For Remote Notifications With Error: \(error)")
    }

    // important to set the 'content_available' field, otherwise the method wont be called in the background
    public func application(
        _ application: UIApplication,
        didReceiveRemoteNotification payload: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
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

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        guard let targetURL = PushNotificationResponseHandler.getTarget(userInfo: userInfo) else {
            log.error("Could not handle click on push notification!")
            completionHandler()
            return
        }

        DeeplinkHandler.shared.handle(path: targetURL)

        // update app badge count
        UNUserNotificationCenter.current().setBadgeCount(UIApplication.shared.applicationIconBadgeNumber + 1)

        // maybe add as param in handle above
        completionHandler()
    }

    /// Workaround for login screen being shown too often
    /// Forces RootViewModel to refresh its login status
    public func reloadLoginStatus() {
        UserSessionFactory.shared.objectWillChange.send()
    }
}

// Define initializer
private extension String {
    init(deviceToken: Data) {
        self = deviceToken.map { String(format: "%.2hhx", $0) }.joined()
    }
}
