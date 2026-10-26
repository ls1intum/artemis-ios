import SharedModels
import SwiftUI
import XCTest
@testable import Quiz

@MainActor
final class TrainingRenderingTests: XCTestCase {
    func testShortAnswerDraftSurvivesNativeResizeAndReentry() async throws {
        let json = """
        {"id":1,"isRated":true,"isNewSession":false,"questionIds":[],"quizQuestionWithSolutionDTO":{"id":1,"type":"short-answer",
        "title":"Training","text":"[-spot 1] and [-spot 2]","spots":[{"id":913,"spotNr":1},{"id":914,"spotNr":2}]}}
        """
        let question = try JSONDecoder().decode(DTO.QuizQuestionTraining.self, from: Data(json.utf8))
        let service = TrainingStub(pages: [.init(questions: [question], hasNext: false)])
        let model = QuizTrainingViewModel(courseId: 7, transport: service)
        await model.loadQuestions()
        let window = try makeTestWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        defer { window.isHidden = true; window.rootViewController = nil }
        let host = UIHostingController(rootView: NavigationStack { QuizTraingQuestionsView(viewModel: model) })
        window.rootViewController = host; window.makeKeyAndVisible()
        let fields = try await textFields(in: host.view)
        XCTAssertEqual(fields.count, 2)
        fields[0].text = "BINARY SEARCH"
        fields[0].sendActions(for: .editingChanged)
        for _ in 0..<20 {
            if case .shortAnswer(let draft) = model.draft, draft.submittedTexts?.first?.text == "BINARY SEARCH" { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        guard case .shortAnswer(let draft) = model.draft else { XCTFail("Draft was not retained"); return }
        XCTAssertEqual(draft.submittedTexts?.first?.spot?.id, 913)
        XCTAssertEqual(draft.submittedTexts?.first?.text, "BINARY SEARCH")
        window.frame = CGRect(x: 0, y: 0, width: 1024, height: 768)
        host.view.frame = window.bounds; host.view.layoutIfNeeded()
        let resized = try await textFields(in: host.view)
        XCTAssertEqual(resized.first?.text, "BINARY SEARCH")
        let reopened = UIHostingController(rootView: NavigationStack {
            QuizTraingQuestionsView(viewModel: model).dynamicTypeSize(.accessibility3).preferredColorScheme(.dark)
        })
        window.rootViewController = reopened
        let restored = try await textFields(in: reopened.view)
        XCTAssertEqual(restored.first?.text, "BINARY SEARCH")
        XCTAssertEqual(service.requests.count, 1)
        XCTAssertEqual(service.submits, 0)
    }
    private func textFields(in root: UIView) async throws -> [UITextField] {
        for _ in 0..<50 {
            root.layoutIfNeeded()
            let fields = descendants(root)
            if fields.count == 2 { return fields }
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTFail("Native short-answer text fields did not mount")
        return []
    }
    private func descendants(_ view: UIView) -> [UITextField] {
        (view as? UITextField).map { [$0] } ?? view.subviews.flatMap { descendants($0) }
    }
}
