//
//  File.swift
//  
//
//  Created by Sven Andabaka on 17.03.23.
//

import Foundation
import Common
import UserNotifications

@MainActor
class NotificationViewModel: ObservableObject {

    @Published var notifications: DataState<[Notification]> = .loading

    @Published var newNotificationCount = 0

    var lastNotificationSeenDate: Date? {
        didSet {
            UserDefaults.standard.set(lastNotificationSeenDate, forKey: "lastNotificationSeenDate")
            updateNewNotificationCount()
        }
    }

    init() {
        lastNotificationSeenDate = UserDefaults.standard.object(forKey: "lastNotificationSeenDate") as? Date

        Task {
            await loadNotifications()
        }

        // add observer to reload once new notification is received
        NotificationCenter.default.addObserver(self, selector: #selector(reloadNotifications),
                                               name: UserNotifications.Notification.Name("receivedNewNotification"),
                                               object: nil)
    }

    func subscribeToNotificationUpdates() async {
        let stream = NotificationWebsocketServiceFactory.shared.subscribeToNotifications()

        for await notification in stream {
            notifications.value?.append(notification)
            newNotificationCount += 1
        }
    }

    private func updateNewNotificationCount() {
        if let lastNotificationSeenDate {
            newNotificationCount = notifications.value?.filter {
                $0.notificationDate > lastNotificationSeenDate
            }.count ?? 0
        } else {
            newNotificationCount = notifications.value?.count ?? 0
        }
    }

    @objc
    func reloadNotifications() {
        Task {
            await loadNotifications()
        }
    }

    func loadNotifications() async {
        notifications = await NotificationServiceFactory.shared.loadNotifications(page: 0, size: 25)

        updateNewNotificationCount()
    }

    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: UserNotifications.Notification.Name("receivedNewNotification"),
                                                  object: nil)
    }
}
