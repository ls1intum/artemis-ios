import Foundation
import SharedModels

struct Notification: Codable {
    var id: Int
    let title: String
    let text: String?
    let notificationDate: Date
    let target: String
    let author: NotificationUser?
    let notificationType: NotificationType?
}

enum NotificationType: String, RawRepresentable, Codable {
    case system, connection, group, single, conversation
}

// we can't just use User.swift here because the authorities are having a different type (dictionary instead array) in notifications
struct NotificationUser: UserPublicInfo {
    var id: Int64
    var login: String?
    var name: String?
    var firstName: String?
    var lastName: String?
    var isInstructor: Bool?
    var isEditor: Bool?
    var isTeachingAssistant: Bool?
    var isStudent: Bool?
}

extension Notification: Identifiable { }
