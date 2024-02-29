//
//  AnyRepository.swift
//  
//
//  Created by Nityananda Zbil on 28.02.24.
//

import Common
import Foundation
import SwiftData

@Model
final class InstitutionModel {
    @Attribute(.unique)
    var host: String

    @Relationship(deleteRule: .cascade)
    var conversations: [ConversationModel]

    init(host: String, conversations: [ConversationModel] = []) {
        self.host = host
        self.conversations = conversations
    }
}

@Model
final class ConversationModel {
    @Attribute(.unique)
    var remoteId: Int

    var draft: String

    init(
        remoteId: Int,
        draft: String = ""
    ) {
        self.remoteId = remoteId
        self.draft = draft
    }
}

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
        let container = try ModelContainer(for: InstitutionModel.self, configurations: configuration)
        self.container = container
    }
}

@MainActor
extension AnyRepository {
    func fetch(remoteId: Int) throws -> [ConversationModel] {
        try container.mainContext.fetch(FetchDescriptor<ConversationModel>(predicate: #Predicate {
            $0.remoteId == remoteId
        }))
    }

    func insert(institution: InstitutionModel) throws {
        container.mainContext.insert(institution)
        try container.mainContext.save()
    }

    func insert(conversation: ConversationModel) throws {
        container.mainContext.insert(conversation)
        try container.mainContext.save()
    }
}
