import Foundation

public struct Result: Decodable {
    public var id: Int? = nil
    public var completionDate: Date? = nil
    public var successful: Bool? = nil
    public var hasFeedback: Bool? = nil
        /**
     * Current score in percent i.e. between 1 - 100
     * - Can be larger than 100 if bonus points are available
     */
    public var score: Float? = nil
    public var assessmentType: AssessmentType? = nil
    public var rated: Bool? = nil
    public var hasComplaint: Bool? = nil
    public var exampleResult: Bool? = nil
    public var testCaseCount: Int? = nil
    public var passedTestCaseCount: Int? = nil
    public var codeIssueCount: Int? = nil
    public var submission: Submission? = nil
    public var assessor: User? = nil
    //val feedbacks: List<Feedback>? = nil,
    public var participation: Participation? = nil
}
