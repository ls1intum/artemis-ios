//
//  MessageDetailViewModel.swift
//
//
//  Created by Nityananda Zbil on 13.03.24.
//

import Common
import Foundation
import SharedModels
import UserStore

@MainActor
@Observable
final class MessageDetailViewModel {
    static let size = 50

    let course: Course
    let conversation: Conversation
    
    var message: Message
    var offlineAnswers: [MessageOfflineAnswerModel] = []
    var shouldScrollToId: String?

    fileprivate let messagesRepository: MessagesRepository
    private let messagesService: MessagesService
    private let userSession: UserSession

    init(
        course: Course,
        conversation: Conversation,
        message: Message,
        messagesService: MessagesService = MessagesServiceFactory.shared,
        messagesRepository: MessagesRepository = .shared,
        userSession: UserSession = .shared
    ) {
        self.course = course
        self.conversation = conversation
        self.message = message
        self.messagesService = messagesService
        self.messagesRepository = messagesRepository
        self.userSession = userSession
    }

    func loadMessage() async {
        let result = await messagesService.getMessage(
            courseId: course.id,
            conversationId: conversation.id,
            messageId: message.id,
            size: Self.size)
        switch result {
        case let .done(response: message):
            self.message = message
        case let .failure(error: error):
            log.error(error)
        case .loading:
            break
        }
    }

    func sendAnswerMessage(text: String) async {
        if let host = userSession.institution?.baseURL?.host() {
            do {
                let offlineAnswer = try messagesRepository.insertMessageOfflineAnswer(
                    host: host,
                    courseId: course.id,
                    conversationId: Int(conversation.id),
                    messageId: Int(message.id),
                    date: .now,
                    text: text)
                offlineAnswers.append(offlineAnswer)
            } catch {
                log.error(error)
            }
        } else {
            log.verbose("Host is nil")
        }
    }
}

private extension MessageDetailViewModel {
    func fetchOfflineAnswers() {
        if let host = userSession.institution?.baseURL?.host() {
            do {
                self.offlineAnswers = try messagesRepository.fetchMessageOfflineAnswers(
                    host: host, courseId: course.id, conversationId: Int(conversation.id), messageId: Int(message.id)
                )
            } catch {
                log.error(error)
            }
        } else {
            log.verbose("Host is nil")
        }
    }
}

// MARK: - MessageDetailViewModel+MessageOfflineSectionModelDelegate

extension MessageOfflineSectionModelDelegate {
    init(_ messageDetailViewModel: MessageDetailViewModel) {
        self.didSendOfflineAnswer = { answer in
            if let index = messageDetailViewModel.offlineAnswers.firstIndex(of: answer) {
                let answer = messageDetailViewModel.offlineAnswers.remove(at: index)
                messageDetailViewModel.messagesRepository.delete(messageOfflineAnswer: answer)
            }
        }
    }
}
