//
//  CourseHandler.swift
//  
//
//  Created by Sven Andabaka on 11.04.23.
//

import Foundation

private enum CourseTab: String, RawRepresentable {
    case exercises, lectures, messages, unknown
}

struct CourseHandler: Deeplink {

    private let courseId: Int
    private let courseTab: CourseTab?
    private let url: URL

    static func build(from url: URL) -> CourseHandler? {
        guard let indexOfCourseId = url.pathComponents.firstIndex(where: { $0 == "courses" }),
              url.pathComponents.count > indexOfCourseId + 1,
              let courseId = Int(url.pathComponents[indexOfCourseId + 1]),
              url.pathComponents.count <= 3 else { return nil }

        var courseTab: CourseTab?
        if url.pathComponents.count > indexOfCourseId + 2 {
            let path = url.pathComponents[indexOfCourseId + 2]
            switch path {
            case CourseTab.exercises.rawValue:
                courseTab = .exercises
            case CourseTab.lectures.rawValue:
                courseTab = .lectures
            case CourseTab.messages.rawValue:
                courseTab = .messages
            default:
                courseTab = .unknown
            }
        }

        return CourseHandler(courseId: courseId, courseTab: courseTab, url: url)
    }

    func handle(with navigationController: NavigationController) {
        Task(priority: .userInitiated) {
            if let courseTab {
                switch courseTab {
                case .exercises:
                    await navigationController.setTab(identifier: .exercise)
                case .lectures:
                    await navigationController.setTab(identifier: .exercise)
                case .messages:
                    await navigationController.setTab(identifier: .exercise)
                case .unknown:
                    await navigationController.popToRoot()
                    await navigationController.showDeeplinkNotSupported(url: url)
                    return
                }
            } else {
                await navigationController.setTab(identifier: .exercise)
            }

            await navigationController.goToCourse(id: courseId)
        }
    }
}
