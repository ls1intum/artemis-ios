//
//  AnyRepository.swift
//  
//
//  Created by Nityananda Zbil on 28.02.24.
//

import Common
import Foundation
import SwiftData

@MainActor
final class AnyRepository {
    static let shared: AnyRepository = {
        do {
            return try AnyRepository()
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

extension AnyRepository {
    func fetch(remoteId: Int) throws -> [SchemaConversation] {
        try context.fetch(
            FetchDescriptor<SchemaConversation>(predicate: #Predicate {
                $0.remoteId == remoteId
            })
        )
    }

    func insert(institution: SchemaServer) throws {
        context.insert(institution)
    }

    func insert(conversation: SchemaConversation) throws {
        context.insert(conversation)
    }
}
