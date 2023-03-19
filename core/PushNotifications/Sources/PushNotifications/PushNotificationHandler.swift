//
//  PushNotificationHandler.swift
//  Artemis
//
//  Created by Sven Andabaka on 19.02.23.
//  Copyright © 2023 orgName. All rights reserved.
//

import Foundation
import Common
import UserNotifications

public class PushNotificationHandler {

    // swiftlint:disable identifier_name
    public static func handle(payload: String, iv: String) {
        log.verbose("Notification received with payload: \(payload)")

        guard let notification = PushNotificationEncrypter.decrypt(payload: payload, iv: iv) else {
            log.verbose("Notification could not be encrypted.")
            return
        }

        dispatchNotification(notification)

        // post local notification
        NotificationCenter.default.post(name: Notification.Name("receivedNewNotification"), object: nil)
    }

    private static func dispatchNotification(_ notification: PushNotification) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus != .authorized {
                log.error("Notifications are not allowed")
                return
            }
        }

        Task {
            let notification = await prepareNotification(notification)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil)

            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    log.error(error.localizedDescription)
                }
            }
        }
    }

    private static func prepareNotification(_ notification: PushNotification) async -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
//        content.categoryIdentifier = type.rawValue
        content.userInfo = [PushNotificationUserInfoKeys.target: notification.target,
                            PushNotificationUserInfoKeys.type: notification.type.rawValue]
        return content
    }
}

class PushNotificationUserInfoKeys {
    static var target = "target"
    static var type = "type"
}
