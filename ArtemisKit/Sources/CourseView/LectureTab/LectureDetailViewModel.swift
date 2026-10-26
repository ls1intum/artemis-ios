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
import Navigation

extension Notification.Name {
    static let lectureUnitCompletionDidChange = Notification.Name("lectureUnitCompletionDidChange")
}

class LectureDetailViewModel: BaseViewModel {

    @Published var lecture: DataState<Lecture> = .loading
    @Published var targetPresentation: LectureUnitPresentation?
    private var pendingTarget: LectureMediaTarget?
    private var requestedTarget: LectureMediaTarget?
    private var targetConsumed = false
    private var completionStarted = false
    private var lectureService: LectureService = LectureServiceFactory.shared
    private var sessionCheck: (() -> Bool)?
    private var isCurrent: Bool { sessionCheck?() ?? (mediaSession?.isCurrent == true) }

    @Published var studentVersions: [Int: String] = [:]
    @Published var course: DataState<CourseForOverviewDTO> = .loading
    @Published var channel: DataState<Channel> = .loading

    private let mediaSession = LectureMediaSession.capture()
    private var lectureGeneration = LectureMediaLoadGeneration()

    let lectureId: Int
    let courseId: Int

    init(course: CourseForOverviewDTO, lectureId: Int, lectureService: LectureService = LectureServiceFactory.shared, isCurrent: (() -> Bool)? = nil) {
        self.lectureService = lectureService
        self.sessionCheck = isCurrent
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

    func configureTarget(_ target: LectureMediaTarget?) {
        guard requestedTarget != target else { return }
        requestedTarget = target
        pendingTarget = target
        targetConsumed = false
        targetPresentation = nil
    }

    func retryTarget() async {
        targetConsumed = false
        targetPresentation = nil
        await loadLecture()
    }

    func refreshSlideAccess(for target: LectureMediaTarget) async -> DataState<LectureSlideAccess> {
        guard isCurrent else { return .failure(error: UserFacingError(title: LectureMediaError.sessionChanged.localizedDescription)) }
        // The visibility endpoint omits file-access fields. Validate complete
        // details on both sides rather than interpreting omission as removal.
        let firstResult = await lectureService.getLectureDetails(lectureId: lectureId)
        guard !Task.isCancelled, isCurrent else { return .failure(error: UserFacingError(title: LectureMediaError.sessionChanged.localizedDescription)) }
        guard let before = firstResult.value else { return slideFailure(firstResult) }
        let projectionResult = await lectureService.getLecturesWithSlides(courseId: courseId)
        guard !Task.isCancelled, isCurrent else { return .failure(error: UserFacingError(title: LectureMediaError.sessionChanged.localizedDescription)) }
        guard let lectures = projectionResult.value else { return slideFailure(projectionResult) }
        let finalResult = await lectureService.getLectureDetails(lectureId: lectureId)
        guard !Task.isCancelled, isCurrent else { return .failure(error: UserFacingError(title: LectureMediaError.sessionChanged.localizedDescription)) }
        guard let after = finalResult.value else { return slideFailure(finalResult) }
        guard let projection = lectures.first(where: { $0.lecture.id == lectureId }),
              let access = LectureSlideAccess.resolve(target: target, before: before, projection: projection, after: after) else {
            return .failure(error: UserFacingError(title: "The referenced slide or attachment changed or is unavailable. Try again."))
        }
        return .done(response: access)
    }

    private func slideFailure<Value>(_ state: DataState<Value>) -> DataState<LectureSlideAccess> {
        if case .failure(let error) = state { return .failure(error: error) }
        return .failure(error: UserFacingError(title: "Slide information could not be loaded. Try again."))
    }

    private func resolvePendingTarget(in details: LectureMediaDetails) {
        guard !targetConsumed, let pendingTarget else { return }
        guard let unit = pendingTarget.resolve(in: details.lecture.lectureUnits ?? []) else {
            targetConsumed = true
            presentError(userFacingError: UserFacingError(title: "The referenced lecture attachment is unavailable."))
            return
        }
        let studentVersion: String?
        if case .attachmentVideo(let attachment) = unit {
            studentVersion = attachment.attachment.flatMap { details.studentVersions[$0.id] }
        } else { studentVersion = nil }
        targetConsumed = true
        targetPresentation = LectureUnitPresentation(unit: unit, target: pendingTarget, studentVersion: studentVersion)
    }

    func loadLecture() async {
        let generation = lectureGeneration.begin()
        let result = await lectureService.getLectureDetails(lectureId: lectureId)
        guard !Task.isCancelled, lectureGeneration.accepts(generation) else { return }
        guard isCurrent else {
            lecture = .failure(error: UserFacingError(title: LectureMediaError.sessionChanged.localizedDescription))
            return
        }
        switch result {
        case .done(let details):
            studentVersions = details.studentVersions
            lecture = .done(response: details.lecture)
            resolvePendingTarget(in: details)
        case .failure(let error): lecture = .failure(error: error)
        case .loading: lecture = .loading
        }
    }

    func loadCourse() async {
        let result = await CourseServiceFactory.shared.getCourse(courseId: courseId)
        guard !Task.isCancelled, isCurrent else { return }
        course = result
    }

    func loadAssociatedChannel() async {
        // We only have a channel if communication is enabled
        guard course.value?.courseInformationSharingConfiguration != .disabled else { return }

        let result = await lectureService.getAssociatedChannel(for: lectureId, in: courseId)
        guard !Task.isCancelled, isCurrent else { return }
        channel = result
    }

    /// Opening a unit marks it complete using the existing policy. This user
    /// action must settle even when Back removes the page during the request.
    func completePresentedUnitIfNeeded() {
        guard !completionStarted, let unit = targetPresentation?.unit,
              !(unit.baseUnit.completed ?? false), unit.baseUnit.visibleToStudents ?? false, isCurrent else { return }
        completionStarted = true
        Task { _ = await updateLectureUnitCompletion(lectureUnit: unit, completed: true) }
    }

    func updateLectureUnitCompletion(lectureUnit: LectureUnit, completed: Bool) async -> LectureUnit {
        guard isCurrent else { return lectureUnit }
        let result = await lectureService.updateLectureUnitCompletion(lectureId: lectureId,
                                                                     lectureUnitId: lectureUnit.id,
                                                                     completed: completed)
        guard isCurrent else { return lectureUnit }
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

            NotificationCenter.default.post(name: .lectureUnitCompletionDidChange, object: nil,
                                            userInfo: ["courseId": courseId, "lectureId": lectureId])
            return newLectureUnit
        }
    }
}
