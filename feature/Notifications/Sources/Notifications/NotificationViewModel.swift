//
//  File.swift
//  
//
//  Created by Sven Andabaka on 17.03.23.
//

import Foundation
import Common

@MainActor
class NotificationViewModel: ObservableObject {

    @Published var notifications: DataState<[Notification]> = .loading

    @Published var newNotificationCount = 0

    var lastNotificationSeenDate: Date? {
        didSet {
            UserDefaults.standard.set(lastNotificationSeenDate, forKey: "lastNotificationSeenDate")
        }
    }

    init() {
        lastNotificationSeenDate = UserDefaults.standard.object(forKey: "lastNotificationSeenDate") as? Date
        Task {
            await loadNotifications()
        }
    }

    func loadNotifications() async {
        notifications = await NotificationServiceFactory.shared.loadNotifications(page: 0, size: 25)

        if let lastNotificationSeenDate {
            newNotificationCount = notifications.value?.filter {
                $0.notificationDate > lastNotificationSeenDate
            }.count ?? 0
        } else {
            newNotificationCount = notifications.value?.count ?? 0
        }
    }
}
