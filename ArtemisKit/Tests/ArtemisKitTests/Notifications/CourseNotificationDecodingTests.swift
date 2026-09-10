import PushNotifications
import XCTest
@testable import Notifications

/// Covers both shapes the notification list is served in, because the app decides between them per response.
///
/// Artemis 10.0 moved the values of a notification out of the flat `parameters` map into a `payload` named for the
/// notification type. An install talks to whichever version its institution runs, so a version that only read one of
/// the two would show an error instead of the list on every server of the other kind, and that is the failure these
/// tests exist to catch: `parameters` used to be a required key, so its absence failed the decode of the whole page
/// rather than of the one notification that could not be read.
final class CourseNotificationDecodingTests: XCTestCase {

    private func decode(_ json: String) throws -> CourseNotification {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(CourseNotification.self, from: XCTUnwrap(json.data(using: .utf8)))
    }

    /// The shape Artemis 10.0 and later send.
    func testDecodesTypedPayload() throws {
        let notification = try decode("""
        {
          "notificationType": "newPostNotification",
          "notificationId": 5,
          "courseId": 42,
          "creationDate": "2026-09-04T12:00:00Z",
          "category": "COMMUNICATION",
          "status": "UNSEEN",
          "courseTitle": "Introduction to Software Engineering",
          "courseIconUrl": "/courses/42/icon.png",
          "payload": {
            "postId": 90037,
            "channelId": 12,
            "channelName": "announcement",
            "authorName": "Some Author",
            "postMarkdownContent": "Hello"
          },
          "relativeWebAppUrl": "/courses/42/communication?conversationId=12&focusPostId=90037"
        }
        """)

        XCTAssertEqual(notification.notificationId, 5)
        XCTAssertEqual(notification.status, .unseen)

        guard case .newPost(let post) = notification.notification else {
            return XCTFail("Expected a new post notification, got \(notification.notification)")
        }
        XCTAssertEqual(post.postId, 90037)
        XCTAssertEqual(post.channelId, 12)
        XCTAssertEqual(post.authorName, "Some Author")
        // Decoded from the notification rather than from its values, which is where it sits in both shapes
        XCTAssertEqual(post.courseId, 42)
    }

    /// The shape servers before Artemis 10.0 send, and which 10.0 keeps sending alongside the payload.
    func testDecodesLegacyFlatParameters() throws {
        let notification = try decode("""
        {
          "notificationType": "newPostNotification",
          "notificationId": 5,
          "courseId": 42,
          "creationDate": "2026-09-04T12:00:00Z",
          "category": "COMMUNICATION",
          "status": "UNSEEN",
          "parameters": {
            "postId": 90037,
            "channelId": 12,
            "channelName": "announcement",
            "authorName": "Some Author",
            "postMarkdownContent": "Hello",
            "courseTitle": "Introduction to Software Engineering",
            "courseIconUrl": "/courses/42/icon.png"
          },
          "relativeWebAppUrl": "/courses/42/communication?conversationId=12&focusPostId=90037"
        }
        """)

        guard case .newPost(let post) = notification.notification else {
            return XCTFail("Expected a new post notification, got \(notification.notification)")
        }
        XCTAssertEqual(post.postId, 90037)
        XCTAssertEqual(post.channelId, 12)
        XCTAssertEqual(post.authorName, "Some Author")
        XCTAssertEqual(post.courseId, 42)
        XCTAssertEqual(post.courseTitle, "Introduction to Software Engineering")
    }

    /// A 10.0 server sends both, and the payload is the one to read.
    func testPrefersThePayloadWhenBothShapesArePresent() throws {
        let notification = try decode("""
        {
          "notificationType": "newPostNotification",
          "notificationId": 5,
          "courseId": 42,
          "creationDate": "2026-09-04T12:00:00Z",
          "category": "COMMUNICATION",
          "status": "SEEN",
          "courseTitle": "Introduction to Software Engineering",
          "payload": { "postId": 90037, "channelName": "from the payload" },
          "parameters": { "postId": 90037, "channelName": "from the parameters" }
        }
        """)

        guard case .newPost(let post) = notification.notification else {
            return XCTFail("Expected a new post notification, got \(notification.notification)")
        }
        XCTAssertEqual(post.channelName, "from the payload")
    }

    /// A null payload counts as absent, so the values are still read rather than the decode failing.
    func testTreatsANullPayloadAsAbsent() throws {
        let notification = try decode("""
        {
          "notificationType": "newPostNotification",
          "notificationId": 5,
          "courseId": 42,
          "creationDate": "2026-09-04T12:00:00Z",
          "category": "COMMUNICATION",
          "status": "UNSEEN",
          "payload": null,
          "parameters": { "postId": 90037, "channelName": "from the parameters" }
        }
        """)

        guard case .newPost(let post) = notification.notification else {
            return XCTFail("Expected a new post notification, got \(notification.notification)")
        }
        XCTAssertEqual(post.channelName, "from the parameters")
    }

    /// A notification type this version does not know must not fail the page it arrives in.
    func testDecodesAnUnknownNotificationType() throws {
        let notification = try decode("""
        {
          "notificationType": "someNotificationTypeFromALaterRelease",
          "notificationId": 5,
          "courseId": 42,
          "creationDate": "2026-09-04T12:00:00Z",
          "category": "GENERAL",
          "status": "UNSEEN",
          "payload": { "somethingNew": 1 }
        }
        """)

        XCTAssertEqual(notification.notificationType, .unknown)
        XCTAssertNil(notification.notification.displayable)
    }
}
