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

// MARK: - Server

extension MessagesRepository {
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
}

// MARK: - Conversation

extension MessagesRepository {
    @discardableResult
    func insertConversation(host: String, conversationId: Int, draft: String) throws -> ConversationModel {
        let server = try fetchServer(host: host) ?? insertServer(host: host)
        let conversation = ConversationModel(server: server, conversationId: conversationId, draft: draft)
        context.insert(conversation)
        return conversation
    }

    func fetchConversation(host: String, conversationId: Int) throws -> ConversationModel? {
        let predicate = #Predicate<ConversationModel> {
            $0.server.host == host
            &&
            $0.conversationId == conversationId
        }
        let servers = try context.fetch(FetchDescriptor(predicate: predicate))
        return servers.first
    }
}
