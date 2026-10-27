import SharedModels
import XCTest
@testable import Quiz

final class TrainingTransportTests: XCTestCase {
    override func tearDown() { TrainingURLProtocol.handler = nil; super.tearDown() }
    func testActualPagingRequestRetainsSnapshotAndAuthoritativeHeader() async throws {
        let transport = makeTransport()
        defer { transport.invalidate() }
        TrainingURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/quiz/courses/8/training-questions")
            XCTAssertEqual(request.url?.query, "page=2&size=10&isNewSession=false&sort=id,asc")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer a")
            XCTAssertEqual(try JSONDecoder().decode([Int64].self, from: requestBody(request)), [91, 93])
            return (200, ["X-Has-Next": "true"], Data("[]".utf8))
        }
        let page = try await transport.page(.init(page: 2, isNewSession: false, questionIDs: [91, 93]))
        XCTAssertTrue(page.hasNext)
    }
    func testMissingPaginationHeaderIsAnExplicitContractFailure() async throws {
        let transport = makeTransport()
        defer { transport.invalidate() }
        TrainingURLProtocol.handler = { _ in (200, [:], Data("[]".utf8)) }
        do { _ = try await transport.page(.init()); XCTFail("Missing continuation must not silently finish") } catch TrainingError.contract {} catch { XCTFail("Unexpected error: \(error)") }
    }
    func testReadsNeverWriteGlobalVisibilityOrCreateCourseEntry() async throws {
        let transport = makeTransport()
        defer { transport.invalidate() }
        var paths: [String] = []
        TrainingURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            paths.append(request.url!.path)
            let json = request.url!.path.hasSuffix("leaderboard-settings") ? #"{"showInLeaderboard":null}"# :
                #"{"hasUserSetSettings":false,"currentUserEntry":{"dueDate":null},"leaderboardEntries":[]}"#
            return (200, [:], Data(json.utf8))
        }
        let overview = try await transport.overview()
        XCTAssertFalse(try XCTUnwrap(overview.hasUserSetSettings))
        let visibility = try await transport.visibility()
        XCTAssertNil(visibility)
        XCTAssertEqual(paths, ["/api/quiz/courses/8/training/leaderboard", "/api/quiz/leaderboard-settings"])
    }
    func testExplicitPrivacyChoiceUsesOnlyGlobalPUT() async throws {
        let transport = makeTransport()
        defer { transport.invalidate() }
        TrainingURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "PUT")
            XCTAssertEqual(request.url?.path, "/api/quiz/leaderboard-settings")
            XCTAssertFalse(try XCTUnwrap(JSONDecoder().decode(TrainingVisibility.self, from: requestBody(request)).showInLeaderboard))
            return (200, [:], Data())
        }
        try await transport.setVisibility(false)
    }
    func testSubmissionPreservesExactPayloadAndReturnedZero() async throws {
        let transport = makeTransport()
        defer { transport.invalidate() }
        let body = Data(#"{"type":"short-answer","quizQuestion":{"id":102},"submittedTexts":[{"spot":{"id":913},"text":"BINARY SEARCH"}]}"#.utf8)
        TrainingURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/quiz/courses/8/training-questions/102/submit")
            XCTAssertEqual(request.url?.query, "isRated=false")
            XCTAssertEqual(try requestBody(request), body)
            let json = """
            {"type":"short-answer","quizQuestion":{"id":102,"type":"short-answer"},"scoreInPoints":0,
            "submittedTexts":[{"spot":{"id":913,"spotNr":1},"text":"BINARY SEARCH","isCorrect":true}]}
            """
            return (200, [:], Data(json.utf8))
        }
        let result = try await transport.submit(questionID: 102, rated: false, answer: body)
        XCTAssertEqual(TrainingProjection.points(result), 0)
        guard case .shortAnswer(let shortAnswer) = result else { XCTFail("Wrong subtype"); return }
        XCTAssertEqual(shortAnswer.submittedTexts?.first?.isCorrect, true)
    }
    func testDeniedProtectedAssetRevokesCapturedSession() async throws {
        let transport = makeTransport()
        defer { transport.invalidate() }
        var loads = 0
        TrainingURLProtocol.handler = { request in
            loads += 1
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer a")
            return (403, [:], Data())
        }
        do { _ = try await transport.assetData("/api/core/files/quiz/image.png"); XCTFail("Denied assets must fail") } catch {}
        XCTAssertFalse(transport.isCurrent)
        do { _ = try await transport.assetData("/api/core/files/quiz/image.png"); XCTFail("Revoked session must fail") } catch {}
        XCTAssertEqual(loads, 1)
    }
    func testRedirectPolicyNeverForwardsCredentials() {
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        let url = URL(string: "https://one.example")!
        let task = session.dataTask(with: url)
        let response = HTTPURLResponse(url: url, statusCode: 302, httpVersion: nil, headerFields: ["Location": "https://foreign.example"])!
        TrainingRedirectPolicy().urlSession(session, task: task, willPerformHTTPRedirection: response, newRequest: URLRequest(url: URL(string: "https://foreign.example")!)) {
            XCTAssertNil($0)
        }
    }
    private func makeTransport() -> TrainingTransport {
        let identity = TrainingIdentity(baseURL: URL(string: "https://one.example")!, username: "alice", token: "a", courseID: 8)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [TrainingURLProtocol.self]
        return TrainingTransport(captured: identity, current: { identity }, configuration: configuration)
    }
}

private func requestBody(_ request: URLRequest) throws -> Data {
    if let body = request.httpBody { return body }
    guard let stream = request.httpBodyStream else { return Data() }
    stream.open(); defer { stream.close() }
    var result = Data(); var buffer = [UInt8](repeating: 0, count: 1024)
    while stream.hasBytesAvailable {
        let read = stream.read(&buffer, maxLength: buffer.count)
        guard read >= 0 else { throw URLError(.cannotDecodeRawData) }
        if read == 0 { break }
        result.append(buffer, count: read)
    }
    return result
}

final class TrainingURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, [String: String], Data))?
    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            guard let handler = Self.handler else { throw URLError(.cancelled) }
            let (status, headers, data) = try handler(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: headers)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data); client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}
