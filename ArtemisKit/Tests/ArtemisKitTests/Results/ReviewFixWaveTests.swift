import Common
import SharedModels
import SwiftUI
import XCTest
@testable import CourseView
@testable import Quiz

final class ReviewFixWaveTests: XCTestCase {
    func testShortAnswerUsesStableSpotIdentityAndServerEvaluationWithoutExactMatch() throws {
        let question = try JSONDecoder().decode(DTO.ShortAnswerQuizQuestionWithSolution.self, from: Data(#"""
        {"id":1,
        "type":"short-answer",
        "text":"[-spot 1] then [-spot 2]",
        "spots":[{"id":913,
        "spotNr":1},{"id":914,
        "spotNr":2}],
        "correctMappings":[{"spot":{"id":913,
        "spotNr":1},
        "solution":{"text":"expected"}}]}
        """#.utf8))
        let answer = try JSONDecoder().decode(DTO.ShortAnswerSubmittedAnswerAfterEvaluation.self, from: Data(#"""
        {"type":"short-answer",
        "submittedTexts":[{"text":"EXPECTED",
        "isCorrect":true,
        "spot":{"id":913,
        "spotNr":1}},{"text":"unknown",
        "spot":{"id":914,
        "spotNr":2}}]}
        """#.utf8))
        let presentation = ShortAnswerReviewPresentation(question: question, answer: answer)
        XCTAssertEqual(presentation.answer(number: 1)?.spotID, 913)
        XCTAssertEqual(presentation.answer(number: 1)?.text, "EXPECTED")
        XCTAssertEqual(presentation.answer(number: 1)?.isCorrect, true)
        XCTAssertEqual(presentation.answer(number: 2)?.text, "unknown")
        XCTAssertNil(presentation.answer(number: 2)?.isCorrect)
        guard case .answer = presentation.segments.first else { XCTFail("Leading placeholder was moved after prose"); return }
    }
    func testDnDEmptyRequiredAndWithheldStates() throws {
        XCTAssertTrue(try XCTUnwrap(QuizDropEvaluation.correct(locationID: 1, selectedItemID: nil, correctMappings: [])))
        XCTAssertFalse(try XCTUnwrap(QuizDropEvaluation.correct(locationID: 1, selectedItemID: nil, correctMappings: [.init(dragItem: .init(id: 2), dropLocation: .init(id: 1))])))
        XCTAssertNil(QuizDropEvaluation.correct(locationID: 1, selectedItemID: 2, correctMappings: nil))
    }
    func testManualPracticeDeadlineRebuildAndAthenaPresentationStates() {
        let now = Date(timeIntervalSince1970: 1000)
        func state(_ type: String, exercise: String = "SEMI_AUTOMATIC", due: Double? = nil, practice: Bool = false, successful: Bool? = nil, completion: Double? = 500) -> ReviewAssessmentState {
            ReviewAssessmentState.resolve(.init(exerciseType: "programming", exerciseAssessment: exercise, resultAssessment: type,
                                                completion: completion.map(Date.init(timeIntervalSince1970:)), successful: successful, practice: practice,
                                                assessmentDue: due.map(Date.init(timeIntervalSince1970:)), rebuild: Date(timeIntervalSince1970: 2000)), now: now)
        }
        XCTAssertEqual(state("MANUAL"), .assessed)
        XCTAssertEqual(state("AUTOMATIC", due: 900), .assessed)
        XCTAssertEqual(state("AUTOMATIC", due: 1100), .preliminary)
        XCTAssertEqual(state("AUTOMATIC", practice: true), .assessed)
        XCTAssertEqual(state("AUTOMATIC", exercise: "AUTOMATIC"), .preliminary)
        XCTAssertEqual(state("AUTOMATIC_ATHENA", completion: 1100), .feedbackPending)
        XCTAssertEqual(state("AUTOMATIC_ATHENA", completion: nil), .feedbackPending)
        XCTAssertEqual(state("AUTOMATIC_ATHENA", completion: 900), .feedbackTimedOut)
        XCTAssertEqual(state("AUTOMATIC_ATHENA", successful: false), .feedbackFailed)
        XCTAssertEqual(state("AUTOMATIC_ATHENA", successful: true), .preliminary)
    }
    func testSharedBadgePointsAndPercentUseRequestedPrecisionAndPreserveMissing() throws {
        let decoder = JSONDecoder()
        let exercise = try decoder.decode(Exercise.self, from: Data(#"{"id":1,"type":"text","mode":"INDIVIDUAL","includedInOverallScore":"INCLUDED_COMPLETELY","maxPoints":10}"#.utf8))
        let participation = try decoder.decode(Participation.self, from: Data(#"{"id":1,"type":"student"}"#.utf8)).baseParticipation
        let result = try decoder.decode(SharedModels.Result.self, from: Data(#"{"score":82.5,"rated":true}"#.utf8))
        for precision in 0...2 {
            let badge = SubmissionResultView(exercise: exercise, participation: participation, result: result, missingResultInfo: .noInformation,
                                             isBuilding: false, scorePrecision: precision)
            XCTAssertTrue(try XCTUnwrap(badge.score).contains(try XCTUnwrap(ReviewScore.points(score: 82.5, maximum: 10, precision: precision)).clean))
        }
        let precise = try decoder.decode(SharedModels.Result.self, from: Data(#"{"score":82.555,"rated":true}"#.utf8))
        let preciseBadge = SubmissionResultView(exercise: exercise, participation: participation, result: precise, missingResultInfo: .noInformation, isBuilding: false, scorePrecision: 2)
        XCTAssertTrue(try XCTUnwrap(preciseBadge.score).contains("82.56"))
        let zero = try decoder.decode(SharedModels.Result.self, from: Data(#"{"score":0,"rated":true}"#.utf8))
        XCTAssertNotNil(SubmissionResultView(exercise: exercise, participation: participation, result: zero, missingResultInfo: .noInformation, isBuilding: false, scorePrecision: 2).score)
        let unknown = try decoder.decode(SharedModels.Result.self, from: Data("{}".utf8))
        XCTAssertNil(SubmissionResultView(exercise: exercise, participation: participation, result: unknown, missingResultInfo: .noInformation, isBuilding: false, scorePrecision: 2).score)
    }
    func testSharedProgrammingBadgeUsesManualFinalityBeforeRebuild() throws {
        var programming = ProgrammingExercise(id: 1)
        programming.assessmentType = .semiAutomatic
        programming.buildAndTestStudentSubmissionsAfterDueDate = Date(timeIntervalSince1970: 2000)
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(SharedModels.Result.self, from: Data(#"{"id":5,"assessmentType":"MANUAL","completionDate":"1970-01-01T00:01:00Z","score":100}"#.utf8))
        let participation = try decoder.decode(Participation.self, from: Data(#"{"id":1,"type":"student"}"#.utf8)).baseParticipation
        let badge = SubmissionResultView(exercise: .programming(exercise: programming), participation: participation, result: result,
                                         missingResultInfo: .noInformation, isBuilding: false, scorePrecision: 2)
        XCTAssertEqual(badge.presentationState, .assessed)
    }
    func testDecimalHalfBoundaryMatchesWebRounding() {
        XCTAssertEqual(ReviewScore.rounded(1.005, precision: 2), 1.01)
        XCTAssertEqual(ReviewScore.points(score: 10.05, maximum: 10, precision: 2), 1.01)
        XCTAssertEqual(ReviewScore.rounded(-1.005, precision: 2), -1)
    }
    func testCourseBadgeContextLoadsPrecisionFromExistingStudentCourseEndpoint() async throws {
        let precision = try await CourseScoreMetadata.load(courseID: 7, reader: CoursePrecisionReader())
        XCTAssertEqual(precision, 2)
    }
    func testReleasedQuestionExplanationsSurviveForAllTypesWithoutOptionExplanations() throws {
        for type in ["multiple-choice", "short-answer", "drag-and-drop"] {
            let data = Data("{\"id\":1,\"type\":\"\(type)\",\"explanation\":\"Released explanation\"}".utf8)
            let question = try JSONDecoder().decode(DTO.QuizQuestionWithSolution.self, from: data)
            XCTAssertEqual(QuizReviewQuestionContent(question).explanation, "Released explanation")
        }
    }
}

private struct CoursePrecisionReader: ReviewReading {
    var isCurrent: Bool { true }
    func data(_ path: String) async throws -> Data {
        guard path == "/api/course/courses/7/for-overview" else { throw ReviewError.http(404) }
        return Data(#"{"id":7,"accuracyOfScores":2}"#.utf8)
    }
}
