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
        let server = ServerModel(host: host)
        context.insert(server)
        return server
    }

    func fetchServer(host: String) throws -> ServerModel? {
        let predicate = #Predicate<ServerModel> {
            $0.host == host
        }
        let servers = try context.fetch(FetchDescriptor(predicate: predicate))
        return servers.first
    }

    // MARK: - Course

    @discardableResult
    func insertCourse(host: String, courseId: Int) throws -> CourseModel {
        let server = try fetchServer(host: host) ?? insertServer(host: host)
        let course = CourseModel(server: server, courseId: courseId)
        context.insert(course)
        return course
    }

    func fetchCourse(host: String, courseId: Int) throws -> CourseModel? {
        let predicate = #Predicate<CourseModel> {
            $0.server.host == host
            && $0.courseId == courseId
        }
        let servers = try context.fetch(FetchDescriptor(predicate: predicate))
        return servers.first
    }

    // MARK: - Conversation

    @discardableResult
    func insertConversation(host: String, courseId: Int, conversationId: Int, draft: String) throws -> ConversationModel {
        let course = try fetchCourse(host: host, courseId: courseId) ?? insertCourse(host: host, courseId: courseId)
        let conversation = ConversationModel(course: course, conversationId: conversationId, draft: draft)
        context.insert(conversation)
        return conversation
    }

    func fetchConversation(host: String, courseId: Int, conversationId: Int) throws -> ConversationModel? {
        let predicate = #Predicate<ConversationModel> {
            $0.course.server.host == host
            && $0.course.courseId == courseId
            && $0.conversationId == conversationId
        }
        let servers = try context.fetch(FetchDescriptor(predicate: predicate))
        return servers.first
    }
}
