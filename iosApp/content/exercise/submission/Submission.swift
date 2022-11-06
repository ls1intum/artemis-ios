import Foundation

protocol Submission: Decodable {
    var id: Int? { get }
    var submitted: Bool? { get }
    var submissionDate: Date? { get }
    var exampleSubmission: Bool? { get }
    var durationInMinutes: Float? { get }
    var results: [Result] { get }
    var participation: Participation? { get }
}