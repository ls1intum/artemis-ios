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
        let container = try ModelContainer(for: Schema.Institution.self, configurations: configuration)
        self.container = container
    }
}

@MainActor
extension AnyRepository {
    func fetch(remoteId: Int) throws -> [Schema.Conversation] {
        try container.mainContext.fetch(FetchDescriptor<Schema.Conversation>(predicate: #Predicate {
            $0.remoteId == remoteId
        }))
    }

    func insert(institution: Schema.Institution) throws {
        container.mainContext.insert(institution)
        try container.mainContext.save()
    }

    func insert(conversation: Schema.Conversation) throws {
        container.mainContext.insert(conversation)
        try container.mainContext.save()
    }
}
