//
//  OfflineMessageCellModel.swift
//
//
//  Created by Nityananda Zbil on 09.03.24.
//

import Common
import Foundation
import SharedModels

@MainActor
struct OfflineMessageCellModelDelegate {
    let didSendConversationOfflineMessage: (ConversationOfflineMessageModel) async -> Void
}

@Observable
final class OfflineMessageCellModel {
    let course: Course
    let conversation: Conversation
    let message: ConversationOfflineMessageModel

    var task: Task<Void, Error>?
    var taskDidFail = false

    var retryButtonAction: (() -> Void)? {
        if taskDidFail {
            return nil
        } else {
            return {
                if let task = self.task {
                    log.verbose("In progress")
                } else {
                    self.task = Task {
                        await self.sendMessage()
                    }
                }
            }
        }
    }

    private let delegate: OfflineMessageCellModelDelegate
    private let messagesService: MessagesService

    init(
        course: Course,
        conversation: Conversation,
        message: ConversationOfflineMessageModel,
        delegate: OfflineMessageCellModelDelegate,
        messagesService: MessagesService = MessagesServiceFactory.shared
    ) {
        self.course = course
        self.conversation = conversation
        self.message = message

        self.delegate = delegate
        self.messagesService = messagesService
    }

    func sendMessage() async {
        let result = await messagesService.sendMessage(for: course.id, conversation: conversation, content: message.text)
        switch result {
        case .notStarted, .loading:
            break
        case .success:
            await delegate.didSendConversationOfflineMessage(message)
        case .failure:
            taskDidFail = true
        }
    }
}
