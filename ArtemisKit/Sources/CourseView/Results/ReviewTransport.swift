import Common
import Foundation
import UserStore

struct ReviewSession: Equatable {
    let baseURL: URL
    let username: String
    let token: String
    static func current() -> Self? {
        let user = UserSessionFactory.shared
        guard user.isLoggedIn, let base = user.institution?.baseURL, let username = user.username, let token = user.getToken() else { return nil }
        return Self(baseURL: base, username: username, token: token)
    }
    func matches(_ current: Self?) -> Bool { self == current }
    func url(for path: String) throws -> URL {
        guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL,
              url.scheme == baseURL.scheme, url.host == baseURL.host, url.port == baseURL.port,
              url.user == nil, url.password == nil else { throw ReviewError.invalidURL }
        return url
    }
}

/// Each request belongs to the account and server captured when the review opened.
/// Uses the existing student endpoints with a memory-only session and no response cache.
protocol ReviewReading {
    var isCurrent: Bool { get }
    func data(_ path: String) async throws -> Data
}

extension ReviewReading {
    func read<T: Decodable>(_ type: T.Type, path: String) async throws -> T {
        let data = try await data(path)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .customISO8601
        return try decoder.decode(type, from: data)
    }
}

final class ReviewTransport: NSObject, URLSessionTaskDelegate, ReviewReading {
    let captured: ReviewSession
    private let currentSession: () -> ReviewSession?
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpShouldSetCookies = false
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    init(captured: ReviewSession, currentSession: @escaping () -> ReviewSession? = ReviewSession.current) {
        self.captured = captured
        self.currentSession = currentSession
    }
    var isCurrent: Bool { captured.matches(currentSession()) }
    func data(_ path: String) async throws -> Data {
        guard isCurrent else { throw ReviewError.sessionChanged }
        var request = URLRequest(url: try captured.url(for: path))
        request.httpMethod = "GET"
        request.setValue("Bearer \(captured.token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard isCurrent, !Task.isCancelled else { throw ReviewError.sessionChanged }
        guard let response = response as? HTTPURLResponse else { throw ReviewError.http(0) }
        if response.statusCode == 401 || response.statusCode == 403 { throw ReviewError.denied }
        guard (200..<300).contains(response.statusCode) else { throw ReviewError.http(response.statusCode) }
        return data
    }
    func read<T: Decodable>(_ type: T.Type, path: String) async throws -> T {
        let data = try await data(path)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .customISO8601
        return try decoder.decode(type, from: data)
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        // APIs and submitted artifacts should not redirect. In particular, never forward a bearer token to another origin.
        completionHandler(nil)
    }
    func invalidate() { session.invalidateAndCancel() }
}

enum ReviewSourcePath {
    static func file(reference: ReviewReference, commit: String, name: String) throws -> String {
        guard commit.count == 40, commit.allSatisfy({ $0.isHexDigit }) else { throw ReviewError.identity }
        var components = URLComponents()
        components.path = "/api/programming/participations/\(reference.participationID)/repository/commits/\(commit)/file"
        components.queryItems = [.init(name: "file", value: name)]
        guard let path = components.string else { throw ReviewError.invalidURL }
        return path
    }
}
