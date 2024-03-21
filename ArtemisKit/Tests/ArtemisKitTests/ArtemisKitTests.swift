import XCTest
import SharedModels

final class ArtemisKitTests: XCTestCase {
    func testIdentifiableMessage() throws {
        struct IdentifiableMessage: Hashable, Identifiable {
            var id: Int64 {
                message.id
            }

            let message: Message

            func hash(into hasher: inout Hasher) {
                hasher.combine(id)
            }
        }

        // given
        let now = Date.now

        var a = Message(id: 0)
        a.creationDate = now
        a.content = "Hello"

        var b = a
        b.creationDate = Calendar.current.date(byAdding: .day, value: 1, to: now)
        b.content = "Hello, world!"

        do {
            // when
            let old: Set<IdentifiableMessage> = [.init(message: a)]
            let new: Set<IdentifiableMessage> = [.init(message: b)]

            let combine = new.union(old)

            // then
            let c = try XCTUnwrap(combine.first)
            XCTAssertEqual(c.message.content, b.content)
        }

        do {
            let messages/*: Set*/ = [IdentifiableMessage(message: a), .init(message: b)]
            let grouping = Dictionary(grouping: messages) { message in
                message.message.creationDate
            }
            XCTAssertEqual(grouping.keys.count, 2)
        }
    }
}
