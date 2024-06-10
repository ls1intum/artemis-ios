//
//  File.swift
//  
//
//  Created by Sven Andabaka on 17.03.23.
//

import Foundation
import Common
import UserNotifications
import UserStore

@MainActor
class NotificationViewModel: ObservableObject {

    @Published var notifications: DataState<[Notification]> = .loading

    @Published var newNotificationCount = 0

    private var lastNotificationSeenDate: Date? {
        didSet {
            UserDefaults.standard.set(lastNotificationSeenDate, forKey: "lastNotificationSeenDate")
            updateNewNotificationCount()
        }
    }

    init() {
        updateLastNotificationSeenDate()

        Task {
            await loadNotifications()
        }
    }

    func subscribeToNotificationUpdates() async {
        let stream = NotificationWebsocketServiceFactory.shared.subscribeToNotifications()

        for await notification in stream {
            notifications.value?.insert(notification, at: 0)
            newNotificationCount += 1
        }
    }

    private func updateLastNotificationSeenDate() {
        let userLastNotificationSeen = UserSessionFactory.shared.user?.lastNotificationRead
        let storedLastNotificationSeenDate = UserDefaults.standard.object(forKey: "lastNotificationSeenDate") as? Date

        if let userLastNotificationSeen,
           storedLastNotificationSeenDate == nil {
            self.lastNotificationSeenDate = userLastNotificationSeen
        } else if userLastNotificationSeen == nil,
                  let storedLastNotificationSeenDate {
            self.lastNotificationSeenDate = storedLastNotificationSeenDate
        } else if let userLastNotificationSeen,
                  let storedLastNotificationSeenDate {
            if storedLastNotificationSeenDate > userLastNotificationSeen {
                self.lastNotificationSeenDate = storedLastNotificationSeenDate
            } else {
                self.lastNotificationSeenDate = userLastNotificationSeen
            }
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

    func updateNotificationSeenDate() async {
        let result = await NotificationServiceFactory.shared.updateUserNotificationDate()

        switch result {
        case .notStarted, .loading:
            return
        case .success:
            lastNotificationSeenDate = .now
        case .failure(let error):
            log.error(error)
        }
    }
}
