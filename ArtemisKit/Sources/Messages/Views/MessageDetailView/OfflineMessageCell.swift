//
//  OfflineMessageCell.swift
//
//
//  Created by Nityananda Zbil on 08.03.24.
//

import Common
import Navigation
import SharedModels
import SwiftUI

@MainActor
struct OfflineMessageCellModelDelegate {
    let didSendConversationOfflineMessage: (ConversationOfflineMessageModel) async -> Void
}

@Observable
final class OfflineMessageCellModel {
    let course: Course
    let conversation: Conversation
    let message: ConversationOfflineMessageModel

    var inProgress: Task<Void, Error>?

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
//        isLoading = true
        let result = await messagesService.sendMessage(for: course.id, conversation: conversation, content: message.text)
        switch result {
        case .notStarted, .loading:
//            isLoading = false
            break
        case .success:
            await delegate.didSendConversationOfflineMessage(message)
//            delegate.scrollToId("bottom")
//            await delegate.loadMessages()
//            isLoading = false
        case .failure(let error):
//            isLoading = false
            break
//            #warning("SendMessageView keeps loading")
//            do {
//                if let host = userSession.institution?.baseURL?.host() {
//                    let conversation = try MessagesRepository.shared.fetchConversation(
//                        host: host, courseId: course.id, conversationId: Int(conversation.id)
//                    ) ?? MessagesRepository.shared.insertConversation(
//                        host: host, courseId: course.id, conversationId: Int(conversation.id), messageDraft: ""
//                    )
//                    offlineMessages.append(ConversationOfflineMessageModel(conversation: conversation, date: Date.now, text: text))
//                }
//            } catch {
//                log.error(error)
//                if let apiClientError = error as? APIClientError {
//                    delegate.presentError(UserFacingError(error: apiClientError))
//                } else {
//                    delegate.presentError(UserFacingError(title: error.localizedDescription))
//                }
//            }
        }
//        return result
    }
}

struct OfflineMessageCell: View {
    let viewModel: OfflineMessageCellModel
    let conversationViewModel: ConversationViewModel

    var body: some View {
        MessageCell(
            viewModel: conversationViewModel,
            message: Binding.constant(DataState<BaseMessage>.done(response: ConversationOfflineMessage(viewModel.message))),
            conversationPath: ConversationPath?.none,
            isHeaderVisible: true,
            retryButtonAction: {
                if let task = viewModel.inProgress {
                    log.info("In progress")
                } else {
                    viewModel.inProgress = Task {
                        await viewModel.sendMessage()
                    }
                }
            }
        )
        .task {
            await viewModel.sendMessage()
        }
    }
}
