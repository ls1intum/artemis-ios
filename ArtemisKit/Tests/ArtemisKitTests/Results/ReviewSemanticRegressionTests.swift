import Common
import SharedModels
import SwiftUI
import XCTest
@testable import CourseView
@testable import Quiz

final class ReviewSemanticRegressionTests: XCTestCase {
    func testSelectedShortAnswerRestoresPlaceholderUsingSpotNumberRatherThanID() throws {
        let question = try JSONDecoder().decode(DTO.ShortAnswerQuizQuestionWithSolution.self, from: Data(#"{"id":1,"type":"short-answer","text":"[-spot 1]","spots":[{"id":913,"spotNr":1}]}"#.utf8))
        let answer = try JSONDecoder().decode(DTO.SubmittedAnswerAfterEvaluation.self, from: Data(#"""
        {"type":"short-answer",
        "quizQuestion":{"id":1,
        "type":"short-answer"},
        "submittedTexts":[{"text":"Answer",
        "isCorrect":true,
        "spot":{"id":913,
        "spotNr":1}}]}
        """#.utf8))
        guard case .shortAnswer(let evaluated) = answer else { XCTFail("Wrong submitted type"); return }
        let presentation = ShortAnswerReviewPresentation(question: question, answer: evaluated)
        XCTAssertEqual(presentation.answer(number: 1)?.text, "Answer")
        XCTAssertEqual(presentation.answer(number: 1)?.spotID, 913)
    }
    func testDnDAcceptsAnyAuthorizedMappingForLocation() throws {
        let mappings = try JSONDecoder().decode([DTO.DragAndDropMapping].self, from: Data(#"[{"dragItem":{"id":11},"dropLocation":{"id":1}},{"dragItem":{"id":12},"dropLocation":{"id":1}}]"#.utf8))
        let view = DropLocation(questionId: 1, dragItems: [.init(id: 11), .init(id: 12)], location: .init(id: 1), scaleX: 1, scaleY: 1,
                                mappings: .constant([.init(dragItem: .init(id: 12), dropLocation: .init(id: 1))]), correctMappings: mappings)
        XCTAssertTrue(try XCTUnwrap(view.isCorrect))
    }
    func testFinalManualProgrammingAssessmentIsNotMadePreliminaryByRebuildDate() throws {
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let exercise = try decoder.decode(ReviewExercise.self, from: Data(#"""
        {"id":1,
        "type":"programming",
        "assessmentType":"SEMI_AUTOMATIC",
        "buildAndTestStudentSubmissionsAfterDueDate":"2026-12-01T00:00:00Z"}
        """#.utf8))
        let result = try decoder.decode(ReviewResult.self, from: Data(#"{"id":5,"assessmentType":"MANUAL","completionDate":"2026-10-01T00:00:00Z"}"#.utf8))
        let submission = try decoder.decode(ReviewSubmission.self, from: Data(#"{"id":4}"#.utf8))
        let reference = ReviewReference(courseID: 1, exerciseID: 1, participationID: 3, submissionID: 4, resultID: 5)
        XCTAssertFalse(ReviewDocument(reference: reference, exercise: exercise, submission: submission, result: result, feedback: []).preliminary)
    }
}
