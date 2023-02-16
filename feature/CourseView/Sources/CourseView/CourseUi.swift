import SwiftUI
import UI

private struct CourseDest: Hashable {
    let courseId: Int
}

public extension View {
    func courseViewDestination() -> some View {
        navigationDestination(for: CourseDest.self) { dest in
            CourseView(courseId: dest.courseId)
        }
    }
}

public extension NavigationPath {
    mutating func appendCourseView(courseId: Int) {
        append(CourseDest(courseId: courseId))
    }
}

struct CourseView: View {

    let courseId: Int
    @StateObject var viewController: CourseViewController

    init(courseId: Int) {
        self.courseId = courseId
        self._viewController = StateObject(wrappedValue: CourseViewController(courseId: courseId))
    }

    var body: some View {
        BasicDataStateView(
            data: viewController.course,
            loadingText: "course_ui_loading_course_loading",
            failureText: "course_ui_loading_course_failed",
            suspendedText: "course_ui_loading_course_suspended",
            retryButtonText: "course_ui_loading_course_try_again",
            clickRetryButtonAction: { await viewController.loadCourse(courseId: courseId) }
        ) { _ in
            ZStack {
                ExerciseListView(
                    exerciseDataState: viewController.exercisesGroupedByWeek,
                    onClickExercise: { _ in }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(
            viewController.course.value?.title ?? ""
        )

    }
}
