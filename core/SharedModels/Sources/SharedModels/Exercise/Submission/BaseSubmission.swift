import Foundation

public protocol BaseSubmission: Decodable {
    static var type: String { get }

    var id: Int? { get }
    var submitted: Bool? { get }
    var submissionDate: Date? { get }
    var exampleSubmission: Bool? { get }
    var durationInMinutes: Float? { get }
    var results: [Result]? { get }
    var participation: Participation? { get }
}

public enum Submission: Decodable {
    fileprivate enum Keys: String, CodingKey {
        case type = "submissionExerciseType"
    }

    case unknown(submission: UnknownSubmission)
    case instructor(submission: InstructorSubmission)
    case test(submission: TestSubmission)

    public var baseSubmission: BaseSubmission {
        switch self {
        case .unknown(let submission): return submission
        case .instructor(let submission): return submission
        case .test(let submission): return submission
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let type = try container.decode(String.self, forKey: Keys.type)
        switch type {
        case InstructorSubmission.type: self = .instructor(submission: try InstructorSubmission(from: decoder))
        case TestSubmission.type: self = .test(submission: try TestSubmission(from: decoder))
        default: self = .unknown(submission: try UnknownSubmission(from: decoder))
        }
    }
}
