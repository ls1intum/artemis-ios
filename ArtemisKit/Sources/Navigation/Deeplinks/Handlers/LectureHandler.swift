//
//  File.swift
//  
//
//  Created by Sven Andabaka on 12.06.23.
//

import Foundation

struct LectureHandler: Deeplink {

    let courseId: Int
    let lectureId: Int
    let target: LectureMediaTarget?

    static func build(from url: URL) -> LectureHandler? {
        guard let indexOfCourseId = url.pathComponents.firstIndex(where: { $0 == "courses" }),
              url.pathComponents.count > indexOfCourseId + 1,
              let courseId = Int(url.pathComponents[indexOfCourseId + 1]),
              let indexOfExerciseId = url.pathComponents.firstIndex(where: { $0 == "lectures" }),
              url.pathComponents.count > indexOfExerciseId + 1,
              let lectureId = Int(url.pathComponents[indexOfExerciseId + 1]),
              let urlComponent = URLComponents(string: url.absoluteString),
              urlComponent.queryItems?.first(where: { $0.name == "postId" })?.value == nil else { return nil }

        let query = urlComponent.queryItems ?? []
        let unitId = query.first(where: { $0.name == "lectureUnitId" })?.value.flatMap(Int64.init)
        let attachmentId = query.first(where: { $0.name == "attachmentId" })?.value.flatMap(Int.init)
        let page = query.first(where: { $0.name == "page" || $0.name == "pageNumber" })?.value.flatMap(Int.init)
        let target = unitId != nil || attachmentId != nil ? LectureMediaTarget(unitId: unitId, attachmentId: attachmentId, page: page) : nil
        return LectureHandler(courseId: courseId, lectureId: lectureId, target: target)
    }

    func handle(with navigationController: NavigationController) {
        Task(priority: .userInitiated) {
            await navigationController.goToLecture(courseId: courseId, lectureId: lectureId, target: target)
        }
    }
}
