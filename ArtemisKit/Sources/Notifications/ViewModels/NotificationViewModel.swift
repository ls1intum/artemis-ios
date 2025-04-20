//
//  NotificationViewModel.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 23.03.25.
//

import Common
import DesignLibrary
import SwiftUI

@Observable
class NotificationViewModel {
    let courseId: Int

    var notifications: DataState<[CourseNotification]> = .loading
    var filteredNotifications: [CourseNotification] {
        notifications.value?.filter { filter.matches($0) } ?? []
    }

    var filter: NotificationFilter = .communication

    init(courseId: Int) {
        self.courseId = courseId
    }

    func loadNotifications() async {
        let service = NotificationServiceFactory.shared
        notifications = await service.loadNotifications(courseId: courseId, page: 0, size: 20)
    }
}

enum NotificationFilter: FilterPicker {
    case general, communication

    var displayName: String {
        switch self {
        case .general:
            R.string.localizable.general()
        case .communication:
            R.string.localizable.communication()
        }
    }

    var iconName: String {
        switch self {
        case .general:
            "bell"
        case .communication:
            "bubble"
        }
    }

    var selectedColor: Color {
        switch self {
        case .general:
            .green
        case .communication:
            .blue
        }
    }

    var id: Self { self }

    func matches(_ notification: CourseNotification) -> Bool {
        switch self {
        case .general:
            notification.category == .general
        case .communication:
            notification.category == .communication
        }
    }
}
