//
//  MessagesRepository.swift
//
//
//  Created by Nityananda Zbil on 28.02.24.
//

import Common
import Foundation
import SwiftData

@MainActor
final class MessagesRepository {
    static let shared: MessagesRepository = {
        do {
            return try MessagesRepository()
        } catch {
            log.error(error)
            fatalError("Failed to initialize repository")
        }
    }()

    private let container: ModelContainer
    private let seconds: Int

    init(timeoutInSeconds: Int = 24 * 60 * 60) throws {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = ModelConfiguration(schema: schema)
        self.container = try ModelContainer(for: schema, configurations: configuration)
        self.seconds = timeoutInSeconds
    }

    /// Saves the current starte of the ModelContext/Container.
    /// Call this method before dismissing the View.
    func save() {
        do {
            try container.mainContext.save()
        } catch {
            log.error(error)
        }
    }
}

extension MessagesRepository {

    // MARK: - Server

    @discardableResult
    func insertServer(host: String) -> ServerModel {
        log.verbose("begin")
        let server = ServerModel(host: host, lastAccessDate: .now)
        container.mainContext.insert(server)
        return server
    }

    func fetchServer(host: String) throws -> ServerModel? {
        log.verbose("begin")
        try purge(host: host)
        let predicate = #Predicate<ServerModel> { server in
            server.host == host
        }
        return try container.mainContext.fetch(FetchDescriptor(predicate: predicate)).first
    }

    // MARK: - Course

    @discardableResult
    func insertCourse(host: String, courseId: Int) throws -> CourseModel {
        log.verbose("begin")
        let server = try fetchServer(host: host) ?? insertServer(host: host)
        try touch(server: server)
        let course = CourseModel(server: server, courseId: courseId)
        container.mainContext.insert(course)
        return course
    }

    func fetchCourse(host: String, courseId: Int) throws -> CourseModel? {
        log.verbose("begin")
        try purge(host: host)
        let predicate = #Predicate<CourseModel> { course in
            course.server?.host == host
            && course.courseId == courseId
        }
        return try container.mainContext.fetch(FetchDescriptor(predicate: predicate)).first
    }

    // MARK: - Conversation

    @discardableResult
    func insertConversation(host: String, courseId: Int, conversationId: Int, messageDraft: String) throws -> ConversationModel {
        log.verbose("begin")
        let course = try fetchCourse(host: host, courseId: courseId) ?? insertCourse(host: host, courseId: courseId)
        try touch(server: course.server)
        let conversation = try fetchConversation(host: host,
                                                 courseId: courseId,
                                                 conversationId: conversationId)
        ?? ConversationModel(course: course,
                             conversationId: conversationId,
                             messageDraft: "")
        conversation.messageDraft = messageDraft
        container.mainContext.insert(conversation)
        try container.mainContext.save()
        return conversation
    }

    func fetchConversation(host: String, courseId: Int, conversationId: Int) throws -> ConversationModel? {
        log.verbose("begin")
        try purge(host: host)
        let predicate = #Predicate<ConversationModel> { conversation in
            if let course = conversation.course {
                course.server?.host == host
                && course.courseId == courseId
                && conversation.conversationId == conversationId
            } else {
                false
            }
        }
        return try container.mainContext.fetch(FetchDescriptor(predicate: predicate)).first
    }

    // MARK: Conversation Offline Message

    @discardableResult
    func insertConversationOfflineMessage(
        host: String, courseId: Int, conversationId: Int, date: Date, text: String
    ) throws -> ConversationOfflineMessageModel {
        log.verbose("begin")
        let conversation = try fetchConversation(host: host, courseId: courseId, conversationId: conversationId)
            ?? insertConversation(host: host, courseId: courseId, conversationId: conversationId, messageDraft: "")
        try touch(server: conversation.course?.server)
        let message = ConversationOfflineMessageModel(conversation: conversation, date: date, text: text)
        container.mainContext.insert(message)
        return message
    }

    func fetchConversationOfflineMessages(
        host: String, courseId: Int, conversationId: Int
    ) throws -> [ConversationOfflineMessageModel] {
        log.verbose("begin")
        try purge(host: host)
        let predicate = #Predicate<ConversationOfflineMessageModel> { message in
            if let course = message.conversation.course {
                course.server?.host == host
                && course.courseId == courseId
                && message.conversation.conversationId == conversationId
            } else {
                false
            }
        }
        return try container.mainContext.fetch(FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.date)]))
    }

    func delete(conversationOfflineMessage: ConversationOfflineMessageModel) {
        container.mainContext.delete(conversationOfflineMessage)
    }

    // MARK: - Message

    @discardableResult
    func insertMessage(host: String, courseId: Int, conversationId: Int, messageId: Int, answerMessageDraft: String) throws -> MessageModel {
        log.verbose("begin")
        let conversation = try fetchConversation(host: host, courseId: courseId, conversationId: conversationId)
            ?? insertConversation(host: host, courseId: courseId, conversationId: conversationId, messageDraft: "")
        try touch(server: conversation.course?.server)
        let message = try fetchMessage(host: host,
                                       courseId: courseId,
                                       conversationId: conversationId,
                                       messageId: messageId)
        ?? MessageModel(conversation: conversation,
                        messageId: messageId,
                        answerMessageDraft: "")
        message.answerMessageDraft = answerMessageDraft
        container.mainContext.insert(message)
        try container.mainContext.save()
        return message
    }

    func fetchMessage(host: String, courseId: Int, conversationId: Int, messageId: Int) throws -> MessageModel? {
        log.verbose("begin")
        try purge(host: host)
        let predicate = #Predicate<MessageModel> { message in
            if let course = message.conversation.course {
                course.server?.host == host
                && course.courseId == courseId
                && message.conversation.conversationId == conversationId
                && message.messageId == messageId
            } else {
                false
            }
        }
        return try container.mainContext.fetch(FetchDescriptor(predicate: predicate)).first
    }

    // MARK: Message Offline Answer

    @discardableResult
    // swiftlint:disable:next function_parameter_count
    func insertMessageOfflineAnswer(
        host: String, courseId: Int, conversationId: Int, messageId: Int, date: Date, text: String
    ) throws -> MessageOfflineAnswerModel {
        log.verbose("begin")
        let message = try fetchMessage(host: host, courseId: courseId, conversationId: conversationId, messageId: messageId)
            ?? insertMessage(host: host, courseId: courseId, conversationId: conversationId, messageId: messageId, answerMessageDraft: "")
        try touch(server: message.conversation.course?.server)
        let answer = MessageOfflineAnswerModel(message: message, date: date, text: text)
        container.mainContext.insert(answer)
        return answer
    }

    func fetchMessageOfflineAnswers(
        host: String, courseId: Int, conversationId: Int, messageId: Int
    ) throws -> [MessageOfflineAnswerModel] {
        log.verbose("begin")
        try purge(host: host)
        let predicate = #Predicate<MessageOfflineAnswerModel> { answer in
            if let course = answer.message.conversation.course {
                course.server?.host == host
                && course.courseId == courseId
                && answer.message.conversation.conversationId == conversationId
                && answer.message.messageId == messageId
            } else {
                false
            }
        }
        return try container.mainContext.fetch(FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.date)]))
    }

    func delete(messageOfflineAnswer: MessageOfflineAnswerModel) {
        container.mainContext.delete(messageOfflineAnswer)
    }

    // - Cache Invalidation

    func touch(server: ServerModel?) throws {
        log.verbose("begin")
        server?.lastAccessDate = .now
    }

    func purge(host: String) throws {
        log.verbose("begin")
        try container.mainContext.enumerate(FetchDescriptor<ServerModel>()) { server in
            if server.host == host {
                let date = Calendar.current.date(byAdding: .second, value: seconds, to: server.lastAccessDate) ?? .now

                if date < .now {
                    container.mainContext.delete(server)
                }
            } else {
                container.mainContext.delete(server)
            }
        }
    }
}
