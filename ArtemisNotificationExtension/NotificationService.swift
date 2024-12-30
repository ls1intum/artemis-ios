//
//  NotificationService.swift
//  ArtemisNotificationExtension
//
//  Created by Anian Schleyer on 14.11.24.
//  Copyright © 2024 TUM. All rights reserved.
//

import PushNotifications
import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard var bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        // Decrypt notification and deliver it
        let payload = bestAttemptContent.userInfo
        guard let payloadString = payload["payload"] as? String,
              let initVector = payload["iv"] as? String else {
            return
        }

        Task {
            bestAttemptContent = await PushNotificationHandler
                .extractNotification(from: payloadString, iv: initVector) ?? bestAttemptContent

            // Add communication notification info
            if let intent = await PushNotificationHandler.getCommunicationIntent(for: bestAttemptContent) {
                do {
                    let content = try bestAttemptContent.updating(from: intent)
                    contentHandler(content)
                    return
                } catch {
                    // Ignore error in case of failure and use previous best attempt content
                }
            }

            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler, let bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
