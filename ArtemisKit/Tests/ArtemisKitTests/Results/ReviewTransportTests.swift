import SharedModels
import UserStore
import XCTest
@testable import CourseView

final class ReviewTransportTests: XCTestCase {
    @MainActor
    func testAuthenticatedAccountIsCapturedWithoutRememberedUsername() throws {
        let account = UserSessionFactory.shared
        let oldLoggedIn = account.isLoggedIn
        let oldUsername = account.username
        let oldInstitution = account.institution
        let oldUserData = UserDefaults.standard.data(forKey: "User")
        defer {
            account.saveUsername(username: oldUsername)
            account.saveInstitution(identifier: oldInstitution)
            account.setUserLoggedIn(isLoggedIn: oldLoggedIn)
            if let oldUserData { UserDefaults.standard.set(oldUserData, forKey: "User") } else { UserDefaults.standard.removeObject(forKey: "User") }
        }
        account.saveInstitution(identifier: .custom(URL(string: "https://review.example")!))
        account.saveUsername(username: nil)
        account.user = .mock
        var currentToken: String? = "synthetic-review-token"
        account.setUserLoggedIn(isLoggedIn: true)

        let captured = try XCTUnwrap(ReviewSession.current(user: account, token: { currentToken }))
        XCTAssertEqual(captured.username, Account.mock.login)
        XCTAssertNil(account.username, "Opening results must preserve the remembered-login preference")
        let transport = ReviewTransport(captured: captured, currentSession: { ReviewSession.current(user: account, token: { currentToken }) })
        defer { transport.invalidate() }
        XCTAssertTrue(transport.isCurrent)
        currentToken = nil
        XCTAssertNil(ReviewSession.current(user: account, token: { currentToken }), "Authenticated account data alone cannot authorize a request")
        XCTAssertFalse(transport.isCurrent)
        currentToken = ""
        XCTAssertNil(ReviewSession.current(user: account, token: { currentToken }))
        currentToken = "synthetic-review-token"
        account.setUserLoggedIn(isLoggedIn: false)
        XCTAssertNil(ReviewSession.current(user: account, token: { currentToken }))
    }

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
