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
    var lectures: [Lecture]

    private let delegate: SendMessageMentionContentDelegate
    private let lectureService: LectureService

    init(
        course: Course,
        lectures: [Lecture] = [],
        delegate: SendMessageMentionContentDelegate,
        lectureService: LectureService = LectureServiceFactory.shared
    ) {
        self.course = course
        self.lectures = lectures
        self.delegate = delegate
        self.lectureService = lectureService
    }

    func task() async {
        let lectures = await lectureService.getLecturesWithSlides(courseId: course.id)

        if case let .done(lectures) = lectures {
            self.lectures = lectures
        }
    }

    func select(lecture: Lecture) {
        if let title = lecture.title {
            delegate.pickerDidSelect("[lecture]\(title)(/courses/\(course.id)/lectures/\(lecture.id))[/lecture]")
        }
    }

    func select(lectureUnit: LectureUnit) {
        if let name = lectureUnit.baseUnit.name,
           case let .attachment(attachment) = lectureUnit,
           case let .file(file) = attachment.attachment,
           let link = file.link,
           let url = URL(string: link),
           url.pathComponents.count >= 7 {
            let path = url.pathComponents[4...]
            let id = path.joined(separator: "/")

            delegate.pickerDidSelect("[lecture-unit]\(name)(\(id))[/lecture-unit]")
        }
    }

    func select(lectureUnit: LectureUnit, slide: Slide) {
        if let name = lectureUnit.baseUnit.name,
           let slideNumber = slide.slideNumber,
           let slideImagePath = slide.slideImagePath,
           let url = URL(string: slideImagePath),
           url.pathComponents.count >= 9 {
            let path = url.pathComponents[4...7]
            let id = path.joined(separator: "/")

            delegate.pickerDidSelect("[slide]\(name) Slide \(slideNumber)(\(id))[/slide]")
        }
    }
}
