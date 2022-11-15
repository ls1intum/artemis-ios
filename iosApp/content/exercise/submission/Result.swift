import Foundation

struct Result: Decodable {
    var id: Int? = nil
    var completionDate: Date? = nil
    var successful: Bool? = nil
    var hasFeedback: Bool? = nil
        /**
     * Current score in percent i.e. between 1 - 100
     * - Can be larger than 100 if bonus points are available
     */
    var score: Float? = nil
    var assessmentType: AssessmentType? = nil
    var rated: Bool? = nil
    var hasComplaint: Bool? = nil
    var exampleResult: Bool? = nil
    var testCaseCount: Int? = nil
    var passedTestCaseCount: Int? = nil
    var codeIssueCount: Int? = nil
    var submission: Submission? = nil
    var assessor: User? = nil
    //val feedbacks: List<Feedback>? = nil,
    var participation: Participation? = nil
}
