import XCTest
import SharedModels

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
        let first0 = set
            .sorted {
                if let lhs = $0.rawValue.creationDate, let rhs = $1.rawValue.creationDate {
                    lhs.compare(rhs) == .orderedAscending
                } else {
                    false
                }
            }
            .first
        let first = try XCTUnwrap(first0)
        XCTAssertEqual(first.rawValue.content, Self.a.content)
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
        let messageIndex = try XCTUnwrap(set.firstIndex(of: .init(id: Self.c.id)))
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

    func testSubscription() {
        // Remove message, if contained:
        // true: refresh same page
        // false: refresh next page, out of scope
    }
}

struct IdentifiableMessage: RawRepresentable {
    let rawValue: Message
}

extension IdentifiableMessage {
    init(id: Int64) {
        self.init(rawValue: Message(id: id))
    }
}

extension IdentifiableMessage: Equatable, Hashable, Identifiable {
    static func == (lhs: IdentifiableMessage, rhs: IdentifiableMessage) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    var id: Int64 {
        rawValue.id
    }
}
