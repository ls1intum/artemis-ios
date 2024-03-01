//
//  AnyRepository.swift
//  
//
//  Created by Nityananda Zbil on 28.02.24.
//

import Common
import Foundation
import SwiftData

final class AnyRepository {
    static let shared: AnyRepository = {
        do {
            return try AnyRepository()
        } catch {
            log.error(error)
            fatalError("Failed to initialize repository")
        }
    }()

    let container: ModelContainer

    init() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SchemaInstitution.self, configurations: configuration)
        self.container = container
    }

    deinit {
        Task { @MainActor in
            do {
                try container.mainContext.save()
            } catch {
                log.error(error)
            }
        }
    }
}

@MainActor
extension AnyRepository {
    func fetch(remoteId: Int) throws -> [SchemaConversation] {
        try container.mainContext.fetch(
            FetchDescriptor<SchemaConversation>(predicate: #Predicate {
                $0.remoteId == remoteId
            })
        )
    }

    func insert(institution: SchemaInstitution) throws {
        container.mainContext.insert(institution)
    }

    func insert(conversation: SchemaConversation) throws {
        container.mainContext.insert(conversation)
    }
}
