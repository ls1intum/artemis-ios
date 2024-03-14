//
//  MessageOfflineSectionModel.swift
//
//
//  Created by Nityananda Zbil on 14.03.24.
//

import Common
import Foundation
import SharedModels

@MainActor
struct MessageOfflineSectionModelDelegate {
    let didSendOfflineAnswer: (MessageOfflineAnswerModel) async -> Void
}

@MainActor
@Observable
final class MessageOfflineSectionModel {
    let course: Course
    let conversation: Conversation
    let message: Message
    let answer: MessageOfflineAnswerModel
    let answerQueue: ArraySlice<MessageOfflineAnswerModel>

    private(set) var task: Task<Void, Error>?
    private(set) var taskDidFail = false

    var retryButtonAction: (() -> Void)? {
        if taskDidFail {
            return {
                if self.task != nil {
                    log.verbose("In progress")
                } else {
                    self.task = Task {
                        await self.sendAnswer()
                    }
                }
            }
        } else {
            return nil
        }
    }

    private let delegate: MessageOfflineSectionModelDelegate
    private let messagesService: MessagesService

    init(
        course: Course,
        conversation: Conversation,
        message: Message,
        answer: MessageOfflineAnswerModel,
        answerQueue: ArraySlice<MessageOfflineAnswerModel>,
        delegate: MessageOfflineSectionModelDelegate,
        messagesService: MessagesService = MessagesServiceFactory.shared
    ) {
        self.course = course
        self.conversation = conversation
        self.message = message
        self.answer = answer
        self.answerQueue = answerQueue
        self.delegate = delegate
        self.messagesService = messagesService
    }

    func sendAnswer() async {
        let result = await messagesService.sendAnswerMessage(for: course.id, message: message, content: answer.text)
        switch result {
        case .notStarted, .loading:
            break
        case .success:
            await delegate.didSendOfflineAnswer(answer)
        case .failure:
            taskDidFail = true
        }
    }
}
