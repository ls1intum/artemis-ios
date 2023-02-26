import Foundation

public struct UnknownSubmission: BaseSubmission {
    public var id: Int?
    public var submitted: Bool?
    public var submissionDate: Date?
    public var exampleSubmission: Bool?
    public var durationInMinutes: Float?
    public var results: [Result]? = []
    public var participation: Participation?

    public static var type: String {
        "unknown"
    }
}
