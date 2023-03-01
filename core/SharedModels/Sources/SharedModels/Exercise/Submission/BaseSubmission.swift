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

    case Unknown(submission: UnknownSubmission)
    case Instructor(submission: InstructorSubmission)
    case Test(submission: TestSubmission)

    public var baseSubmission: BaseSubmission {
        switch self {
        case .Unknown(let submission): return submission
        case .Instructor(let submission): return submission
        case .Test(let submission): return submission
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let type = try container.decode(String.self, forKey: Keys.type)
        switch type {
        case InstructorSubmission.type: self = .Instructor(submission: try InstructorSubmission(from: decoder))
        case TestSubmission.type: self = .Test(submission: try TestSubmission(from: decoder))
        default: self = .Unknown(submission: try UnknownSubmission(from: decoder))
        }
    }
}
