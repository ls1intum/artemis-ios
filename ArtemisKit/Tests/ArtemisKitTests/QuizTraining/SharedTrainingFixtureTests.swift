import SharedModels
import XCTest
@testable import Quiz

final class SharedTrainingFixtureTests: XCTestCase {
    private func fixture() throws -> [String: Any] {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: Self.self)
        #endif
        let url = try XCTUnwrap(bundle.url(forResource: "quiz-training-fixtures", withExtension: "json", subdirectory: "Fixtures") ??
                                bundle.url(forResource: "quiz-training-fixtures", withExtension: "json"))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }
    func testAllSharedQuestionsRenderThroughSafeProjection() throws {
        let fixture = try fixture()
        for key in ["ratedPage1", "ratedPage2", "ratedFinalPage", "legacyUnratedPage1", "legacyUnratedPage2"] {
            let page = try XCTUnwrap(fixture[key] as? [String: Any])
            let questions = try JSONDecoder().decode([DTO.QuizQuestionTraining].self, from: JSONSerialization.data(withJSONObject: XCTUnwrap(page["body"])))
            for question in questions {
                XCTAssertTrue(TrainingProjection.canAnswer(question), "\(key) question \(question.id ?? -1)")
                let projection = TrainingProjection.answering(question)
                XCTAssertEqual(projection.id, question.id)
                XCTAssertEqual(projection.isRated, question.isRated)
                let text = try XCTUnwrap(String(data: JSONEncoder().encode(projection), encoding: .utf8))
                XCTAssertFalse(text.contains("isCorrect")); XCTAssertFalse(text.contains("correctMappings")); XCTAssertFalse(text.contains("explanation"))
            }
        }
    }
    func testAuthoritativeShortAnswerCorrectnessAndStableIDs() throws {
        let evaluations = try evaluations()
        let result = try XCTUnwrap(evaluations.first { if case .shortAnswer = $0 { return true }; return false })
        guard case .shortAnswer(let answer) = result, case .shortAnswer(let question) = answer.quizQuestion else { XCTFail("Missing short answer"); return }
        let presentation = ShortAnswerReviewPresentation(question: question, answer: answer)
        XCTAssertEqual(presentation.answer(number: 1)?.spotID, 913)
        XCTAssertEqual(presentation.answer(number: 1)?.isCorrect, true)
        XCTAssertEqual(presentation.answer(number: 2)?.isCorrect, false)
        XCTAssertEqual(TrainingProjection.shortAnswerInputs(question: question).first?.spot?.id, 913)
    }
    func testEveryAllowedDragAlternativeIsAcceptedByNativeReader() throws {
        let result = try XCTUnwrap(evaluations().first { if case .dragAndDrop = $0 { return true }; return false })
        guard case .dragAndDrop(let answer) = result, case .dragAndDrop(let question) = answer.quizQuestion else { XCTFail("Missing drag and drop"); return }
        XCTAssertEqual(question.correctMappings?.count, 4)
        for mapping in question.correctMappings ?? [] {
            XCTAssertEqual(QuizDropEvaluation.correct(locationID: mapping.dropLocation?.id, selectedItemID: mapping.dragItem?.id, correctMappings: question.correctMappings), true)
        }
    }
    private func evaluations() throws -> [DTO.SubmittedAnswerAfterEvaluation] {
        try JSONDecoder().decode([DTO.SubmittedAnswerAfterEvaluation].self, from: JSONSerialization.data(withJSONObject: XCTUnwrap(fixture()["evaluations"])))
    }
}
