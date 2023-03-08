import SwiftUI
import SharedModels
import DesignLibrary

public struct CourseRegistrationView: View {

    @StateObject var viewModel = CourseRegistrationViewModel()

    public init() { }

    public var body: some View {
        NavigationView {
            List {
                DataStateView(data: $viewModel.registrableCourses,
                              retryHandler: { await viewModel.loadCourses() }) { registrableCourses in
                    ForEach(registrableCourses) { semesterCourse in
                        Section(semesterCourse.semester) {
                            ForEach(semesterCourse.courses) { course in
                                CourseRegistrationListCell(viewModel: viewModel, course: course)
                            }
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.loadCourses()
            }
            .navigationTitle("course_registration_title")
        }
    }
}

private struct CourseRegistrationListCell: View {

    @ObservedObject var viewModel: CourseRegistrationViewModel

    @State private var showSignUpAlert = false

    let course: Course

    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text(course.title ?? "TODO")
                        .font(.title)
                    Text(course.description ?? "TODO")
                }
            }
            Button("Sign Up") {
                showSignUpAlert = true
            }
            .alert("course_registration_sign_up_dialog_message", isPresented: $showSignUpAlert, actions: {
                Button("Sign Up Now") {
                    Task {
                        await viewModel.signUpForCourse(course)
                    }
                }
                Button("Cancel", role: .cancel) {
                    showSignUpAlert = false
                }
            })
        }
        .padding(8)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(lineWidth: 1)
                .foregroundColor(.white)
                .shadow(color: .gray, radius: 2, x: 0, y: 2)
        )
    }
}
