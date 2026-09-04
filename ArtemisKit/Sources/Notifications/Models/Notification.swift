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
        // Custom decoding required for CoursePushNotification
        self.notification = try CoursePushNotification(from: decoder, typeKey: Keys.notificationType, parametersKey: Self.valuesKey(in: decoder))
    }

    /// Where the values of this notification are, which depends on the version of the server that sent it.
    ///
    /// Artemis 10.0 gives every notification type a payload of its own, so the values sit under `payload` and are
    /// declared rather than being flattened into a map of objects. Older servers only send `parameters`, and an
    /// install talks to whichever version its institution has deployed, so the shape is read from the response rather
    /// than assumed. A 10.0 server sends both while the released apps that read `parameters` are still in use.
    ///
    /// Note that this leaves `courseTitle` and `courseIconUrl` of the decoded notification empty on the new shape,
    /// where they are siblings of `payload` rather than part of it. Nothing on this screen reads them: the list
    /// belongs to one course already, and `communicationInfo`, the one place that does read them, builds from a push
    /// notification body, which keeps the flat shape its version pins it to.
    private static func valuesKey(in decoder: any Decoder) -> Keys {
        guard let container = try? decoder.container(keyedBy: Keys.self) else {
            return .parameters
        }
        return container.contains(.payload) ? .payload : .parameters
    }

    private enum Keys: String, CodingKey {
        case notificationType
        case courseId
        case parameters
        case payload
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
