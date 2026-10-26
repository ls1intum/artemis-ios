import SharedModels
import SwiftUI
import XCTest
@testable import CourseView
@testable import Quiz

@MainActor
final class TrainingToolbarIntegrationTests: XCTestCase {
    func testCourseTabHierarchyHidesBarForTrainingAndRestoresItAfterBack() async throws {
        let question = try JSONDecoder().decode(DTO.QuizQuestionTraining.self, from: Data("""
        {"id":1,"isRated":true,"isNewSession":false,"questionIds":[],
        "quizQuestionWithSolutionDTO":{"id":1,"type":"multiple-choice","answerOptions":[{"id":2,"text":"Answer"}]}}
        """.utf8))
        let service = TrainingStub(pages: [.init(questions: [question], hasNext: false)])
        let model = QuizTrainingViewModel(courseId: 7, transport: service)
        let navigation = TrainingToolbarNavigation()
        let host = UIHostingController(rootView: TrainingCourseTabHierarchy(navigation: navigation, model: model))
        let window = try makeTestWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        let tabBar = try await mountedTabBar(in: host.view)
        XCTAssertTrue(visible(tabBar, in: window))
        navigation.trainingVisible = true
        try await waitUntil { model.phase == .answering }
        try await waitUntil { !self.visible(tabBar, in: window) }
        XCTAssertFalse(visible(tabBar, in: window), "Course tabs must not cover Submit answer")
        XCTAssertEqual(service.requests.count, 1)
        XCTAssertEqual(service.submits, 0)
        navigation.trainingVisible = false
        try await waitUntil { self.visible(tabBar, in: window) }
        XCTAssertTrue(visible(tabBar, in: window), "Native Back must restore course navigation")
        XCTAssertEqual(model.currentQuestion?.id, 1)
    }
    func testQuestionScoreUsesEvaluatedMaximumAndPreservesZeroOrUnknown() async throws {
        for maximum in [Double(4), 0, nil] {
            let transport = TrainingMaximumTransport(maximum: maximum)
            let model = QuizTrainingViewModel(courseId: 7, transport: transport)
            await model.loadQuestions()
            await model.submitAnswer(questionId: 1, isRated: true, answer: .multipleChoice(.init(quizQuestion: .init(id: 1), selectedOptions: [], _type: .multipleChoice)))
            XCTAssertEqual(model.currentScore?.total, maximum)
            XCTAssertEqual(model.phase, .evaluated)
        }
    }
    private func mountedTabBar(in root: UIView) async throws -> UITabBar {
        for _ in 0..<100 {
            root.layoutIfNeeded()
            if let bar = descendants(root).first { return bar }
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTFail("The actual native course tab bar did not mount")
        throw NSError(domain: "TrainingToolbarIntegrationTests", code: 1)
    }
    private func descendants(_ view: UIView) -> [UITabBar] {
        (view as? UITabBar).map { [$0] } ?? view.subviews.flatMap { descendants($0) }
    }
    private func visible(_ bar: UITabBar, in window: UIWindow) -> Bool {
        !bar.isHidden && bar.alpha > 0.01 && bar.window != nil && window.bounds.intersects(bar.convert(bar.bounds, to: window))
    }
    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<100 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(20))
        }
    }
}

@MainActor
private final class TrainingToolbarNavigation: ObservableObject {
    @Published var trainingVisible = false
}

private struct TrainingCourseTabHierarchy: View {
    @ObservedObject var navigation: TrainingToolbarNavigation
    let model: QuizTrainingViewModel
    var body: some View {
        TabView {
            Tab("Exercises", systemImage: "list.bullet.clipboard.fill") {
                TabBarIpad {
                    NavigationSplitView(preferredCompactColumn: .constant(.detail)) {
                        Text("Exercises")
                    } detail: {
                        NavigationStack {
                            Text("Training overview")
                                .navigationDestination(isPresented: $navigation.trainingVisible) {
                                    QuizTraingQuestionsView(viewModel: model)
                                }
                        }
                    }
                }
            }
            Tab("Lectures", systemImage: "character.book.closed.fill") { Text("Lectures") }
        }
        .environment(\.horizontalSizeClass, .compact)
    }
}

private struct TrainingMaximumTransport: TrainingServing {
    let maximum: Double?
    var isCurrent: Bool { true }
    func page(_ request: TrainingPageRequest) async throws -> TrainingPage {
        let question = try JSONDecoder().decode(DTO.QuizQuestionTraining.self, from: Data("""
        {"id":1,"isRated":true,"isNewSession":false,"questionIds":[],
        "quizQuestionWithSolutionDTO":{"id":1,"type":"multiple-choice","points":2}}
        """.utf8))
        return .init(questions: [question], hasNext: false)
    }
    func submit(questionID: Int64, rated: Bool, answer: Data) async throws -> DTO.SubmittedAnswerAfterEvaluation {
        let points = maximum.map { String($0) } ?? "null"
        return try JSONDecoder().decode(DTO.SubmittedAnswerAfterEvaluation.self, from: Data("""
        {"type":"multiple-choice","scoreInPoints":0,"quizQuestion":{"id":1,"type":"multiple-choice","points":\(points)}}
        """.utf8))
    }
}
