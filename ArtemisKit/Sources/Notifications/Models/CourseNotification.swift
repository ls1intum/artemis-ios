//
//  CourseNotification.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 23.03.25.
//

import Foundation
import PushNotifications
import SharedModels

struct CourseNotification: Codable {
    let notificationType: CourseNotificationType
    let notificationId: Int
    let courseId: Int
    let creationDate: Date
    let category: CourseNotificationCategory
    let status: CourseNotificationStatus
    let notification: CoursePushNotification

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.notificationType = try container.decode(CourseNotificationType.self, forKey: .notificationType)
        self.notificationId = try container.decode(Int.self, forKey: .notificationId)
        self.courseId = try container.decode(Int.self, forKey: .courseId)
        self.creationDate = try container.decode(Date.self, forKey: .creationDate)
        self.category = try container.decode(CourseNotificationCategory.self, forKey: .category)
        self.status = try container.decode(CourseNotificationStatus.self, forKey: .status)
        // Custom decoding required for CoursePushNotification
        self.notification = try CoursePushNotification(from: decoder, typeKey: Keys.notificationType, parametersKey: Keys.parameters)
    }

    private enum Keys: String, CodingKey {
        case notificationType
        case parameters
    }
}

enum CourseNotificationCategory: String, ConstantsEnum {
    case communication = "COMMUNICATION"
    case general = "GENERAL"
    case unknown
}

enum CourseNotificationStatus: String, ConstantsEnum {
    case unseen = "UNSEEN"
    case seen = "SEEN"
    case unknown
}
