import Foundation

struct Result: Decodable {
    let id: Int? = nil
    let completionDate: Date? = nil
    let successful: Bool? = nil
    let hasFeedback: Bool? = nil
        /**
     * Current score in percent i.e. between 1 - 100
     * - Can be larger than 100 if bonus points are available
     */
    let score: Float? = nil
    let assessmentType: AssessmentType? = nil
    let rated: Bool? = nil
    let hasComplaint: Bool? = nil
    let exampleResult: Bool? = nil
    let testCaseCount: Int? = nil
    let passedTestCaseCount: Int? = nil
    let codeIssueCount: Int? = nil
    let submission: Submission? = nil
    let assessor: User? = nil
    //val feedbacks: List<Feedback>? = nil,
    let participation: Participation? = nil
}
