import XCTest
@testable import Websocket

final class WebsocketTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Websocket().text, "Hello, World!")
    }
}
