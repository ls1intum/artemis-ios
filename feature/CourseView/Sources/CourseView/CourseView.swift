import SwiftUI
import Common
import SharedModels
import Navigation
import Messages
import DesignLibrary

public struct CourseView: View {

    @StateObject var viewModel: CourseViewModel

    @EnvironmentObject private var navigationController: NavigationController

    @State private var showNewMessageDialog = false
    @State private var searchText = ""

    private let courseId: Int

    public init(courseId: Int) {
        self.courseId = courseId
        self._viewModel = StateObject(wrappedValue: CourseViewModel(courseId: courseId))
    }

    init(viewModel: CourseViewModel, courseId: Int) {
        self.courseId = courseId
        _viewModel = .init(wrappedValue: viewModel)
    }

    public var body: some View {
        TabView(selection: $navigationController.courseTab) {
            ExerciseListView(viewModel: viewModel, searchText: $searchText)
                .tabItem {
                    Label(R.string.localizable.exercisesTabLabel(), systemImage: "list.bullet.clipboard.fill")
                }
                .tag(TabIdentifier.exercise)

            LectureListView(viewModel: viewModel, searchText: $searchText)
                .tabItem {
                    Label(R.string.localizable.lectureTabLabel(), systemImage: "character.book.closed.fill")
                }
                .tag(TabIdentifier.lecture)

            if viewModel.course.value == nil ||
                viewModel.course.value?.courseInformationSharingConfiguration == .communicationAndMessaging ||
                viewModel.course.value?.courseInformationSharingConfiguration == .messagingOnly {
                Group {
                    if let course = viewModel.course.value {
                        MessagesTabView(searchText: $searchText, course: course)
                    } else {
                        Text("Loading...")
                    }
                }
                    .tabItem {
                        Label(R.string.localizable.messagesTabLabel(), systemImage: "bubble.right.fill")
                    }
                    .tag(TabIdentifier.communication)
            }
        }
            .navigationTitle(viewModel.course.value?.title ?? R.string.localizable.loading())
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText)
            .onChange(of: navigationController.courseTab) {
                searchText = ""
            }
    }
}

struct CourseView_Previews: PreviewProvider {
    static var previews: some View {
        CourseView(viewModel: {
            let viewModel = CourseViewModel(courseId: 1)
            viewModel.course = .done(response: .init(
                id: 1,
                exercises: [
                    {
                        var exercise = ModelingExercise(id: 1)
                        exercise.title = "Combining Logical Operators"
                        exercise.dueDate = .tomorrow
                        exercise.releaseDate = .yesterday
                        exercise.difficulty = .EASY
//                        exercise.mode = .team
//                        exercise.categories = [.i]
                        return .modeling(exercise: exercise)
                    }(),
//                    Range Operators
                    {
                        var exercise = ProgrammingExercise(id: 2)
                        exercise.title = "Range Operators"
                        exercise.dueDate = .tomorrow
                        exercise.releaseDate = .yesterday
                        exercise.difficulty = .MEDIUM
                        exercise.studentParticipations = [
                            .student(participation: .init(
                                testRun: false,
                                id: 1,
                                submissions: [
                                    .programming(submission: .init(
                                        id: nil,
                                        submitted: nil,
                                        submissionDate: nil,
                                        exampleSubmission: nil,
                                        durationInMinutes: nil,
                                        results: [
                                            .init(),
                                        ],
                                        participation: nil,
                                        buildFailed: nil))
                                ])),
                        ]
                        return .programming(exercise: exercise)
                    }(),
                ],
                courseInformationSharingConfiguration: .communicationAndMessaging))
            return viewModel
        }(), courseId: 1)
            .environmentObject({ () -> NavigationController in
                let navigationController = NavigationController()
//                navigationController.courseTab = .lecture
                return navigationController
            }())


            CourseView(viewModel: {
                let viewModel = CourseViewModel(courseId: 1)
                viewModel.course = .done(response: {
                    var course = Course(
                        id: 1,
                        courseInformationSharingConfiguration: .communicationAndMessaging)
                    course.lectures = [
                        .init(id: 1,
                              title: "A",
                              description: "D",
                              startDate: .yesterday,
                              endDate: .tomorrow,
                              attachments: [
                                .file(attachment: .init(id: 1)),
                              ],
                              lectureUnits: [
//                                .attachment(lectureUnit: .),
                              ])
                    ]
                    return course
                }())
                return viewModel
            }(), courseId: 1)
                .environmentObject({ () -> NavigationController in
                    let navigationController = NavigationController()
                    navigationController.courseTab = .lecture
                    return navigationController
                }())
    }
}
