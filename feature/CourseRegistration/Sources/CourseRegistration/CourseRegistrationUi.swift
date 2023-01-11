import Foundation
import SwiftUI
import Factory
import MarkdownUI
import Model
import Data
import Datastore
import RxSwift
import UI

public extension View {
    func courseRegistrationDestination(onNavigateUp: () -> Void, onRegisteredInCourse: (_ courseId: Int) -> Void) -> some View {
        navigationDestination(for: CourseRegistration.self) { _ in
            CourseRegistrationView()
        }
    }
}

public extension NavigationPath {
    mutating func appendCourseRegistration() {
        append(CourseRegistration())
    }
}


struct CourseRegistration: Hashable {
}

struct CourseRegistrationView: View {

    private let accountService = Container.accountService()
    private let serverConfigurationService = Container.serverConfigurationService()

    @StateObject var viewModel = CourseRegistrationViewController()

    /**
     * If the user clicks on signup, this variable holds the course the user wants to sign up to. While set, a dialog with the registration information is displayed.
     */
    @State var courseCandidate: Course? = nil

    var body: some View {
        RegisterForCourseContentView(
                courses: viewModel.registrableCourses,
                reloadCourses: {
                    await viewModel.reloadRegistrableCourses()
                },
                onClickSignUp: { course in courseCandidate = course }
        )
            .navigationTitle("course_registration_title")
            .sheet(item: $courseCandidate) { selectedCourse in
                CourseRegistrationSheetView(course: selectedCourse)
            }
    }
}

struct RegisterForCourseContentView: View {

    let courses: DataState<[SemesterCourses]>
    let reloadCourses: () async -> Void
    let onClickSignUp: (Course) -> Void

    var body: some View {
        BasicDataStateView(
                data: courses,
                loadingText: "course_registration_loading_courses_loading",
                failureText: "course_registration_loading_courses_failed",
                suspendedText: "course_registration_loading_courses_suspended",
                retryButtonText: "course_registration_loading_courses_try_again",
                clickRetryButtonAction: reloadCourses
        ) { data in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(data) { semesterCourse in
                        Section(header: Text(verbatim: semesterCourse.semester)) {
                            ForEach(semesterCourse.courses, id: \.self.id) { course in
                                RegistrableCourseView(
                                        course: course,
                                        onClickSignup: { onClickSignUp(course) }
                                )
                                        .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct RegistrableCourseView: View {

    let course: Course
    let onClickSignup: () -> Void

    var body: some View {
        CoursesHeaderView(course: course) {
            VStack(spacing: 0) {
                Divider()

                HStack {
                    Spacer()

                    Button(
                            action: onClickSignup,
                            label: { Text("course_registration_sign_up") }
                    )
                            .padding(.bottom, 8)
                            .padding(.trailing, 8)
                            .buttonStyle(.borderedProminent)
                }
                        .padding(.top, 8)
            }
        }
    }
}

private struct CourseRegistrationSheetView: View {

    let course: Course

    var body: some View {
        let registrationConfirmationMessage = course.registrationConfirmationMessage

        VStack {
            ScrollView {
                if registrationConfirmationMessage != nil {
                    Markdown(registrationConfirmationMessage ?? "")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 32)
                } else {
                    VStack {
                        Text(verbatim: course.title ?? "")
                        Text("course_registration_sign_up_dialog_message")
                    }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 32)
                }

            }
        }

        Spacer()

        Button(action: {}, label: { Text("course_registration_sign_up_dialog_positive_button") })
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 32)
                .presentationDetents([.medium, .large])
    }
}
