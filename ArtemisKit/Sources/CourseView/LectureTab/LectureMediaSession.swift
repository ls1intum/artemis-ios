import Foundation
import SharedModels
import UserStore

struct LectureMediaSession: Equatable {
    let account: String
    let origin: URL
    let token: String?

    static func capture() -> Self? {
        let session = UserSessionFactory.shared
        guard session.isLoggedIn, !session.tokenExpired,
              let account = session.user?.login ?? session.username, let origin = session.institution?.baseURL,
              LectureMediaOrigin.normalized(origin) != nil else { return nil }
        return Self(account: account, origin: origin, token: session.getToken())
    }

    var isCurrent: Bool { self == Self.capture() }
    var policy: LectureMediaRequestPolicy { .init(origin: origin, token: token) }

    func progress(identity: String) -> LectureMediaProgress {
        LectureMediaProgress(account: account, server: origin, identity: identity)
    }
}

enum LectureMediaError: LocalizedError {
    case invalidURL, sessionChanged, response(Int), invalidDocument, unavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "This media link is invalid."
        case .sessionChanged: return "Your session changed or expired. Close this media and sign in again."
        case .response(let status) where status == 401 || status == 403:
            return "Access to this media was denied. Sign in again or open it in your browser."
        case .response: return "The media could not be loaded. Try again or open it in your browser."
        case .invalidDocument: return "This PDF could not be opened. You can export the file to another app."
        case .unavailable: return "This media could not be played. Try again or open it in your browser."
        }
    }
}

/// A private cookie/credential store avoids the domain-wide JWT cookie installed by APIClient.
final class LectureMediaDownloader: @unchecked Sendable {
    let policy: LectureMediaRequestPolicy

    init(policy: LectureMediaRequestPolicy) { self.policy = policy }

    static func configuration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCredentialStorage = nil
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 30
        return configuration
    }

    func data(from url: URL) async throws -> (Data, HTTPURLResponse) {
        guard LectureMediaSource.classify(url) != .invalid else { throw LectureMediaError.invalidURL }
        let session = URLSession(configuration: Self.configuration())
        defer { session.finishTasksAndInvalidate() }
        let redirects = RedirectDelegate(policy: policy)
        let (data, response) = try await session.data(for: policy.request(for: url), delegate: redirects)
        guard let response = response as? HTTPURLResponse else { throw LectureMediaError.unavailable }
        guard (200..<300).contains(response.statusCode) else { throw LectureMediaError.response(response.statusCode) }
        return (data, response)
    }

    /// A redirect chain owns its policy so concurrent/repeated downloads remain independent.
    private final class RedirectDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
        private var policy: LectureMediaRequestPolicy
        init(policy: LectureMediaRequestPolicy) { self.policy = policy }

        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                        newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            guard let source = response.url, let destination = request.url else { completionHandler(nil); return }
            if !LectureMediaOrigin.matches(policy.origin, source) || !LectureMediaOrigin.matches(policy.origin, destination) {
                policy = .init(origin: policy.origin, token: nil)
            }
            guard var redirected = policy.redirect(from: source, to: destination) else { completionHandler(nil); return }
            redirected.setValue(task.originalRequest?.value(forHTTPHeaderField: "Range"), forHTTPHeaderField: "Range")
            completionHandler(redirected)
        }
    }
}
