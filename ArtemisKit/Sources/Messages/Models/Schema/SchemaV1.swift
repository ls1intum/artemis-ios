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
        [
            Server.self,
            Course.self,
            Conversation.self,
            ConversationOfflineMessage.self,
            Message.self,
            MessageOfflineAnswer.self
        ]
    }

    @Model
    final class Server {
        @Attribute(.unique)
        var host: String

        var lastAccessDate: Date

        @Relationship(deleteRule: .cascade)
        var courses: [Course]

        init(host: String, lastAccessDate: Date, courses: [Course] = []) {
            self.host = host
            self.lastAccessDate = lastAccessDate
            self.courses = courses
        }
    }

    @Model
    final class Course {
        var server: Server?

        @Attribute(.unique)
        var courseId: Int

        @Relationship(deleteRule: .cascade)
        var conversations: [Conversation]

        init(server: Server, courseId: Int, conversations: [Conversation] = []) {
            self.server = server
            self.courseId = courseId
            self.conversations = conversations
        }
    }

    // MARK: Conversation

    @Model
    final class Conversation {
        var course: Course?

        @Attribute(.unique)
        var conversationId: Int

        @Relationship(deleteRule: .cascade, inverse: \ConversationOfflineMessage.conversation)
        var offlineMessages: [ConversationOfflineMessage]

        /// A user's draft of a message, which they began to compose.
        var messageDraft: String

        init(
            course: Course,
            conversationId: Int,
            offlineMessages: [ConversationOfflineMessage] = [],
            messageDraft: String = ""
        ) {
            self.course = course
            self.conversationId = conversationId
            self.offlineMessages = offlineMessages
            self.messageDraft = messageDraft
        }
    }

    @Model
    final class ConversationOfflineMessage {
        var conversation: Conversation

        var date: Date
        var text: String

        init(conversation: Conversation, date: Date, text: String) {
            self.conversation = conversation
            self.date = date
            self.text = text
        }
    }

    // MARK: Message

    @Model
    final class Message {
        var conversation: Conversation?

        @Attribute(.unique)
        var messageId: Int

        @Relationship(deleteRule: .cascade, inverse: \MessageOfflineAnswer.message)
        var offlineAnswers: [MessageOfflineAnswer]

        /// A user's draft of an answer message, which they began to compose.
        var answerMessageDraft: String

        init(
            conversation: Conversation?,
            messageId: Int,
            offlineAnswers: [MessageOfflineAnswer] = [],
            answerMessageDraft: String = ""
        ) {
            self.conversation = conversation
            self.messageId = messageId
            self.offlineAnswers = offlineAnswers
            self.answerMessageDraft = answerMessageDraft
        }
    }

    @Model
    final class MessageOfflineAnswer {
        var message: Message

        var date: Date
        var text: String

        init(message: Message, date: Date, text: String = "") {
            self.message = message
            self.date = date
            self.text = text
        }
    }
}
