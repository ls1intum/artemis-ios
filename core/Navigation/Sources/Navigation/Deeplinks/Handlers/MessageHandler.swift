//
//  MessageHandler.swift
//  
//
//  Created by Sven Andabaka on 11.04.23.
//

import Foundation

struct MessageHandler: Deeplink {

    let courseId: Int
    let conversationId: Int64

    static func build(from url: URL) -> MessageHandler? {
        guard let indexOfCourseId = url.pathComponents.firstIndex(where: { $0 == "courses" }),
              url.pathComponents.count > indexOfCourseId + 1,
              let courseId = Int(url.pathComponents[indexOfCourseId + 1]),
              url.pathComponents.firstIndex(where: { $0 == "messages" }) != nil,
              let urlComponent = URLComponents(string: url.absoluteString),
              let conversationIdString = urlComponent.queryItems?.first(where: { $0.name == "conversationId" })?.value,
              let conversationId = Int64(conversationIdString) else { return nil }

        return MessageHandler(courseId: courseId, conversationId: conversationId)
    }

    func handle(with navigationController: NavigationController) {
        Task(priority: .userInitiated) {
            await navigationController.goToCourseConversation(courseId: courseId, conversationId: conversationId)
        }
    }
}
