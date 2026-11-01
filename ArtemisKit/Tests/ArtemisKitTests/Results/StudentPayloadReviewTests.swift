import XCTest
@testable import CourseView

/// Sanitized snapshots fetched with the synthetic owning student account, not staff payloads.
final class StudentPayloadReviewTests: XCTestCase {
    func testOwningStudentFiveExercisePayloadsKeepExactIdentity() async throws {
        let reader = StudentPayloadReader()
        for (exercise, participation, submission, result, score) in [(10, 10, 10, 1, 82.5), (11, 11, 12, 2, 65.0), (12, 12, 13, 3, 90.0), (13, 13, 14, 4, 60.0), (14, 14, 15, 5, 50.0)] {
            let reference = ReviewReference(courseID: 7, exerciseID: exercise, participationID: participation, submissionID: submission, resultID: result)
            let document = try await ReviewLoader(reader: reader).load(reference)
            XCTAssertEqual(document.submission.id, submission)
            XCTAssertEqual(document.result.id, result)
            if exercise != 14 { XCTAssertEqual(document.result.score, score) }
            if exercise == 10 { XCTAssertFalse(document.submission.blocks?.isEmpty ?? true) }
            if exercise == 11 { XCTAssertEqual(document.submission.filePath?.hasSuffix("Algorithm_Report.pdf"), true) }
            if exercise == 13 { XCTAssertEqual(document.feedback.filter { $0.group == .tests }.count, 5) }
            if exercise == 14 {
                guard case .afterQuizEnd(let quiz) = document.quiz else { XCTFail("Released questions were lost"); return }
                XCTAssertEqual(quiz.submissions?.first?.id, 15)
                XCTAssertFalse(quiz.exercise?.quizQuestions?.isEmpty ?? true)
            }
        }
    }
}

private struct StudentPayloadReader: ReviewReading {
    let isCurrent = true
    func data(_ path: String) async throws -> Data {
        let name: String
        if path.hasPrefix("/api/exercise/exercises/") {
            let id = path.split(separator: "/")[3]
            name = "qa-exercise-\(id)"
        } else {
            switch path {
            case "/api/text/participations/10/text-editor?resultId=1": name = "qa-text-text-editor"
            case "/api/assessment/participations/10/results/1/details": name = "qa-text-details"
            case "/api/assessment/participations/11/results/2/details": name = "qa-file-upload-details"
            case "/api/modeling/participations/12/submissions-with-results": name = "qa-modeling-submissions-with-results"
            case "/api/programming/programming-exercise-participations/13/student-participation-with-all-results": name = "qa-programming-history"
            case "/api/assessment/participations/13/results/4/details": name = "qa-programming-details"
            case "/api/quiz/quiz-exercises/14/participations/14/result?submissionId=15": name = "qa-quiz-review"
            default: throw ReviewError.http(404)
            }
        }
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: StudentPayloadReviewTests.self)
        #endif
        let url = try XCTUnwrap(bundle.url(forResource: name, withExtension: "json", subdirectory: "Fixtures/StudentQA") ?? bundle.url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }
}
