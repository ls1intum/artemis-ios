//
//  File.swift
//  
//
//  Created by TUM School on 24.09.23.
//

import Common
import Dependencies
import SharedModels
import SharedServices
import SwiftUI

struct CoursesOverviewView_Previews: PreviewProvider {

    struct CourseServiceStub: CourseService {

        private let course = {
            var course = CourseForDashboard(
                course: .init(
                    id: 1,
                    title: "The Swift Programming Language",
                    courseIcon: "stub",
                    exercises: [
                        .programming(exercise: {
                            var exercise = ProgrammingExercise(id: 1)
                            exercise.title = "Basic Operators"
                            exercise.dueDate = .now.advanced(by: 42)
                            return exercise
                        }()),
                        .text(exercise: {
                            TextExercise(id: 1)
                        }()),
                    ],
                    courseInformationSharingConfiguration: .communicationAndMessaging),
                totalScores: .init(
                    maxPoints: 0,
                    reachablePoints: 5, // denominator
                    studentScores: .init(
                        absoluteScore: 3, // numerator
                        relativeScore: 0,
                        currentRelativeScore: 0,
                        presentationScore: 0)))
            course.course.lectures = [
                .init(
                    id: 1,
                    title: nil,
                    description: nil,
                    startDate: nil,
                    endDate: nil,
                    attachments: nil,
                    lectureUnits: nil
                ),
                .init(
                    id: 2,
                    title: nil,
                    description: nil,
                    startDate: nil,
                    endDate: nil,
                    attachments: nil,
                    lectureUnits: nil
                ),
                .init(
                    id: 3,
                    title: nil,
                    description: nil,
                    startDate: nil,
                    endDate: nil,
                    attachments: nil,
                    lectureUnits: nil
                ),
            ]
            return course
        }()

        func getCourses() async -> Common.DataState<[SharedModels.CourseForDashboard]> {
            .done(response: [course])
        }

        func getCourse(courseId: Int) async -> Common.DataState<SharedModels.CourseForDashboard> {
            .done(response: course)
        }

        func getCourseForAssessment(courseId: Int) async -> Common.DataState<SharedModels.Course> {
            .done(response: course.course)
        }

        func courseIconURL(for course: Course) -> URL? {
            URL(string: "https://raw.githubusercontent.com/ls1intum/Artemis/develop/src/main/resources/public/images/logo.png")
        }
    }

    static var previews: some View {
        NavigationStack {
            withDependencies { values in
                values.courseService = CourseServiceStub()
            } operation: {
                CoursesOverviewView(viewModel: withDependencies({ values in
                    values.courseService = CourseServiceStub()
                }, operation: {
                    CoursesOverviewViewModel()
                }))
            }
        }
    }
}
