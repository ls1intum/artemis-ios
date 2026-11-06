import SharedModels
import XCTest
@testable import Quiz

final class QuizReviewTests: XCTestCase {
    func testEvaluatedSelectedAnswerRestoresOriginalAttemptChoice() throws {
        let json = #"{"type":"multiple-choice","quizQuestion":{"id":5,"type":"multiple-choice"},"selectedOptions":[{"id":7}],"scoreInPoints":2}"#
        let answer = try JSONDecoder().decode(DTO.SubmittedAnswerAfterEvaluation.self, from: Data(json.utf8))
        guard case .multipleChoice(let restored) = answer.reviewAnswer else { XCTFail("Wrong answer kind"); return }
        XCTAssertEqual(restored.selectedOptions?.compactMap(\.id), [7])
        XCTAssertEqual(restored.quizQuestion?.id, 5)
    }
    func testWithheldCorrectnessRemainsUnknownAfterSubmission() {
        XCTAssertEqual(QuizReviewCorrectness.resolve(submitted: true, correct: nil), .unknown)
        XCTAssertEqual(QuizReviewCorrectness.resolve(submitted: true, correct: false), .incorrect)
        XCTAssertEqual(QuizReviewCorrectness.resolve(submitted: true, correct: true), .correct)
        XCTAssertEqual(QuizReviewCorrectness.resolve(submitted: false, correct: true), .unknown)
    }
}
