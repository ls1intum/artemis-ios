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

    private let context: ModelContext

    init() throws {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        self.context = container.mainContext
    }

    deinit {
        do {
            try context.save()
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
        let server = ServerModel(host: host)
        context.insert(server)
        return server
    }

    func fetchServer(host: String) throws -> ServerModel? {
        log.verbose("begin")
        let predicate = #Predicate<ServerModel> { server in
            server.host == host
        }
        return try context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    // MARK: - Course

    @discardableResult
    func insertCourse(host: String, courseId: Int) throws -> CourseModel {
        log.verbose("begin")
        let server = try fetchServer(host: host) ?? insertServer(host: host)
        let course = CourseModel(server: server, courseId: courseId)
        context.insert(course)
        return course
    }

    func fetchCourse(host: String, courseId: Int) throws -> CourseModel? {
        log.verbose("begin")
        let predicate = #Predicate<CourseModel> { course in
            course.server.host == host
            && course.courseId == courseId
        }
        return try context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    // MARK: - Conversation

    @discardableResult
    func insertConversation(host: String, courseId: Int, conversationId: Int, messageDraft: String) throws -> ConversationModel {
        log.verbose("begin")
        let course = try fetchCourse(host: host, courseId: courseId) ?? insertCourse(host: host, courseId: courseId)
        let conversation = ConversationModel(course: course, conversationId: conversationId, messageDraft: messageDraft)
        context.insert(conversation)
        return conversation
    }

    func fetchConversation(host: String, courseId: Int, conversationId: Int) throws -> ConversationModel? {
        log.verbose("begin")
        let predicate = #Predicate<ConversationModel> { conversation in
            conversation.course.server.host == host
            && conversation.course.courseId == courseId
            && conversation.conversationId == conversationId
        }
        return try context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    // MARK: Conversation Offline Message

    @discardableResult
    func insertConversationOfflineMessage(
        host: String, courseId: Int, conversationId: Int, date: Date, text: String
    ) throws -> ConversationOfflineMessageModel {
        log.verbose("begin")
        let conversation = try fetchConversation(host: host, courseId: courseId, conversationId: conversationId)
        ?? insertConversation(host: host, courseId: courseId, conversationId: conversationId, messageDraft: "")
        let message = ConversationOfflineMessageModel(conversation: conversation, date: date, text: text)
        context.insert(message)
        return message
    }

    func fetchConversationOfflineMessages(
        host: String, courseId: Int, conversationId: Int
    ) throws -> [ConversationOfflineMessageModel] {
        log.verbose("begin")
        let predicate = #Predicate<ConversationOfflineMessageModel> { message in
            message.conversation.course.server.host == host
            && message.conversation.course.courseId == courseId
            && message.conversation.conversationId == conversationId
        }
        return try context.fetch(FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.date)]))
    }

    func delete(conversationOfflineMessage: ConversationOfflineMessageModel) {
        context.delete(conversationOfflineMessage)
    }

    // MARK: - Message

    @discardableResult
    func insertMessage(host: String, courseId: Int, conversationId: Int, messageId: Int, answerMessageDraft: String) throws -> MessageModel {
        log.verbose("begin")
        let conversation = try fetchConversation(host: host, courseId: courseId, conversationId: conversationId)
        ?? insertConversation(host: host, courseId: courseId, conversationId: conversationId, messageDraft: "")
        let message = MessageModel(conversation: conversation, messageId: messageId, answerMessageDraft: answerMessageDraft)
        context.insert(message)
        return message
    }

    func fetchMessage(host: String, courseId: Int, conversationId: Int, messageId: Int) throws -> MessageModel? {
        log.verbose("begin")
        let predicate = #Predicate<MessageModel> { message in
            message.conversation.course.server.host == host
            && message.conversation.course.courseId == courseId
            && message.conversation.conversationId == conversationId
            && message.messageId == messageId
        }
        return try context.fetch(FetchDescriptor(predicate: predicate)).first
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
        let answer = MessageOfflineAnswerModel(message: message, date: date, text: text)
        context.insert(answer)
        return answer
    }

    func fetchMessageOfflineAnswers(
        host: String, courseId: Int, conversationId: Int, messageId: Int
    ) throws -> [MessageOfflineAnswerModel] {
        log.verbose("begin")
        let predicate = #Predicate<MessageOfflineAnswerModel> { answer in
            answer.message.conversation.course.server.host == host
            && answer.message.conversation.course.courseId == courseId
            && answer.message.conversation.conversationId == conversationId
            && answer.message.messageId == messageId
        }
        return try context.fetch(FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.date)]))
    }

    func delete(messageOfflineAnswer: MessageOfflineAnswerModel) {
        context.delete(messageOfflineAnswer)
    }
}
