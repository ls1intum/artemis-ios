import Foundation

public protocol BaseSubmission: Codable {
    static var type: String { get }

    var id: Int? { get }
    var submitted: Bool? { get }
    var submissionDate: Date? { get }
    var exampleSubmission: Bool? { get }
    var durationInMinutes: Double? { get }
    var results: [Result]? { get }
    var participation: Participation? { get }
}

public enum Submission: Codable {
    fileprivate enum Keys: String, CodingKey {
        case type = "submissionExerciseType"
    }

    case unknown(submission: UnknownSubmission)
    case fileUpload(submission: FileUploadSubmission)
    case modeling(submission: ModelingSubmission)
    case programming(submission: ProgrammingSubmission)
    case quiz(submission: QuizSubmission)
    case text(submission: TextSubmission)

    public var baseSubmission: BaseSubmission {
        switch self {
        case .unknown(let submission): return submission
        case .fileUpload(let submission): return submission
        case .modeling(let submission): return submission
        case .programming(let submission): return submission
        case .quiz(let submission): return submission
        case .text(let submission): return submission
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let type = try container.decode(String.self, forKey: Keys.type)
        switch type {
        case FileUploadSubmission.type: self = .fileUpload(submission: try FileUploadSubmission(from: decoder))
        case ModelingSubmission.type: self = .modeling(submission: try ModelingSubmission(from: decoder))
        case ProgrammingSubmission.type: self = .programming(submission: try ProgrammingSubmission(from: decoder))
        case QuizSubmission.type: self = .quiz(submission: try QuizSubmission(from: decoder))
        case TextSubmission.type: self = .text(submission: try TextSubmission(from: decoder))
        default: self = .unknown(submission: try UnknownSubmission(from: decoder))
        }
    }
}
