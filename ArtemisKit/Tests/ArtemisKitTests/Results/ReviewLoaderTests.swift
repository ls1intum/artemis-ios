import XCTest
@testable import CourseView

final class ReviewLoaderTests: XCTestCase {
    func testTextReviewFetchesExactResultAndNeverUsesNewerDraft() async throws {
        let reader = ReviewReaderFixture(payloads: [
            "/api/exercise/exercises/2/details": #"{"exercise":{"id":2,"type":"text","course":{"id":1,"accuracyOfScores":2}}}"#,
            "/api/text/participations/3/text-editor?resultId=5": #"{"id":3,"submissions":[{"id":9,"text":"draft"},{"id":4,"text":"assessed","results":[{"id":5,"score":0}]}]}"#,
            "/api/assessment/participations/3/results/5/details": "[]"
        ])
        let document = try await ReviewLoader(reader: reader).load(.init(courseID: 1, exerciseID: 2, participationID: 3, submissionID: 4, resultID: 5))
        XCTAssertEqual(document.submission.text, "assessed")
        XCTAssertEqual(document.result.score, 0)
        XCTAssertEqual(document.exercise.course?.accuracyOfScores, 2)
    }
    func testAuthorizedAthenaModelUsesHistoryWithoutManualAssessmentEndpoint() async throws {
        let reader = ReviewReaderFixture(payloads: [
            "/api/exercise/exercises/2/details": #"{"exercise":{"id":2,"type":"modeling","course":{"id":1}}}"#,
            "/api/modeling/participations/3/submissions-with-results": #"""
            [{"id":4,"model":"{}","results":[{"id":5,"assessmentType":"AUTOMATIC_ATHENA","successful":true,"feedbacks":[{"detailText":"Released AI comment"}]}]}]
            """#
        ])
        let document = try await ReviewLoader(reader: reader).load(.init(courseID: 1, exerciseID: 2, participationID: 3, submissionID: 4, resultID: 5))
        XCTAssertEqual(document.feedback.first?.message, "Released AI comment")
        XCTAssertTrue(document.preliminary)
    }

    func testSessionChangedWhileLoadingRejectsTheCompletedPayload() async {
        let reader = ReviewReaderFixture(payloads: [
            "/api/exercise/exercises/2/details": #"{"exercise":{"id":2,"type":"text","course":{"id":1}}}"#,
            "/api/text/participations/3/text-editor?resultId=5": #"{"id":3,"submissions":[{"id":4,"text":"protected","results":[{"id":5}]}]}"#,
            "/api/assessment/participations/3/results/5/details": "[]"
        ], invalidatingPath: "/api/assessment/participations/3/results/5/details")
        do {
            _ = try await ReviewLoader(reader: reader).load(.init(courseID: 1, exerciseID: 2, participationID: 3, submissionID: 4, resultID: 5))
            XCTFail("A response from the previous account was displayed")
        } catch {
            guard case ReviewError.sessionChanged = error else { XCTFail("Wrong failure"); return }
        }
    }

    func testStaleSessionCannotReturnProtectedDocument() async {
        let reader = ReviewReaderFixture(payloads: [:], isCurrent: false)
        do {
            _ = try await ReviewLoader(reader: reader).load(.init(courseID: 1, exerciseID: 2, participationID: 3, submissionID: 4, resultID: 5))
            XCTFail("Stale session returned protected work")
        } catch { XCTAssertTrue(error is ReviewError) }
    }
}

private final class ReviewReaderFixture: ReviewReading {
    var isCurrent: Bool
    let payloads: [String: String]
    let invalidatingPath: String?
    init(payloads: [String: String], isCurrent: Bool = true, invalidatingPath: String? = nil) {
        self.payloads = payloads; self.isCurrent = isCurrent; self.invalidatingPath = invalidatingPath
    }
    func data(_ path: String) async throws -> Data {
        guard let body = payloads[path] else { throw ReviewError.http(404) }
        if path == invalidatingPath { isCurrent = false }
        return Data(body.utf8)
    }
}
