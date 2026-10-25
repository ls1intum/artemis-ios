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
    struct DraftKey: Hashable {
        let host: String
        let courseId: Int
        let conversationId: Int
        var messageId: Int?
    }

    // Send operations and all repository instances run on MainActor. Revisions distinguish
    // a newly typed identical draft from the message already being sent, without a schema change.
    private static var draftRevisions: [DraftKey: UUID] = [:]
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

    init(timeoutInSeconds: Int = 24 * 60 * 60, inMemory: Bool = false) throws {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        self.container = try ModelContainer(for: schema, configurations: configuration)
        self.seconds = timeoutInSeconds
    }

    /// Saves the current state of the ModelContext/Container.
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
        let server = (try? fetchServer(host: host)) ?? ServerModel(host: host, lastAccessDate: .now)
        server.lastAccessDate = .now
        container.mainContext.insert(server)
        save()
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
        let course = try fetchCourse(host: host, courseId: courseId)
        ?? CourseModel(server: server, courseId: courseId)
        container.mainContext.insert(course)
        save()
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
        container.mainContext.insert(course)
        try touch(server: course.server)
        let conversation = try fetchConversation(host: host,
                                                 courseId: courseId,
                                                 conversationId: conversationId)
        ?? ConversationModel(course: course,
                             conversationId: conversationId,
                             messageDraft: "")
        // An explicit write represents new draft input even when this context's
        // registered model still contains the same value from an older snapshot.
        Self.draftRevisions[DraftKey(host: host, courseId: courseId, conversationId: conversationId)] = UUID()
        conversation.messageDraft = messageDraft
        container.mainContext.insert(conversation)
        save()
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
        try container.mainContext.save()
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
        container.mainContext.insert(conversation)
        try touch(server: conversation.course?.server)
        let message = try fetchMessage(host: host,
                                       courseId: courseId,
                                       conversationId: conversationId,
                                       messageId: messageId)
        ?? MessageModel(conversation: conversation,
                        messageId: messageId,
                        answerMessageDraft: "")
        Self.draftRevisions[DraftKey(host: host, courseId: courseId, conversationId: conversationId, messageId: messageId)] = UUID()
        message.answerMessageDraft = answerMessageDraft
        container.mainContext.insert(message)
        save()
        return message
    }

    func fetchMessage(host: String, courseId: Int, conversationId: Int, messageId: Int) throws -> MessageModel? {
        log.verbose("begin")
        try purge(host: host)
        let predicate = #Predicate<MessageModel> { message in
            if let conversation = message.conversation,
               let course = conversation.course {
                course.server?.host == host
                && course.courseId == courseId
                && conversation.conversationId == conversationId
                && message.messageId == messageId
            } else {
                false
            }
        }
        return try container.mainContext.fetch(FetchDescriptor(predicate: predicate)).first
    }

    // MARK: Message Offline Answer

    // swiftlint:disable function_parameter_count
    @discardableResult
    func insertMessageOfflineAnswer(
        host: String, courseId: Int, conversationId: Int, messageId: Int, date: Date, text: String
    ) throws -> MessageOfflineAnswerModel {
        log.verbose("begin")
        let message = try fetchMessage(host: host, courseId: courseId, conversationId: conversationId, messageId: messageId)
            ?? insertMessage(host: host, courseId: courseId, conversationId: conversationId, messageId: messageId, answerMessageDraft: "")
        try touch(server: message.conversation?.course?.server)
        let answer = MessageOfflineAnswerModel(message: message, date: date, text: text)
        container.mainContext.insert(answer)
        return answer
    }
    // swiftlint:enable function_parameter_count

    func fetchMessageOfflineAnswers(
        host: String, courseId: Int, conversationId: Int, messageId: Int
    ) throws -> [MessageOfflineAnswerModel] {
        log.verbose("begin")
        try purge(host: host)
        let predicate = #Predicate<MessageOfflineAnswerModel> { answer in
            if let conversation = answer.message.conversation,
               let course = conversation.course {
                course.server?.host == host
                && course.courseId == courseId
                && conversation.conversationId == conversationId
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
        // Remove messages that don't belong to any conversation anymore
        try container.mainContext.delete(model: MessageModel.self, where: #Predicate { message in
            message.conversation == nil
        })
        save()
    }
}

extension MessagesRepository {
    func draftRevision(for key: DraftKey) -> UUID? { Self.draftRevisions[key] }

    func currentDraft(for key: DraftKey) throws -> String {
        try purge(host: key.host)
        let fresh = ModelContext(container)
        let host = key.host
        let courseId = key.courseId
        let conversationId = key.conversationId
        if let messageId = key.messageId {
            let predicate = #Predicate<MessageModel> { message in
                if let conversation = message.conversation, let course = conversation.course {
                    course.server?.host == host && course.courseId == courseId
                    && conversation.conversationId == conversationId && message.messageId == messageId
                } else { false }
            }
            return try fresh.fetch(FetchDescriptor(predicate: predicate)).first?.answerMessageDraft ?? ""
        }
        let predicate = #Predicate<ConversationModel> { conversation in
            if let course = conversation.course {
                course.server?.host == host && course.courseId == courseId && conversation.conversationId == conversationId
            } else { false }
        }
        return try fresh.fetch(FetchDescriptor(predicate: predicate)).first?.messageDraft ?? ""
    }

    /// The comparison and write have no suspension point, so another in-app composer cannot intervene.
    func draftAfterSending(_ sentText: String, revision: UUID?, for key: DraftKey) throws -> String {
        let current = try currentDraft(for: key)
        let unchangedRevision = Self.draftRevisions[key] == revision
        let remaining = unchangedRevision && current == sentText ? "" : current
        // Also refresh a registered model in a retained repository with the surviving value.
        if let messageId = key.messageId {
            try fetchMessage(host: key.host, courseId: key.courseId, conversationId: key.conversationId,
                             messageId: messageId)?.answerMessageDraft = remaining
        } else {
            try fetchConversation(host: key.host, courseId: key.courseId, conversationId: key.conversationId)?.messageDraft = remaining
        }
        try container.mainContext.save()
        if unchangedRevision && current == sentText { Self.draftRevisions[key] = UUID() }
        return remaining
    }
}
