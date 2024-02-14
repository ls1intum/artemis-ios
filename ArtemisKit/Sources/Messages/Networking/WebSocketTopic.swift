//
//  WebSocketTopic.swift
//
//
//  Created by Nityananda Zbil on 09.02.24.
//

enum WebSocketTopic {
    /// Makes a topic for notifications through course-wide channels.
    ///
    /// E.g., notifications for writing in a channel.
    static func makeChannelNotifications(courseId: Int) -> String {
        "/topic/metis/courses/\(courseId)"
    }

    /// Makes a topic for conversation notifications of a user.
    ///
    /// E.g., notifications for writing in a group chat.
    static func makeConversationNotifications(userId: Int64) -> String {
        "/topic/user/\(userId)/notifications/conversations"
    }

    // MARK: - User space

    /// Makes a topic for membership notifications of a user in a course.
    ///
    /// E.g., notifications for starting a group chat.
    static func makeConversationMembershipNotifications(courseId: Int, userId: Int64) -> String {
        "/user/topic/metis/courses/\(courseId)/conversations/user/\(userId)"
    }
}
