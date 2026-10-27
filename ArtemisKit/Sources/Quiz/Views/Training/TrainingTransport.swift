import Common
import Foundation
import ReviewContent
import SharedModels
import UserStore

struct TrainingIdentity: Equatable {
    let baseURL: URL
    let username: String
    let token: String
    let courseID: Int
    static func current(courseID: Int, user: UserSession = UserSessionFactory.shared, token: (() -> String?)? = nil) -> Self? {
        // username is only the SDK's remembered-login preference; account.login survives nonremembered login.
        let capturedToken: String?
        if let token { capturedToken = token() } else { capturedToken = user.getToken() }
        guard user.isLoggedIn, let baseURL = user.institution?.baseURL,
              let username = user.user?.login ?? user.username, !username.isEmpty, let token = capturedToken, !token.isEmpty else { return nil }
        return Self(baseURL: baseURL, username: username, token: token, courseID: courseID)
    }
    func url(_ path: String) throws -> URL {
        guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL,
              ["http", "https"].contains(url.scheme), url.scheme == baseURL.scheme, url.host == baseURL.host, url.port == baseURL.port,
              url.user == nil, url.password == nil else { throw TrainingError.identity }
        return url
    }
}

final class TrainingTransport: TrainingServing, TrainingOverviewServing {
    let captured: TrainingIdentity
    private let current: () -> TrainingIdentity?
    private let accessLock = NSLock()
    private var revoked = false
    private let session: URLSession
    init(captured: TrainingIdentity, current: (() -> TrainingIdentity?)? = nil, configuration: URLSessionConfiguration = .ephemeral) {
        self.captured = captured
        self.current = current ?? { TrainingIdentity.current(courseID: captured.courseID) }
        configuration.urlCache = nil; configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpShouldSetCookies = false; configuration.httpCookieStorage = nil; configuration.urlCredentialStorage = nil
        session = URLSession(configuration: configuration, delegate: TrainingRedirectPolicy(), delegateQueue: nil)
    }
    deinit { session.invalidateAndCancel() }
    var isCurrent: Bool { accessLock.withLock { !revoked } && current() == captured }
    func makeRequest(path: String, method: String, body: Data? = nil) throws -> URLRequest {
        guard isCurrent else { throw TrainingError.identity }
        var request = URLRequest(url: try captured.url(path))
        request.httpMethod = method; request.httpBody = body; request.httpShouldHandleCookies = false
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("Bearer \(captured.token)", forHTTPHeaderField: "Authorization")
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        return request
    }
    private func send(path: String, method: String = "GET", body: Data? = nil) async throws -> (Data, HTTPURLResponse) {
        let request = try makeRequest(path: path, method: method, body: body)
        let (data, response) = try await session.data(for: request)
        guard isCurrent, !Task.isCancelled else { throw TrainingError.identity }
        guard let response = response as? HTTPURLResponse else { throw TrainingError.http(0) }
        if response.statusCode == 401 || response.statusCode == 403 { invalidate(); throw TrainingError.denied }
        guard (200..<300).contains(response.statusCode) else { throw TrainingError.http(response.statusCode) }
        return (data, response)
    }
    private func decode<T: Decodable>(_ type: T.Type, _ data: Data) throws -> T {
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .customISO8601
        return try decoder.decode(type, from: data)
    }
    func page(_ request: TrainingPageRequest) async throws -> TrainingPage {
        let path = "/api/quiz/courses/\(captured.courseID)/training-questions?page=\(request.page)&size=10&isNewSession=\(request.isNewSession)&sort=id,asc"
        let (data, response) = try await send(path: path, method: "POST", body: JSONEncoder().encode(request.questionIDs))
        guard let header = response.value(forHTTPHeaderField: "X-Has-Next")?.lowercased(), ["true", "false"].contains(header) else { throw TrainingError.contract }
        return TrainingPage(questions: try decode([DTO.QuizQuestionTraining].self, data), hasNext: header == "true")
    }
    func submit(questionID: Int64, rated: Bool, answer: Data) async throws -> DTO.SubmittedAnswerAfterEvaluation {
        let path = "/api/quiz/courses/\(captured.courseID)/training-questions/\(questionID)/submit?isRated=\(rated)"
        let (data, _) = try await send(path: path, method: "POST", body: answer)
        return try decode(DTO.SubmittedAnswerAfterEvaluation.self, data)
    }
    func overview() async throws -> TrainingLeaderboard {
        let (data, _) = try await send(path: "/api/quiz/courses/\(captured.courseID)/training/leaderboard")
        return try decode(TrainingLeaderboard.self, data)
    }
    func visibility() async throws -> Bool? {
        let (data, _) = try await send(path: "/api/quiz/leaderboard-settings")
        return try decode(TrainingVisibility.self, data).showInLeaderboard
    }
    func setVisibility(_ visible: Bool) async throws {
        _ = try await send(path: "/api/quiz/leaderboard-settings", method: "PUT", body: JSONEncoder().encode(TrainingVisibility(showInLeaderboard: visible)))
    }
    func assetData(_ path: String) async throws -> Data { try await send(path: path).0 }
    func invalidate() { accessLock.withLock { revoked = true }; session.invalidateAndCancel() }
}

final class TrainingRedirectPolicy: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) { completionHandler(nil) }
}
