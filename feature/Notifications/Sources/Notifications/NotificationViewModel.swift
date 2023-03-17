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

    func loadNotifications() async {
        notifications = await NotificationServiceFactory.shared.loadNotifications(page: 0, size: 25)
    }
}
