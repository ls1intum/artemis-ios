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
    @Published var studentVersions: [Int: String] = [:]
    @Published var course: DataState<CourseForOverviewDTO> = .loading
    @Published var channel: DataState<Channel> = .loading

    private let mediaSession = LectureMediaSession.capture()
    private var lectureGeneration = LectureMediaLoadGeneration()

    let lectureId: Int
    let courseId: Int

    init(course: CourseForOverviewDTO, lectureId: Int) {
        self.courseId = course.id
        self.lectureId = lectureId

        self.course = .done(response: course)

        super.init()
    }

    init(courseId: Int?, lectureId: Int?) {
        if let courseId, let lectureId {
            self.courseId = courseId
            self.lectureId = lectureId
        } else {
            self.courseId = -1
            self.lectureId = -1
        }

        super.init()

        if courseId == -1 || lectureId == -1 {
            return
        }

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
        let generation = lectureGeneration.begin()
        let result = await LectureServiceFactory.shared.getLectureDetails(lectureId: lectureId)
        guard !Task.isCancelled, lectureGeneration.accepts(generation) else { return }
        guard mediaSession?.isCurrent == true else {
            lecture = .failure(error: UserFacingError(title: LectureMediaError.sessionChanged.localizedDescription))
            return
        }
        switch result {
        case .done(let details):
            studentVersions = details.studentVersions
            lecture = .done(response: details.lecture)
        case .failure(let error): lecture = .failure(error: error)
        case .loading: lecture = .loading
        }
    }

    func loadCourse() async {
        let result = await CourseServiceFactory.shared.getCourse(courseId: courseId)
        guard !Task.isCancelled, mediaSession?.isCurrent == true else { return }
        course = result
    }

    func loadAssociatedChannel() async {
        // We only have a channel if communication is enabled
        guard course.value?.courseInformationSharingConfiguration != .disabled else { return }

        let result = await LectureServiceFactory.shared.getAssociatedChannel(for: lectureId, in: courseId)
        guard !Task.isCancelled, mediaSession?.isCurrent == true else { return }
        channel = result
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
