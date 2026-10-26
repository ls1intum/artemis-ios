import Foundation
import XCTest
@testable import CourseView

final class ReviewSourceSelectionTests: XCTestCase {
    @MainActor
    func testSourceBRemainsSelectedWhenACompletesLast() async {
        let reader = ControlledSourceReader()
        let selection = ReviewSourceSelection()
        let reference = ReviewReference(courseID: 1, exerciseID: 2, participationID: 3, submissionID: 4, resultID: 5)
        let commit = String(repeating: "a", count: 40)
        let first = Task { await selection.load(file: "A.java", reference: reference, commit: commit, reader: reader) }
        await reader.waitForRequests(1)
        let second = Task { await selection.load(file: "B.java", reference: reference, commit: commit, reader: reader) }
        await reader.waitForRequests(2)
        await reader.complete(file: "B.java", result: .success(Data("B content".utf8)))
        await second.value
        await reader.complete(file: "A.java", result: .success(Data("A content".utf8)))
        await first.value
        XCTAssertEqual(selection.loaded?.file, "B.java")
        XCTAssertEqual(selection.loaded?.text, "B content")
        XCTAssertNil(selection.highlight(for: ReviewCodeLocation(reference: "file:A.java_line:0-2")))
    }
    @MainActor
    func testSelectingBImmediatelyClearsAAndFailureDoesNotRestoreOldFile() async {
        let reader = ControlledSourceReader()
        let selection = ReviewSourceSelection()
        let reference = ReviewReference(courseID: 1, exerciseID: 2, participationID: 3, submissionID: 4, resultID: 5)
        let commit = String(repeating: "a", count: 40)
        let first = Task { await selection.load(file: "A.java", reference: reference, commit: commit, reader: reader) }
        await reader.waitForRequests(1)
        await reader.complete(file: "A.java", result: .success(Data("A content".utf8))); await first.value
        let second = Task { await selection.load(file: "B.java", reference: reference, commit: commit, reader: reader) }
        await reader.waitForRequests(2)
        XCTAssertNil(selection.loaded)
        await reader.complete(file: "B.java", result: .failure(ReviewError.http(404))); await second.value
        XCTAssertNil(selection.loaded)
        XCTAssertNotNil(selection.error)
        XCTAssertFalse(selection.loading)
    }
}

private actor ControlledSourceReader: ReviewReading {
    nonisolated var isCurrent: Bool { true }
    private var pending: [String: CheckedContinuation<Data, Error>] = [:]
    private var count = 0
    private var waiters: [(Int, CheckedContinuation<Void, Never>)] = []
    func data(_ path: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let file = URLComponents(string: path)?.queryItems?.first(where: { $0.name == "file" })?.value ?? ""
            pending[file] = continuation; count += 1
            let ready = waiters.filter { $0.0 <= count }; waiters.removeAll { $0.0 <= count }
            ready.forEach { $0.1.resume() }
        }
    }
    func waitForRequests(_ target: Int) async {
        if count >= target { return }
        await withCheckedContinuation { waiters.append((target, $0)) }
    }
    func complete(file: String, result: Result<Data, Error>) { pending.removeValue(forKey: file)?.resume(with: result) }
}
