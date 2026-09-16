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
    var tabs: DataState<CourseAvailableTabsDTO>

    private let courseService: CourseService

    init(path: CoursePath, courseService: CourseService = CourseServiceFactory.shared) {
        self.path = path
        self.course = path.course.map(DataState.done) ?? .loading
        self.tabs = path.tabs.map(DataState.done) ?? .loading
        self.courseService = courseService
    }

    func reloadCourse() async {
        self.course = await courseService.getCourse(courseId: path.id)
    }

    func reloadTabs() async {
        self.tabs = await courseService.getAvailableTabs(courseId: path.id)
    }

    func loadCourse() async {
        // If course is already loaded, skip this
        switch (course, tabs) {
        case (.done, .done):
            return
        default:
            break
        }

        async let course = await courseService.getCourse(courseId: path.id)
        async let tabs = await courseService.getAvailableTabs(courseId: path.id)

        self.course = await course
        self.tabs = await tabs
    }
}
