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

extension ConversationRepository {
    func fetch(remoteId: Int) throws -> [ConversationModel] {
        let predicate = #Predicate<ConversationModel> {
            $0.remoteId == remoteId
        }
        return try context.fetch(FetchDescriptor(predicate: predicate))
    }

    func insert(institution: ServerModel) throws {
        context.insert(institution)
    }

    func insert(conversation: ConversationModel) throws {
        context.insert(conversation)
    }
}
