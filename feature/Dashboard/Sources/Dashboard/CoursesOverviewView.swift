import SwiftUI
import Common
import SharedModels

/**
 * Display the course overview with the course list.
 */
public struct CoursesOverviewView: View {

    @StateObject var viewModel: CoursesOverviewViewModel = CoursesOverviewViewModel()
    let onClickRegisterForCourse: () -> Void
    let onNavigateToCourse: (_ courseId: Int) -> Void
    let onLogout: () -> Void

    public var body: some View {
        VStack(alignment: .center) {
            DataStateView(data: $viewModel.courses,
                          retryHandler: { await viewModel.loadCourses() }) { courses in
                List {
                    ForEach(courses) { course in
                        CourseListCell(course: course)
                    }.padding(.horizontal, 8)
                }
            }
        }
        .navigationTitle(Text("course_overview_title"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: onClickRegisterForCourse, label: {
                    Label("course_overview_register_button_text", systemImage: "pencil")
                })

                Button("Logout") {
                    viewModel.logout()
                    onLogout()
                }
            }
        }
        .navigationBarBackButtonHidden()
        .task {
            await viewModel.loadCourses()
        }
    }
}

private struct CourseListCell: View {

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
            Spacer()
            HStack {
                ProgressView(value: 40, total: 100)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.trailing)
                Text("\(40)/\(100)P (\(40)%)")
            }
        }
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(lineWidth: 1)
                    .foregroundColor(.white)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
            )
        // TODO: add click action


    }
}
