import Common
import SharedModels
import XCTest
@testable import Quiz

final class MixedQuizReviewTests: XCTestCase {
    func testOwningStudentMixedReviewPreservesServerShortAnswerEvaluationAndAllDnDAlternatives() throws {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: Self.self)
        #endif
        let url = try XCTUnwrap(bundle.url(forResource: "qa-mixed-quiz-review", withExtension: "json", subdirectory: "Fixtures/StudentQA") ??
                                bundle.url(forResource: "qa-mixed-quiz-review", withExtension: "json"))
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .customISO8601
        let participation = try decoder.decode(DTO.StudentQuizParticipation.self, from: Data(contentsOf: url))
        guard case .afterQuizEnd(let review) = participation else { XCTFail("Solutions were not authorized"); return }
        let questions = try XCTUnwrap(review.exercise?.quizQuestions)
        let answers = try XCTUnwrap(review.submissions?.first(where: { $0.id == 19 })?.submittedAnswers)
        for question in questions {
            XCTAssertNotNil(QuizReviewQuestionContent(question).explanation)
            switch question {
            case .shortAnswer(let short):
                guard case .shortAnswer(let evaluated) = answers.first(where: { $0.question?.id == short.id }) else { XCTFail("Missing evaluated answer"); return }
                let value = ShortAnswerReviewPresentation(question: short, answer: evaluated)
                XCTAssertEqual(value.answer(number: 1)?.spotID, 913)
                XCTAssertEqual(value.answer(number: 1)?.text, "binary search")
                XCTAssertEqual(value.answer(number: 1)?.isCorrect, true)
                XCTAssertEqual(value.answer(number: 2)?.spotID, 914)
                XCTAssertEqual(value.answer(number: 2)?.text, "linear")
                XCTAssertEqual(value.answer(number: 2)?.isCorrect, false)
            case .dragAndDrop(let drag):
                XCTAssertEqual(drag.correctMappings?.count, 4)
                guard case .dragAndDrop(let evaluated) = answers.first(where: { $0.question?.id == drag.id }) else { XCTFail("Missing evaluated mapping"); return }
                for mapping in evaluated.mappings ?? [] {
                    XCTAssertTrue(try XCTUnwrap(QuizDropEvaluation.correct(locationID: mapping.dropLocation?.id, selectedItemID: mapping.dragItem?.id, correctMappings: drag.correctMappings)))
                }
                XCTAssertEqual(drag.backgroundFilePath, "drag-and-drop/questions/12/backgrounds/results-alternatives.png")
            default: XCTFail("Unexpected fixture type")
            }
        }
    }
}
