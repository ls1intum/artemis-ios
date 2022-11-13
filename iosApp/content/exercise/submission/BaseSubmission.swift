import Foundation

protocol BaseSubmission: Decodable {
    static var type: String { get }

    var id: Int? { get }
    var submitted: Bool? { get }
    var submissionDate: Date? { get }
    var exampleSubmission: Bool? { get }
    var durationInMinutes: Float? { get }
    var results: [Result]? { get }
    var participation: Participation? { get }
}

enum Submission: Decodable {
    fileprivate enum Keys: String, CodingKey {
        case type = "submissionExerciseType"
    }

    case Unknown(submission: UnknownSubmission)

    var baseSubmission: BaseSubmission {
        switch self {
        case .Unknown(let submission): return submission
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let type = try container.decode(String.self, forKey: Keys.type)
        switch type {
        default: self = .Unknown(submission: try UnknownSubmission(from: decoder))
        }
    }
}