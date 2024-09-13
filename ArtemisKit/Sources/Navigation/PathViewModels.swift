//
//  PathViewModels.swift
//
//
//  Created by Nityananda Zbil on 05.03.24.
//

import Common
import Extensions
import SharedModels
import SharedServices
import SwiftUI

@Observable
final class CoursePathViewModel {
    let path: CoursePath
    var course: DataState<Course>

    private let courseService: CourseService

    init(path: CoursePath, courseService: CourseService = CourseServiceFactory.shared) {
        self.path = path
        self.course = path.course.map(DataState.done) ?? .loading
        self.courseService = courseService
    }

    func loadCourse() async {
        let start = Date().timeIntervalSince1970

        let result = await courseService.getCourse(courseId: path.id)
        defer {
            self.course = result.map(\.course)
        }

        // Ensure 0.3s for animation has passed
        let end = Date().timeIntervalSince1970
        let durationNanoSeconds = (end - start) * 1_000_000_000
        let timeToWait = max(0, 300_000_000 - durationNanoSeconds)
        do {
            try await Task.sleep(nanoseconds: UInt64(timeToWait))
        } catch {}
    }
}
