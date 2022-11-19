import Foundation
import SwiftDate

struct InstructorSubmission: BaseSubmission {
    var id: Int? = nil
    var submitted: Bool? = nil
    var submissionDate: Date? = nil
    var exampleSubmission: Bool? = nil
    var durationInMinutes: Float? = nil
    var results: [Result]? = []
    var participation: Participation? = nil

    static var type: String {
        "INSTRUCTOR"
    }
}
