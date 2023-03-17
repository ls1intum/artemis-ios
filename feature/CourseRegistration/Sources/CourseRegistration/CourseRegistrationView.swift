import SwiftUI
import SharedModels
import DesignLibrary

public struct CourseRegistrationView: View {

    @StateObject var viewModel: CourseRegistrationViewModel

    public init(successCompletion: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: CourseRegistrationViewModel(successCompletion: successCompletion))
    }

    public var body: some View {
        NavigationView {
            List {
                DataStateView(data: $viewModel.registrableCourses,
                              retryHandler: { await viewModel.loadCourses() }) { registrableCourses in
                    ForEach(registrableCourses) { semesterCourse in
                        Section(semesterCourse.semester) {
                            ForEach(semesterCourse.courses) { course in
                                CourseRegistrationListCell(viewModel: viewModel, course: course)
                            }.listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .refreshable {
                await viewModel.loadCourses()
            }
            .task {
                await viewModel.loadCourses()
            }
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
            .loadingIndicator(isLoading: $viewModel.isLoading)
            .navigationTitle(R.string.localizable.course_registration_title())
        }
    }
}

private struct CourseRegistrationListCell: View {

    @ObservedObject var viewModel: CourseRegistrationViewModel

    @State private var showSignUpAlert = false

    let course: Course

    var body: some View {
        VStack(spacing: .m) {
            VStack(alignment: .leading) {
                Text(course.title ?? R.string.localizable.unknown())
                    .font(.title2)
                Text(course.description ?? R.string.localizable.unknown())
                    .font(.caption)
            }
            Button(R.string.localizable.course_registration_register_button()) {
                showSignUpAlert = true
            }.buttonStyle(ArtemisButton())
        }
            .padding(.m)
            .frame(maxWidth: .infinity)
            .cardModifier()
            .alert(R.string.localizable.course_registration_sign_up_dialog_message(), isPresented: $showSignUpAlert, actions: {
                Button(R.string.localizable.confirm()) {
                    viewModel.isLoading = true
                    Task {
                        await viewModel.signUpForCourse(course)
                    }
                }
                Button(R.string.localizable.cancel(), role: .cancel) {
                    showSignUpAlert = false
                }
            })
    }
}
