//
//  SchemaV1.swift
//  
//
//  Created by Nityananda Zbil on 29.02.24.
//

import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Server.self, Conversation.self]
    }

    @Model
    final class Server {
        @Attribute(.unique)
        var host: String

        @Relationship(deleteRule: .cascade, inverse: \Conversation.server)
        var conversations: [Conversation]

        init(host: String, conversations: [Conversation] = []) {
            self.host = host
            self.conversations = conversations
        }
    }

    @Model
    final class Conversation {
        var server: Server

        // Assumes that a server assigns non-hierarchical IDs,
        // i.e., every conversation of every course has a unique ID, here `conversationId`.
        @Attribute(.unique)
        var conversationId: Int

        var draft: String

        init(server: Server, conversationId: Int, draft: String) {
            self.server = server
            self.conversationId = conversationId
            self.draft = draft
        }
    }
}
