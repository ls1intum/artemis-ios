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
    var course: DataState<CourseForOverviewDTO>

    private let courseService: CourseService

    init(path: CoursePath, courseService: CourseService = CourseServiceFactory.shared) {
        self.path = path
        self.course = path.course.map(DataState.done) ?? .loading
        self.courseService = courseService
    }

    func reloadCourse() async {
        self.course = await courseService.getCourse(courseId: path.id)
    }

    func loadCourse() async {
        // If course is already loaded, skip this
        switch course {
        case .done:
            return
        default:
            break
        }

        self.course = await courseService.getCourse(courseId: path.id)
    }
}
