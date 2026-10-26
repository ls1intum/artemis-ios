import XCTest
@testable import CourseView

final class ReviewTransportTests: XCTestCase {
    func testCodeReferenceKeepsZeroBasedRangeAndRejectsMalformedLocation() {
        let location = ReviewCodeLocation(reference: "file:src/Search.java_line:0-2")
        XCTAssertEqual(location?.file, "src/Search.java")
        XCTAssertEqual(location?.firstLine, 0)
        XCTAssertEqual(location?.lastLine, 2)
        XCTAssertNil(ReviewCodeLocation(reference: "file:src/A.java_line:-1"))
    }
    func testCapturedSessionRequiresSameAccountServerAndToken() {
        let original = ReviewSession(baseURL: URL(string: "https://one.example")!, username: "alice", token: "a")
        XCTAssertTrue(original.matches(original))
        XCTAssertFalse(original.matches(.init(baseURL: URL(string: "https://two.example")!, username: "alice", token: "a")))
        XCTAssertFalse(original.matches(.init(baseURL: original.baseURL, username: "bob", token: "a")))
        XCTAssertFalse(original.matches(nil))
    }
    func testFileURLRejectsCredentialsAndOtherOrigins() throws {
        let session = ReviewSession(baseURL: URL(string: "https://one.example")!, username: "alice", token: "a")
        XCTAssertEqual(try session.url(for: "/api/core/files/submission.pdf").host, "one.example")
        XCTAssertThrowsError(try session.url(for: "https://other.example/a.pdf"))
        XCTAssertThrowsError(try session.url(for: "https://user:secret@one.example/a.pdf"))
    }
    func testImmutableProgrammingSourcePathRequiresFullCommit() throws {
        let ref = ReviewReference(courseID: 1, exerciseID: 2, participationID: 3, submissionID: 4, resultID: 5)
        XCTAssertThrowsError(try ReviewSourcePath.file(reference: ref, commit: "HEAD", name: "Main.java"))
        let path = try ReviewSourcePath.file(reference: ref, commit: String(repeating: "a", count: 40), name: "src/A B.java")
        XCTAssertTrue(path.contains("/commits/"))
        XCTAssertTrue(path.contains("file=src/A%20B.java"))
    }
}
