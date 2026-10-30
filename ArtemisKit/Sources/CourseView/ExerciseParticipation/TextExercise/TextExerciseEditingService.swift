import APIClient
import Foundation
import UserStore

struct TextExerciseEditorSubmission: Codable, Equatable, Sendable {
    var id: Int?
    var text: String = ""
    var submitted: Bool = false
    var submissionDate: Date?
    var participation: ParticipationReference?

    struct ParticipationReference: Codable, Equatable, Sendable {
        var id: Int
    }

    private enum CodingKeys: String, CodingKey {
        case id, text, submitted, submissionDate, participation
    }

    init(id: Int? = nil, text: String = "", submitted: Bool = false, submissionDate: Date? = nil) {
        self.id = id
        self.text = text
        self.submitted = submitted
        self.submissionDate = submissionDate
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(Int.self, forKey: .id)
        text = try values.decodeIfPresent(String.self, forKey: .text) ?? ""
        submitted = try values.decodeIfPresent(Bool.self, forKey: .submitted) ?? false
        submissionDate = try values.decodeIfPresent(Date.self, forKey: .submissionDate)
        participation = try values.decodeIfPresent(ParticipationReference.self, forKey: .participation)
    }
}

struct TextExerciseEditorContext: Decodable {
    var id: Int
    var initializationDate: Date?
    var individualDueDate: Date?
    var testRun: Bool?
    var exercise: ExerciseInfo
    var submissions: [TextExerciseEditorSubmission]?

    struct ExerciseInfo: Decodable {
        var id: Int
        var title: String?
        var problemStatement: String?
        var dueDate: Date?
        var releaseDate: Date?
        var course: Reference?
        var exerciseGroup: Reference?

        struct Reference: Decodable {
            var id: Int
        }
    }

    var latestSubmission: TextExerciseEditorSubmission {
        (submissions ?? []).max {
            if $0.submissionDate != $1.submissionDate {
                return ($0.submissionDate ?? .distantPast) < ($1.submissionDate ?? .distantPast)
            }
            return ($0.id ?? 0) < ($1.id ?? 0)
        } ?? TextExerciseEditorSubmission()
    }

    func isSubmissionOpen(at date: Date) -> Bool {
        guard testRun != true, exercise.exerciseGroup == nil else { return false }
        if let release = exercise.releaseDate, date < release { return false }
        guard let deadline = individualDueDate ?? exercise.dueDate else { return true }
        if date <= deadline { return true }
        // Artemis permits participation initialized after its effective deadline.
        return initializationDate.map { $0 >= deadline } ?? false
    }
}

@MainActor
protocol TextExerciseEditingService {
    func load(participationId: Int) async throws -> TextExerciseEditorContext
    func submit(exerciseId: Int, submissionId: Int?, text: String) async throws -> TextExerciseEditorSubmission
}

/// Credentials and origin are captured once. Requests never inherit another account's cookies or token.
@MainActor
struct TextExerciseEditingSession: Equatable {
    let baseURL: URL
    let account: String
    private let token: String

    static var current: Self? {
        let user = UserSessionFactory.shared
        return capture(baseURL: user.institution?.baseURL, token: user.getToken(), isLoggedIn: user.isLoggedIn)
    }

    // The server authenticates the token. Its subject identifies the account even without remembered credentials.
    static func capture(baseURL: URL?, token: String?, isLoggedIn: Bool) -> Self? {
        struct Claims: Decodable { let sub: String }
        guard isLoggedIn, let baseURL, let token,
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              components.host != nil else { return nil }
        components.user = nil
        components.password = nil
        components.query = nil
        components.fragment = nil
        guard let server = components.url else { return nil }
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }
        var payload = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        payload += String(repeating: "=", count: (4 - payload.count % 4) % 4)
        guard let data = Data(base64Encoded: payload), let claims = try? JSONDecoder().decode(Claims.self, from: data),
              !claims.sub.isEmpty else { return nil }
        return Self(baseURL: server, account: claims.sub, token: token)
    }

    func request(path: String, method: String, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.httpBody = body
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        return request
    }
}

@MainActor
final class NativeTextExerciseService: TextExerciseEditingService {
    let session: TextExerciseEditingSession
    private let transport: URLSession

    init(session: TextExerciseEditingSession) {
        self.session = session
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 30
        transport = URLSession(configuration: configuration, delegate: TextExerciseRedirectGuard(), delegateQueue: nil)
    }

    func open(exerciseId: Int) async throws -> Int {
        struct Details: Decodable {
            var exercise: Exercise
            struct Exercise: Decodable {
                var id: Int
                var type: String
                var exerciseGroup: TextExerciseEditorContext.ExerciseInfo.Reference?
                var studentParticipations: [Participation]?
            }
            struct Participation: Decodable {
                var id: Int
                var testRun: Bool?
            }
        }
        let details: Details = try await send(path: "api/exercise/exercises/\(exerciseId)/details")
        guard details.exercise.id == exerciseId, details.exercise.type == "text", details.exercise.exerciseGroup == nil else {
            throw TextExerciseEditingError.invalidResponse
        }
        if let participation = details.exercise.studentParticipations?.first(where: { $0.testRun != true }) {
            return participation.id
        }
        let participation: Details.Participation = try await send(path: "api/exercise/exercises/\(exerciseId)/participations", method: "POST")
        guard participation.testRun != true else { throw TextExerciseEditingError.invalidResponse }
        return participation.id
    }

    func load(participationId: Int) async throws -> TextExerciseEditorContext {
        try await send(path: "api/text/participations/\(participationId)/text-editor")
    }

    func submit(exerciseId: Int, submissionId: Int?, text: String) async throws -> TextExerciseEditorSubmission {
        struct Payload: Encodable {
            let id: Int?
            let text: String
            let submitted = true
        }
        let body = try JSONEncoder().encode(Payload(id: submissionId, text: text))
        return try await send(path: "api/text/exercises/\(exerciseId)/text-submissions", method: submissionId == nil ? "POST" : "PUT", body: body)
    }

    private func send<Response: Decodable>(path: String, method: String = "GET", body: Data? = nil) async throws -> Response {
        guard TextExerciseEditingSession.current == session else { throw TextExerciseEditingError.sessionChanged }
        let (data, response) = try await transport.data(for: session.request(path: path, method: method, body: body))
        guard TextExerciseEditingSession.current == session else { throw TextExerciseEditingError.sessionChanged }
        guard let response = response as? HTTPURLResponse else { throw TextExerciseEditingError.invalidResponse }
        guard (200..<300).contains(response.statusCode) else { throw TextExerciseEditingError.http(response.statusCode) }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .customISO8601
        return try decoder.decode(Response.self, from: data)
    }
}

private final class TextExerciseRedirectGuard: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}

enum TextExerciseEditingError: Error {
    case invalidResponse
    case sessionChanged
    case http(Int)
}
