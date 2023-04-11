//
//  CourseHandler.swift
//  
//
//  Created by Sven Andabaka on 11.04.23.
//

import Foundation

struct CourseHandler: Deeplink {

    let courseId: Int

    static func build(from url: URL) -> CourseHandler? {
        guard let indexOfCourseId = url.pathComponents.firstIndex(where: { $0 == "courses" }),
              url.pathComponents.count > indexOfCourseId + 1,
              let courseId = Int(url.pathComponents[indexOfCourseId + 1]) else { return nil }

        return CourseHandler(courseId: courseId)
    }

    func handle(with navigationController: NavigationController) {
        Task(priority: .userInitiated) {
            await navigationController.goToCourse(id: courseId)
        }
    }
}
