import XCTest
@testable import CourseView

final class StudentReviewTests: XCTestCase {
    func testFeedbackDecodesSignedIDAndOnlyPublicStandardMessage() throws {
        let json = #"""
        {"id":-9223372036854775000,"text":"Title","detailText":"Detail","credits":0,"type":"AUTOMATIC_ADAPTED",
         "gradingInstruction":{"feedback":"Released comment","instructionDescription":"PRIVATE","gradingScale":"PRIVATE"}}
        """#
        let feedback = try JSONDecoder().decode(StudentFeedback.self, from: Data(json.utf8))
        XCTAssertEqual(feedback.id, -9_223_372_036_854_775_000)
        XCTAssertEqual(feedback.standardMessage, "Released comment")
        XCTAssertEqual(feedback.message, "Released comment\nDetail\nTitle")
        XCTAssertEqual(feedback.group, .tests)
        XCTAssertEqual(feedback.credits, 0)
    }

    func testStaticAnalysisMapsPublicDiagnosticAndOneBasedToolLines() throws {
        let json = #"""
        {"id":-7,"type":"AUTOMATIC","text":"SCAFeedbackIdentifier:Style",
         "detailText":"{\"filePath\":\"src/Search.java\",\"startLine\":1,\"endLine\":3,\"rule\":\"Bounds\",\"message\":\"Check empty input\",\"priority\":\"HIGH\"}"}
        """#
        let feedback = try JSONDecoder().decode(StudentFeedback.self, from: Data(json.utf8))
        XCTAssertEqual(feedback.group, .staticAnalysis)
        XCTAssertEqual(feedback.message, "Check empty input")
        XCTAssertEqual(feedback.sourceReference, "file:src/Search.java_line:0-2")
        XCTAssertEqual(feedback.title, "Style · Bounds")
    }
    func testSubmissionPolicyPrefixIsGroupedAndStrippedFromTitle() throws {
        let json = #"{"type":"AUTOMATIC","text":"SubPolFeedbackIdentifier:Too many submissions","detailText":"One point deduction","credits":-1}"#
        let feedback = try JSONDecoder().decode(StudentFeedback.self, from: Data(json.utf8))
        XCTAssertEqual(feedback.group, .policy)
        XCTAssertEqual(feedback.title, "Too many submissions")
    }

    func testLateStatusUsesIndividualDeadlineAndPreservesUnknownDates() throws {
        let submitted = Date(timeIntervalSince1970: 200)
        XCTAssertFalse(try XCTUnwrap(ReviewDeadline.isLate(submitted: submitted, due: Date(timeIntervalSince1970: 100), individual: Date(timeIntervalSince1970: 300))))
        XCTAssertTrue(try XCTUnwrap(ReviewDeadline.isLate(submitted: submitted, due: Date(timeIntervalSince1970: 100), individual: nil)))
        XCTAssertNil(ReviewDeadline.isLate(submitted: submitted, due: nil, individual: nil))
    }

    func testMissingScoreStaysMissingAndBonusUsesCoursePrecision() {
        XCTAssertNil(ReviewScore.points(score: nil, maximum: 10, precision: 2))
        XCTAssertEqual(ReviewScore.points(score: 0, maximum: 10, precision: 2), 0)
        XCTAssertEqual(ReviewScore.points(score: 112.345, maximum: 10, precision: 2), 11.23)
    }

    func testUTF16AnchorKeepsEmojiCombiningRTLAndCRLF() {
        let text = "A😀e\u{301}\r\nאב"
        XCTAssertEqual(ReviewTextAnchor.range(start: 1, end: 3, in: text), NSRange(location: 1, length: 2))
        XCTAssertEqual(ReviewTextAnchor.range(start: 3, end: 5, in: text), NSRange(location: 3, length: 2))
        XCTAssertNil(ReviewTextAnchor.range(start: 2, end: 3, in: text))
        XCTAssertNil(ReviewTextAnchor.range(start: -1, end: 2, in: text))
        XCTAssertNil(ReviewTextAnchor.range(start: 2, end: 100, in: text))
    }

    func testExactSourceRejectsNewerWorkAndMismatchedResult() throws {
        let json = #"{"id":7,"submissions":[{"id":20,"text":"new draft","results":[]},{"id":19,"text":"assessed","results":[{"id":42,"score":0}]}]}"#
        let participation = try JSONDecoder().decode(ReviewParticipation.self, from: Data(json.utf8))
        XCTAssertEqual(try participation.assessedSubmission(submissionID: 19, resultID: 42).text, "assessed")
        XCTAssertThrowsError(try participation.assessedSubmission(submissionID: 20, resultID: 42))
        XCTAssertThrowsError(try participation.assessedSubmission(submissionID: 19, resultID: 43))
    }

    func testReferenceSelectionKeepsUnratedResultAttachedToOriginalSubmission() throws {
        let json = #"{"id":7,"submissions":[{"id":20,"results":[]},{"id":19,"results":[{"id":42,"rated":false,"completionDate":"2026-10-25T12:00:00Z"}]}]}"#
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let participation = try decoder.decode(ReviewParticipation.self, from: Data(json.utf8))
        let references = participation.references(courseID: 1, exerciseID: 2)
        XCTAssertEqual(references.count, 1)
        XCTAssertEqual(references.first?.submissionID, 19)
        XCTAssertEqual(references.first?.resultID, 42)
        XCTAssertEqual(references.first?.rated, false)
    }
}
