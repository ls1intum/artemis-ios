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
        [Server.self, Course.self, Conversation.self]
    }

    @Model
    final class Server {
        @Attribute(.unique)
        var host: String

        @Relationship(deleteRule: .cascade, inverse: \Course.server)
        var courses: [Course]

        init(host: String, courses: [Course] = []) {
            self.host = host
            self.courses = courses
        }
    }

    @Model
    final class Course {
        var server: Server

        @Attribute(.unique)
        var courseId: Int

        @Relationship(deleteRule: .cascade, inverse: \Conversation.course)
        var conversations: [Conversation]

        init(server: Server, courseId: Int, conversations: [Conversation] = []) {
            self.server = server
            self.courseId = courseId
            self.conversations = conversations
        }
    }

    @Model
    final class Conversation {
        var course: Course

        @Attribute(.unique)
        var conversationId: Int

        /// A user's draft of a message, which they began to compose.
        var draft: String

        init(course: Course, conversationId: Int, draft: String = "") {
            self.course = course
            self.conversationId = conversationId
            self.draft = draft
        }
    }
}
