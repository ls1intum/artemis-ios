//
//  LectureDetailViewModel.swift
//  
//
//  Created by Sven Andabaka on 02.05.23.
//

import Common
import Dependencies
import Foundation
import SharedModels
import SharedServices

class LectureDetailViewModel: BaseViewModel {

    @Dependency(\.courseService) private var courseService
    @Dependency(\.lectureService) private var lectureService

    @Published var lecture: DataState<Lecture> = .loading
    @Published var course: DataState<Course> = .loading

    let lectureId: Int
    let courseId: Int

    init(course: Course, lectureId: Int) {
        self.courseId = course.id
        self.lectureId = lectureId

        self.course = .done(response: course)

        super.init()
    }

    init(courseId: Int, lectureId: Int) {
        self.courseId = courseId
        self.lectureId = lectureId

        super.init()

        Task {
            await loadCourse()
        }
    }

    func loadLecture() async {
        lecture = await lectureService.getLectureDetails(lectureId: lectureId)
    }

    func loadCourse() async {
        let result = await courseService.getCourse(courseId: courseId)

        switch result {
        case .loading:
            course = .loading
        case .failure(let error):
            course = .failure(error: error)
        case .done(let response):
            course = .done(response: response.course)
        }
    }

    func updateLectureUnitCompletion(lectureUnit: LectureUnit, completed: Bool) async -> LectureUnit {
        let result = await lectureService.updateLectureUnitCompletion(lectureId: lectureId,
                                                                      lectureUnitId: lectureUnit.id,
                                                                      completed: completed)

        switch result {
        case .failure(let error):
            presentError(userFacingError: UserFacingError(title: error.localizedDescription))
            return lectureUnit
        case .loading, .notStarted:
            return lectureUnit
        case .success:
            var newLectureUnit: LectureUnit?
            switch lectureUnit {
            case .attachment(let lectureUnit):
                var newBaseLectureUnit = lectureUnit
                newBaseLectureUnit.completed = completed
                newLectureUnit = LectureUnit(lectureUnit: newBaseLectureUnit)
            case .exercise(let lectureUnit):
                var newBaseLectureUnit = lectureUnit
                newBaseLectureUnit.completed = completed
                newLectureUnit = LectureUnit(lectureUnit: newBaseLectureUnit)
            case .text(let lectureUnit):
                var newBaseLectureUnit = lectureUnit
                newBaseLectureUnit.completed = completed
                newLectureUnit = LectureUnit(lectureUnit: newBaseLectureUnit)
            case .video(let lectureUnit):
                var newBaseLectureUnit = lectureUnit
                newBaseLectureUnit.completed = completed
                newLectureUnit = LectureUnit(lectureUnit: newBaseLectureUnit)
            case .online(let lectureUnit):
                var newBaseLectureUnit = lectureUnit
                newBaseLectureUnit.completed = completed
                newLectureUnit = LectureUnit(lectureUnit: newBaseLectureUnit)
            case .unknown(let lectureUnit):
                var newBaseLectureUnit = lectureUnit
                newBaseLectureUnit.completed = completed
                newLectureUnit = LectureUnit(lectureUnit: newBaseLectureUnit)
            }

            guard let newLectureUnit else {
                presentError(userFacingError: UserFacingError(title: "Could not update Lecture Unit"))
                return lectureUnit
            }

            return newLectureUnit
        }
    }
}
