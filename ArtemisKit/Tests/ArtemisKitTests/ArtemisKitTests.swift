import XCTest

final class ArtemisKitTests: XCTestCase {
    func testCompare() {
        // given
        let text = "channel"
        let search = "cháN"

        // when
        let range = text.range(of: search, options: [.caseInsensitive, .diacriticInsensitive])

        // then
        XCTAssertNotNil(range)
    }

    func testMatch() throws {
        // given
        let regex = #/#(?<candidate>[\w-]*)/#
        let text = "#tech- \n#tech- "
        let expectation = "#tech- \n[channel]x(0)[\\channel] "

        // when
        // - match
        let matches = text.matches(of: regex)
        XCTAssertEqual(matches.count, 2)

        let last = try XCTUnwrap(matches.last)
        XCTAssertEqual(last.candidate, "tech-")

        // - replace
        let replace = "#" + last.candidate
        let replacement = text.replacingOccurrences(of: replace, with: "[channel]x(0)[\\channel]", range: last.range)

        // then
        XCTAssertEqual(replacement, expectation)
    }
}
