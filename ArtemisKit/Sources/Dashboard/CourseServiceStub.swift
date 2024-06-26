//
//  CourseServiceStub.swift
//
//
//  Created by Nityananda Zbil on 18.03.24.
//

import Common
import SharedModels
import SharedServices

struct CourseServiceStub: CourseService {
    static let course: CourseForDashboardDTO = {
        var course = CourseForDashboardDTO(course: Course(id: 1, courseInformationSharingConfiguration: .disabled))
        course.course.title = "Hello, world!"
        course.totalScores = CourseScore()
        course.totalScores?.studentScores = StudentScore()
        course.totalScores?.studentScores.absoluteScore = 0
        course.totalScores?.reachablePoints = 0
        return course
    }()

    static let courses: CoursesForDashboardDTO = {
        return .mock
    }()

    func getCourses() async -> DataState<CoursesForDashboardDTO> {
        return .done(response: Self.courses)
    }

    func getCourse(courseId: Int) async -> DataState<CourseForDashboardDTO> {
        .loading
    }

    func getCourseForAssessment(courseId: Int) async -> DataState<Course> {
        .loading
    }

    func getCourseMembers(courseId: Int, searchLoginOrName: String) async -> DataState<[UserNameAndLoginDTO]> {
        .loading
    }
}
