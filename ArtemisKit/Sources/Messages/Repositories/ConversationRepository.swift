//
//  ConversationRepository.swift
//
//
//  Created by Nityananda Zbil on 28.02.24.
//

import Common
import Foundation
import SwiftData

@MainActor
final class ConversationRepository {
    static let shared: ConversationRepository = {
        do {
            return try ConversationRepository()
        } catch {
            log.error(error)
            fatalError("Failed to initialize repository")
        }
    }()

    private let context: ModelContext

    init() throws {
        let schema = Schema([SchemaServer.self, SchemaConversation.self])
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

extension ConversationRepository {
    func fetch(remoteId: Int) throws -> [SchemaConversation] {
        let predicate = #Predicate<SchemaConversation> {
            $0.remoteId == remoteId
        }
        return try context.fetch(FetchDescriptor(predicate: predicate))
    }

    func insert(institution: SchemaServer) throws {
        context.insert(institution)
    }

    func insert(conversation: SchemaConversation) throws {
        context.insert(conversation)
    }
}
