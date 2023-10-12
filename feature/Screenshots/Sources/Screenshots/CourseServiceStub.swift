//
//  File.swift
//
//
//  Created by Nityananda Zbil on 10.10.23.
//

import Common
import Dependencies
import SharedModels
import SharedServices
import SwiftUI

struct CourseServiceStub: CourseService {

    private let aae = {
        var course = CourseForDashboard(
            course: Course(
                id: 1,
                title: "Advanced Aerospace Engineering 🚀",
                courseIcon: "stub",
                exercises: [
                    .modeling(exercise: {
                        var exercise = ModelingExercise(id: 1)
                        exercise.title = "Designing a rocket engine"
                        exercise.dueDate = .tomorrow
                        return exercise
                    }()),
                    .text(exercise: {
                        var exercise = TextExercise(id: 2)
                        exercise.title = "Sending a rover to Saturn 🪐"
                        exercise.dueDate = .tomorrow
                        return exercise
                    }()),
                    .programming(exercise: {
                        var exercise = ProgrammingExercise(id: 3)
                        exercise.title = "Heat control on atmospheric entry 🔥"
                        exercise.dueDate = .tomorrow
                        return exercise
                    }()),
                ],
                courseInformationSharingConfiguration: .communicationAndMessaging),
            totalScores: CourseScore(
                maxPoints: 0,
                reachablePoints: 100,
                studentScores: StudentScore(
                    absoluteScore: 80,
                    relativeScore: 0.8,
                    currentRelativeScore: 0,
                    presentationScore: 0)))
        return course
    }()

    func getCourses() async -> Common.DataState<[SharedModels.CourseForDashboard]> {
        .done(response: [aae])
    }

    func getCourse(courseId: Int) async -> Common.DataState<SharedModels.CourseForDashboard> {
        switch courseId {
        case 1:
            return .done(response: aae)
        default:
            return .loading
        }
    }

    func getCourseForAssessment(courseId: Int) async -> Common.DataState<SharedModels.Course> {
        .done(response: aae.course)
    }

    func courseIconURL(for course: Course) -> URL? {
        switch course.id {
        case 1:
            return Bundle.module.url(forResource: "saturn5", withExtension: "png", subdirectory: "Media")
        case 2:
            return Bundle.module.url(forResource: "mars", withExtension: "png", subdirectory: "Media")
        default:
            return nil
        }
    }
}
