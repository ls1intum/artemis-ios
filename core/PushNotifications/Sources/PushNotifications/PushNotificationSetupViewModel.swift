//
//  File.swift
//  
//
//  Created by Sven Andabaka on 11.03.23.
//

import Foundation
import Common
import UserStore
import UIKit

@MainActor
class PushNotificationSetupViewModel: ObservableObject {

    func register() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .badge, .alert])

            guard granted else { return }
            // 2. Attempt registration for remote notifications on the main thread
            UIApplication.shared.registerForRemoteNotifications()
        } catch {
            log.error("Error registering for remote notification", error.localizedDescription)
        }
    }

    func skip() {
        UserSession.shared.saveNotificationDeviceConfiguration(token: nil, encryptionKey: nil, skippedNotifications: true)
    }
}
