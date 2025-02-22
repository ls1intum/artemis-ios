//
//  NotificationMessageResponseHandler.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 22.02.25.
//

import PushNotifications
import SharedModels
import UserStore

public struct NotificationMessageResponseHandler {
    public static func handle(responseText: String, info: PushNotificationCommunicationInfo) {
        let courseId = info.courseId
        let channelId = Int64(info.channelId)
        let messageId = Int64(info.messageId) ?? 0
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
}
