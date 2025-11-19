//
//  LectureDetailViewModel.swift
//  
//
//  Created by Sven Andabaka on 02.05.23.
//

import Foundation
import Common
import SharedModels
import SharedServices

class LectureDetailViewModel: BaseViewModel {

    @Published var lecture: DataState<Lecture> = .loading
    @Published var course: DataState<Course> = .loading
    @Published var channel: DataState<Channel> = .loading

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

    var visibleLectureUnitsWithPDF: [LectureUnit] {
        guard let units = lecture.value?.lectureUnits, !units.isEmpty else { return [] }
        return units.compactMap { unit in
            guard unit.baseUnit.visibleToStudents ?? false else { return nil }
            if case let .attachmentVideo(attachmentUnit) = unit, attachmentUnit.attachment?.pathExtension?.lowercased() == "pdf" {
                return unit
            }
            return nil
        }
    }

    var shouldShowDownloadCompletePDFButton: Bool {
        !visibleLectureUnitsWithPDF.isEmpty
    }

    func loadLecture() async {
        lecture = await LectureServiceFactory.shared.getLectureDetails(lectureId: lectureId)
    }

    func loadCourse() async {
        let result = await CourseServiceFactory.shared.getCourse(courseId: courseId)

        switch result {
        case .loading:
            course = .loading
        case .failure(let error):
            course = .failure(error: error)
        case .done(let response):
            course = .done(response: response.course)
        }
    }

    func loadAssociatedChannel() async {
        // We only have a channel if communication is enabled
        guard course.value?.courseInformationSharingConfiguration != .disabled else { return }

        channel = await LectureServiceFactory.shared.getAssociatedChannel(for: lectureId, in: courseId)
    }

    func updateLectureUnitCompletion(lectureUnit: LectureUnit, completed: Bool) async -> LectureUnit {
        let result = await LectureServiceFactory.shared.updateLectureUnitCompletion(lectureId: lectureId,
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
            case .attachmentVideo(let lectureUnit):
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
