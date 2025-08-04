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
    let conversationName: String?

    static func build(from url: URL) -> MessageHandler? {
        guard let indexOfCourseId = url.pathComponents.firstIndex(where: { $0 == "courses" }),
              url.pathComponents.count > indexOfCourseId + 1,
              let courseId = Int(url.pathComponents[indexOfCourseId + 1]),
              url.pathComponents.contains("communication"),
              let urlComponent = URLComponents(string: url.absoluteString),
              let conversationIdString = urlComponent.queryItems?.first(where: { $0.name == "conversationId" })?.value,
              let conversationId = Int64(conversationIdString) else { return nil }

        var threadId: Int64?
        var conversationName: String?

        if let threadIdString = urlComponent.queryItems?.first(where: { $0.name == "focusPostId" })?.value {
            threadId = Int64(threadIdString)
        }
        conversationName = urlComponent.queryItems?.first(where: { $0.name == "conversationName" })?.value

        return MessageHandler(courseId: courseId,
                              conversationId: conversationId,
                              threadId: threadId,
                              conversationName: conversationName)
    }

    func handle(with navigationController: NavigationController) {
        Task(priority: .userInitiated) {
            if let threadId {
                // TODO: Maybe add proper loading for channel
                var conversation = Channel(id: conversationId)
                conversation.name = conversationName

                let course = Course(id: courseId, courseInformationSharingConfiguration: .communicationAndMessaging)
                await navigationController.goToCourseConversation(courseId: courseId, conversationId: conversationId)

                let threadPath = ThreadPath(postId: threadId, conversation: .channel(conversation: conversation), coursePath: .init(course: course))
                await MainActor.run {
                    navigationController.tabPath.append(threadPath)
                }
            } else {
                await navigationController.goToCourseConversation(courseId: courseId, conversationId: conversationId)
            }
        }
    }
}
