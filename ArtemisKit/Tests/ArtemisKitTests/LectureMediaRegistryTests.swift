import XCTest
@testable import CourseView

final class LectureMediaRegistryTests: XCTestCase {
    func testReplacedManifestKeepsActiveResourceUntilItsLeaseEnds() throws {
        let registry = LectureMediaResourceRegistry()
        let base = URL(string: "https://example.org/master.m3u8")!
        let root = try registry.addRoot(base, role: .playlist)
        func local(_ id: String) -> URL { URL(string: "http://127.0.0.1/" + id)! }
        let first = try registry.rewrite("#EXTM3U\nold.ts\nold.ts", relativeTo: base, owner: root, localURL: local)
        let old = try XCTUnwrap(first.split(separator: "\n").last.flatMap { URL(string: String($0))?.lastPathComponent })
        XCTAssertNotNil(registry.acquire(old))
        _ = try registry.rewrite("#EXTM3U\nnew.ts", relativeTo: base, owner: root, localURL: local)
        XCTAssertNotNil(registry.resource(old))
        registry.release(old)
        XCTAssertNil(registry.resource(old))
    }

    func testFailedManifestReplacementRollsBackToPreviousSeekableRoutes() throws {
        let registry = LectureMediaResourceRegistry(byteBudget: 1800)
        let base = URL(string: "https://example.org/master.m3u8")!
        let root = try registry.addRoot(base, role: .playlist)
        func local(_ id: String) -> URL { URL(string: "http://127.0.0.1/" + id)! }
        let first = try registry.rewrite("#EXTM3U\nold.ts", relativeTo: base, owner: root, localURL: local)
        let old = try XCTUnwrap(first.split(separator: "\n").last.flatMap { URL(string: String($0))?.lastPathComponent })
        XCTAssertThrowsError(try registry.rewrite("#EXTM3U\n" + String(repeating: "a", count: 1200) + ".ts", relativeTo: base, owner: root, localURL: local))
        XCTAssertNotNil(registry.resource(old))
        let again = try registry.rewrite("#EXTM3U\nold.ts", relativeTo: base, owner: root, localURL: local)
        XCTAssertEqual(first, again)
    }
}
