//
//  SchemaV1.swift
//  
//
//  Created by Nityananda Zbil on 29.02.24.
//

import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Institution.self, Conversation.self]
    }

    @Model
    final class Institution {
        @Attribute(.unique)
        var host: String

        @Relationship(deleteRule: .cascade)
        var conversations: [Conversation]

        init(host: String, conversations: [Conversation] = []) {
            self.host = host
            self.conversations = conversations
        }
    }

    @Model
    final class Conversation {
        @Attribute(.unique)
        var remoteId: Int

        var draft: String

        init(remoteId: Int, draft: String = "") {
            self.remoteId = remoteId
            self.draft = draft
        }
    }
}
