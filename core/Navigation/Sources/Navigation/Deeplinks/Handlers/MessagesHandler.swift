//
//  File.swift
//  
//
//  Created by Sven Andabaka on 11.04.23.
//

import Foundation

struct MessagesHandler: Deeplink {

    let courseId: Int

    static func build(from url: URL) -> MessagesHandler? {
        guard let indexOfCourseId = url.pathComponents.firstIndex(where: { $0 == "courses" }),
              url.pathComponents.count > indexOfCourseId + 1,
              let courseId = Int(url.pathComponents[indexOfCourseId + 1]),
              url.pathComponents.firstIndex(where: { $0 == "messages" }) != nil else { return nil }

        return MessagesHandler(courseId: courseId)
    }

    func handle(with navigationController: NavigationController) {
        Task(priority: .userInitiated) {
            await navigationController.goToCourseConversations(courseId: courseId)
        }
    }
}
