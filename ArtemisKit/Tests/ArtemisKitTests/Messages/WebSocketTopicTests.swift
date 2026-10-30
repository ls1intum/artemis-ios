import XCTest
@testable import Messages

final class WebSocketTopicTests: XCTestCase {
    func testChannelNotificationsTopic() {
        XCTAssertEqual(
            WebSocketTopic.makeChannelNotifications(courseId: 42),
            "/topic/communication/courses/42")
    }

    func testConversationNotificationsTopic() {
        XCTAssertEqual(
            WebSocketTopic.makeConversationNotifications(userId: 7),
            "/topic/user/7/notifications/conversations")
    }

    func testConversationMembershipNotificationsTopic() {
        XCTAssertEqual(
            WebSocketTopic.makeConversationMembershipNotifications(courseId: 42, userId: 7),
            "/user/topic/communication/courses/42/conversations/user/7")
    }
}
