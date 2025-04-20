//
//  NotificationService.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 23.03.25.
//

import Common

protocol NotificationService {
    /**
     * Load notifications for the given course from the server.
     */
    func loadNotifications(courseId: Int, page: Int, size: Int) async -> DataState<[CourseNotification]>
}

enum NotificationServiceFactory {

    static let shared: NotificationService = NotificationServiceImpl()
}
