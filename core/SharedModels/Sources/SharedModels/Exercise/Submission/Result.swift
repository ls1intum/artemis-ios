import Foundation

public struct Result: Decodable {
    public var id: Int?
    public var completionDate: Date?
    public var successful: Bool?
    public var hasFeedback: Bool?
    /**
     * Current score in percent i.e. between 1 - 100
     * - Can be larger than 100 if bonus points are available
     */
    public var score: Float?
    public var assessmentType: AssessmentType?
    public var rated: Bool?
    public var hasComplaint: Bool?
    public var exampleResult: Bool?
    public var testCaseCount: Int?
    public var passedTestCaseCount: Int?
    public var codeIssueCount: Int?
    public var submission: Submission?
    public var assessor: User?
    // val feedbacks: List<Feedback>? = nil,
    public var participation: Participation?
}
