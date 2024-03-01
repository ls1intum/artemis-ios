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
        var url: URL

        // Assumes that a server assigns non-hierarchical IDs,
        // i.e., every conversation of every course has a unique ID, here `remoteId`.
        @Relationship(deleteRule: .cascade)
        var conversations: [Conversation]

        init(url: URL, conversations: [Conversation] = []) {
            self.url = url
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
