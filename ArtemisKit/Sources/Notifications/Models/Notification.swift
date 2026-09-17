//
//  Notification.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 23.03.25.
//

import Foundation
import PushNotifications
import SharedModels

struct CourseNotification: Codable, Identifiable {
    let notificationType: CourseNotificationType
    let notificationId: Int
    let courseId: Int
    let creationDate: Date
    let category: NotificationCategory
    let status: NotificationStatus
    let notification: CoursePushNotification

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.notificationType = try container.decode(CourseNotificationType.self, forKey: .notificationType)
        self.notificationId = try container.decode(Int.self, forKey: .notificationId)
        self.courseId = try container.decode(Int.self, forKey: .courseId)
        self.creationDate = try container.decode(Date.self, forKey: .creationDate)
        self.category = try container.decode(NotificationCategory.self, forKey: .category)
        self.status = try container.decode(NotificationStatus.self, forKey: .status)
        // Which key the values arrive under depends on the version of the server that sent them, and
        // CoursePushNotification decides that for both this list and the push body so the two cannot drift apart.
        self.notification = try CoursePushNotification(from: decoder)
    }

    var id: Int { notificationId }
}

enum NotificationCategory: String, ConstantsEnum {
    case communication = "COMMUNICATION"
    case general = "GENERAL"
    case unknown
}

enum NotificationStatus: String, ConstantsEnum {
    case unseen = "UNSEEN"
    case seen = "SEEN"
    case unknown
}
