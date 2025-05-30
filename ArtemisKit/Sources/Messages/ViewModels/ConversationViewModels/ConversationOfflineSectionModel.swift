//
//  ConversationOfflineSectionModel.swift
//
//
//  Created by Nityananda Zbil on 09.03.24.
//

import Common
import Foundation
import SharedModels

@MainActor
struct ConversationOfflineSectionModelDelegate {
    let didSendOfflineMessage: (ConversationOfflineMessageModel) async -> Void
}

@MainActor
@Observable
final class ConversationOfflineSectionModel {
    let course: Course
    let conversation: Conversation
    let message: ConversationOfflineMessageModel
    let messageQueue: ArraySlice<ConversationOfflineMessageModel>

    private(set) var task: Task<Void, Error>?
    private(set) var taskDidFail = false

    var retryButtonAction: (() -> Void)? {
        if taskDidFail {
            return {
                if self.task != nil {
                    log.verbose("In progress")
                } else {
                    self.task = Task {
                        await self.sendMessage()
                    }
                }
            }
        } else {
            return nil
        }
    }

    private let delegate: ConversationOfflineSectionModelDelegate
    private let messagesService: MessagesService

    init(
        course: Course,
        conversation: Conversation,
        message: ConversationOfflineMessageModel,
        messageQueue: ArraySlice<ConversationOfflineMessageModel>,
        delegate: ConversationOfflineSectionModelDelegate,
        messagesService: MessagesService = MessagesServiceFactory.shared
    ) {
        self.course = course
        self.conversation = conversation
        self.message = message
        self.messageQueue = messageQueue
        self.delegate = delegate
        self.messagesService = messagesService
    }

    func sendMessage() async {
        let result = await messagesService.sendMessage(for: course.id, conversation: conversation, content: message.text, hasForwardedMessages: nil)
        switch result {
        case .loading:
            break
        case .done:
            await delegate.didSendOfflineMessage(message)
        case .failure:
            taskDidFail = true
        }
    }
}
