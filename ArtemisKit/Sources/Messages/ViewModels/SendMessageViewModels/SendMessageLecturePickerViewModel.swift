//
//  SendMessageLecturePickerViewModel.swift
//
//
//  Created by Nityananda Zbil on 30.05.24.
//

import SharedModels
import SwiftUI

@Observable
@MainActor
final class SendMessageLecturePickerViewModel {

    let course: Course
    var lectureUnits: [LectureUnit]

    private let lectureService: LectureService

    init(
        course: Course,
        lectureUnits: [LectureUnit] = [],
        lectureService: LectureService = LectureServiceFactory.shared
    ) {
        self.course = course
        self.lectureUnits = lectureUnits
        self.lectureService = lectureService
    }

    func task() async {
        let lectures = await lectureService.getLecturesWithSlides(courseId: course.id)

        if case let .done(lectures) = lectures,
           let lecture = lectures.first,
           let lectureUnits = lecture.lectureUnits
//           let lectureUnit = lectureUnits.first,
//           case let .attachment(attachment) = lectureUnit,
//           case let .file(file) = attachment.attachment,
//           let link = file.link
        {
            self.lectureUnits = lectureUnits
        }
    }
}
