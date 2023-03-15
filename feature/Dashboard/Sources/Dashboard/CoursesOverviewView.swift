import SwiftUI
import Common
import SharedModels
import CourseRegistration
import DesignLibrary
import Navigation
import CourseView
import Account

/**
 * Display the course overview with the course list.
 */
public struct CoursesOverviewView: View {

    @StateObject private var viewModel = CoursesOverviewViewModel()

    @State private var showCourseRegistrationSheet = false
    @State private var showNotificationSheet = false

    public init() { }

    public var body: some View {
        VStack(alignment: .center) {
            DataStateView(data: $viewModel.courses,
                          retryHandler: { await viewModel.loadCourses() }) { courses in
                List {
                    Group {
                        ForEach(courses) { course in
                            CourseListCell(course: course)
                        }
                        Button("Register for a course") {
                            showCourseRegistrationSheet = true
                        }
                            .buttonStyle(ArtemisButton())
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    await viewModel.loadCourses()
                }
            }
        }
        .navigationDestination(for: CoursePath.self) { coursePath in
            CourseView(courseId: coursePath.id)
        }
        .navigationTitle(Text("course_overview_title"))
        .accountMenu(error: $viewModel.error)
        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button(action: { showNotificationSheet = true }, label: {
                    Label("Notifications", systemImage: "bell.fill")
                })
            }
        }
        .sheet(isPresented: $showCourseRegistrationSheet) {
            CourseRegistrationView()
        }
        .sheet(isPresented: $showNotificationSheet) {
            Text("Notification TODO")
        }
        .navigationBarBackButtonHidden()
        .task {
            await viewModel.loadCourses()
        }
    }
}

private struct CourseListCell: View {

    @EnvironmentObject var navigationController: NavigationController

    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                .frame(width: .extraLargeImage, height: .extraLargeImage)
                VStack(alignment: .leading) {
                    Text(course.title ?? "TODO")
                        .font(.custom("SF Pro", size: 22, relativeTo: .title))
                    Text("Exercises: \(course.exercises?.count ?? 0)")
                    Text("Lectures: \(course.lectures?.count ?? 0)")
                }
                .padding(.m)
            }
            Divider()
            HStack {
                ProgressView(value: 40, total: 100)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(course.courseColor)
                    .padding(.trailing)
                Text("\(40)/\(100)P (\(40)%)")
            }.padding(.m)
        }
        .cardModifier()
        .onTapGesture {
            navigationController.path.append(CoursePath(id: course.id, course: course))
        }
    }
}
