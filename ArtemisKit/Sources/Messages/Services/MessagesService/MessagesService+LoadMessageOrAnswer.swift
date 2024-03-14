//
//  MessagesService+LoadMessageOrAnswer.swift
//
//
//  Created by Nityananda Zbil on 14.03.24.
//

import Common
import SharedModels

extension MessagesService {
    // TODO: add API to only load one single message
    func getMessage(courseId: Int, conversationId: Int64, messageId: Int64, size: Int) async -> DataState<Message> {
        let result = await getMessages(for: courseId, and: conversationId, size: size)
        return result.flatMap { messages in
            guard let message = messages.first(where: { $0.id == messageId }) else {
                return .failure(UserFacingError(title: R.string.localizable.messageCouldNotBeLoadedError()))
            }
            return .success(message)
        }
    }

    // TODO: add API to only load one single answer message
    func getAnswerMessage(courseId: Int, conversationId: Int64, answerMessageId: Int64, size: Int) async -> DataState<AnswerMessage> {
        let result = await getMessages(for: courseId, and: conversationId, size: size)
        return result.flatMap { messages in
            guard let message = messages.first(where: { $0.answers?.contains(where: { $0.id == answerMessageId }) ?? false }),
                  let answerMessage = message.answers?.first(where: { $0.id == answerMessageId }) else {
                return .failure(UserFacingError(title: R.string.localizable.messageCouldNotBeLoadedError()))
            }
            return .success(answerMessage)
        }
    }
}
