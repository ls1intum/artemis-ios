import XCTest
import SharedModels
@testable import Messages

final class ArtemisKitTests: XCTestCase {
    static let now = Date.now

    static let a: Message = {
        var a = Message(id: 0)
        a.creationDate = now
        a.content = "Hello"
        return a
    }()

    static let b: Message = {
        var b = a
        b.content = "Hello, world!"
        return b
    }()

    static let c: Message = {
        var c = Message(id: 1)
        c.creationDate = Calendar.current.date(byAdding: .day, value: 1, to: now)
        c.content = "Bye"
        c.answers = [
            .init(id: 0)
        ]
        return c
    }()

    func testFirstEverMessage() throws {
        // First ever message in set
        let set = Set<IdentifiableMessage>([.init(rawValue: Self.a), .init(rawValue: Self.c)])
        let first0 = set.firstByCreationDate()
        let first = try XCTUnwrap(first0)
        XCTAssertEqual(first.content, Self.a.content)
    }

    func testMergeNewWithOld() throws {
        // Merge new with old, preferring new
        let old: Set<IdentifiableMessage> = [.init(rawValue: Self.a)]
        let new: Set<IdentifiableMessage> = [.init(rawValue: Self.b), .init(rawValue: Self.c)]

        let update = new.union(old)

        let firstIndex = try XCTUnwrap(update.firstIndex(of: .init(rawValue: Self.b)))
        let first = update[firstIndex]
        XCTAssertEqual(first.rawValue.content, Self.b.content)
        XCTAssertEqual(update.count, 2)
    }

    func testInsertNewMessage() {
        // Insert new message
        var set: Set<IdentifiableMessage> = [.init(rawValue: Self.a)]

        set.insert(.init(rawValue: Self.c))

        XCTAssertEqual(set.count, 2)
    }

    func testUpdateExistingMessage() throws {
        // Update existing message
        var set: Set<IdentifiableMessage> = [.init(rawValue: Self.a)]

        set.update(with: .init(rawValue: Self.b))

        let firstIndex = try XCTUnwrap(set.firstIndex(of: .init(rawValue: Self.b)))
        let first = set[firstIndex]
        XCTAssertEqual(first.rawValue.content, Self.b.content)
    }

    func testRemoveExistingMessage() {
        // Remove existing message
        var set: Set<IdentifiableMessage> = [.init(rawValue: Self.a)]

        set.remove(.init(rawValue: Self.b))

        XCTAssertTrue(set.isEmpty)
    }

    func testBinding() throws {
        var set: Set<IdentifiableMessage> = [.init(rawValue: Self.c)]

        // Bind to an id
        let messageIndex = try XCTUnwrap(set.firstIndex(of: .id(Self.c.id)))
        let message = set[messageIndex]
        // set.update(with: message)

        XCTAssertEqual(message.rawValue.content, Self.c.content)

        // Bind to an answer id
        let answerId = 0
        let answerIndex = set.firstIndex { message in
            let contains = message.rawValue.answers?.contains { answer in
                answer.id == answerId
            }
            return contains ?? false
        }
        // set.update

        XCTAssertNotNil(answerIndex)
    }

    func testCreationIndex() throws {
        // Index with creation day
        let set: Set<IdentifiableMessage> = [.init(rawValue: Self.b), .init(rawValue: Self.c)]

        let groups = Dictionary(grouping: set.map(\.rawValue)) { message in
            message.creationDate
        }

        XCTAssertEqual(groups.count, 2)
    }
}

extension ArtemisKitTests {
    // Remove message, if contained:
    // true: refresh same page
    // false: refresh next page, out of scope
    func testSubscriptionContainsTrue() {
        let size = 50
        let page = 0
        var diff = 0

        let set: Set<IdentifiableMessage> = [.message(Self.a), .message(Self.c)]

        let isContained = set.contains(.id(Self.b.id))
        diff -= isContained ? 1 : 0

        let (quotient, remainder) = diff.quotientAndRemainder(dividingBy: size)
        XCTAssertEqual(quotient, 0)
        XCTAssertEqual(remainder, -1)
    }

    func testSubscriptionContainsFalse() {
        let size = 50
        let page = 0
        var diff = 0

        let set: Set<IdentifiableMessage> = [.message(Self.c)]

        let isContained = set.contains(.id(Self.b.id))
        diff -= isContained ? 1 : 0

        let (quotient, remainder) = diff.quotientAndRemainder(dividingBy: size)
        XCTAssertEqual(quotient, 0)
        XCTAssertEqual(remainder, -1)
        // XCTAssertEqual failed: ("0") is not equal to ("-1")
    }

    func testQuotientAndRemainder() {
        let size = 50
        var count = 0
        var page = 0
        guard let n = (1...5).randomElement() else {
            XCTFail()
            return
        }
        for i in 0..<n {
            count += 50
            page += 1
        }

        do {
            // Remove more than the size of one page
            guard let diff0 = (0...count).randomElement() else {
                XCTFail()
                return
            }
            let diff = -diff0
            let (quotient, remainder) = diff.quotientAndRemainder(dividingBy: size)
            XCTAssertLessThanOrEqual(remainder, 0)
            XCTAssertGreaterThanOrEqual(page + quotient, 0)
        }
        do {
            // More than the size of one page
            guard let m = (1...5).randomElement() else {
                XCTFail()
                return
            }
            let diff = m * size
            let (quotient, remainder) = diff.quotientAndRemainder(dividingBy: size)
            XCTAssertGreaterThanOrEqual(remainder, 0)
            XCTAssertGreaterThanOrEqual(page + quotient, page)
        }
    }
}
