//
//  MessageHandler.swift
//  
//
//  Created by Sven Andabaka on 11.04.23.
//

import Foundation
import SharedModels

struct MessageHandler: Deeplink {

    let courseId: Int
    let conversationId: Int64
    let threadId: Int64?

    static func build(from url: URL) -> MessageHandler? {
        guard let indexOfCourseId = url.pathComponents.firstIndex(where: { $0 == "courses" }),
              url.pathComponents.count > indexOfCourseId + 1,
              let courseId = Int(url.pathComponents[indexOfCourseId + 1]),
              url.pathComponents.contains("communication"),
              let urlComponent = URLComponents(string: url.absoluteString),
              let conversationIdString = urlComponent.queryItems?.first(where: { $0.name == "conversationId" })?.value,
              let conversationId = Int64(conversationIdString) else { return nil }

        if let threadIdString = urlComponent.queryItems?.first(where: { $0.name == "focusPostId" })?.value, let threadId = Int64(threadIdString) {
            return MessageHandler(courseId: courseId, conversationId: conversationId, threadId: threadId)
        }

        return MessageHandler(courseId: courseId, conversationId: conversationId, threadId: nil)
    }

    func handle(with navigationController: NavigationController) {
        Task(priority: .userInitiated) {
            if let threadId {
                // TODO: Add proper loading for channel
                var conversation = Channel(id: conversationId)
                conversation.name = "Conversation"

                let course = Course(id: courseId, courseInformationSharingConfiguration: .communicationAndMessaging)
                await navigationController.goToThread(for: threadId, in: .channel(conversation: conversation), of: course)
            } else {
                await navigationController.goToCourseConversation(courseId: courseId, conversationId: conversationId)
            }
        }
    }
}
