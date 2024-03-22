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
        let result = await courseService.getCourse(courseId: path.id)
        self.course = result.map(\.course)
    }
}
