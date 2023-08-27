import SwiftUI
import Common
import SharedModels
import Navigation
import Messages
import DesignLibrary
import MarkdownUI

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
    
    @State
    private var isAccepted: Bool = false
    
    @State
    private var isCodeOfConductPresented: Bool = false
    
    @State
    private var codeOfConduct: String = ""
    
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
                        MessagesTabView(searchText: $searchText, course: course, isAccepted: $isAccepted)
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
        .toolbar {
            if navigationController.courseTab == .communication {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isAccepted {
                        Button {
                            isAccepted = true
                        } label: {
                            Text("Accept")
                        }
                    } else {
                        Button {
                            isCodeOfConductPresented = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        
                    }
                }
            }
        }
            .navigationTitle(viewModel.course.value?.title ?? R.string.localizable.loading())
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText)
            .onChange(of: navigationController.courseTab) { _ in
                searchText = ""
            }
            .sheet(isPresented: $isCodeOfConductPresented) {
                NavigationStack {
                    ScrollView {
                        Markdown(codeOfConduct)
                            .task {
                                do {
                                    let data = try await URLSession.shared.data(
                                        from: URL(string: "https://raw.githubusercontent.com/ls1intum/Artemis/develop/CODE_OF_CONDUCT.md")!)
                                    codeOfConduct = .init(data: data.0, encoding: .utf8) ?? "Error"
                                } catch {
                                    print(error.localizedDescription)
                                }
                            }
                    }
                    .padding()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                isCodeOfConductPresented = false
                            }
                        }
                    }
                }
            }
    }
}
