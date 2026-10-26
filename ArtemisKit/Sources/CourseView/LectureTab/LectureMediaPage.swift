import Common
import DesignLibrary
import Navigation
import SharedModels
import SwiftUI

/// This stack sits above the course's tab/split views so study pages use the
/// entire window on iPad while retaining the exact originating view underneath.
struct LectureMediaNavigation: View {
    @EnvironmentObject private var navigation: NavigationController
    let course: CourseForOverviewDTO

    var body: some View {
        NavigationStack(path: $navigation.lectureMediaPath) {
            Color.clear
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: LectureMediaPath.self) { path in
                    LectureMediaPage(course: course, path: path)
                        .toolbar(.visible, for: .navigationBar)
                }
        }
        .opacity(navigation.lectureMediaPath.isEmpty ? 0 : 1)
        .allowsHitTesting(!navigation.lectureMediaPath.isEmpty)
        .accessibilityHidden(navigation.lectureMediaPath.isEmpty)
    }
}

struct LectureMediaPage: View {
    let path: LectureMediaPath
    @StateObject private var viewModel: LectureDetailViewModel

    init(course: CourseForOverviewDTO, path: LectureMediaPath) {
        self.init(viewModel: LectureDetailViewModel(course: course, lectureId: path.lectureId), path: path)
    }

    init(viewModel: LectureDetailViewModel, path: LectureMediaPath) {
        self.path = path
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        DataStateView(data: $viewModel.lecture, retryHandler: { await viewModel.retryTarget() }) { lecture in
            if path.target == nil {
                AttachmentUnitContent(attachmentUnit: nil, lectureId: path.lectureId, lectureName: lecture.title ?? "",
                                      identity: "course/\(path.courseId)/lecture/\(path.lectureId)/merged")
            } else if let presentation = viewModel.targetPresentation {
                LectureUnitContent(unit: presentation.unit,
                                   identity: "course/\(path.courseId)/lecture/\(path.lectureId)/unit/\(presentation.unit.id)",
                                   explicitPage: path.target?.page,
                                   originalSlideNumber: path.target?.originalSlideNumber,
                                   visibleSlideNumbers: path.target?.visibleSlideNumbers,
                                   studentVersion: presentation.studentVersion,
                                   refreshSlide: slideRefresh)
                .onAppear { viewModel.completePresentedUnitIfNeeded() }
            } else {
                ContentUnavailableView {
                    Label("Lecture unit is unavailable", systemImage: "doc.questionmark")
                } description: {
                    Text("The referenced lecture unit could not be opened.")
                } actions: {
                    Button("Retry") { Task { await viewModel.retryTarget() } }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .navigationTitle(viewModel.targetPresentation?.unit.baseUnit.name ?? viewModel.lecture.value?.title ?? "Lecture")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
        .task {
            viewModel.configureTarget(path.target)
            await viewModel.loadLecture()
        }
    }

    private var slideRefresh: (() async -> DataState<LectureSlideAccess>)? {
        guard let target = path.target, target.slideId != nil || target.originalSlideNumber != nil else { return nil }
        return { await viewModel.refreshSlideAccess(for: target) }
    }
}
