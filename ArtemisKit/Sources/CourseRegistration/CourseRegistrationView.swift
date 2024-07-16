import SwiftUI
import SharedModels
import DesignLibrary

public struct CourseRegistrationView: View {

    @StateObject var viewModel: CourseRegistrationViewModel

    @Environment(\.dismiss) var dismiss

    public var body: some View {
        NavigationView {
            List {
                DataStateView(data: $viewModel.registrableCourses) {
                    await viewModel.loadCourses()
                } content: { registrableCourses in
                    if registrableCourses.isEmpty {
                        ContentUnavailableView(
                            R.string.localizable.course_registration_no_course_available(),
                            systemImage: "graduationcap")
                    } else {
                        ForEach(registrableCourses) { semesterCourse in
                            Section(semesterCourse.semester) {
                                ForEach(semesterCourse.courses) { course in
                                    CourseRegistrationListCell(viewModel: viewModel, course: course)
                                }
                            }
                        }
                    }
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.loadCourses()
            }
            .task {
                await viewModel.loadCourses()
            }
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
            .loadingIndicator(isLoading: $viewModel.isLoading)
            .navigationTitle(R.string.localizable.course_registration_title())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(R.string.localizable.cancel()) {
                        dismiss()
                    }
                }
            }
        }
    }
}

public extension CourseRegistrationView {
    init(successCompletion: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: CourseRegistrationViewModel(successCompletion: successCompletion))
    }
}

private struct CourseRegistrationListCell: View {
    @ObservedObject var viewModel: CourseRegistrationViewModel

    @State private var showSignUpAlert = false

    let course: Course

    var body: some View {
        if let title = course.title {
            VStack(alignment: .leading, spacing: .m) {
                Text(title)
                    .font(.title2)

                if let description = course.description {
                    Text(description)
                        .font(.caption)
                }

                HStack {
                    Spacer()
                    Button(R.string.localizable.course_registration_register_button()) {
                        showSignUpAlert = true
                    }
                    .buttonStyle(ArtemisButton())
                    Spacer()
                }
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
}

#Preview {
    CourseRegistrationView(
        viewModel: CourseRegistrationViewModel(
            successCompletion: {},
            courseRegistrationService: CourseRegistrationServiceStub()))
}
