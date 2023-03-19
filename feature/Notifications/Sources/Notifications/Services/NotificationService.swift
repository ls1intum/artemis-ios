//
//  NotificationService.swift
//  
//
//  Created by Sven Andabaka on 17.03.23.
//

import Foundation
import Common

protocol NotificationService {
    /**
     * Load the notifications from the specified server using the specified authentication data.
     */
    func loadNotifications(page: Int, size: Int) async -> Common.DataState<[Notification]>
}

enum NotificationServiceFactory {

    static let shared: NotificationService = NotificationServiceImpl()
}
