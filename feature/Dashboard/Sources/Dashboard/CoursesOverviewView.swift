import SwiftUI
import Common
import SharedModels
import CourseRegistration
import DesignLibrary

/**
 * Display the course overview with the course list.
 */
public struct CoursesOverviewView: View {

    @StateObject private var viewModel = CoursesOverviewViewModel()

    @State private var showCourseRegistrationSheet = false

    public init() { }

    public var body: some View {
        VStack(alignment: .center) {
            DataStateView(data: $viewModel.courses,
                          retryHandler: { await viewModel.loadCourses() }) { courses in
                List {
                    ForEach(courses) { course in
                        CourseListCell(course: course)
                    }
                        .listRowSeparator(.hidden)
                }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await viewModel.loadCourses()
                    }
            }
        }
        .navigationTitle(Text("course_overview_title"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { showCourseRegistrationSheet = true }, label: {
                    Label("course_overview_register_button_text", systemImage: "pencil")
                })

                Button("Logout") {
                    viewModel.logout()
                }
            }
        }
        .sheet(isPresented: $showCourseRegistrationSheet) {
            CourseRegistrationView()
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
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                AsyncImage(url: course.courseIconURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        Image("questionmark.square.dashed")
                    @unknown default:
                        EmptyView()
                    }
                }
                    .frame(width: .largeImage, height: .largeImage)
                VStack(alignment: .leading) {
                    Text(course.title ?? "TODO")
                        .font(.title)
                    Text("Exercises: \(course.exercises?.count ?? 0)")
                    Text("Lectures: \(course.lectures?.count ?? 0)")
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
