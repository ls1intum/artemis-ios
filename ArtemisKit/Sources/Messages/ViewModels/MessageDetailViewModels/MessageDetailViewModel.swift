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
    let course: Course
    let conversation: Conversation
    let message: Message

    var offlineAnswers: [MessageOfflineAnswerModel] = []

    fileprivate let messagesRepository: MessagesRepository
    private let userSession: UserSession

    init(
        course: Course,
        conversation: Conversation,
        message: Message,
        messagesRepository: MessagesRepository = .shared,
        userSession: UserSession = .shared
    ) {
        self.course = course
        self.conversation = conversation
        self.message = message
        self.messagesRepository = messagesRepository
        self.userSession = userSession
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
