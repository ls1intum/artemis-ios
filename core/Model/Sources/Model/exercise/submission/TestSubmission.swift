import Foundation
import SwiftDate

public struct TestSubmission: BaseSubmission {
    public var id: Int? = nil
    public var submitted: Bool? = nil
    public var submissionDate: Date? = nil
    public var exampleSubmission: Bool? = nil
    public var durationInMinutes: Float? = nil
    public var results: [Result]? = []
    public var participation: Participation? = nil

    public static var type: String {
        "TEST"
    }
}
