//
//  SendMessageExercisePickerViewModel.swift
//
//
//  Created by Nityananda Zbil on 30.05.24.
//

import SharedModels
import SharedServices
import SwiftUI

@Observable
@MainActor
final class SendMessageExercisePickerViewModel {

    let course: CourseForOverviewDTO
    var exercises: [Exercise]

    private let service: CourseService
    private let delegate: SendMessageMentionContentDelegate

    init(
        course: CourseForOverviewDTO,
        exercises: [Exercise] = [],
        delegate: SendMessageMentionContentDelegate = SendMessageMentionContentDelegate { _ in },
        service: CourseService = CourseServiceFactory.shared
    ) {
        self.course = course
        self.exercises = exercises
        self.delegate = delegate
        self.service = service
    }

    func loadExercises() async {
        let exercises = await service.getExerciseOverview(courseId: course.id)

        if case let .done(exercises) = exercises {
            self.exercises = exercises.exercises ?? []
        }
    }

    func select(exercise: Exercise) {
        let type: String?
        switch exercise {
        case .fileUpload:
            type = "file-upload"
        case .modeling:
            type = "modeling"
        case .programming:
            type = "programming"
        case .quiz:
            type = "quiz"
        case .text:
            type = "text"
        case .unknown:
            type = nil
        }

        guard let type, let title = exercise.baseExercise.title else {
            return
        }

        delegate.pickerDidSelect("[\(type)]\(title)(/courses/\(course.id)/exercises/\(exercise.id))[/\(type)]")
    }
}
