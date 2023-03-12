//
//  NewReplyOnCoursePostHandler.swift
//  
//
//  Created by Sven Andabaka on 12.03.23.
//

import Foundation

struct NewReplyOnCoursePostHandler: Deeplink {

    let courseId: Int
    let postId: String

    static func build(from url: URL) -> NewReplyOnCoursePostHandler? {
        guard let indexOfCourseId = url.pathComponents.firstIndex(where: { $0 == "courses" }),
              let courseId = Int(url.pathComponents[indexOfCourseId + 1]),
              let urlComponent = URLComponents(string: url.absoluteString),
              let postId = urlComponent.queryItems?.first(where: { $0.name == "searchText" })?.value else { return nil }

        return NewReplyOnCoursePostHandler(courseId: courseId, postId: postId)
    }

    func handle(with navigationController: NavigationController) {
        navigationController.setCourse(id: courseId)
        navigationController.setTab(identifier: .communication)
        // TODO: set postId
    }
}
