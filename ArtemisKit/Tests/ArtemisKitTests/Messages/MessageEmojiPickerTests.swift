import XCTest
@testable import Messages

final class MessageEmojiPickerTests: XCTestCase {
    func testCategoriesUseFamiliarEmojiOrderAndIncludeNewerEmojis() {
        let sections = Emojis.pickerSections(matching: "")
        XCTAssertEqual(sections.map(\.category), [.smileys, .people, .nature, .food, .travel, .activities, .objects, .symbols, .flags])
        XCTAssertEqual(Array(sections[0].emojis.prefix(8)), ["😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂"])
        XCTAssertTrue(sections[0].emojis.contains("🫠"))
        XCTAssertTrue(sections[1].emojis.contains("🫶"))
        XCTAssertTrue(sections[2].emojis.contains("🪸"))
        XCTAssertTrue(sections[3].emojis.contains("🫘"))
        let all = sections.flatMap(\.emojis)
        XCTAssertEqual(Set(all), Set(Emojis.all.values), "Categorization must not lose any emoji")
        XCTAssertEqual(all.count, Set(all).count, "Aliases must not produce duplicate buttons")
    }

    func testSearchKeepsCategoryOrderAndFindsAliasesAndSymbols() {
        XCTAssertEqual(Emojis.pickerSections(matching: "  GRINNING  ").flatMap(\.emojis), ["😀"])
        XCTAssertEqual(Emojis.pickerSections(matching: "🫠").flatMap(\.emojis), ["🫠"])
        XCTAssertEqual(Emojis.pickerSections(matching: "heart hands").flatMap(\.emojis), ["🫶"])
        XCTAssertTrue(Emojis.pickerSections(matching: "no-such-emoji").isEmpty)
    }
}
