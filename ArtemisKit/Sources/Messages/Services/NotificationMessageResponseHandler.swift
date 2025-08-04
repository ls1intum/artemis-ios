//
//  NotificationMessageResponseHandler.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 22.02.25.
//

import PushNotifications
import SharedModels
import UserNotifications
import UserStore

public struct NotificationMessageResponseHandler {
    public static func handle(responseText: String, info: PushNotificationCommunicationInfo) {
        let courseId = info.courseId
        let channelId = Int64(info.channelId)
        let messageId = Int64(info.messageId)
        Task {
            var message = Message(id: messageId)
            message.conversation = .channel(conversation: .init(id: channelId))
            let result = await MessagesServiceFactory.shared.sendAnswerMessage(for: courseId,
                                                                               message: message,
                                                                               content: responseText)
            switch result {
            case .failure:
                // Save message to try again later in case of failure
                let host = UserSessionFactory.shared.institution?.baseURL?.host() ?? ""
                let repository = await MessagesRepository.shared
                _ = try? await repository.insertMessage(host: host,
                                                        courseId: courseId,
                                                        conversationId: Int(channelId),
                                                        messageId: Int(messageId),
                                                        answerMessageDraft: responseText)
                await repository.save()
            default:
                break
            }
        }
    }

    public static func muteChannel(info: PushNotificationCommunicationInfo) {
        let service = MessagesServiceFactory.shared
        Task {
            let courseId = info.courseId
            let channelId = info.channelId
            _ = await service.updateIsConversationMuted(for: courseId, and: Int64(channelId), isMuted: true)

            // Remove all notifications from muted channel
            let notifications = await UNUserNotificationCenter.current().deliveredNotifications()
            let notificationsForChannel = notifications.filter {
                PushNotificationResponseHandler.getConversationId(from: $0.request.content.userInfo) == channelId
            }.map { $0.request.identifier }

            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: notificationsForChannel)
        }
    }

    public static func saveMessage(info: PushNotificationCommunicationInfo) {
        let service = MessagesServiceFactory.shared
        Task {
            let messageId = info.messageId
            let type = info.isReply ? PostType.answer : PostType.post
            _ = await service.addSavedPost(with: Int64(messageId), of: type)
        }
    }
}
