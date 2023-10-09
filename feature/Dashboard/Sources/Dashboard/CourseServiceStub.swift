//
//  File.swift
//  
//
//  Created by Nityananda Zbil on 09.10.23.
//

import Common
import Dependencies
import SharedModels
import SharedServices
import SwiftUI

struct CourseServiceStub: CourseService {

    private let aae = {
        var course = CourseForDashboard(
            course: .init(
                id: 1,
                title: "Advanced Aerospace Engineering 🚀",
                courseIcon: "stub",
                exercises: (1...5).map { id in
                    .modeling(exercise: {
                        var exercise = ModelingExercise(id: id)
                        exercise.title = "Designing a rocket engine"
                        exercise.dueDate = .now.advanced(by: 42)
                        return exercise
                    }())
                },
                courseInformationSharingConfiguration: .communicationAndMessaging),
            totalScores: CourseScore(
                maxPoints: 0,
                reachablePoints: 100,
                studentScores: StudentScore(
                    absoluteScore: 80,
                    relativeScore: 0.8,
                    currentRelativeScore: 0,
                    presentationScore: 0)))
        course.course.lectures = (1...3).map { id in
            Lecture(
                id: id,
                title: nil,
                description: nil,
                startDate: nil,
                endDate: nil,
                attachments: nil,
                lectureUnits: nil
            )
        }
        return course
    }()

    private let mst = {
        var course = CourseForDashboard(
            course: .init(
                id: 2,
                title: "Manned Space Travel 🧑‍🚀",
                courseIcon: "stub",
                exercises: (1...8).map { id in
                    .programming(exercise: {
                        var exercise = ProgrammingExercise(id: id)
                        exercise.title = "Space walk"
                        exercise.dueDate = .now.advanced(by: 42)
                        return exercise
                    }())
                },
                courseInformationSharingConfiguration: .communicationAndMessaging),
            totalScores: CourseScore(
                maxPoints: 0,
                reachablePoints: 100,
                studentScores: StudentScore(
                    absoluteScore: 90,
                    relativeScore: 0.8,
                    currentRelativeScore: 0,
                    presentationScore: 0)))
        course.course.lectures = (1...2).map { id in
            Lecture(
                id: id,
                title: nil,
                description: nil,
                startDate: nil,
                endDate: nil,
                attachments: nil,
                lectureUnits: nil
            )
        }
        return course
    }()

    func getCourses() async -> Common.DataState<[SharedModels.CourseForDashboard]> {
        .done(response: [aae, mst])
    }

    func getCourse(courseId: Int) async -> Common.DataState<SharedModels.CourseForDashboard> {
        switch courseId {
        case 1:
            return .done(response: aae)
        case 2:
            return .done(response: mst)
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
